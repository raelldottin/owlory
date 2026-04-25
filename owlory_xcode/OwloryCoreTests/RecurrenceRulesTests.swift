import XCTest
#if SWIFT_PACKAGE
@testable import OwloryCore
#endif

final class RecurrenceRulesTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func makeDate(_ string: String) -> Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: string)!
    }

    func testHomeTaskResetClearsCompletedStateOnDueDay() {
        let completedAt = makeDate("2026-04-01T22:00:00Z")
        let dueMorning = makeDate("2026-04-02T06:00:00Z")
        let task = HomeTask(
            title: "Daily review",
            isCompleted: true,
            isRecurring: true,
            recurrenceIntervalDays: 1,
            lastCompleted: completedAt
        )

        let reset = RecurrenceRules.resetHomeTaskIfDue(task, asOf: dueMorning, calendar: calendar)

        XCTAssertNotNil(reset)
        XCTAssertFalse(reset!.isCompleted)
        XCTAssertFalse(reset!.isSkipped)
        XCTAssertEqual(reset!.lastCompleted, completedAt)
    }

    func testHomeTaskResetClearsSkippedStateOnDueDay() {
        let skippedAt = makeDate("2026-04-01T09:00:00Z")
        let dueDay = makeDate("2026-04-08T12:00:00Z")
        let task = HomeTask(
            title: "Water plants",
            isSkipped: true,
            isRecurring: true,
            recurrenceIntervalDays: 7,
            lastSkipped: skippedAt
        )

        let reset = RecurrenceRules.resetHomeTaskIfDue(task, asOf: dueDay, calendar: calendar)

        XCTAssertNotNil(reset)
        XCTAssertFalse(reset!.isCompleted)
        XCTAssertFalse(reset!.isSkipped)
        XCTAssertEqual(reset!.lastSkipped, skippedAt)
    }

    func testHomeTaskDoesNotResetBeforeDueDayOrWhenNotRecurring() {
        let completedAt = makeDate("2026-04-01T09:00:00Z")
        let beforeDue = makeDate("2026-04-05T09:00:00Z")
        let recurring = HomeTask(
            title: "Water plants",
            isCompleted: true,
            isRecurring: true,
            recurrenceIntervalDays: 7,
            lastCompleted: completedAt
        )
        let oneTime = HomeTask(
            title: "Replace filter",
            isCompleted: true,
            isRecurring: false,
            recurrenceIntervalDays: 1,
            lastCompleted: completedAt
        )

        XCTAssertNil(RecurrenceRules.resetHomeTaskIfDue(recurring, asOf: beforeDue, calendar: calendar))
        XCTAssertNil(RecurrenceRules.resetHomeTaskIfDue(oneTime, asOf: beforeDue, calendar: calendar))
    }

    func testHomeTaskResetDecisionReportsWhyTaskDidNotReset() {
        let completedAt = makeDate("2026-04-01T09:00:00Z")
        let dueDay = makeDate("2026-04-08T09:00:00Z")

        XCTAssertEqual(
            RecurrenceRules.homeTaskResetDecision(
                HomeTask(title: "One-time", isCompleted: true, lastCompleted: completedAt),
                asOf: dueDay,
                calendar: calendar
            ).rejection,
            .notRecurring
        )
        XCTAssertEqual(
            RecurrenceRules.homeTaskResetDecision(
                HomeTask(title: "Active", isRecurring: true, recurrenceIntervalDays: 7),
                asOf: dueDay,
                calendar: calendar
            ).rejection,
            .unresolved
        )
        XCTAssertEqual(
            RecurrenceRules.homeTaskResetDecision(
                HomeTask(title: "Missing schedule", isCompleted: true, isRecurring: true),
                asOf: dueDay,
                calendar: calendar
            ).rejection,
            .missingSchedule
        )
    }

    func testTrainingSessionSpawnsWhenDue() {
        let day1 = makeDate("2026-04-01T09:00:00Z")
        let day2 = makeDate("2026-04-02T06:00:00Z")
        let session = TrainingSession(
            date: day1,
            plannedActivity: "Morning Run",
            status: .completed,
            isRecurring: true,
            recurrenceIntervalDays: 1
        )

        let spawned = RecurrenceRules.trainingSessionToSpawnIfDue(
            from: session,
            existingSessions: [session],
            asOf: day2,
            calendar: calendar
        )

        XCTAssertNotNil(spawned)
        XCTAssertEqual(spawned!.date, day2)
        XCTAssertEqual(spawned!.plannedActivity, "Morning Run")
        XCTAssertEqual(spawned!.status, .planned)
        XCTAssertTrue(spawned!.isRecurring)
        XCTAssertEqual(spawned!.recurrenceIntervalDays, 1)
    }

    func testTrainingSessionAutoSkipsWhenPlannedSessionCrossesDayBoundary() {
        let day1 = makeDate("2026-04-01T09:00:00Z")
        let day2 = makeDate("2026-04-02T06:00:00Z")
        let session = TrainingSession(
            date: day1,
            plannedActivity: "Morning Run",
            status: .planned
        )

        let skipped = RecurrenceRules.autoSkipTrainingSessionIfPastDay(
            session,
            asOf: day2,
            calendar: calendar
        )

        XCTAssertNotNil(skipped)
        XCTAssertEqual(skipped?.status, .skipped)
        XCTAssertEqual(skipped?.plannedActivity, "Morning Run")
    }

    func testTrainingSessionAutoSkipLeavesTodayAndResolvedSessionsUntouched() {
        let today = makeDate("2026-04-02T06:00:00Z")
        let plannedToday = TrainingSession(
            date: today,
            plannedActivity: "Mobility",
            status: .planned
        )
        let completedYesterday = TrainingSession(
            date: makeDate("2026-04-01T09:00:00Z"),
            plannedActivity: "Strength",
            status: .completed
        )

        XCTAssertNil(
            RecurrenceRules.autoSkipTrainingSessionIfPastDay(
                plannedToday,
                asOf: today,
                calendar: calendar
            )
        )
        XCTAssertNil(
            RecurrenceRules.autoSkipTrainingSessionIfPastDay(
                completedYesterday,
                asOf: today,
                calendar: calendar
            )
        )
    }

    func testTrainingSessionSpawnsAfterSkippedOrModifiedWhenDue() {
        let day1 = makeDate("2026-04-01T09:00:00Z")
        let day2 = makeDate("2026-04-02T06:00:00Z")
        let skipped = TrainingSession(
            date: day1,
            plannedActivity: "Morning Run",
            status: .skipped,
            isRecurring: true,
            recurrenceIntervalDays: 1
        )
        let modified = TrainingSession(
            date: day1,
            plannedActivity: "Strength",
            status: .modified,
            isRecurring: true,
            recurrenceIntervalDays: 1
        )

        XCTAssertNotNil(
            RecurrenceRules.trainingSessionToSpawnIfDue(
                from: skipped,
                existingSessions: [skipped],
                asOf: day2,
                calendar: calendar
            )
        )
        XCTAssertNotNil(
            RecurrenceRules.trainingSessionToSpawnIfDue(
                from: modified,
                existingSessions: [modified],
                asOf: day2,
                calendar: calendar
            )
        )
    }

    func testTrainingSessionDoesNotSpawnBeforeDueWhilePlannedOrWhenAlreadyExistsToday() {
        let day1 = makeDate("2026-04-01T09:00:00Z")
        let day2 = makeDate("2026-04-02T06:00:00Z")
        let day5 = makeDate("2026-04-05T09:00:00Z")
        let completed = TrainingSession(
            date: day1,
            plannedActivity: "Weekly Yoga",
            status: .completed,
            isRecurring: true,
            recurrenceIntervalDays: 7
        )
        let planned = TrainingSession(
            date: day1,
            plannedActivity: "Morning Run",
            status: .planned,
            isRecurring: true,
            recurrenceIntervalDays: 1
        )
        let existingToday = TrainingSession(date: day2, plannedActivity: "Morning Run")

        XCTAssertNil(
            RecurrenceRules.trainingSessionToSpawnIfDue(
                from: completed,
                existingSessions: [completed],
                asOf: day5,
                calendar: calendar
            )
        )
        XCTAssertNil(
            RecurrenceRules.trainingSessionToSpawnIfDue(
                from: planned,
                existingSessions: [planned],
                asOf: day2,
                calendar: calendar
            )
        )
        XCTAssertNil(
            RecurrenceRules.trainingSessionToSpawnIfDue(
                from: TrainingSession(
                    date: day1,
                    plannedActivity: "Morning Run",
                    status: .completed,
                    isRecurring: true,
                    recurrenceIntervalDays: 1
                ),
                existingSessions: [existingToday],
                asOf: day2,
                calendar: calendar
            )
        )
    }

    func testTrainingSessionSpawnDecisionReportsDuplicateExistingToday() {
        let day1 = makeDate("2026-04-01T09:00:00Z")
        let day2 = makeDate("2026-04-02T06:00:00Z")
        let completed = TrainingSession(
            date: day1,
            plannedActivity: "Morning Run",
            status: .completed,
            isRecurring: true,
            recurrenceIntervalDays: 1
        )
        let existingToday = TrainingSession(
            date: day2,
            plannedActivity: "Morning Run",
            status: .planned
        )

        let decision = RecurrenceRules.trainingSessionSpawnDecision(
            from: completed,
            existingSessions: [completed, existingToday],
            asOf: day2,
            calendar: calendar
        )

        XCTAssertFalse(decision.shouldSpawn)
        XCTAssertNil(decision.spawnedSession)
        XCTAssertEqual(decision.rejection, .alreadyExistsToday)
    }
}
