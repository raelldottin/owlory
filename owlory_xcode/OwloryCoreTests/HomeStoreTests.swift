import XCTest
#if SWIFT_PACKAGE
@testable import OwloryCore
#endif

@MainActor
final class HomeStoreTests: XCTestCase {

    private func makeDate(_ string: String) -> Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: string)!
    }

    private func makeStore(now: Date = Date()) -> HomeStore {
        HomeStore(
            taskRepository: InMemoryItemListRepository<HomeTask>(),
            protocolRepository: InMemoryItemListRepository<HouseholdProtocol>(),
            runRepository: InMemoryItemListRepository<ProtocolRun>(),
            clock: FixedClock(now: now)
        )
    }

    // MARK: - Tasks

    func testAddTaskAppendsToList() {
        let store = makeStore()
        store.addTask(title: "Clean gutters", isRecurring: true, recurrenceIntervalDays: 90)
        XCTAssertEqual(store.tasks.count, 1)
        XCTAssertEqual(store.tasks[0].title, "Clean gutters")
        XCTAssertTrue(store.tasks[0].isRecurring)
        XCTAssertEqual(store.tasks[0].recurrenceIntervalDays, 90)
        XCTAssertFalse(store.tasks[0].isCompleted)
        XCTAssertFalse(store.tasks[0].isSkipped)
    }

    func testAddTaskReturnsUUID() {
        let store = makeStore()
        let id = store.addTask(title: "Linked Task")
        XCTAssertEqual(store.tasks[0].id, id)
    }

    func testHomeTaskDecodesLegacyTaskWithoutSkippedFields() throws {
        let json = """
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "title": "Legacy task",
            "isCompleted": false,
            "isRecurring": false,
            "notes": ""
        }
        """.data(using: .utf8)!

        let task = try JSONDecoder().decode(HomeTask.self, from: json)

        XCTAssertEqual(task.title, "Legacy task")
        XCTAssertFalse(task.isCompleted)
        XCTAssertFalse(task.isSkipped)
        XCTAssertNil(task.lastSkipped)
        XCTAssertNil(task.origin)
    }

    func testPromoteWritingNoteToTaskCreatesTaskWithOrigin() {
        let now = makeDate("2026-04-29T13:30:00Z")
        let store = makeStore(now: now)
        let noteID = UUID()
        let note = WritingNote(
            id: noteID,
            title: "  Email John about AWS billing  ",
            body: "Ask for the updated estimate before Friday.",
            createdDate: makeDate("2026-04-29T12:00:00Z")
        )

        let taskID = store.promoteWritingNoteToTask(note)

        XCTAssertEqual(store.tasks.count, 1)
        XCTAssertEqual(store.tasks.first?.id, taskID)
        XCTAssertEqual(store.tasks.first?.title, "Email John about AWS billing")
        XCTAssertEqual(store.tasks.first?.notes, "Ask for the updated estimate before Friday.")
        XCTAssertFalse(store.tasks.first?.isCompleted ?? true)
        XCTAssertFalse(store.tasks.first?.isSkipped ?? true)
        XCTAssertEqual(store.tasks.first?.origin?.kind, .writingNote)
        XCTAssertEqual(store.tasks.first?.origin?.id, noteID)
        XCTAssertEqual(store.tasks.first?.origin?.createdAt, now)
        XCTAssertEqual(note.id, noteID)
        XCTAssertEqual(note.title, "  Email John about AWS billing  ")
    }

    func testPromoteWritingNoteToTaskRejectsDuplicateOrigin() {
        let store = makeStore()
        let note = WritingNote(
            title: "Email John about AWS billing",
            body: "Ask for the updated estimate."
        )

        XCTAssertNotNil(store.promoteWritingNoteToTask(note))
        XCTAssertFalse(store.canPromoteWritingNoteToTask(note))
        XCTAssertNil(store.promoteWritingNoteToTask(note))
        XCTAssertEqual(store.tasks.count, 1)
    }

    func testPromoteWritingNoteToTaskRejectsBlankTitle() {
        let store = makeStore()
        let note = WritingNote(title: "   ", body: "Untitled actionable thought")

        XCTAssertFalse(store.canPromoteWritingNoteToTask(note))
        XCTAssertNil(store.promoteWritingNoteToTask(note))
        XCTAssertTrue(store.tasks.isEmpty)
    }

    func testToggleCompleteSetsCompletedAndDate() {
        let now = makeDate("2026-04-08T09:00:00Z")
        let store = makeStore(now: now)

        store.addTask(title: "Mow lawn")
        let id = store.tasks[0].id

        store.toggleComplete(id: id)
        XCTAssertTrue(store.tasks[0].isCompleted)
        XCTAssertNotNil(store.tasks[0].lastCompleted)

        store.toggleComplete(id: id)
        XCTAssertFalse(store.tasks[0].isCompleted)
    }

    func testActiveCompletedAndSkippedTasksFilterCorrectly() {
        let store = makeStore()
        store.addTask(title: "Active Task")
        store.addTask(title: "Done Task")
        store.addTask(title: "Skipped Task")
        store.toggleComplete(id: store.tasks[1].id)
        store.skipTask(id: store.tasks[2].id)

        XCTAssertEqual(store.activeTasks.count, 1)
        XCTAssertEqual(store.activeTasks[0].title, "Active Task")
        XCTAssertEqual(store.completedTasks.count, 1)
        XCTAssertEqual(store.completedTasks[0].title, "Done Task")
        XCTAssertEqual(store.skippedTasks.count, 1)
        XCTAssertEqual(store.skippedTasks[0].title, "Skipped Task")
    }

    func testSkipTaskMovesOutOfActiveWithoutCompletingIt() {
        let now = makeDate("2026-04-08T09:00:00Z")
        let store = makeStore(now: now)

        store.addTask(title: "Call plumber")
        let id = store.tasks[0].id

        store.skipTask(id: id)

        XCTAssertFalse(store.tasks[0].isCompleted)
        XCTAssertTrue(store.tasks[0].isSkipped)
        XCTAssertEqual(store.tasks[0].lastSkipped, now)
        XCTAssertTrue(store.activeTasks.isEmpty)
        XCTAssertTrue(store.completedTasks.isEmpty)
        XCTAssertEqual(store.skippedTasks.map(\.title), ["Call plumber"])
    }

    func testCompletingSkippedTaskClearsSkippedState() {
        let store = makeStore()
        store.addTask(title: "Call plumber")
        let id = store.tasks[0].id

        store.skipTask(id: id)
        store.toggleComplete(id: id)

        XCTAssertTrue(store.tasks[0].isCompleted)
        XCTAssertFalse(store.tasks[0].isSkipped)
        XCTAssertEqual(store.completedTasks.map(\.title), ["Call plumber"])
        XCTAssertTrue(store.skippedTasks.isEmpty)
    }

    func testRestoreTaskMovesSkippedTaskBackToActive() {
        let store = makeStore()
        store.addTask(title: "Call plumber")
        let id = store.tasks[0].id

        store.skipTask(id: id)
        store.restoreTask(id: id)

        XCTAssertFalse(store.tasks[0].isCompleted)
        XCTAssertFalse(store.tasks[0].isSkipped)
        XCTAssertEqual(store.activeTasks.map(\.title), ["Call plumber"])
    }

    func testDeleteTaskRemovesIt() {
        let store = makeStore()
        store.addTask(title: "To delete")
        let id = store.tasks[0].id
        store.deleteTask(id: id)
        XCTAssertTrue(store.tasks.isEmpty)
    }

    // MARK: - Protocols

    func testAddProtocolAppendsToList() {
        let store = makeStore()
        store.addProtocol(title: "Fix leaky faucet", steps: ["Turn off water", "Remove handle", "Replace washer"])
        XCTAssertEqual(store.protocols.count, 1)
        XCTAssertEqual(store.protocols[0].title, "Fix leaky faucet")
        XCTAssertEqual(store.protocols[0].steps.count, 3)
    }

    func testUpdateProtocolChangesContent() {
        let store = makeStore()
        store.addProtocol(title: "Original", steps: ["Step 1"])
        let id = store.protocols[0].id

        store.updateProtocol(id: id, title: "Updated", steps: ["New Step 1", "New Step 2"])
        XCTAssertEqual(store.protocols[0].title, "Updated")
        XCTAssertEqual(store.protocols[0].steps.count, 2)
    }

    func testDeleteProtocolRemovesIt() {
        let store = makeStore()
        store.addProtocol(title: "To delete", steps: [])
        let id = store.protocols[0].id
        store.deleteProtocol(id: id)
        XCTAssertTrue(store.protocols.isEmpty)
    }

    // MARK: - Recurring Task Reset

    func testRecurringTaskResetsWhenDue() {
        let day1 = makeDate("2026-04-01T09:00:00Z")
        let taskRepo = InMemoryItemListRepository<HomeTask>()
        let protoRepo = InMemoryItemListRepository<HouseholdProtocol>()
        let runRepo = InMemoryItemListRepository<ProtocolRun>()

        // Create store on day 1, add recurring task (7-day interval), complete it
        let store1 = HomeStore(taskRepository: taskRepo, protocolRepository: protoRepo, runRepository: runRepo, clock: FixedClock(now: day1))
        store1.addTask(title: "Water plants", isRecurring: true, recurrenceIntervalDays: 7)
        let taskId = store1.tasks[0].id
        store1.toggleComplete(id: taskId)
        XCTAssertTrue(store1.tasks[0].isCompleted)

        // Load on day 8 midday (well past calendar day boundary in any timezone)
        let day8 = makeDate("2026-04-08T12:00:00Z")
        let store2 = HomeStore(taskRepository: taskRepo, protocolRepository: protoRepo, runRepository: runRepo, clock: FixedClock(now: day8))
        XCTAssertFalse(store2.tasks[0].isCompleted, "Recurring task should reset at start of due calendar day")
    }

    func testSkippedRecurringTaskResetsWhenDue() {
        let day1 = makeDate("2026-04-01T09:00:00Z")
        let taskRepo = InMemoryItemListRepository<HomeTask>()
        let protoRepo = InMemoryItemListRepository<HouseholdProtocol>()
        let runRepo = InMemoryItemListRepository<ProtocolRun>()

        let store1 = HomeStore(taskRepository: taskRepo, protocolRepository: protoRepo, runRepository: runRepo, clock: FixedClock(now: day1))
        store1.addTask(title: "Water plants", isRecurring: true, recurrenceIntervalDays: 7)
        let taskId = store1.tasks[0].id
        store1.skipTask(id: taskId)
        XCTAssertTrue(store1.tasks[0].isSkipped)

        let day8 = makeDate("2026-04-08T12:00:00Z")
        let store2 = HomeStore(taskRepository: taskRepo, protocolRepository: protoRepo, runRepository: runRepo, clock: FixedClock(now: day8))
        XCTAssertFalse(store2.tasks[0].isCompleted)
        XCTAssertFalse(store2.tasks[0].isSkipped, "Skipped recurring task should reset at the next due calendar day")
        XCTAssertEqual(store2.activeTasks.map(\.title), ["Water plants"])
    }

    func testRecurringTaskResetsEarlyMorningOfDueDay() {
        let day1Evening = makeDate("2026-04-01T22:00:00Z")
        let taskRepo = InMemoryItemListRepository<HomeTask>()
        let protoRepo = InMemoryItemListRepository<HouseholdProtocol>()
        let runRepo = InMemoryItemListRepository<ProtocolRun>()

        let store1 = HomeStore(taskRepository: taskRepo, protocolRepository: protoRepo, runRepository: runRepo, clock: FixedClock(now: day1Evening))
        store1.addTask(title: "Daily review", isRecurring: true, recurrenceIntervalDays: 1)
        store1.toggleComplete(id: store1.tasks[0].id)
        XCTAssertTrue(store1.tasks[0].isCompleted)

        // Next morning at 6 AM - should already be reset (calendar day boundary, not 24h from 10 PM)
        let day2Morning = makeDate("2026-04-02T06:00:00Z")
        let store2 = HomeStore(taskRepository: taskRepo, protocolRepository: protoRepo, runRepository: runRepo, clock: FixedClock(now: day2Morning))
        XCTAssertFalse(store2.tasks[0].isCompleted, "Daily task completed at night should reset next morning")
    }

    func testRecurringTaskStaysCompleteBeforeInterval() {
        let day1 = makeDate("2026-04-01T09:00:00Z")
        let taskRepo = InMemoryItemListRepository<HomeTask>()
        let protoRepo = InMemoryItemListRepository<HouseholdProtocol>()
        let runRepo = InMemoryItemListRepository<ProtocolRun>()

        let store1 = HomeStore(taskRepository: taskRepo, protocolRepository: protoRepo, runRepository: runRepo, clock: FixedClock(now: day1))
        store1.addTask(title: "Water plants", isRecurring: true, recurrenceIntervalDays: 7)
        let taskId = store1.tasks[0].id
        store1.toggleComplete(id: taskId)

        // Load on day 5 (before the 7-day interval) - task should stay completed
        let day5 = makeDate("2026-04-05T09:00:00Z")
        let store2 = HomeStore(taskRepository: taskRepo, protocolRepository: protoRepo, runRepository: runRepo, clock: FixedClock(now: day5))
        XCTAssertTrue(store2.tasks[0].isCompleted, "Recurring task should stay complete before interval")
    }

    func testNonRecurringTaskNeverResets() {
        let day1 = makeDate("2026-04-01T09:00:00Z")
        let taskRepo = InMemoryItemListRepository<HomeTask>()
        let protoRepo = InMemoryItemListRepository<HouseholdProtocol>()
        let runRepo = InMemoryItemListRepository<ProtocolRun>()

        let store1 = HomeStore(taskRepository: taskRepo, protocolRepository: protoRepo, runRepository: runRepo, clock: FixedClock(now: day1))
        store1.addTask(title: "One-time task", isRecurring: false)
        let taskId = store1.tasks[0].id
        store1.toggleComplete(id: taskId)

        let day30 = makeDate("2026-05-01T09:00:00Z")
        let store2 = HomeStore(taskRepository: taskRepo, protocolRepository: protoRepo, runRepository: runRepo, clock: FixedClock(now: day30))
        XCTAssertTrue(store2.tasks[0].isCompleted, "Non-recurring task should never reset")
    }

    // MARK: - updateTask

    func testUpdateTaskChangesAllFields() {
        let store = makeStore()
        store.addTask(title: "Original", isRecurring: false, notes: "old notes")
        let id = store.tasks[0].id

        store.updateTask(id: id, title: "Updated", notes: "new notes", isRecurring: true, recurrenceIntervalDays: 14)

        XCTAssertEqual(store.tasks[0].title, "Updated")
        XCTAssertEqual(store.tasks[0].notes, "new notes")
        XCTAssertTrue(store.tasks[0].isRecurring)
        XCTAssertEqual(store.tasks[0].recurrenceIntervalDays, 14)
    }

    // MARK: - Protocol Runs

    func testStartRunCreatesStepsFromProtocol() {
        let store = makeStore()
        store.addProtocol(title: "Kitchen Reset", steps: ["Clear sink", "Wipe counters", "Sweep floor"])
        let protoID = store.protocols[0].id

        let runID = store.startRun(protocolID: protoID)
        XCTAssertNotNil(runID)
        XCTAssertEqual(store.runs.count, 1)

        let run = store.runs[0]
        XCTAssertEqual(run.protocolID, protoID)
        XCTAssertEqual(run.protocolTitle, "Kitchen Reset")
        XCTAssertEqual(run.status, .active)
        XCTAssertEqual(run.steps.count, 3)
        XCTAssertEqual(run.steps[0].title, "Clear sink")
        XCTAssertEqual(run.steps[0].stepNumber, 1)
        XCTAssertEqual(run.steps[0].status, .pending)
        XCTAssertEqual(run.steps[2].title, "Sweep floor")
        XCTAssertEqual(run.steps[2].stepNumber, 3)
    }

    func testContinueOrStartRunReturnsExistingActiveRunWithoutDuplicating() {
        let store = makeStore()
        store.addProtocol(title: "Kitchen Reset", steps: ["Clear sink", "Wipe counters"])
        let protoID = store.protocols[0].id

        guard let firstRunID = store.continueOrStartRun(protocolID: protoID) else {
            return XCTFail("Expected first run to start")
        }
        let continuedRunID = store.continueOrStartRun(protocolID: protoID)

        XCTAssertEqual(continuedRunID, firstRunID)
        XCTAssertEqual(store.runs.count, 1)
        XCTAssertEqual(store.activeRun(forProtocolID: protoID)?.id, firstRunID)
    }

    func testContinueOrStartRunFindsPersistedActiveRunAfterReload() {
        let day1 = makeDate("2026-04-11T10:00:00Z")
        let day2 = makeDate("2026-04-12T10:00:00Z")
        let taskRepo = InMemoryItemListRepository<HomeTask>()
        let protoRepo = InMemoryItemListRepository<HouseholdProtocol>()
        let runRepo = InMemoryItemListRepository<ProtocolRun>()

        let store1 = HomeStore(
            taskRepository: taskRepo,
            protocolRepository: protoRepo,
            runRepository: runRepo,
            clock: FixedClock(now: day1)
        )
        store1.addProtocol(title: "Weekend bathroom reset", steps: ["Sink", "Toilet"])
        let protoID = store1.protocols[0].id
        guard let firstRunID = store1.continueOrStartRun(protocolID: protoID) else {
            return XCTFail("Expected first run to start")
        }

        let store2 = HomeStore(
            taskRepository: taskRepo,
            protocolRepository: protoRepo,
            runRepository: runRepo,
            clock: FixedClock(now: day2)
        )
        let continuedRunID = store2.continueOrStartRun(protocolID: protoID)

        XCTAssertEqual(continuedRunID, firstRunID)
        XCTAssertEqual(store2.runs.count, 1)
        XCTAssertEqual(store2.activeRuns.map(\.id), [firstRunID])
    }

    func testStartRunStillAllowsExplicitSecondActiveRun() {
        let store = makeStore()
        store.addProtocol(title: "Kitchen Reset", steps: ["Clear sink", "Wipe counters"])
        let protoID = store.protocols[0].id

        guard let firstRunID = store.continueOrStartRun(protocolID: protoID) else {
            return XCTFail("Expected first run to start")
        }
        guard let secondRunID = store.startRun(protocolID: protoID) else {
            return XCTFail("Expected explicit second run to start")
        }

        XCTAssertNotEqual(secondRunID, firstRunID)
        XCTAssertEqual(store.runs.count, 2)
        XCTAssertEqual(store.activeRuns.count, 2)
    }

    func testContinueOrStartRunStartsNewAfterExistingRunCompletes() {
        let store = makeStore()
        store.addProtocol(title: "Single-step reset", steps: ["Clear sink"])
        let protoID = store.protocols[0].id
        let firstRunID = store.continueOrStartRun(protocolID: protoID)!

        store.completeStep(runID: firstRunID, stepID: store.runs[0].steps[0].id)
        guard let nextRunID = store.continueOrStartRun(protocolID: protoID) else {
            return XCTFail("Expected next run to start")
        }

        XCTAssertNotEqual(nextRunID, firstRunID)
        XCTAssertEqual(store.runs.count, 2)
        XCTAssertEqual(store.activeRuns.map(\.id), [nextRunID])
        XCTAssertEqual(store.completedRuns.map(\.id), [firstRunID])
    }

    func testStartRunWithEmptyProtocolReturnsNil() {
        let store = makeStore()
        store.addProtocol(title: "Empty", steps: [])
        let runID = store.startRun(protocolID: store.protocols[0].id)
        XCTAssertNil(runID)
        XCTAssertTrue(store.runs.isEmpty)
    }

    func testStartRunWithInvalidProtocolReturnsNil() {
        let store = makeStore()
        let runID = store.startRun(protocolID: UUID())
        XCTAssertNil(runID)
    }

    func testCompleteStepMarksItDone() {
        let store = makeStore()
        store.addProtocol(title: "Test", steps: ["Step 1", "Step 2"])
        let runID = store.startRun(protocolID: store.protocols[0].id)!

        let stepID = store.runs[0].steps[0].id
        store.completeStep(runID: runID, stepID: stepID)

        XCTAssertEqual(store.runs[0].steps[0].status, .completed)
        XCTAssertNotNil(store.runs[0].steps[0].completedAt)
        XCTAssertEqual(store.runs[0].steps[1].status, .pending)
        XCTAssertEqual(store.runs[0].status, .active)
    }

    func testSkipStepMarksItSkipped() {
        let store = makeStore()
        store.addProtocol(title: "Test", steps: ["Step 1", "Step 2"])
        let runID = store.startRun(protocolID: store.protocols[0].id)!

        let stepID = store.runs[0].steps[0].id
        store.skipStep(runID: runID, stepID: stepID)

        XCTAssertEqual(store.runs[0].steps[0].status, .skipped)
        XCTAssertEqual(store.runs[0].status, .active)
    }

    func testProtocolRunRemainsActiveAcrossDaysUntilResolved() {
        let day1 = makeDate("2026-04-11T10:00:00Z")
        let day2 = makeDate("2026-04-12T10:00:00Z")
        let taskRepo = InMemoryItemListRepository<HomeTask>()
        let protoRepo = InMemoryItemListRepository<HouseholdProtocol>()
        let runRepo = InMemoryItemListRepository<ProtocolRun>()

        let store1 = HomeStore(
            taskRepository: taskRepo,
            protocolRepository: protoRepo,
            runRepository: runRepo,
            clock: FixedClock(now: day1)
        )
        store1.addProtocol(
            title: "Weekend bathroom reset",
            steps: ["Sink", "Toilet", "Shower", "Floor"]
        )
        let runID = store1.startRun(protocolID: store1.protocols[0].id)!
        store1.completeStep(runID: runID, stepID: store1.runs[0].steps[0].id)
        store1.completeStep(runID: runID, stepID: store1.runs[0].steps[1].id)

        let store2 = HomeStore(
            taskRepository: taskRepo,
            protocolRepository: protoRepo,
            runRepository: runRepo,
            clock: FixedClock(now: day2)
        )

        XCTAssertEqual(store2.activeRuns.count, 1)
        XCTAssertEqual(store2.completedRuns.count, 0)
        XCTAssertEqual(store2.runs[0].status, .active)
        XCTAssertEqual(store2.runs[0].completedStepCount, 2)
        XCTAssertEqual(store2.runs[0].resolvedStepCount, 2)
        XCTAssertEqual(store2.runs[0].nextPendingStepNumber, 3)
        XCTAssertEqual(store2.runs[0].startedDayCount(asOf: day2), 1)
        XCTAssertEqual(store2.protocols[0].steps, ["Sink", "Toilet", "Shower", "Floor"])
    }

    func testRunAutoCompletesWhenAllStepsResolved() {
        let store = makeStore()
        store.addProtocol(title: "Test", steps: ["Step 1", "Step 2"])
        let runID = store.startRun(protocolID: store.protocols[0].id)!

        store.completeStep(runID: runID, stepID: store.runs[0].steps[0].id)
        XCTAssertEqual(store.runs[0].status, .active)

        store.skipStep(runID: runID, stepID: store.runs[0].steps[1].id)
        XCTAssertEqual(store.runs[0].status, .completed)
        XCTAssertNotNil(store.runs[0].completedAt)
    }

    func testCompletingFinishedRunDoesNotAppendDuplicateHistory() throws {
        let now = makeDate("2026-04-18T10:00:00Z")
        let taskRepo = InMemoryItemListRepository<HomeTask>()
        let protoRepo = InMemoryItemListRepository<HouseholdProtocol>()
        let runRepo = InMemoryItemListRepository<ProtocolRun>()
        let historyRepo = InMemoryItemListRepository<CompletionTimePredictor.CompletionRecord>()
        let completionHistory = CompletionHistoryStore(
            repository: historyRepo,
            clock: FixedClock(now: now)
        )
        let store = HomeStore(
            taskRepository: taskRepo,
            protocolRepository: protoRepo,
            runRepository: runRepo,
            clock: FixedClock(now: now),
            completionHistory: completionHistory
        )
        store.addProtocol(title: "Kitchen Reset", steps: ["Clear sink"])
        let runID = store.startRun(protocolID: store.protocols[0].id)!
        let stepID = store.runs[0].steps[0].id

        store.completeStep(runID: runID, stepID: stepID)
        store.completeStep(runID: runID, stepID: stepID)

        let records = try historyRepo.loadAll()
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.itemKey, CompletionTimePredictor.key(forProtocolRun: "Kitchen Reset"))
    }

    func testAbandonRunSetsStatusAndDate() {
        let store = makeStore()
        store.addProtocol(title: "Test", steps: ["Step 1"])
        let runID = store.startRun(protocolID: store.protocols[0].id)!

        store.abandonRun(id: runID)
        XCTAssertEqual(store.runs[0].status, .abandoned)
        XCTAssertNotNil(store.runs[0].completedAt)
    }

    func testActiveCompletedAndTerminalRunsFilter() {
        let store = makeStore()
        store.addProtocol(title: "Test", steps: ["Step 1"])
        let protoID = store.protocols[0].id

        let run1ID = store.startRun(protocolID: protoID)!
        let run2ID = store.startRun(protocolID: protoID)!
        let run3ID = store.startRun(protocolID: protoID)!

        store.completeStep(runID: run1ID, stepID: store.runs[0].steps[0].id)
        store.abandonRun(id: run2ID)

        XCTAssertEqual(store.activeRuns.count, 1)
        XCTAssertEqual(store.completedRuns.count, 1)
        XCTAssertEqual(store.completedRuns.map(\.id), [run1ID])
        XCTAssertEqual(store.terminalRuns.count, 2)
        XCTAssertEqual(Set(store.terminalRuns.map(\.id)), Set([run1ID, run2ID]))
        XCTAssertEqual(store.activeRuns.map(\.id), [run3ID])
    }

    func testHighlightedRunToPresentReturnsRunForNewActiveRequest() {
        let runID = UUID()
        let requestID = UUID()

        let presented = HomeContinueRouting.highlightedRunToPresent(
            highlightedRunID: runID,
            requestID: requestID,
            lastPresentedRequestID: nil,
            activeRunIDs: Set([runID])
        )

        XCTAssertEqual(presented, runID)
    }

    func testHighlightedRunToPresentRejectsRepeatedOrInactiveRequests() {
        let runID = UUID()
        let requestID = UUID()

        XCTAssertNil(
            HomeContinueRouting.highlightedRunToPresent(
                highlightedRunID: runID,
                requestID: requestID,
                lastPresentedRequestID: requestID,
                activeRunIDs: Set([runID])
            )
        )

        XCTAssertNil(
            HomeContinueRouting.highlightedRunToPresent(
                highlightedRunID: runID,
                requestID: requestID,
                lastPresentedRequestID: nil,
                activeRunIDs: []
            )
        )

        XCTAssertNil(
            HomeContinueRouting.highlightedRunToPresent(
                highlightedRunID: nil,
                requestID: requestID,
                lastPresentedRequestID: nil,
                activeRunIDs: Set([runID])
            )
        )
    }

    func testAddStepNoteUpdatesNote() {
        let store = makeStore()
        store.addProtocol(title: "Test", steps: ["Step 1"])
        let runID = store.startRun(protocolID: store.protocols[0].id)!
        let stepID = store.runs[0].steps[0].id

        store.addStepNote(runID: runID, stepID: stepID, note: "Used different cleaner")
        XCTAssertEqual(store.runs[0].steps[0].note, "Used different cleaner")
    }

    func testRunProgressComputation() {
        let store = makeStore()
        store.addProtocol(title: "Test", steps: ["Step 1", "Step 2", "Step 3"])
        let runID = store.startRun(protocolID: store.protocols[0].id)!

        XCTAssertEqual(store.runs[0].completedStepCount, 0)
        XCTAssertEqual(store.runs[0].resolvedStepCount, 0)
        XCTAssertEqual(store.runs[0].totalStepCount, 3)
        XCTAssertEqual(store.runs[0].currentStepIndex, 0)
        XCTAssertEqual(store.runs[0].nextPendingStepNumber, 1)

        store.completeStep(runID: runID, stepID: store.runs[0].steps[0].id)
        XCTAssertEqual(store.runs[0].completedStepCount, 1)
        XCTAssertEqual(store.runs[0].resolvedStepCount, 1)
        XCTAssertEqual(store.runs[0].currentStepIndex, 1)
        XCTAssertEqual(store.runs[0].nextPendingStepNumber, 2)

        store.skipStep(runID: runID, stepID: store.runs[0].steps[1].id)
        XCTAssertEqual(store.runs[0].completedStepCount, 1)
        XCTAssertEqual(store.runs[0].resolvedStepCount, 2)
        XCTAssertEqual(store.runs[0].currentStepIndex, 2)
        XCTAssertEqual(store.runs[0].nextPendingStepNumber, 3)
    }

    func testRunDoesNotMutateOriginalProtocol() {
        let store = makeStore()
        store.addProtocol(title: "Kitchen Reset", steps: ["Clear sink", "Wipe counters"])
        let protoID = store.protocols[0].id
        let runID = store.startRun(protocolID: protoID)!

        store.completeStep(runID: runID, stepID: store.runs[0].steps[0].id)
        store.addStepNote(runID: runID, stepID: store.runs[0].steps[0].id, note: "Used bleach")

        // Original protocol unchanged
        XCTAssertEqual(store.protocols[0].steps, ["Clear sink", "Wipe counters"])
        XCTAssertEqual(store.protocols[0].title, "Kitchen Reset")
    }
}
