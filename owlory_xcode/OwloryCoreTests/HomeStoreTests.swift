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

    func testHouseholdProtocolDecodesLegacyProtocolWithoutSchedule() throws {
        let json = """
        {
            "id": "00000000-0000-0000-0000-000000000002",
            "title": "Legacy protocol",
            "steps": ["Step one"],
            "origin": null
        }
        """.data(using: .utf8)!

        let proto = try JSONDecoder().decode(HouseholdProtocol.self, from: json)

        XCTAssertEqual(proto.title, "Legacy protocol")
        XCTAssertEqual(proto.steps, ["Step one"])
        XCTAssertNil(proto.schedule)
        XCTAssertFalse(proto.isArchived)
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

    func testTaskPromotedFromWritingNoteReturnsExistingDestination() {
        let store = makeStore()
        let note = WritingNote(
            title: "Email John about AWS billing",
            body: "Ask for the updated estimate."
        )

        let taskID = store.promoteWritingNoteToTask(note)
        let promotedTask = store.taskPromotedFromWritingNote(note)

        XCTAssertEqual(promotedTask?.id, taskID)
        XCTAssertEqual(promotedTask?.origin?.kind, .writingNote)
        XCTAssertEqual(promotedTask?.origin?.id, note.id)
    }

    func testPromoteWritingNoteToTaskRejectsBlankTitle() {
        let store = makeStore()
        let note = WritingNote(title: "   ", body: "Untitled actionable thought")

        XCTAssertFalse(store.canPromoteWritingNoteToTask(note))
        XCTAssertNil(store.promoteWritingNoteToTask(note))
        XCTAssertTrue(store.tasks.isEmpty)
    }

    func testTaskSourceRoutingReturnsAvailableWritingNoteRoute() {
        let noteID = UUID()
        let task = HomeTask(
            title: "Email John",
            origin: OwloryItemOrigin(
                kind: .writingNote,
                id: noteID,
                createdAt: makeDate("2026-04-29T13:30:00Z")
            )
        )
        let note = WritingNote(id: noteID, title: "Email John", body: "Draft context")

        let route = HomeTaskSourceRouting.writeNoteRoute(
            for: task,
            writingNotes: [note]
        )

        XCTAssertEqual(route, .availableWritingNote(noteID))
    }

    func testTaskSourceRoutingReturnsMissingWritingNoteRoute() {
        let noteID = UUID()
        let task = HomeTask(
            title: "Email John",
            origin: OwloryItemOrigin(
                kind: .writingNote,
                id: noteID,
                createdAt: makeDate("2026-04-29T13:30:00Z")
            )
        )

        let route = HomeTaskSourceRouting.writeNoteRoute(
            for: task,
            writingNotes: []
        )

        XCTAssertEqual(route, .missingWritingNote(noteID))
    }

    func testTaskSourceRoutingHidesNonWriteOrigins() {
        let taskWithoutOrigin = HomeTask(title: "Clean gutters")
        let taskWithHomeOrigin = HomeTask(
            title: "Clean gutters",
            origin: OwloryItemOrigin(
                kind: .homeTask,
                id: UUID(),
                createdAt: makeDate("2026-04-29T13:30:00Z")
            )
        )

        XCTAssertEqual(
            HomeTaskSourceRouting.writeNoteRoute(for: taskWithoutOrigin, writingNotes: []),
            .none
        )
        XCTAssertEqual(
            HomeTaskSourceRouting.writeNoteRoute(for: taskWithHomeOrigin, writingNotes: []),
            .none
        )
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
        XCTAssertNil(store.protocols[0].schedule)
    }

    func testAddProtocolStoresScheduleWindow() {
        let store = makeStore()
        let schedule = HouseholdProtocolSchedule(
            preset: .weekend,
            startDate: makeDate("2026-05-02T00:00:00Z"),
            endDate: makeDate("2026-05-03T00:00:00Z")
        )

        store.addProtocol(
            title: "Weekend reset",
            steps: ["Clear kitchen"],
            schedule: schedule
        )

        XCTAssertEqual(store.protocols.count, 1)
        XCTAssertEqual(store.protocols[0].schedule, schedule)
        XCTAssertTrue(store.runs.isEmpty)
    }

    func testArchiveAndUnarchiveProtocolPersistsTemplateWithoutDeletingMetadata() throws {
        let taskRepo = InMemoryItemListRepository<HomeTask>()
        let protoRepo = InMemoryItemListRepository<HouseholdProtocol>()
        let runRepo = InMemoryItemListRepository<ProtocolRun>()
        let schedule = HouseholdProtocolSchedule(
            preset: .weekend,
            startDate: makeDate("2026-05-02T00:00:00Z"),
            endDate: makeDate("2026-05-03T00:00:00Z")
        )
        let store = HomeStore(
            taskRepository: taskRepo,
            protocolRepository: protoRepo,
            runRepository: runRepo,
            clock: FixedClock(now: makeDate("2026-05-01T12:00:00Z"))
        )
        let protocolID = store.addProtocol(
            title: "Weekend reset",
            steps: ["Clear kitchen", "Review calendar"],
            schedule: schedule
        )

        store.archiveProtocol(id: protocolID)

        XCTAssertTrue(store.protocols[0].isArchived)
        XCTAssertTrue(store.activeProtocols.isEmpty)
        XCTAssertEqual(store.archivedProtocols.map(\.id), [protocolID])
        let archived = try XCTUnwrap(try protoRepo.loadAll().first)
        XCTAssertTrue(archived.isArchived)
        XCTAssertEqual(archived.steps, ["Clear kitchen", "Review calendar"])
        XCTAssertEqual(archived.schedule, schedule)

        store.unarchiveProtocol(id: protocolID)

        XCTAssertFalse(store.protocols[0].isArchived)
        XCTAssertEqual(store.activeProtocols.map(\.id), [protocolID])
        XCTAssertTrue(store.archivedProtocols.isEmpty)
        XCTAssertFalse(try XCTUnwrap(try protoRepo.loadAll().first).isArchived)
    }

    func testArchivedProtocolRejectsNewRunsButCanResumeExistingActiveRun() {
        let store = makeStore()
        let protocolID = store.addProtocol(title: "Kitchen reset", steps: ["Clear sink"])
        let activeRunID = store.startRun(protocolID: protocolID)

        store.archiveProtocol(id: protocolID)

        XCTAssertEqual(store.continueOrStartRun(protocolID: protocolID), activeRunID)
        XCTAssertNil(store.startRun(protocolID: protocolID))
        XCTAssertEqual(store.runs.count, 1)
        XCTAssertEqual(store.activeRuns.map(\.id), [activeRunID])
    }

    func testArchivedProtocolWithoutActiveRunCannotStartNewRun() {
        let store = makeStore()
        let protocolID = store.addProtocol(title: "Kitchen reset", steps: ["Clear sink"])

        store.archiveProtocol(id: protocolID)

        XCTAssertNil(store.continueOrStartRun(protocolID: protocolID))
        XCTAssertNil(store.startRun(protocolID: protocolID))
        XCTAssertTrue(store.runs.isEmpty)
    }

    func testActiveRunForArchivedProtocolTerminatesNormally() {
        let store = makeStore()
        let protocolID = store.addProtocol(title: "Kitchen reset", steps: ["Clear sink"])
        let runID = store.startRun(protocolID: protocolID)!
        let stepID = store.runs[0].steps[0].id

        store.archiveProtocol(id: protocolID)
        store.completeStep(runID: runID, stepID: stepID)

        XCTAssertEqual(store.runs[0].status, .completed)
        XCTAssertNotNil(store.runs[0].completedAt)
        XCTAssertTrue(store.activeRuns.isEmpty)
        XCTAssertEqual(store.completedRuns.map(\.id), [runID])
    }

    func testPromoteWritingNoteToProtocolCreatesDraftWithoutRun() {
        let now = makeDate("2026-04-30T09:30:00Z")
        let store = makeStore(now: now)
        let noteID = UUID()
        let note = WritingNote(
            id: noteID,
            title: "  Weekly reset protocol  ",
            body: "Clear kitchen\nReview calendar\nSet training kit",
            createdDate: makeDate("2026-04-30T08:00:00Z")
        )

        let protocolID = store.promoteWritingNoteToProtocol(note)

        XCTAssertEqual(store.protocols.count, 1)
        XCTAssertEqual(store.protocols.first?.id, protocolID)
        XCTAssertEqual(store.protocols.first?.title, "Weekly reset protocol")
        XCTAssertEqual(store.protocols.first?.steps, [
            "Clear kitchen",
            "Review calendar",
            "Set training kit",
        ])
        XCTAssertEqual(store.protocols.first?.origin?.kind, .writingNote)
        XCTAssertEqual(store.protocols.first?.origin?.id, noteID)
        XCTAssertEqual(store.protocols.first?.origin?.createdAt, now)
        XCTAssertTrue(store.runs.isEmpty)
        XCTAssertEqual(note.id, noteID)
        XCTAssertEqual(note.title, "  Weekly reset protocol  ")
        XCTAssertNil(store.protocols.first?.schedule)
    }

    func testPromoteWritingNoteToProtocolRejectsDuplicateOrigin() {
        let store = makeStore()
        let note = WritingNote(
            title: "Weekly reset protocol",
            body: "Clear kitchen"
        )

        XCTAssertNotNil(store.promoteWritingNoteToProtocol(note))
        XCTAssertFalse(store.canPromoteWritingNoteToProtocol(note))
        XCTAssertNil(store.promoteWritingNoteToProtocol(note))
        XCTAssertEqual(store.protocols.count, 1)
        XCTAssertTrue(store.runs.isEmpty)
    }

    func testProtocolPromotedFromWritingNoteReturnsExistingDestination() {
        let store = makeStore()
        let note = WritingNote(
            title: "Weekly reset protocol",
            body: "Clear kitchen"
        )

        let protocolID = store.promoteWritingNoteToProtocol(note)
        let promotedProtocol = store.protocolPromotedFromWritingNote(note)

        XCTAssertEqual(promotedProtocol?.id, protocolID)
        XCTAssertEqual(promotedProtocol?.origin?.kind, .writingNote)
        XCTAssertEqual(promotedProtocol?.origin?.id, note.id)
    }

    func testPromoteWritingNoteToProtocolRejectsBlankTitle() {
        let store = makeStore()
        let note = WritingNote(title: "   ", body: "Clear kitchen")

        XCTAssertFalse(store.canPromoteWritingNoteToProtocol(note))
        XCTAssertNil(store.promoteWritingNoteToProtocol(note))
        XCTAssertTrue(store.protocols.isEmpty)
        XCTAssertTrue(store.runs.isEmpty)
    }

    func testProtocolSourceRoutingReturnsWritingNoteRoutes() {
        let noteID = UUID()
        let proto = HouseholdProtocol(
            title: "Weekly reset",
            steps: ["Clear kitchen"],
            origin: OwloryItemOrigin(
                kind: .writingNote,
                id: noteID,
                createdAt: makeDate("2026-04-30T09:30:00Z")
            )
        )
        let note = WritingNote(id: noteID, title: "Weekly reset", body: "Clear kitchen")

        XCTAssertEqual(
            HomeProtocolSourceRouting.writeNoteRoute(for: proto, writingNotes: [note]),
            .availableWritingNote(noteID)
        )
        XCTAssertEqual(
            HomeProtocolSourceRouting.writeNoteRoute(for: proto, writingNotes: []),
            .missingWritingNote(noteID)
        )
        XCTAssertEqual(
            HomeProtocolSourceRouting.writeNoteRoute(
                for: HouseholdProtocol(title: "Manual protocol"),
                writingNotes: [note]
            ),
            .none
        )
    }

    func testUpdateProtocolChangesContentAndSchedule() {
        let store = makeStore()
        store.addProtocol(title: "Original", steps: ["Step 1"])
        let id = store.protocols[0].id
        let schedule = HouseholdProtocolSchedule(
            preset: .custom,
            startDate: makeDate("2026-05-04T00:00:00Z"),
            endDate: makeDate("2026-05-06T00:00:00Z")
        )

        store.updateProtocol(
            id: id,
            title: "Updated",
            steps: ["New Step 1", "New Step 2"],
            schedule: schedule
        )
        XCTAssertEqual(store.protocols[0].title, "Updated")
        XCTAssertEqual(store.protocols[0].steps.count, 2)
        XCTAssertEqual(store.protocols[0].schedule, schedule)
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

    func testRevertCompletedStepReturnsToPending() {
        let store = makeStore()
        store.addProtocol(title: "Test", steps: ["Step 1", "Step 2"])
        let runID = store.startRun(protocolID: store.protocols[0].id)!
        let stepID = store.runs[0].steps[0].id

        store.completeStep(runID: runID, stepID: stepID)
        XCTAssertEqual(store.runs[0].steps[0].status, .completed)

        store.revertStep(runID: runID, stepID: stepID)
        XCTAssertEqual(store.runs[0].steps[0].status, .pending)
        XCTAssertNil(store.runs[0].steps[0].completedAt)
        XCTAssertEqual(store.runs[0].status, .active)
    }

    func testRevertLastResolvedStepReopensCompletedRun() {
        let store = makeStore()
        store.addProtocol(title: "Test", steps: ["Step 1"])
        let runID = store.startRun(protocolID: store.protocols[0].id)!
        let stepID = store.runs[0].steps[0].id

        store.completeStep(runID: runID, stepID: stepID)
        XCTAssertEqual(store.runs[0].status, .completed)

        store.revertStep(runID: runID, stepID: stepID)
        XCTAssertEqual(store.runs[0].status, .active)
        XCTAssertNil(store.runs[0].completedAt)
        XCTAssertEqual(store.runs[0].steps[0].status, .pending)
    }

    func testRevertPendingStepIsNoOp() {
        let store = makeStore()
        store.addProtocol(title: "Test", steps: ["Step 1"])
        let runID = store.startRun(protocolID: store.protocols[0].id)!
        let stepID = store.runs[0].steps[0].id

        store.revertStep(runID: runID, stepID: stepID)
        XCTAssertEqual(store.runs[0].steps[0].status, .pending)
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

    // MARK: - Schedule Status

    private var scheduleCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.firstWeekday = 1
        return calendar
    }

    private func scheduledProtocol(
        in store: HomeStore,
        title: String,
        schedule: HouseholdProtocolSchedule
    ) -> HouseholdProtocol {
        store.addProtocol(title: title, steps: ["Step one"], schedule: schedule)
        return store.protocols.first { $0.title == title }!
    }

    func testScheduleStatusReturnsNilForUnscheduledTemplate() {
        let now = makeDate("2026-05-02T12:00:00Z")
        let store = makeStore(now: now)
        store.addProtocol(title: "No schedule", steps: ["Step one"])
        let template = store.protocols[0]

        XCTAssertNil(store.scheduleStatus(for: template, calendar: scheduleCalendar))
    }

    func testScheduleStatusReturnsOverdueWhenWindowPassedAndNoRunStarted() {
        let now = makeDate("2026-05-03T12:00:00Z")
        let store = makeStore(now: now)
        let schedule = HouseholdProtocolSchedule(
            preset: .today,
            startDate: makeDate("2026-05-01T00:00:00Z"),
            endDate: makeDate("2026-05-01T00:00:00Z")
        )
        let template = scheduledProtocol(in: store, title: "Morning routine", schedule: schedule)

        XCTAssertEqual(
            store.scheduleStatus(for: template, calendar: scheduleCalendar),
            .overdue
        )
    }

    func testScheduleStatusReturnsSatisfiedWhenRunStartedDuringWindow() {
        let runDay = makeDate("2026-05-01T08:00:00Z")
        let assertDay = makeDate("2026-05-03T12:00:00Z")
        let schedule = HouseholdProtocolSchedule(
            preset: .today,
            startDate: makeDate("2026-05-01T00:00:00Z"),
            endDate: makeDate("2026-05-01T00:00:00Z")
        )
        let taskRepo = InMemoryItemListRepository<HomeTask>()
        let protoRepo = InMemoryItemListRepository<HouseholdProtocol>()
        let runRepo = InMemoryItemListRepository<ProtocolRun>()

        // Day 1: create the protocol with the schedule and start a run during
        // the window. A new store on a later day should see the run.
        let day1Store = HomeStore(
            taskRepository: taskRepo,
            protocolRepository: protoRepo,
            runRepository: runRepo,
            clock: FixedClock(now: runDay)
        )
        day1Store.addProtocol(title: "Morning routine", steps: ["Step one"], schedule: schedule)
        _ = day1Store.startRun(protocolID: day1Store.protocols[0].id)

        let assertStore = HomeStore(
            taskRepository: taskRepo,
            protocolRepository: protoRepo,
            runRepository: runRepo,
            clock: FixedClock(now: assertDay)
        )
        let template = assertStore.protocols.first { $0.title == "Morning routine" }!

        XCTAssertEqual(
            assertStore.scheduleStatus(for: template, calendar: scheduleCalendar),
            .satisfied
        )
    }

    func testScheduleStatusFiltersRunsByProtocolID() {
        let runDay = makeDate("2026-05-01T08:00:00Z")
        let assertDay = makeDate("2026-05-03T12:00:00Z")
        let schedule = HouseholdProtocolSchedule(
            preset: .today,
            startDate: makeDate("2026-05-01T00:00:00Z"),
            endDate: makeDate("2026-05-01T00:00:00Z")
        )
        let taskRepo = InMemoryItemListRepository<HomeTask>()
        let protoRepo = InMemoryItemListRepository<HouseholdProtocol>()
        let runRepo = InMemoryItemListRepository<ProtocolRun>()

        // Day 1: create both protocols, start a run for the OTHER protocol
        // during the target's window.
        let day1Store = HomeStore(
            taskRepository: taskRepo,
            protocolRepository: protoRepo,
            runRepository: runRepo,
            clock: FixedClock(now: runDay)
        )
        day1Store.addProtocol(title: "Target", steps: ["Step one"], schedule: schedule)
        day1Store.addProtocol(title: "Other", steps: ["Step one"])
        let other = day1Store.protocols.first { $0.title == "Other" }!
        _ = day1Store.startRun(protocolID: other.id)

        let assertStore = HomeStore(
            taskRepository: taskRepo,
            protocolRepository: protoRepo,
            runRepository: runRepo,
            clock: FixedClock(now: assertDay)
        )
        let target = assertStore.protocols.first { $0.title == "Target" }!

        XCTAssertEqual(
            assertStore.scheduleStatus(for: target, calendar: scheduleCalendar),
            .overdue
        )
    }

    func testScheduleStatusOverdueIgnoresRunsStartedBeforeWindow() {
        let oldRunDay = makeDate("2026-04-25T08:00:00Z")
        let assertDay = makeDate("2026-05-03T12:00:00Z")
        let schedule = HouseholdProtocolSchedule(
            preset: .today,
            startDate: makeDate("2026-05-01T00:00:00Z"),
            endDate: makeDate("2026-05-01T00:00:00Z")
        )
        let taskRepo = InMemoryItemListRepository<HomeTask>()
        let protoRepo = InMemoryItemListRepository<HouseholdProtocol>()
        let runRepo = InMemoryItemListRepository<ProtocolRun>()

        // Old run from before the window should not satisfy the schedule.
        let day1Store = HomeStore(
            taskRepository: taskRepo,
            protocolRepository: protoRepo,
            runRepository: runRepo,
            clock: FixedClock(now: oldRunDay)
        )
        day1Store.addProtocol(title: "Morning routine", steps: ["Step one"], schedule: schedule)
        _ = day1Store.startRun(protocolID: day1Store.protocols[0].id)

        let assertStore = HomeStore(
            taskRepository: taskRepo,
            protocolRepository: protoRepo,
            runRepository: runRepo,
            clock: FixedClock(now: assertDay)
        )
        let template = assertStore.protocols.first { $0.title == "Morning routine" }!

        XCTAssertEqual(
            assertStore.scheduleStatus(for: template, calendar: scheduleCalendar),
            .overdue
        )
    }

    func testScheduleSummaryReportsSemanticStatusWhenSatisfied() {
        let now = makeDate("2026-05-03T12:00:00Z")
        let schedule = HouseholdProtocolSchedule(
            preset: .today,
            startDate: makeDate("2026-05-01T00:00:00Z"),
            endDate: makeDate("2026-05-01T00:00:00Z")
        )
        let runs = [
            ProtocolRun(
                protocolID: UUID(),
                protocolTitle: "Morning routine",
                createdAt: makeDate("2026-05-01T08:00:00Z")
            )
        ]

        let summary = ProtocolScheduleRules.summary(
            for: schedule,
            runs: runs,
            now: now,
            calendar: scheduleCalendar
        )

        XCTAssertEqual(
            summary,
            ProtocolScheduleRules.ScheduleSummary(
                preset: .today,
                startDate: makeDate("2026-05-01T00:00:00Z"),
                endDate: makeDate("2026-05-01T00:00:00Z"),
                status: .satisfied
            )
        )
    }

    func testScheduleSummaryReportsSemanticStatusWhenOverdue() {
        let now = makeDate("2026-05-03T12:00:00Z")
        let schedule = HouseholdProtocolSchedule(
            preset: .today,
            startDate: makeDate("2026-05-01T00:00:00Z"),
            endDate: makeDate("2026-05-01T00:00:00Z")
        )

        let summary = ProtocolScheduleRules.summary(
            for: schedule,
            runs: [],
            now: now,
            calendar: scheduleCalendar
        )

        XCTAssertEqual(
            summary,
            ProtocolScheduleRules.ScheduleSummary(
                preset: .today,
                startDate: makeDate("2026-05-01T00:00:00Z"),
                endDate: makeDate("2026-05-01T00:00:00Z"),
                status: .overdue
            )
        )
    }
}
