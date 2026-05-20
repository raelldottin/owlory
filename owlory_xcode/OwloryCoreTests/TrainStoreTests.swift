import XCTest
#if SWIFT_PACKAGE
@testable import OwloryCore
#endif

@MainActor
final class TrainStoreTests: XCTestCase {

    private func makeDate(_ string: String) -> Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: string)!
    }

    private func makeStore(now: Date) -> TrainStore {
        TrainStore(
            repository: InMemoryItemListRepository<TrainingSession>(),
            clock: FixedClock(now: now)
        )
    }

    func testAddSessionCreatesPlannedSession() {
        let now = makeDate("2026-04-08T09:00:00Z")
        let store = makeStore(now: now)

        store.addSession(plannedActivity: "Run 5K", readinessNote: "Feeling good")
        XCTAssertEqual(store.sessions.count, 1)
        XCTAssertEqual(store.sessions[0].plannedActivity, "Run 5K")
        XCTAssertEqual(store.sessions[0].readinessLevel, 3)
        XCTAssertEqual(store.sessions[0].readinessNote, "Feeling good")
        XCTAssertEqual(store.sessions[0].status, .planned)
    }

    func testTrainingSessionDecodesLegacyPayloadWithoutReadinessLevel() throws {
        let json = """
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "date": "2026-04-08T09:00:00Z",
            "plannedActivity": "Legacy run",
            "actualActivity": "",
            "status": "planned",
            "readinessNote": "Steady",
            "reflection": "",
            "isRecurring": false
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let session = try decoder.decode(TrainingSession.self, from: json)

        XCTAssertEqual(session.plannedActivity, "Legacy run")
        XCTAssertEqual(session.readinessLevel, 3)
        XCTAssertEqual(session.readinessNote, "Steady")
    }

    func testTodaySessionReturnsTodaysSession() {
        let now = makeDate("2026-04-08T09:00:00Z")
        let store = makeStore(now: now)

        store.addSession(plannedActivity: "Morning Run")
        XCTAssertNotNil(store.todaySession)
        XCTAssertEqual(store.todaySession?.plannedActivity, "Morning Run")
    }

    func testUpdateSessionChangesStatusAndContent() {
        let now = makeDate("2026-04-08T09:00:00Z")
        let store = makeStore(now: now)

        store.addSession(plannedActivity: "Strength")
        let id = store.sessions[0].id

        store.updateSession(id: id, actualActivity: "Upper body focus", status: .completed, reflection: "Felt strong")
        XCTAssertEqual(store.sessions[0].status, .completed)
        XCTAssertEqual(store.sessions[0].actualActivity, "Upper body focus")
        XCTAssertEqual(store.sessions[0].reflection, "Felt strong")
    }

    func testUpdateSessionUsesVoiceTranscriptionWhenReflectionIsBlank() {
        let now = makeDate("2026-04-08T09:00:00Z")
        let store = makeStore(now: now)

        store.addSession(plannedActivity: "Strength")
        let id = store.sessions[0].id

        store.updateSession(
            id: id,
            actualActivity: "Upper body focus",
            status: .completed,
            reflection: "  ",
            reflectionAudioFileName: "reflection.m4a",
            reflectionAudioTranscription: "Felt strong after the final set."
        )

        XCTAssertEqual(store.sessions[0].reflection, "Felt strong after the final set.")
        XCTAssertEqual(store.sessions[0].reflectionAudioFileName, "reflection.m4a")
        XCTAssertEqual(store.sessions[0].reflectionAudioTranscription, "Felt strong after the final set.")
    }

    func testUpdateSessionKeepsTypedReflectionWhenVoiceTranscriptionExists() {
        let now = makeDate("2026-04-08T09:00:00Z")
        let store = makeStore(now: now)

        store.addSession(plannedActivity: "Strength")
        let id = store.sessions[0].id

        store.updateSession(
            id: id,
            actualActivity: "Upper body focus",
            status: .completed,
            reflection: "Typed reflection",
            reflectionAudioFileName: "reflection.m4a",
            reflectionAudioTranscription: "Voice transcription"
        )

        XCTAssertEqual(store.sessions[0].reflection, "Typed reflection")
        XCTAssertEqual(store.sessions[0].reflectionAudioFileName, "reflection.m4a")
        XCTAssertEqual(store.sessions[0].reflectionAudioTranscription, "Voice transcription")
    }

    func testDeleteSessionRemovesIt() {
        let now = makeDate("2026-04-08T09:00:00Z")
        let store = makeStore(now: now)

        store.addSession(plannedActivity: "Yoga")
        let id = store.sessions[0].id
        store.deleteSession(id: id)
        XCTAssertTrue(store.sessions.isEmpty)
    }

    func testUpdateReadinessLevelPersistsTrainingSignal() {
        let now = makeDate("2026-04-08T09:00:00Z")
        let store = makeStore(now: now)

        store.addSession(plannedActivity: "Yoga")
        let id = store.sessions[0].id

        store.updateReadinessLevel(id: id, readinessLevel: 5)

        XCTAssertEqual(store.sessions[0].readinessLevel, 5)
    }

    func testAddSessionReturnsUUID() {
        let now = makeDate("2026-04-08T09:00:00Z")
        let store = makeStore(now: now)

        let id = store.addSession(plannedActivity: "Sprint intervals")
        XCTAssertEqual(store.sessions[0].id, id)
    }

    func testTodaySessionsReturnsMultiple() {
        let now = makeDate("2026-04-08T09:00:00Z")
        let store = makeStore(now: now)

        store.addSession(plannedActivity: "Morning Run")
        store.addSession(plannedActivity: "Evening Yoga")
        XCTAssertEqual(store.todaySessions.count, 2)
    }

    func testActiveTodaySessionsOnlyIncludesPlannedSessionsForToday() {
        let now = makeDate("2026-04-08T09:00:00Z")
        let store = makeStore(now: now)

        let plannedID = store.addSession(plannedActivity: "Morning Run")
        let completedID = store.addSession(plannedActivity: "Strength")

        store.updateSession(
            id: completedID,
            actualActivity: "Upper body focus",
            status: .completed,
            reflection: "Done"
        )

        XCTAssertEqual(store.todaySessions.map(\.id), [plannedID, completedID])
        XCTAssertEqual(store.activeTodaySessions.map(\.id), [plannedID])
        XCTAssertEqual(store.todaySession?.id, plannedID)
    }

    func testHistorySessionsIncludesResolvedTodaySessions() {
        let now = makeDate("2026-04-08T09:00:00Z")
        let store = makeStore(now: now)

        let plannedID = store.addSession(plannedActivity: "Morning Run")
        let completedID = store.addSession(plannedActivity: "Strength")
        let modifiedID = store.addSession(plannedActivity: "Mobility")
        let skippedID = store.addSession(plannedActivity: "Intervals")

        store.updateSession(
            id: completedID,
            actualActivity: "Upper body focus",
            status: .completed,
            reflection: "Done"
        )
        store.updateSession(
            id: modifiedID,
            actualActivity: "Short mobility",
            status: .modified,
            reflection: "Adapted"
        )
        store.updateSession(
            id: skippedID,
            actualActivity: "",
            status: .skipped,
            reflection: "No time"
        )

        let historyIDs = store.historySessions.map(\.id)
        XCTAssertFalse(historyIDs.contains(plannedID))
        XCTAssertTrue(historyIDs.contains(completedID))
        XCTAssertTrue(historyIDs.contains(modifiedID))
        XCTAssertTrue(historyIDs.contains(skippedID))
    }

    func testPastSessionsExcludesToday() {
        let now = makeDate("2026-04-08T09:00:00Z")
        let store = makeStore(now: now)

        store.addSession(plannedActivity: "Today's Session")
        XCTAssertTrue(store.pastSessions.isEmpty, "Today's session should not appear in past")
    }

    func testHistorySessionsIncludesPastSessions() {
        let day1 = makeDate("2026-04-07T09:00:00Z")
        let day2 = makeDate("2026-04-08T09:00:00Z")
        let repo = InMemoryItemListRepository<TrainingSession>()

        let store1 = TrainStore(repository: repo, clock: FixedClock(now: day1))
        let pastID = store1.addSession(plannedActivity: "Past Run")
        store1.updateSession(
            id: pastID,
            actualActivity: "Ran 5K",
            status: .completed,
            reflection: "Good"
        )

        let store2 = TrainStore(repository: repo, clock: FixedClock(now: day2))
        let todayID = store2.addSession(plannedActivity: "Today Ride")

        XCTAssertEqual(store2.activeTodaySessions.map(\.id), [todayID])
        XCTAssertEqual(store2.historySessions.map(\.id), [pastID])
    }

    func testCompletedTodaySessionMovesFromActiveTodayToHistory() {
        let now = makeDate("2026-04-08T09:00:00Z")
        let store = makeStore(now: now)

        let id = store.addSession(plannedActivity: "Strength")
        XCTAssertEqual(store.activeTodaySessions.map(\.id), [id])
        XCTAssertTrue(store.historySessions.isEmpty)

        store.updateSession(
            id: id,
            actualActivity: "Upper body focus",
            status: .completed,
            reflection: "Done"
        )

        XCTAssertTrue(store.activeTodaySessions.isEmpty)
        XCTAssertEqual(store.historySessions.map(\.id), [id])
    }

    // MARK: - Recurring Sessions

    func testRecurringSessionSpawnsNewSessionWhenDue() {
        let day1 = makeDate("2026-04-01T09:00:00Z")
        let repo = InMemoryItemListRepository<TrainingSession>()

        let store1 = TrainStore(repository: repo, clock: FixedClock(now: day1))
        store1.addSession(plannedActivity: "Morning Run", isRecurring: true, recurrenceIntervalDays: 1)
        let id = store1.sessions[0].id
        store1.updateSession(id: id, actualActivity: "Ran 5K", status: .completed, reflection: "Good")
        XCTAssertEqual(store1.sessions.count, 1)

        // Next day morning - should spawn a new planned session
        let day2 = makeDate("2026-04-02T06:00:00Z")
        let store2 = TrainStore(repository: repo, clock: FixedClock(now: day2))
        XCTAssertEqual(store2.sessions.count, 2, "Should spawn new session for recurring activity")
        let newSession = store2.sessions.last!
        XCTAssertEqual(newSession.plannedActivity, "Morning Run")
        XCTAssertEqual(newSession.status, .planned)
        XCTAssertTrue(newSession.isRecurring)
        XCTAssertEqual(newSession.recurrenceIntervalDays, 1)
    }

    func testRecurringSessionDoesNotSpawnBeforeDue() {
        let day1 = makeDate("2026-04-01T09:00:00Z")
        let repo = InMemoryItemListRepository<TrainingSession>()

        let store1 = TrainStore(repository: repo, clock: FixedClock(now: day1))
        store1.addSession(plannedActivity: "Weekly Yoga", isRecurring: true, recurrenceIntervalDays: 7)
        store1.updateSession(id: store1.sessions[0].id, actualActivity: "Yoga", status: .completed, reflection: "")

        // Day 5 - not yet due
        let day5 = makeDate("2026-04-05T09:00:00Z")
        let store2 = TrainStore(repository: repo, clock: FixedClock(now: day5))
        XCTAssertEqual(store2.sessions.count, 1, "Should not spawn before interval passes")
    }

    func testRecurringSessionDoesNotDuplicateForSameDay() {
        let day1 = makeDate("2026-04-01T09:00:00Z")
        let repo = InMemoryItemListRepository<TrainingSession>()

        let store1 = TrainStore(repository: repo, clock: FixedClock(now: day1))
        store1.addSession(plannedActivity: "Morning Run", isRecurring: true, recurrenceIntervalDays: 1)
        store1.updateSession(id: store1.sessions[0].id, actualActivity: "Ran", status: .completed, reflection: "")

        let day2 = makeDate("2026-04-02T06:00:00Z")
        let store2 = TrainStore(repository: repo, clock: FixedClock(now: day2))
        XCTAssertEqual(store2.sessions.count, 2)

        // Reload same day - should NOT create another duplicate
        let store3 = TrainStore(repository: repo, clock: FixedClock(now: day2))
        XCTAssertEqual(store3.sessions.count, 2, "Should not duplicate session on same-day reload")
    }

    func testPlannedRecurringSessionAutoSkipsAndSpawnsNextOccurrence() {
        let day1 = makeDate("2026-04-01T09:00:00Z")
        let repo = InMemoryItemListRepository<TrainingSession>()

        let store1 = TrainStore(repository: repo, clock: FixedClock(now: day1))
        store1.addSession(plannedActivity: "Morning Run", isRecurring: true, recurrenceIntervalDays: 1)
        // Leave as planned - don't complete it

        let day2 = makeDate("2026-04-02T06:00:00Z")
        let store2 = TrainStore(repository: repo, clock: FixedClock(now: day2))
        XCTAssertEqual(store2.sessions.count, 2, "Stale planned recurring sessions should auto-skip and spawn the next occurrence")
        XCTAssertEqual(store2.sessions[0].status, .skipped)
        XCTAssertEqual(store2.sessions[1].plannedActivity, "Morning Run")
        XCTAssertEqual(store2.sessions[1].status, .planned)
    }

    func testPlannedSessionFromPriorDayAutoSkipsOnReload() {
        let day1 = makeDate("2026-04-01T09:00:00Z")
        let repo = InMemoryItemListRepository<TrainingSession>()

        let store1 = TrainStore(repository: repo, clock: FixedClock(now: day1))
        store1.addSession(plannedActivity: "Intervals")
        XCTAssertEqual(store1.sessions[0].status, .planned)

        let day2 = makeDate("2026-04-02T06:00:00Z")
        let store2 = TrainStore(repository: repo, clock: FixedClock(now: day2))
        XCTAssertEqual(store2.sessions.count, 1)
        XCTAssertEqual(store2.sessions[0].status, .skipped)
    }

    // MARK: - Completion fires reminder cancellation
    //
    // Regression for the user-reported bug where a completed train item still
    // received a "window has passed" notification because nothing cancelled
    // the pending reminder synchronously at completion time. The schedule-time
    // suppression in ReminderScheduler.reschedule() only protects against
    // bulk re-schedules; per-item completion needs its own cancel hook.

    func testCompletingSessionCallsOnItemCompletedHookWithPredictorKey() {
        let now = makeDate("2026-04-08T09:00:00Z")
        var recordedKeys: [String] = []
        let store = TrainStore(
            repository: InMemoryItemListRepository<TrainingSession>(),
            clock: FixedClock(now: now),
            onItemCompleted: { key in recordedKeys.append(key) }
        )

        store.addSession(plannedActivity: "Morning Run")
        let id = store.sessions[0].id

        store.updateSession(id: id, actualActivity: "Ran 5K", status: .completed, reflection: "")

        XCTAssertEqual(
            recordedKeys,
            [CompletionTimePredictor.key(forTrainingSession: "Morning Run")],
            "Expected the onItemCompleted hook to fire exactly once with the predictor key for the planned activity when the session flips to .completed."
        )
    }

    func testModifyingSessionAlsoCallsOnItemCompletedHook() {
        let now = makeDate("2026-04-08T09:00:00Z")
        var recordedKeys: [String] = []
        let store = TrainStore(
            repository: InMemoryItemListRepository<TrainingSession>(),
            clock: FixedClock(now: now),
            onItemCompleted: { key in recordedKeys.append(key) }
        )

        store.addSession(plannedActivity: "Morning Run")
        let id = store.sessions[0].id

        store.updateSession(id: id, actualActivity: "Ran 3K", status: .modified, reflection: "")

        XCTAssertEqual(
            recordedKeys,
            [CompletionTimePredictor.key(forTrainingSession: "Morning Run")],
            "Modified status is treated as a completion for predictor / reminder purposes and must fire the cancel hook too."
        )
    }

    func testNonCompletionStatusDoesNotCallOnItemCompletedHook() {
        let now = makeDate("2026-04-08T09:00:00Z")
        var recordedKeys: [String] = []
        let store = TrainStore(
            repository: InMemoryItemListRepository<TrainingSession>(),
            clock: FixedClock(now: now),
            onItemCompleted: { key in recordedKeys.append(key) }
        )

        store.addSession(plannedActivity: "Morning Run")
        let id = store.sessions[0].id

        store.updateSession(id: id, actualActivity: "", status: .skipped, reflection: "")

        XCTAssertTrue(
            recordedKeys.isEmpty,
            "Only .completed and .modified should fire the cancellation hook; .skipped is neither completion nor modification."
        )
    }

}
