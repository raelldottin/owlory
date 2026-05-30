import Foundation

enum LifeDomain: String, CaseIterable, Identifiable, Codable {
    case training
    case writing
    case career
    case home

    var id: String { rawValue }

    var title: String {
        switch self {
        case .training: return "Train"
        case .writing: return "Write"
        case .career: return "Career"
        case .home: return "Home"
        }
    }
}

enum FocusItemStatus: String, CaseIterable, Codable {
    case planned
    case done
    case deferred
    case dropped
}

enum DailyEntryState: Equatable {
    case missing
    case setupIncomplete(DailyEntry)
    case active(DailyEntry)
    case reflected(DailyEntry)
    case historical(DailyEntry)
}

struct OwloryItemOrigin: Equatable, Codable {
    enum Kind: String, Codable {
        case trainingSession
        case writingNote
        case careerRecord
        case homeTask
        case homeProtocolRun
    }

    var kind: Kind
    var id: UUID
    var createdAt: Date
}

typealias FocusItemOrigin = OwloryItemOrigin

struct FocusItem: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var domain: LifeDomain
    var status: FocusItemStatus
    var createdFromDate: Date?
    var linkedRecordID: UUID?
    var origin: FocusItemOrigin?
    /// How the item entered Owlory. `nil` means user-authored (default).
    var provenance: Provenance?

    init(
        id: UUID = UUID(),
        title: String,
        domain: LifeDomain,
        status: FocusItemStatus = .planned,
        createdFromDate: Date? = nil,
        linkedRecordID: UUID? = nil,
        origin: FocusItemOrigin? = nil,
        provenance: Provenance? = nil
    ) {
        self.id = id
        self.title = title
        self.domain = domain
        self.status = status
        self.createdFromDate = createdFromDate
        self.linkedRecordID = linkedRecordID
        self.origin = origin
        self.provenance = provenance
    }
}

struct DailyEntry: Identifiable, Equatable, Codable {
    let id: UUID
    var date: Date
    var focusThree: [FocusItem]
    var domainIntentions: [LifeDomain: String]
    var energy: Int
    var mood: Int
    var sleepQuality: Int
    var carryForward: [FocusItem]
    var eveningReflection: String
    var reflectionAudioFileName: String?
    var reflectionAudioTranscription: String?

    init(
        id: UUID = UUID(),
        date: Date,
        focusThree: [FocusItem] = [],
        domainIntentions: [LifeDomain: String] = [:],
        energy: Int = 3,
        mood: Int = 3,
        sleepQuality: Int = 3,
        carryForward: [FocusItem] = [],
        eveningReflection: String = "",
        reflectionAudioFileName: String? = nil,
        reflectionAudioTranscription: String? = nil
    ) {
        self.id = id
        self.date = date
        self.focusThree = focusThree
        self.domainIntentions = domainIntentions
        self.energy = energy
        self.mood = mood
        self.sleepQuality = sleepQuality
        self.carryForward = carryForward
        self.eveningReflection = eveningReflection
        self.reflectionAudioFileName = reflectionAudioFileName
        self.reflectionAudioTranscription = reflectionAudioTranscription
    }

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case focusThree
        case domainIntentions
        case energy
        case mood
        case sleepQuality
        case carryForward
        case eveningReflection
        case reflectionAudioFileName
        case reflectionAudioTranscription
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        date = try container.decode(Date.self, forKey: .date)
        focusThree = try Self.decodeFocusItems(from: container, forKey: .focusThree)
        domainIntentions = try Self.decodeDomainIntentions(from: container, forKey: .domainIntentions)
        energy = try container.decodeIfPresent(Int.self, forKey: .energy) ?? 3
        mood = try container.decodeIfPresent(Int.self, forKey: .mood) ?? 3
        sleepQuality = try container.decodeIfPresent(Int.self, forKey: .sleepQuality) ?? 3
        carryForward = try Self.decodeFocusItems(from: container, forKey: .carryForward)
        eveningReflection = try container.decodeIfPresent(String.self, forKey: .eveningReflection) ?? ""
        reflectionAudioFileName = try container.decodeIfPresent(String.self, forKey: .reflectionAudioFileName)
        reflectionAudioTranscription = try container.decodeIfPresent(String.self, forKey: .reflectionAudioTranscription)
    }

    private static func decodeFocusItems(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) throws -> [FocusItem] {
        guard var itemContainer = try? container.nestedUnkeyedContainer(forKey: key) else { return [] }

        var items: [FocusItem] = []
        while !itemContainer.isAtEnd {
            let item = try itemContainer.decode(StoredFocusItem.self)
            guard let domain = item.domain.flatMap(LifeDomain.init(rawValue:)) else { continue }
            items.append(
                FocusItem(
                    id: item.id ?? UUID(),
                    title: item.title ?? "",
                    domain: domain,
                    status: item.status ?? .planned,
                    createdFromDate: item.createdFromDate,
                    linkedRecordID: item.linkedRecordID,
                    origin: item.origin,
                    provenance: item.provenance
                )
            )
        }
        return items
    }

    private static func decodeDomainIntentions(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) throws -> [LifeDomain: String] {
        if var intentions = try? container.nestedUnkeyedContainer(forKey: key) {
            var decoded: [LifeDomain: String] = [:]
            while !intentions.isAtEnd {
                let rawDomain = try intentions.decode(String.self)
                let text = try intentions.decode(String.self)
                guard let domain = LifeDomain(rawValue: rawDomain) else { continue }
                decoded[domain] = text
            }
            return decoded
        }

        let keyedIntentions = try container.decodeIfPresent([String: String].self, forKey: key) ?? [:]
        return keyedIntentions.reduce(into: [:]) { result, pair in
            guard let domain = LifeDomain(rawValue: pair.key) else { return }
            result[domain] = pair.value
        }
    }

    private struct StoredFocusItem: Decodable {
        let id: UUID?
        let title: String?
        let domain: String?
        let status: FocusItemStatus?
        let createdFromDate: Date?
        let linkedRecordID: UUID?
        let origin: FocusItemOrigin?
        let provenance: Provenance?
    }
}

enum WritingStage: Int, CaseIterable, Identifiable, Codable {
    case capture
    case source
    case permanent
    case draftSeed
    case draft
    case published
    case archived

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .capture: return "Capture"
        case .source: return "Source Note"
        case .permanent: return "Permanent Note"
        case .draftSeed: return "Draft Seed"
        case .draft: return "Draft"
        case .published: return "Published"
        case .archived: return "Archived"
        }
    }
}

enum WritingSourceType: String, CaseIterable, Identifiable, Codable {
    case article
    case book
    case video
    case podcast
    case webpage
    case conversation
    case document
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .article: return "Article"
        case .book: return "Book"
        case .video: return "Video"
        case .podcast: return "Podcast"
        case .webpage: return "Webpage"
        case .conversation: return "Conversation"
        case .document: return "Document"
        case .other: return "Other"
        }
    }
}

struct WritingSourceMetadata: Equatable, Codable {
    var sourceTitle: String
    var creator: String
    var url: String
    var type: WritingSourceType
    var sourceDate: String
    var citation: String
    var quote: String

    init(
        sourceTitle: String = "",
        creator: String = "",
        url: String = "",
        type: WritingSourceType = .article,
        sourceDate: String = "",
        citation: String = "",
        quote: String = ""
    ) {
        self.sourceTitle = sourceTitle
        self.creator = creator
        self.url = url
        self.type = type
        self.sourceDate = sourceDate
        self.citation = citation
        self.quote = quote
    }
}

struct WritingNote: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var body: String
    var stage: WritingStage
    var createdDate: Date
    var audioFileName: String?
    var audioTranscription: String?
    var sourceMetadata: WritingSourceMetadata?

    init(
        id: UUID = UUID(),
        title: String,
        body: String,
        stage: WritingStage = .capture,
        createdDate: Date = Date(),
        audioFileName: String? = nil,
        audioTranscription: String? = nil,
        sourceMetadata: WritingSourceMetadata? = nil
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.stage = stage
        self.createdDate = createdDate
        self.audioFileName = audioFileName
        self.audioTranscription = audioTranscription
        self.sourceMetadata = sourceMetadata
    }
}

// MARK: - Training

enum TrainingStatus: String, CaseIterable, Codable {
    case planned
    case completed
    case modified
    case skipped

    static let editableCases: [TrainingStatus] = [.planned, .completed, .skipped]
}

struct TrainingSession: Identifiable, Equatable, Codable {
    let id: UUID
    var date: Date
    var plannedActivity: String
    var actualActivity: String
    var status: TrainingStatus
    var readinessLevel: Int
    var readinessNote: String
    var reflection: String
    var reflectionAudioFileName: String?
    var reflectionAudioTranscription: String?
    var isRecurring: Bool
    var recurrenceIntervalDays: Int?

    init(
        id: UUID = UUID(),
        date: Date,
        plannedActivity: String,
        actualActivity: String = "",
        status: TrainingStatus = .planned,
        readinessLevel: Int = 3,
        readinessNote: String = "",
        reflection: String = "",
        reflectionAudioFileName: String? = nil,
        reflectionAudioTranscription: String? = nil,
        isRecurring: Bool = false,
        recurrenceIntervalDays: Int? = nil
    ) {
        self.id = id
        self.date = date
        self.plannedActivity = plannedActivity
        self.actualActivity = actualActivity
        self.status = status
        self.readinessLevel = readinessLevel
        self.readinessNote = readinessNote
        self.reflection = reflection
        self.reflectionAudioFileName = reflectionAudioFileName
        self.reflectionAudioTranscription = reflectionAudioTranscription
        self.isRecurring = isRecurring
        self.recurrenceIntervalDays = recurrenceIntervalDays
    }

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case plannedActivity
        case actualActivity
        case status
        case readinessLevel
        case readinessNote
        case reflection
        case reflectionAudioFileName
        case reflectionAudioTranscription
        case isRecurring
        case recurrenceIntervalDays
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        date = try container.decode(Date.self, forKey: .date)
        plannedActivity = try container.decode(String.self, forKey: .plannedActivity)
        actualActivity = try container.decodeIfPresent(String.self, forKey: .actualActivity) ?? ""
        status = try container.decodeIfPresent(TrainingStatus.self, forKey: .status) ?? .planned
        readinessLevel = try container.decodeIfPresent(Int.self, forKey: .readinessLevel) ?? 3
        readinessNote = try container.decodeIfPresent(String.self, forKey: .readinessNote) ?? ""
        reflection = try container.decodeIfPresent(String.self, forKey: .reflection) ?? ""
        reflectionAudioFileName = try container.decodeIfPresent(String.self, forKey: .reflectionAudioFileName)
        reflectionAudioTranscription = try container.decodeIfPresent(String.self, forKey: .reflectionAudioTranscription)
        isRecurring = try container.decodeIfPresent(Bool.self, forKey: .isRecurring) ?? false
        recurrenceIntervalDays = try container.decodeIfPresent(Int.self, forKey: .recurrenceIntervalDays)
    }
}

// MARK: - Career

enum CareerRecordType: String, CaseIterable, Identifiable, Codable {
    case win
    case impact
    case story

    var id: String { rawValue }

    var title: String {
        switch self {
        case .win: return "Win"
        case .impact: return "Impact"
        case .story: return "Story"
        }
    }
}

struct CareerRecord: Identifiable, Equatable, Codable {
    let id: UUID
    var date: Date
    var type: CareerRecordType
    var title: String
    var body: String
    var metrics: String
    var audioFileName: String?
    var audioTranscription: String?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        type: CareerRecordType,
        title: String,
        body: String = "",
        metrics: String = "",
        audioFileName: String? = nil,
        audioTranscription: String? = nil
    ) {
        self.id = id
        self.date = date
        self.type = type
        self.title = title
        self.body = body
        self.metrics = metrics
        self.audioFileName = audioFileName
        self.audioTranscription = audioTranscription
    }
}

// MARK: - Home

struct HomeTask: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var isSkipped: Bool
    var isRecurring: Bool
    var recurrenceIntervalDays: Int?
    var lastCompleted: Date?
    var lastSkipped: Date?
    var notes: String
    var audioFileName: String?
    var audioTranscription: String?
    var origin: OwloryItemOrigin?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case isCompleted
        case isSkipped
        case isRecurring
        case recurrenceIntervalDays
        case lastCompleted
        case lastSkipped
        case notes
        case audioFileName
        case audioTranscription
        case origin
    }

    init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        isSkipped: Bool = false,
        isRecurring: Bool = false,
        recurrenceIntervalDays: Int? = nil,
        lastCompleted: Date? = nil,
        lastSkipped: Date? = nil,
        notes: String = "",
        audioFileName: String? = nil,
        audioTranscription: String? = nil,
        origin: OwloryItemOrigin? = nil
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.isSkipped = isSkipped
        self.isRecurring = isRecurring
        self.recurrenceIntervalDays = recurrenceIntervalDays
        self.lastCompleted = lastCompleted
        self.lastSkipped = lastSkipped
        self.notes = notes
        self.audioFileName = audioFileName
        self.audioTranscription = audioTranscription
        self.origin = origin
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        isSkipped = try container.decodeIfPresent(Bool.self, forKey: .isSkipped) ?? false
        isRecurring = try container.decodeIfPresent(Bool.self, forKey: .isRecurring) ?? false
        recurrenceIntervalDays = try container.decodeIfPresent(Int.self, forKey: .recurrenceIntervalDays)
        lastCompleted = try container.decodeIfPresent(Date.self, forKey: .lastCompleted)
        lastSkipped = try container.decodeIfPresent(Date.self, forKey: .lastSkipped)
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        audioFileName = try container.decodeIfPresent(String.self, forKey: .audioFileName)
        audioTranscription = try container.decodeIfPresent(String.self, forKey: .audioTranscription)
        origin = try container.decodeIfPresent(OwloryItemOrigin.self, forKey: .origin)
    }
}

enum HomeTaskPromotionRules {
    static func taskPromotedFromWritingNote(
        _ note: WritingNote,
        in tasks: [HomeTask]
    ) -> HomeTask? {
        tasks.first { task in
            isTaskLinkedToWritingNote(task, noteID: note.id)
        }
    }

    static func canPromoteWritingNoteToTask(
        _ note: WritingNote,
        in tasks: [HomeTask]
    ) -> Bool {
        let title = note.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return false }

        return taskPromotedFromWritingNote(note, in: tasks) == nil
    }

    static func taskPromotingWritingNote(
        _ note: WritingNote,
        id: UUID,
        promotedAt: Date,
        in tasks: [HomeTask]
    ) -> HomeTask? {
        guard canPromoteWritingNoteToTask(note, in: tasks) else { return nil }

        return HomeTask(
            id: id,
            title: note.title.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: note.body.trimmingCharacters(in: .whitespacesAndNewlines),
            origin: OwloryItemOrigin(
                kind: .writingNote,
                id: note.id,
                createdAt: promotedAt
            )
        )
    }

    private static func isTaskLinkedToWritingNote(_ task: HomeTask, noteID: UUID) -> Bool {
        task.origin?.kind == .writingNote && task.origin?.id == noteID
    }
}

enum ProtocolSchedulePreset: String, Codable, CaseIterable, Hashable, Identifiable {
    case today
    case weekend
    case thisWeek
    case custom

    var id: Self { self }
}

struct HouseholdProtocolSchedule: Equatable, Codable, Hashable {
    var preset: ProtocolSchedulePreset
    var startDate: Date
    var endDate: Date

    init(
        preset: ProtocolSchedulePreset,
        startDate: Date,
        endDate: Date
    ) {
        self.preset = preset
        self.startDate = startDate
        self.endDate = endDate
    }
}

struct HouseholdProtocol: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var steps: [String]
    var origin: OwloryItemOrigin?
    var schedule: HouseholdProtocolSchedule?
    var isArchived: Bool

    init(
        id: UUID = UUID(),
        title: String,
        steps: [String] = [],
        origin: OwloryItemOrigin? = nil,
        schedule: HouseholdProtocolSchedule? = nil,
        isArchived: Bool = false
    ) {
        self.id = id
        self.title = title
        self.steps = steps
        self.origin = origin
        self.schedule = schedule
        self.isArchived = isArchived
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case steps
        case origin
        case schedule
        case isArchived
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decode(String.self, forKey: .title)
        steps = try container.decodeIfPresent([String].self, forKey: .steps) ?? []
        origin = try container.decodeIfPresent(OwloryItemOrigin.self, forKey: .origin)
        schedule = try container.decodeIfPresent(HouseholdProtocolSchedule.self, forKey: .schedule)
        isArchived = try container.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
    }
}

enum HomeProtocolPromotionRules {
    static func protocolPromotedFromWritingNote(
        _ note: WritingNote,
        in protocols: [HouseholdProtocol]
    ) -> HouseholdProtocol? {
        protocols.first { proto in
            isProtocolLinkedToWritingNote(proto, noteID: note.id)
        }
    }

    static func canPromoteWritingNoteToProtocol(
        _ note: WritingNote,
        in protocols: [HouseholdProtocol]
    ) -> Bool {
        let title = note.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return false }

        return protocolPromotedFromWritingNote(note, in: protocols) == nil
    }

    static func protocolPromotingWritingNote(
        _ note: WritingNote,
        id: UUID,
        promotedAt: Date,
        in protocols: [HouseholdProtocol]
    ) -> HouseholdProtocol? {
        guard canPromoteWritingNoteToProtocol(note, in: protocols) else { return nil }

        return HouseholdProtocol(
            id: id,
            title: note.title.trimmingCharacters(in: .whitespacesAndNewlines),
            steps: protocolSteps(from: note.body),
            origin: OwloryItemOrigin(
                kind: .writingNote,
                id: note.id,
                createdAt: promotedAt
            )
        )
    }

    private static func isProtocolLinkedToWritingNote(_ proto: HouseholdProtocol, noteID: UUID) -> Bool {
        proto.origin?.kind == .writingNote && proto.origin?.id == noteID
    }

    private static func protocolSteps(from body: String) -> [String] {
        body.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

// MARK: - Protocol Runs

enum ProtocolRunStatus: String, Codable, Equatable {
    case active
    case completed
    case abandoned
}

enum ProtocolStepStatus: String, Codable, Equatable {
    case pending
    case completed
    case skipped
}

struct ProtocolStepInstance: Identifiable, Equatable, Codable {
    let id: UUID
    let stepNumber: Int
    var title: String
    var status: ProtocolStepStatus
    var completedAt: Date?
    var note: String

    init(
        id: UUID = UUID(),
        stepNumber: Int,
        title: String,
        status: ProtocolStepStatus = .pending,
        completedAt: Date? = nil,
        note: String = ""
    ) {
        self.id = id
        self.stepNumber = stepNumber
        self.title = title
        self.status = status
        self.completedAt = completedAt
        self.note = note
    }
}

struct ProtocolRun: Identifiable, Equatable, Codable {
    let id: UUID
    let protocolID: UUID
    let protocolTitle: String
    var status: ProtocolRunStatus
    let createdAt: Date
    var completedAt: Date?
    var steps: [ProtocolStepInstance]

    init(
        id: UUID = UUID(),
        protocolID: UUID,
        protocolTitle: String,
        status: ProtocolRunStatus = .active,
        createdAt: Date,
        completedAt: Date? = nil,
        steps: [ProtocolStepInstance] = []
    ) {
        self.id = id
        self.protocolID = protocolID
        self.protocolTitle = protocolTitle
        self.status = status
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.steps = steps
    }

    var completedStepCount: Int {
        steps.filter { $0.status == .completed }.count
    }

    var resolvedStepCount: Int {
        steps.filter { $0.status != .pending }.count
    }

    var totalStepCount: Int {
        steps.count
    }

    var currentStepIndex: Int? {
        steps.firstIndex { $0.status == .pending }
    }

    var nextPendingStepNumber: Int? {
        guard let currentStepIndex else { return nil }
        return steps[currentStepIndex].stepNumber
    }

    var isFinished: Bool {
        steps.allSatisfy { $0.status != .pending }
    }

    func startedDayCount(asOf date: Date, calendar: Calendar = .current) -> Int {
        let startDay = calendar.startOfDay(for: createdAt)
        let comparisonDay = calendar.startOfDay(for: date)
        let dayCount = calendar.dateComponents([.day], from: startDay, to: comparisonDay).day ?? 0
        return max(0, dayCount)
    }
}
