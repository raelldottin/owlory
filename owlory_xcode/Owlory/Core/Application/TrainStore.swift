import Foundation
#if canImport(Combine)
import Combine
#endif

@MainActor
final class TrainStore: OwloryObservableObject {
    #if canImport(Combine)
    @Published private(set) var sessions: [TrainingSession] = []
    @Published var lastError: String?
    #else
    private(set) var sessions: [TrainingSession] = []
    var lastError: String?
    #endif

    private let repository: any ItemListRepository<TrainingSession>
    private let clock: Clock
    private weak var completionHistory: CompletionHistoryStore?
    private let onItemCompleted: ((String) -> Void)?

    init(
        repository: any ItemListRepository<TrainingSession>,
        clock: Clock,
        completionHistory: CompletionHistoryStore? = nil,
        onItemCompleted: ((String) -> Void)? = nil
    ) {
        self.repository = repository
        self.clock = clock
        self.completionHistory = completionHistory
        self.onItemCompleted = onItemCompleted
        load()
    }

    func load() {
        sessions = (try? repository.loadAll()) ?? []
        applyRecurringRollover()
    }

    @discardableResult
    func addSession(
        plannedActivity: String,
        readinessLevel: Int = 3,
        readinessNote: String = "",
        isRecurring: Bool = false,
        recurrenceIntervalDays: Int? = nil
    ) -> UUID {
        let session = TrainingSession(
            date: clock.now,
            plannedActivity: plannedActivity,
            readinessLevel: readinessLevel,
            readinessNote: readinessNote,
            isRecurring: isRecurring,
            recurrenceIntervalDays: recurrenceIntervalDays
        )
        sessions.append(session)
        persist()
        return session.id
    }

    func updateSession(id: UUID, actualActivity: String, status: TrainingStatus, reflection: String, reflectionAudioFileName: String? = nil, reflectionAudioTranscription: String? = nil) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        sessions[index].actualActivity = actualActivity
        sessions[index].status = status
        sessions[index].reflection = VoiceTranscriptionRoutingRules.applyFallback(
            reflectionAudioTranscription,
            to: reflection,
            in: .trainSessionReflection
        )
        if let audioFileName = reflectionAudioFileName {
            sessions[index].reflectionAudioFileName = audioFileName
        }
        if let transcription = reflectionAudioTranscription {
            sessions[index].reflectionAudioTranscription = transcription
        }
        if status == .completed || status == .modified {
            completionHistory?.logTrainingCompletion(
                activity: sessions[index].plannedActivity,
                completedAt: clock.now
            )
            onItemCompleted?(
                CompletionTimePredictor.key(forTrainingSession: sessions[index].plannedActivity)
            )
        }
        persist()
    }

    func updatePlannedActivity(id: UUID, plannedActivity: String) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        sessions[index].plannedActivity = plannedActivity
        persist()
    }

    func updateReadinessNote(id: UUID, readinessNote: String) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        sessions[index].readinessNote = readinessNote
        persist()
    }

    func updateReadinessLevel(id: UUID, readinessLevel: Int) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        sessions[index].readinessLevel = readinessLevel
        persist()
    }

    func deleteSession(id: UUID) {
        sessions.removeAll { $0.id == id }
        persist()
    }

    var todaySessions: [TrainingSession] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: clock.now)
        return sessions.filter { calendar.startOfDay(for: $0.date) == today }
    }

    var activeTodaySessions: [TrainingSession] {
        todaySessions.filter { $0.status == .planned }
    }

    var todaySession: TrainingSession? {
        activeTodaySessions.first
    }

    var pastSessions: [TrainingSession] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: clock.now)
        return sessions
            .filter { calendar.startOfDay(for: $0.date) < today }
            .sorted { $0.date > $1.date }
    }

    var historySessions: [TrainingSession] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: clock.now)
        return sessions
            .filter { session in
                let sessionDay = calendar.startOfDay(for: session.date)
                return sessionDay < today || session.status != .planned
            }
            .sorted { $0.date > $1.date }
    }

    private func applyRecurringRollover() {
        let result = RecurringRolloverPlanner.rolloverTrainingSessions(
            sessions,
            asOf: clock.now
        )
        sessions = result.sessions
        PerformanceTelemetry.notice(result.trace.telemetryMessage, category: .recurrence)
        if result.didChange { persist() }
    }

    private func persist() {
        do {
            try repository.saveAll(sessions)
            lastError = nil
        } catch {
            lastError = "Failed to save sessions: \(error.localizedDescription)"
        }
    }
}
