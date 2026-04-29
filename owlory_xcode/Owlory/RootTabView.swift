import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(WidgetKit)
import WidgetKit
#endif

struct RootTabView: View {
    @ObservedObject var todayStore: TodayStore
    @ObservedObject var trainStore: TrainStore
    @ObservedObject var writeStore: WriteStore
    @ObservedObject var careerStore: CareerStore
    @ObservedObject var homeStore: HomeStore
    @ObservedObject var patternStore: PatternStore
    @ObservedObject var completionHistory: CompletionHistoryStore
    var reminderScheduler: ReminderScheduler
    @ObservedObject var deepLinkRouter: OwloryDeepLinkRouter

    @State private var selectedTab: OwloryTab = .today
    @State private var continueHighlightTarget: TodayContinuationRules.HighlightTarget?
    @State private var continueSelectionID = UUID()

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                TodayView(
                    store: todayStore,
                    trainStore: trainStore,
                    writeStore: writeStore,
                    careerStore: careerStore,
                    homeStore: homeStore,
                    patternStore: patternStore,
                    completionHistory: completionHistory,
                    onContinueItemSelected: { item in
                        continueSelectionID = UUID()
                        continueHighlightTarget = item.highlightTarget
                        selectedTab = OwloryTab(domain: item.domain)
                    }
                )
            }
            .tabItem {
                Label("Today", systemImage: "sun.max")
            }
            .tag(OwloryTab.today)

            NavigationStack {
                TrainView(
                    store: trainStore,
                    patternStore: patternStore,
                    highlightedSessionID: highlightedTrainingSessionID
                )
            }
            .tabItem {
                Label("Train", systemImage: "figure.run")
            }
            .tag(OwloryTab.train)

            NavigationStack {
                WriteView(
                    store: writeStore,
                    todayStore: todayStore,
                    homeStore: homeStore,
                    patternStore: patternStore,
                    highlightedNoteID: highlightedWritingNoteID,
                    highlightedNoteSelectionID: highlightedWritingNoteSelectionID
                )
            }
            .tabItem {
                Label("Write", systemImage: "square.and.pencil")
            }
            .tag(OwloryTab.write)

            NavigationStack {
                CareerView(
                    store: careerStore,
                    highlightedRecordID: highlightedCareerRecordID
                )
            }
            .tabItem {
                Label("Career", systemImage: "briefcase")
            }
            .tag(OwloryTab.career)

            NavigationStack {
                HomeView(
                    store: homeStore,
                    writeStore: writeStore,
                    highlightedTaskID: highlightedHomeTaskID,
                    highlightedRunID: highlightedHomeRunID,
                    highlightedRunSelectionID: highlightedHomeRunSelectionID,
                    onSourceNoteSelected: { noteID in
                        continueSelectionID = UUID()
                        continueHighlightTarget = .writingNote(noteID)
                        selectedTab = .write
                    }
                )
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            .tag(OwloryTab.home)
        }
        .tint(OwloryColor.brandPrimary)
        .onAppear {
            synchronizeTodayPresentationArtifacts()
            refreshRuntimeArtifacts()
        }
        .onChange(of: reminderRefreshKey) { _, _ in
            synchronizeTodayPresentationArtifacts()
            refreshRuntimeArtifacts()
        }
        .onOpenURL { url in
            handleDeepLink(url)
        }
        .onChange(of: deepLinkRouter.pendingURL) { _, newValue in
            guard let url = newValue else { return }
            handleDeepLink(url)
            deepLinkRouter.clearPendingURL()
        }
        #if canImport(UIKit)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            todayStore.loadToday()
            trainStore.load()
            writeStore.load()
            careerStore.load()
            homeStore.load()
            patternStore.refresh()
            completionHistory.load()
            synchronizeTodayPresentationArtifacts()
            refreshRuntimeArtifacts()
        }
        #endif
    }

    private var currentTodayEntry: DailyEntry? {
        let entry: DailyEntry
        switch todayStore.entryState {
        case .active(let e), .setupIncomplete(let e), .reflected(let e), .historical(let e):
            entry = e
        case .missing:
            return nil
        }
        return entry
    }

    private var highlightedTrainingSessionID: UUID? {
        guard case .trainingSession(let id) = continueHighlightTarget else { return nil }
        return id
    }

    private var highlightedHomeTaskID: UUID? {
        guard case .homeTask(let id) = continueHighlightTarget else { return nil }
        return id
    }

    private var highlightedHomeRunID: UUID? {
        guard case .homeProtocolRun(let id) = continueHighlightTarget else { return nil }
        return id
    }

    private var highlightedHomeRunSelectionID: UUID? {
        guard case .homeProtocolRun = continueHighlightTarget else { return nil }
        return continueSelectionID
    }

    private var highlightedWritingNoteID: UUID? {
        guard case .writingNote(let id) = continueHighlightTarget else { return nil }
        return id
    }

    private var highlightedWritingNoteSelectionID: UUID? {
        guard case .writingNote = continueHighlightTarget else { return nil }
        return continueSelectionID
    }

    private var highlightedCareerRecordID: UUID? {
        guard case .careerRecord(let id) = continueHighlightTarget else { return nil }
        return id
    }

    private var reminderRefreshKey: String {
        let entryPart: String
        if let entry = currentTodayEntry {
            let focusPart = entry.focusThree
                .sorted { $0.id.uuidString < $1.id.uuidString }
                .map {
                    [
                        $0.id.uuidString,
                        $0.status.rawValue,
                        $0.domain.rawValue,
                        dateToken($0.createdFromDate),
                        $0.linkedRecordID?.uuidString ?? "nil",
                    ].joined(separator: "|")
                }
                .joined(separator: "||")
            entryPart = [
                dateToken(entry.date),
                "\(entry.energy)",
                "\(entry.mood)",
                "\(entry.sleepQuality)",
                entry.eveningReflection,
                focusPart,
            ].joined(separator: "|")
        } else {
            entryPart = "missing"
        }

        let homeTaskPart = homeStore.tasks
            .sorted { $0.id.uuidString < $1.id.uuidString }
            .map {
                [
                    $0.id.uuidString,
                    $0.title,
                    "\($0.isCompleted)",
                    "\($0.isSkipped)",
                    dateToken($0.lastCompleted),
                    dateToken($0.lastSkipped),
                ].joined(separator: "|")
            }
            .joined(separator: "||")

        let homeRunPart = homeStore.runs
            .sorted { $0.id.uuidString < $1.id.uuidString }
            .map {
                [
                    $0.id.uuidString,
                    $0.protocolTitle,
                    $0.status.rawValue,
                    dateToken($0.completedAt),
                    "\($0.resolvedStepCount)",
                ].joined(separator: "|")
            }
            .joined(separator: "||")

        let trainPart = trainStore.sessions
            .sorted { $0.id.uuidString < $1.id.uuidString }
            .map {
                [
                    $0.id.uuidString,
                    $0.plannedActivity,
                    $0.status.rawValue,
                    "\( $0.readinessLevel)",
                    dateToken($0.date),
                ].joined(separator: "|")
            }
            .joined(separator: "||")

        let writePart = writeStore.notes
            .sorted { $0.id.uuidString < $1.id.uuidString }
            .map {
                [
                    $0.id.uuidString,
                    $0.stage.title,
                ].joined(separator: "|")
            }
            .joined(separator: "||")

        let predictionPart = completionHistory.predictions.keys.sorted().compactMap { key in
            guard let prediction = completionHistory.predictions[key] else { return nil }
            return [
                key,
                "\(prediction.medianTimeOfDay)",
                "\(prediction.madSeconds)",
                "\(prediction.sampleCount)",
            ].joined(separator: "|")
        }
        .joined(separator: "||")

        return [entryPart, homeTaskPart, homeRunPart, trainPart, writePart, predictionPart].joined(separator: "###")
    }

    /// Build the set of item keys that are already completed today, then
    /// ask the scheduler to reschedule notifications for pending items.
    private func refreshRuntimeArtifacts() {
        let now = Date()
        var completedKeys = Set<String>()

        // Home tasks completed today
        for task in homeStore.completedTasks where task.isRecurring {
            completedKeys.insert(CompletionTimePredictor.key(forHomeTask: task.title))
        }

        // Training sessions completed/modified today
        for session in trainStore.todaySessions
            where session.status == .completed || session.status == .modified {
            completedKeys.insert(
                CompletionTimePredictor.key(forTrainingSession: session.plannedActivity))
        }

        // Protocol runs completed today
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: now)
        for run in homeStore.completedRuns {
            if let completedAt = run.completedAt,
               calendar.startOfDay(for: completedAt) == todayStart {
                completedKeys.insert(
                    CompletionTimePredictor.key(forProtocolRun: run.protocolTitle))
            }
        }

        let promptNotifications = currentTodayEntry.map {
            TodayStore.promptNotifications(
                for: $0,
                homeTasks: homeStore.tasks,
                now: now,
                calendar: calendar
            )
        } ?? []

        let plannedNotifications = reminderScheduler.plannedNotifications(
            predictions: completionHistory.predictions,
            completedKeys: completedKeys,
            promptNotifications: promptNotifications,
            now: now,
            calendar: calendar
        )

        reminderScheduler.reschedule(
            predictions: completionHistory.predictions,
            completedKeys: completedKeys,
            promptNotifications: promptNotifications,
            now: now
        )

        writeWidgetSnapshot(plannedNotifications.specs)
    }

    private func synchronizeTodayPresentationArtifacts() {
        todayStore.garbageCollectHomeProtocolFocusArtifacts(
            protocolRecordIDs: Set(homeStore.protocols.map(\.id) + homeStore.runs.map(\.id))
        )
        todayStore.markLinkedFocusItemsDone(for: completedFocusSources)
    }

    private var completedFocusSources: [TodayFocusCompletionSource] {
        var sources: [TodayFocusCompletionSource] = []

        sources.append(contentsOf: trainStore.sessions.compactMap { session in
            guard session.status == .completed || session.status == .modified else {
                return nil
            }
            return TodayFocusCompletionSource(domain: .training, linkedRecordID: session.id)
        })

        sources.append(contentsOf: homeStore.tasks.compactMap { task in
            guard task.isCompleted else { return nil }
            return TodayFocusCompletionSource(domain: .home, linkedRecordID: task.id)
        })

        sources.append(contentsOf: writeStore.notes.compactMap { note in
            guard note.stage == .published else { return nil }
            return TodayFocusCompletionSource(domain: .writing, linkedRecordID: note.id)
        })

        return sources
    }

    private func writeWidgetSnapshot(_ specs: [ReminderScheduler.NotificationSpec]) {
        guard let defaults = UserDefaults(suiteName: owloryWidgetAppGroupID) else { return }
        let encoder = JSONEncoder()

        if let data = try? encoder.encode(Array(specs.prefix(5))) {
            defaults.set(data, forKey: owloryWidgetNotificationStorageKey)
        } else {
            defaults.removeObject(forKey: owloryWidgetNotificationStorageKey)
        }

        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    private func handleDeepLink(_ url: URL) {
        guard let destination = OwloryDeepLink.parse(url) else { return }
        handleDeepLinkDestination(destination)
    }

    private func handleDeepLinkDestination(_ destination: OwloryDeepLink.Destination) {
        switch destination {
        case .today, .todayPrompt:
            continueSelectionID = UUID()
            continueHighlightTarget = nil
            selectedTab = .today
        case .completionKey(let key):
            routeCompletionKey(key)
        }
    }

    private func routeCompletionKey(_ key: String) {
        continueSelectionID = UUID()

        switch OwloryDeepLink.completionKeyDomain(key) {
        case "home":
            continueHighlightTarget = homeStore.tasks
                .first { CompletionTimePredictor.key(forHomeTask: $0.title) == key }
                .map { .homeTask($0.id) }
            selectedTab = .home
        case "train":
            continueHighlightTarget = trainStore.sessions
                .first { CompletionTimePredictor.key(forTrainingSession: $0.plannedActivity) == key }
                .map { .trainingSession($0.id) }
            selectedTab = .train
        case "protocol":
            continueHighlightTarget = homeStore.activeRuns
                .first { CompletionTimePredictor.key(forProtocolRun: $0.protocolTitle) == key }
                .map { .homeProtocolRun($0.id) }
            selectedTab = .home
        default:
            continueHighlightTarget = nil
            selectedTab = .today
        }
    }

    private func dateToken(_ date: Date?) -> String {
        guard let date else { return "nil" }
        return String(date.timeIntervalSince1970)
    }
}

private let owloryWidgetAppGroupID = "group.com.raelldottin.owlory.shared"
private let owloryWidgetNotificationStorageKey = "owlory.widget.notifications.v1"

private enum OwloryTab: Hashable {
    case today
    case train
    case write
    case career
    case home

    init(domain: LifeDomain) {
        switch domain {
        case .training:
            self = .train
        case .writing:
            self = .write
        case .career:
            self = .career
        case .home:
            self = .home
        }
    }
}
