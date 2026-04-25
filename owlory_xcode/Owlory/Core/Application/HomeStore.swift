import Foundation
#if canImport(Combine)
import Combine
#endif

enum HomeContinueRouting {
    static func highlightedRunToPresent(
        highlightedRunID: UUID?,
        requestID: UUID?,
        lastPresentedRequestID: UUID?,
        activeRunIDs: Set<UUID>
    ) -> UUID? {
        guard let highlightedRunID,
              let requestID,
              requestID != lastPresentedRequestID,
              activeRunIDs.contains(highlightedRunID) else {
            return nil
        }

        return highlightedRunID
    }
}

@MainActor
final class HomeStore: OwloryObservableObject {
    #if canImport(Combine)
    @Published private(set) var tasks: [HomeTask] = []
    @Published private(set) var protocols: [HouseholdProtocol] = []
    @Published private(set) var runs: [ProtocolRun] = []
    @Published var lastError: String?
    #else
    private(set) var tasks: [HomeTask] = []
    private(set) var protocols: [HouseholdProtocol] = []
    private(set) var runs: [ProtocolRun] = []
    var lastError: String?
    #endif

    private let taskRepository: any ItemListRepository<HomeTask>
    private let protocolRepository: any ItemListRepository<HouseholdProtocol>
    private let runRepository: any ItemListRepository<ProtocolRun>
    private let clock: Clock
    private weak var completionHistory: CompletionHistoryStore?

    init(
        taskRepository: any ItemListRepository<HomeTask>,
        protocolRepository: any ItemListRepository<HouseholdProtocol>,
        runRepository: any ItemListRepository<ProtocolRun>,
        clock: Clock,
        completionHistory: CompletionHistoryStore? = nil
    ) {
        self.taskRepository = taskRepository
        self.protocolRepository = protocolRepository
        self.runRepository = runRepository
        self.clock = clock
        self.completionHistory = completionHistory
        load()
    }

    func load() {
        tasks = (try? taskRepository.loadAll()) ?? []
        protocols = (try? protocolRepository.loadAll()) ?? []
        runs = (try? runRepository.loadAll()) ?? []
        applyRecurringTaskRollover()
    }

    // MARK: - Tasks

    @discardableResult
    func addTask(title: String, isRecurring: Bool = false, recurrenceIntervalDays: Int? = nil, notes: String = "", audioFileName: String? = nil, audioTranscription: String? = nil) -> UUID {
        let task = HomeTask(
            title: title,
            isRecurring: isRecurring,
            recurrenceIntervalDays: recurrenceIntervalDays,
            notes: notes,
            audioFileName: audioFileName,
            audioTranscription: audioTranscription
        )
        tasks.append(task)
        persistTasks()
        return task.id
    }

    func toggleComplete(id: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[index].isCompleted.toggle()
        if tasks[index].isCompleted {
            tasks[index].isSkipped = false
            tasks[index].lastCompleted = clock.now
            if tasks[index].isRecurring {
                completionHistory?.logHomeTaskCompletion(
                    title: tasks[index].title,
                    completedAt: clock.now
                )
            }
        }
        persistTasks()
    }

    func skipTask(id: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[index].isCompleted = false
        tasks[index].isSkipped = true
        tasks[index].lastSkipped = clock.now
        persistTasks()
    }

    func restoreTask(id: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[index].isSkipped = false
        persistTasks()
    }

    func updateTask(id: UUID, title: String, notes: String, isRecurring: Bool, recurrenceIntervalDays: Int?) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[index].title = title
        tasks[index].notes = notes
        tasks[index].isRecurring = isRecurring
        tasks[index].recurrenceIntervalDays = recurrenceIntervalDays
        persistTasks()
    }

    func deleteTask(id: UUID) {
        tasks.removeAll { $0.id == id }
        persistTasks()
    }

    var activeTasks: [HomeTask] {
        tasks.filter { !$0.isCompleted && !$0.isSkipped }
    }

    var completedTasks: [HomeTask] {
        tasks.filter { $0.isCompleted }
    }

    var skippedTasks: [HomeTask] {
        tasks.filter { $0.isSkipped }
    }

    // MARK: - Protocols

    func addProtocol(title: String, steps: [String]) {
        let proto = HouseholdProtocol(title: title, steps: steps)
        protocols.append(proto)
        persistProtocols()
    }

    func updateProtocol(id: UUID, title: String, steps: [String]) {
        guard let index = protocols.firstIndex(where: { $0.id == id }) else { return }
        protocols[index].title = title
        protocols[index].steps = steps
        persistProtocols()
    }

    func deleteProtocol(id: UUID) {
        protocols.removeAll { $0.id == id }
        persistProtocols()
    }

    // MARK: - Protocol Runs

    func activeRun(forProtocolID protocolID: UUID) -> ProtocolRun? {
        activeRuns.first { $0.protocolID == protocolID }
    }

    @discardableResult
    func continueOrStartRun(protocolID: UUID) -> UUID? {
        startRun(
            protocolID: protocolID,
            mode: .resumeExistingIfActive
        )
    }

    @discardableResult
    func startRun(protocolID: UUID) -> UUID? {
        startRun(
            protocolID: protocolID,
            mode: .explicitNewRun
        )
    }

    private func startRun(
        protocolID: UUID,
        mode: ProtocolLifecycleRules.StartMode
    ) -> UUID? {
        let proto = protocols.first { $0.id == protocolID }
        let decision = ProtocolLifecycleRules.startDecision(
            template: proto,
            activeRun: activeRun(forProtocolID: protocolID),
            mode: mode
        )

        switch decision {
        case .resumeExisting(let runID):
            return runID
        case .startNew:
            guard let proto else { return nil }
            return appendRun(from: proto)
        case .reject:
            return nil
        }
    }

    private func appendRun(from proto: HouseholdProtocol) -> UUID? {
        let stepIDs = proto.steps.map { _ in UUID() }
        guard let run = ProtocolLifecycleRules.makeRun(
            from: proto,
            runID: UUID(),
            stepIDs: stepIDs,
            createdAt: clock.now
        ) else {
            return nil
        }
        runs.append(run)
        persistRuns()
        return run.id
    }

    func completeStep(runID: UUID, stepID: UUID) {
        guard let runIndex = runs.firstIndex(where: { $0.id == runID }) else { return }
        let result = ProtocolLifecycleRules.resolveStep(
            in: runs[runIndex],
            stepID: stepID,
            resolution: .complete,
            at: clock.now
        )
        guard result.run != runs[runIndex] else { return }
        runs[runIndex] = result.run
        if result.didCompleteRun {
            logProtocolRunCompletion(runIndex: runIndex)
        }
        persistRuns()
    }

    func skipStep(runID: UUID, stepID: UUID) {
        guard let runIndex = runs.firstIndex(where: { $0.id == runID }) else { return }
        let result = ProtocolLifecycleRules.resolveStep(
            in: runs[runIndex],
            stepID: stepID,
            resolution: .skip,
            at: clock.now
        )
        guard result.run != runs[runIndex] else { return }
        runs[runIndex] = result.run
        if result.didCompleteRun {
            logProtocolRunCompletion(runIndex: runIndex)
        }
        persistRuns()
    }

    func addStepNote(runID: UUID, stepID: UUID, note: String) {
        guard let runIndex = runs.firstIndex(where: { $0.id == runID }) else { return }
        guard let stepIndex = runs[runIndex].steps.firstIndex(where: { $0.id == stepID }) else { return }
        runs[runIndex].steps[stepIndex].note = note
        persistRuns()
    }

    func abandonRun(id: UUID) {
        guard let index = runs.firstIndex(where: { $0.id == id }) else { return }
        let updated = ProtocolLifecycleRules.abandon(runs[index], at: clock.now)
        guard updated != runs[index] else { return }
        runs[index] = updated
        persistRuns()
    }

    var activeRuns: [ProtocolRun] {
        runs.filter { $0.status == .active }
    }

    var completedRuns: [ProtocolRun] {
        sortRunsByResolutionDate(
            runs.filter { $0.status == .completed }
        )
    }

    var terminalRuns: [ProtocolRun] {
        sortRunsByResolutionDate(
            runs.filter { $0.status != .active }
        )
    }

    private func logProtocolRunCompletion(runIndex: Int) {
        completionHistory?.logProtocolRunCompletion(
            protocolTitle: runs[runIndex].protocolTitle,
            completedAt: runs[runIndex].completedAt ?? clock.now
        )
    }

    private func sortRunsByResolutionDate(_ runs: [ProtocolRun]) -> [ProtocolRun] {
        runs.sorted { ($0.completedAt ?? $0.createdAt) > ($1.completedAt ?? $1.createdAt) }
    }

    private func persistRuns() {
        do {
            try runRepository.saveAll(runs)
            lastError = nil
        } catch {
            lastError = "Failed to save runs: \(error.localizedDescription)"
        }
    }

    private func applyRecurringTaskRollover() {
        let result = RecurringRolloverPlanner.rolloverHomeTasks(
            tasks,
            asOf: clock.now
        )
        tasks = result.tasks
        PerformanceTelemetry.notice(result.trace.telemetryMessage, category: .recurrence)
        if result.didChange { persistTasks() }
    }

    private func persistTasks() {
        do {
            try taskRepository.saveAll(tasks)
            lastError = nil
        } catch {
            lastError = "Failed to save tasks: \(error.localizedDescription)"
        }
    }

    private func persistProtocols() {
        do {
            try protocolRepository.saveAll(protocols)
            lastError = nil
        } catch {
            lastError = "Failed to save protocols: \(error.localizedDescription)"
        }
    }

}
