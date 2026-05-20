import Foundation
#if canImport(Combine)
import Combine
typealias OwloryObservableObject = ObservableObject
#else
protocol OwloryObservableObject: AnyObject {}
#endif

struct TodayFocusCompletionSource: Equatable {
    let domain: LifeDomain
    let linkedRecordID: UUID

    func matches(_ item: FocusItem) -> Bool {
        item.domain == domain && item.linkedRecordID == linkedRecordID
    }
}

@MainActor
final class TodayStore: OwloryObservableObject {
#if canImport(Combine)
    @Published private(set) var entryState: DailyEntryState = .missing
    @Published private(set) var recentEntries: [DailyEntry] = []
    @Published private(set) var focusSuggestionDrafts: [FocusSuggestionDraft] = []
    @Published private(set) var lastLoadUsedCarryForward = false
    @Published var lastError: String?
#else
    private(set) var entryState: DailyEntryState = .missing
    private(set) var recentEntries: [DailyEntry] = []
    private(set) var focusSuggestionDrafts: [FocusSuggestionDraft] = []
    private(set) var lastLoadUsedCarryForward = false
    var lastError: String?
#endif

    private let clock: Clock
    private let calendar: Calendar
    private let repository: any TodayEntryRepository & TodayEntryRangeRepository
    private var dismissedFocusSuggestionKeys: Set<String> = []
    private let onItemCompleted: ((String) -> Void)?

    init(
        clock: Clock,
        repository: any TodayEntryRepository & TodayEntryRangeRepository,
        calendar: Calendar = .current,
        onItemCompleted: ((String) -> Void)? = nil
    ) {
        self.clock = clock
        self.repository = repository
        self.calendar = calendar
        self.onItemCompleted = onItemCompleted
        loadToday()
    }

    func loadToday() {
        let today = calendar.startOfDay(for: clock.now)
        focusSuggestionDrafts = []
        dismissedFocusSuggestionKeys.removeAll()

        if let existing = (try? repository.loadEntry(for: today)) {
            lastLoadUsedCarryForward = false
            entryState = initialState(for: existing)
            loadRecentEntries()
            return
        }

        let seeded = seedEntry(for: today)
        lastLoadUsedCarryForward = !seeded.carryForward.isEmpty
        entryState = .setupIncomplete(seeded)
        persistCurrentEntry()
        loadRecentEntries()
    }

    func loadRecentEntries(daysBack: Int = 30) {
        let today = calendar.startOfDay(for: clock.now)
        guard let startDate = calendar.date(byAdding: .day, value: -daysBack, to: today) else {
            recentEntries = []
            return
        }

        do {
            recentEntries = try repository.loadEntries(from: startDate, through: today)
                .filter { calendar.startOfDay(for: $0.date) < today }
                .sorted { $0.date > $1.date }
            lastError = nil
        } catch {
            lastError = "Failed to load previous days: \(error.localizedDescription)"
        }
    }

    func markSetupComplete() {
        switch entryState {
        case .setupIncomplete(let entry):
            entryState = .active(entry)
            persistCurrentEntry()
        default:
            break
        }
    }

    func saveReflection(_ text: String, audioFileName: String? = nil) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        switch entryState {
        case .active(var entry), .setupIncomplete(var entry):
            entry.eveningReflection = text
            entry.reflectionAudioFileName = audioFileName ?? entry.reflectionAudioFileName
            entryState = .reflected(entry)
            persistCurrentEntry()
        case .reflected(var entry):
            entry.eveningReflection = text
            entry.reflectionAudioFileName = audioFileName ?? entry.reflectionAudioFileName
            entryState = .reflected(entry)
            persistCurrentEntry()
        default:
            break
        }
    }

    func addFocusItem(
        title: String,
        domain: LifeDomain,
        linkedRecordID: UUID? = nil,
        origin: FocusItemOrigin? = nil
    ) {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let item = FocusItem(title: title, domain: domain, linkedRecordID: linkedRecordID, origin: origin)
        mutateEntry { entry in
            entry = DailyPlanningRules.addingFocusItem(item, to: entry)
        }
    }

    func canPromoteWritingNoteToToday(_ note: WritingNote) -> Bool {
        guard let entry = currentEntry else { return false }
        return DailyPlanningRules.canPromoteWritingNoteToFocus(note, in: entry)
    }

    func focusItemPromotedFromWritingNote(_ note: WritingNote) -> FocusItem? {
        guard let entry = currentEntry else { return nil }
        return entry.focusThree.first { item in
            if item.origin?.kind == .writingNote && item.origin?.id == note.id {
                return true
            }

            return item.domain == .writing && item.linkedRecordID == note.id
        }
    }

    @discardableResult
    func promoteWritingNoteToToday(_ note: WritingNote) -> Bool {
        guard canPromoteWritingNoteToToday(note) else { return false }

        mutateEntry { entry in
            entry = DailyPlanningRules.promotingWritingNoteToFocus(
                note,
                in: entry,
                promotedAt: clock.now
            )
        }
        return true
    }

    func canAddContinueItemToFocus(_ item: TodayContinuationRules.ContinueItem) -> Bool {
        guard item.supportsAddToFocus,
              let entry = currentEntry,
              entry.focusThree.count < DailyPlanningRules.focusItemLimit else {
            return false
        }

        let looseKey = FocusSuggestionRules.key(
            title: item.title,
            domain: item.domain,
            linkedRecordID: nil
        )
        let exactKey = FocusSuggestionRules.key(
            title: item.title,
            domain: item.domain,
            linkedRecordID: item.focusLinkedRecordID
        )
        guard !looseKey.isEmpty else { return false }

        let existingKeys = Set(entry.focusThree.flatMap { focusItem in
            [
                FocusSuggestionRules.key(
                    title: focusItem.title,
                    domain: focusItem.domain,
                    linkedRecordID: nil
                ),
                FocusSuggestionRules.key(
                    title: focusItem.title,
                    domain: focusItem.domain,
                    linkedRecordID: focusItem.linkedRecordID
                ),
            ].filter { !$0.isEmpty }
        })

        return !existingKeys.contains(looseKey) && !existingKeys.contains(exactKey)
    }

    func addContinueItemToFocus(_ item: TodayContinuationRules.ContinueItem) {
        guard canAddContinueItemToFocus(item) else { return }
        addFocusItem(
            title: item.title,
            domain: item.domain,
            linkedRecordID: item.focusLinkedRecordID,
            origin: item.focusOrigin(createdAt: clock.now)
        )
    }

    func garbageCollectHomeProtocolFocusArtifacts(protocolRecordIDs: Set<UUID>) {
        guard !protocolRecordIDs.isEmpty,
              let entry = currentEntry else { return }

        let hasInvalidFocusArtifact = entry.focusThree.contains { item in
            item.domain == .home &&
                item.linkedRecordID.map(protocolRecordIDs.contains) == true
        }
        let hasInvalidCarryForwardArtifact = entry.carryForward.contains { item in
            item.domain == .home &&
                item.linkedRecordID.map(protocolRecordIDs.contains) == true
        }
        guard hasInvalidFocusArtifact || hasInvalidCarryForwardArtifact else { return }

        mutateEntry { entry in
            entry.focusThree.removeAll { item in
                item.domain == .home &&
                    item.linkedRecordID.map(protocolRecordIDs.contains) == true
            }
            entry.carryForward.removeAll { item in
                item.domain == .home &&
                    item.linkedRecordID.map(protocolRecordIDs.contains) == true
            }
        }
    }

    func refreshFocusSuggestions(
        todayEntry: DailyEntry,
        weeklySnapshot: PatternSnapshot?,
        candidates: [FocusSuggestionCandidate]
    ) {
        let calibration = CalibrationRules.calibrate(
            todayEntry: todayEntry,
            weeklySnapshot: weeklySnapshot
        )

        focusSuggestionDrafts = FocusSuggestionRules.drafts(
            todayEntry: todayEntry,
            suggestedFocusLoad: calibration.suggestedFocusLoad,
            candidates: candidates,
            dismissedKeys: dismissedFocusSuggestionKeys
        )
    }

    nonisolated static func eveningReflectionNudge(
        for entry: DailyEntry,
        homeTasks: [HomeTask],
        now: Date,
        calendar: Calendar = .current
    ) -> EveningReflectionNudge? {
        guard entry.eveningReflection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        let hasHomeTasks = !homeTasks.isEmpty
        let allHomeTasksCompleted = hasHomeTasks && homeTasks.allSatisfy { $0.isCompleted && !$0.isSkipped }
        let hour = calendar.component(.hour, from: now)
        guard hour >= 18 else {
            return nil
        }

        if allHomeTasksCompleted {
            return EveningReflectionNudge(kind: .homeWrappedReflection)
        }

        return EveningReflectionNudge(kind: .eveningReflection)
    }

    nonisolated static func hasCheckIn(_ entry: DailyEntry) -> Bool {
        entry.energy != 3 || entry.mood != 3 || entry.sleepQuality != 3
    }

    nonisolated static func promptNotifications(
        for entry: DailyEntry,
        homeTasks: [HomeTask],
        now: Date,
        calendar: Calendar = .current
    ) -> [PromptNotification] {
        var prompts: [PromptNotification] = []

        if let checkInPrompt = checkInPromptNotification(for: entry, now: now, calendar: calendar) {
            prompts.append(checkInPrompt)
        }

        if let reflectionPrompt = reflectionPromptNotification(
            for: entry,
            homeTasks: homeTasks,
            now: now,
            calendar: calendar
        ) {
            prompts.append(reflectionPrompt)
        }

        return prompts.sorted {
            if $0.deadline == $1.deadline {
                return $0.id < $1.id
            }
            return $0.deadline < $1.deadline
        }
    }

    private nonisolated static func checkInPromptNotification(
        for entry: DailyEntry,
        now: Date,
        calendar: Calendar
    ) -> PromptNotification? {
        guard !hasCheckIn(entry) else { return nil }

        let currentHour = calendar.component(.hour, from: now)
        guard currentHour < 18 else { return nil }

        let todayStart = calendar.startOfDay(for: now)
        let morningPrompt = calendar.date(byAdding: .hour, value: 9, to: todayStart) ?? now
        let deadline = morningPrompt > now
            ? morningPrompt
            : nextPromptSlot(after: now, calendar: calendar)

        return PromptNotification(
            id: "today.check-in",
            kind: .checkIn,
            title: "Check-in",
            body: "Take a quick read on energy, mood, and sleep.",
            deadline: deadline
        )
    }

    private nonisolated static func reflectionPromptNotification(
        for entry: DailyEntry,
        homeTasks: [HomeTask],
        now: Date,
        calendar: Calendar
    ) -> PromptNotification? {
        guard entry.eveningReflection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        let hasHomeTasks = !homeTasks.isEmpty
        let allHomeTasksCompleted = hasHomeTasks && homeTasks.allSatisfy { $0.isCompleted && !$0.isSkipped }
        let todayStart = calendar.startOfDay(for: now)
        let eveningPrompt = calendar.date(byAdding: .hour, value: 18, to: todayStart) ?? now
        let isEvening = eveningPrompt <= now
        let deadline: Date
        let kind: PromptNotification.Kind
        let title: String
        let body: String

        if allHomeTasksCompleted && isEvening {
            deadline = nextPromptSlot(after: now, calendar: calendar)
            kind = .homeWrappedReflection
            title = "Home wrapped"
            body = "All home tasks are done. Close the day with one quick reflection."
        } else if eveningPrompt > now {
            deadline = eveningPrompt
            kind = .eveningReflection
            title = "Evening reflection"
            body = "Close the day with one quick reflection."
        } else {
            deadline = nextPromptSlot(after: now, calendar: calendar)
            kind = .eveningReflection
            title = "Evening reflection"
            body = "Close the day with one quick reflection."
        }

        return PromptNotification(
            id: "today.\(kind.rawValue)",
            kind: kind,
            title: title,
            body: body,
            deadline: deadline
        )
    }

    private nonisolated static func nextPromptSlot(
        after now: Date,
        calendar: Calendar
    ) -> Date {
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now)
        let roundedMinute = ((components.minute ?? 0) / 15 + 1) * 15
        let base = calendar.date(from: components) ?? now
        return calendar.date(byAdding: .minute, value: roundedMinute - (components.minute ?? 0), to: base) ?? now
    }

    func acceptFocusSuggestion(id: UUID) {
        guard let suggestion = focusSuggestionDrafts.first(where: { $0.id == id }) else { return }
        addFocusItem(
            title: suggestion.title,
            domain: suggestion.domain,
            linkedRecordID: suggestion.linkedRecordID
        )
        focusSuggestionDrafts.removeAll { $0.id == id }
        dismissedFocusSuggestionKeys.remove(suggestion.key)
    }

    func dismissFocusSuggestion(id: UUID) {
        guard let suggestion = focusSuggestionDrafts.first(where: { $0.id == id }) else { return }
        focusSuggestionDrafts.removeAll { $0.id == id }
        dismissedFocusSuggestionKeys.insert(suggestion.key)
    }

    func removeFocusItem(id: UUID) {
        mutateEntry { entry in
            entry = DailyPlanningRules.removingFocusItem(id: id, from: entry)
        }
    }

    func updateDomainIntention(domain: LifeDomain, text: String) {
        mutateEntry { entry in
            entry.domainIntentions[domain] = text
        }
    }

    func updateReadiness(energy: Int, mood: Int, sleepQuality: Int) {
        mutateEntry { entry in
            entry.energy = energy
            entry.mood = mood
            entry.sleepQuality = sleepQuality
        }
    }

    func updateStatus(for itemID: UUID, to status: FocusItemStatus) {
        let completionKey: String?
        switch entryState {
        case .setupIncomplete(var entry):
            completionKey = itemCompletionKey(for: itemID, to: status, in: entry)
            update(itemID: itemID, status: status, in: &entry)
            entryState = .setupIncomplete(entry)
            persistCurrentEntry()
        case .active(var entry):
            completionKey = itemCompletionKey(for: itemID, to: status, in: entry)
            update(itemID: itemID, status: status, in: &entry)
            entryState = .active(entry)
            persistCurrentEntry()
        case .reflected(var entry):
            completionKey = itemCompletionKey(for: itemID, to: status, in: entry)
            update(itemID: itemID, status: status, in: &entry)
            entryState = .reflected(entry)
            persistCurrentEntry()
        default:
            completionKey = nil
        }

        if let completionKey {
            onItemCompleted?(completionKey)
        }
    }

    func markLinkedFocusItemsDone(for completedSources: [TodayFocusCompletionSource]) {
        guard !completedSources.isEmpty,
              let entry = currentEntry,
              entry.focusThree.contains(where: { item in
                  item.status == .planned && completedSources.contains { $0.matches(item) }
              }) else {
            return
        }

        mutateEntry { entry in
            for index in entry.focusThree.indices {
                let item = entry.focusThree[index]
                guard item.status == .planned,
                      completedSources.contains(where: { $0.matches(item) }) else {
                    continue
                }

                entry.focusThree[index].status = .done
            }
        }
    }

    private func mutateEntry(_ mutation: (inout DailyEntry) -> Void) {
        switch entryState {
        case .setupIncomplete(var entry):
            mutation(&entry)
            entryState = .setupIncomplete(entry)
            persistCurrentEntry()
        case .active(var entry):
            mutation(&entry)
            entryState = .active(entry)
            persistCurrentEntry()
        case .reflected(var entry):
            mutation(&entry)
            entryState = .reflected(entry)
            persistCurrentEntry()
        default:
            break
        }
    }

    private func update(itemID: UUID, status: FocusItemStatus, in entry: inout DailyEntry) {
        entry = DailyPlanningRules.updatingStatus(for: itemID, to: status, in: entry)
    }

    private func itemCompletionKey(
        for itemID: UUID,
        to status: FocusItemStatus,
        in entry: DailyEntry
    ) -> String? {
        guard status == .done,
              let item = entry.focusThree.first(where: { $0.id == itemID }),
              item.status != .done else {
            return nil
        }

        return itemCompletionKey(for: item)
    }

    private func itemCompletionKey(for item: FocusItem) -> String? {
        guard let origin = item.origin else { return nil }

        switch origin.kind {
        case .trainingSession:
            return CompletionTimePredictor.key(forTrainingSession: item.title)
        case .homeTask:
            return CompletionTimePredictor.key(forHomeTask: item.title)
        case .homeProtocolRun:
            return CompletionTimePredictor.key(forProtocolRun: item.title)
        case .writingNote, .careerRecord:
            return nil
        }
    }

    private func persistCurrentEntry() {
        guard let entry = currentEntry else { return }
        do {
            try repository.saveEntry(entry)
            loadRecentEntries()
            lastError = nil
        } catch {
            lastError = "Failed to save today's entry: \(error.localizedDescription)"
        }
    }

    private var currentEntry: DailyEntry? {
        switch entryState {
        case .missing:
            return nil
        case .setupIncomplete(let entry), .active(let entry), .reflected(let entry), .historical(let entry):
            return entry
        }
    }

    private func initialState(for entry: DailyEntry) -> DailyEntryState {
        if !entry.eveningReflection.isEmpty {
            return .reflected(entry)
        }
        return .active(entry)
    }

    private func seedEntry(for today: Date) -> DailyEntry {
        let priorDate = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let carryForward: [FocusItem]
        if let previous = (try? repository.loadEntry(for: priorDate)) {
            carryForward = CarryForwardRules.nextDayItems(from: previous, into: today)
        } else {
            carryForward = []
        }

        return DailyPlanningRules.seedEntry(for: today, carryForward: carryForward)
    }

}

extension TodayStore {
    typealias FocusSuggestionActiveItem = FocusSuggestionRules.ActiveItem
    typealias FocusSuggestionCandidate = FocusSuggestionRules.Candidate
    typealias FocusSuggestionDraft = FocusSuggestionRules.Draft

    nonisolated static func makeFocusSuggestionCandidates(
        todayEntry: DailyEntry,
        recentEntries: [DailyEntry],
        predictions: [String: CompletionTimePredictor.Prediction],
        now: Date,
        calendar: Calendar = .current,
        activeItems: [FocusSuggestionActiveItem] = []
    ) -> [FocusSuggestionCandidate] {
        FocusSuggestionRules.candidates(
            todayEntry: todayEntry,
            recentEntries: recentEntries,
            predictions: predictions,
            now: now,
            calendar: calendar,
            activeItems: activeItems
        )
    }

    struct EveningReflectionNudge: Equatable {
        enum Kind: Equatable {
            case eveningReflection
            case homeWrappedReflection
        }

        let kind: Kind
    }

    struct PromptNotification: Equatable {
        enum Kind: String, Equatable {
            case checkIn = "check-in"
            case eveningReflection = "evening-reflection"
            case homeWrappedReflection = "home-wrapped-reflection"
        }

        let id: String
        let kind: Kind
        let title: String
        let body: String
        let deadline: Date
    }
}
