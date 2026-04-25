import XCTest
#if SWIFT_PACKAGE
@testable import OwloryCore
#endif

final class RecurringRolloverPlannerTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testTrainingRolloverCreatesOneSessionAndDedupesSameDayDuplicate() {
        let day1 = makeDate("2026-04-01T09:00:00Z")
        let day2 = makeDate("2026-04-02T06:00:00Z")
        let sessions = [
            TrainingSession(
                date: day1,
                plannedActivity: "Morning Run",
                status: .completed,
                isRecurring: true,
                recurrenceIntervalDays: 1
            ),
            TrainingSession(
                date: day1,
                plannedActivity: "Morning Run",
                status: .completed,
                isRecurring: true,
                recurrenceIntervalDays: 1
            ),
        ]

        let result = RecurringRolloverPlanner.rolloverTrainingSessions(
            sessions,
            asOf: day2,
            calendar: calendar
        )

        XCTAssertTrue(result.didChange)
        XCTAssertEqual(result.sessions.count, 3)
        XCTAssertEqual(result.sessions.last?.plannedActivity, "Morning Run")
        XCTAssertEqual(result.sessions.last?.status, .planned)
        XCTAssertEqual(result.trace.evaluatedCount, 2)
        XCTAssertEqual(result.trace.createdCount, 1)
        XCTAssertEqual(result.trace.dedupedCount, 1)
        XCTAssertEqual(result.trace.changedItemIDs, [result.sessions.last?.id].compactMap { $0 })
    }

    func testTrainingRolloverTreatsSkippedAndModifiedAsResolvedRecurringSessions() {
        let day1 = makeDate("2026-04-01T09:00:00Z")
        let day2 = makeDate("2026-04-02T06:00:00Z")
        let sessions = [
            TrainingSession(
                date: day1,
                plannedActivity: "Mobility",
                status: .skipped,
                isRecurring: true,
                recurrenceIntervalDays: 1
            ),
            TrainingSession(
                date: day1,
                plannedActivity: "Strength",
                status: .modified,
                isRecurring: true,
                recurrenceIntervalDays: 1
            ),
        ]

        let result = RecurringRolloverPlanner.rolloverTrainingSessions(
            sessions,
            asOf: day2,
            calendar: calendar
        )

        XCTAssertEqual(result.sessions.suffix(2).map(\.plannedActivity), ["Mobility", "Strength"])
        XCTAssertEqual(result.trace.createdCount, 2)
        XCTAssertEqual(result.trace.skippedCount, 0)
    }

    func testTrainingRolloverAutoSkipsStalePlannedSessionsBeforeRecurringSpawn() {
        let day1 = makeDate("2026-04-01T09:00:00Z")
        let day2 = makeDate("2026-04-02T06:00:00Z")
        let sessions = [
            TrainingSession(
                date: day1,
                plannedActivity: "Morning Run",
                status: .planned,
                isRecurring: true,
                recurrenceIntervalDays: 1
            )
        ]

        let result = RecurringRolloverPlanner.rolloverTrainingSessions(
            sessions,
            asOf: day2,
            calendar: calendar
        )

        XCTAssertTrue(result.didChange)
        XCTAssertEqual(result.sessions.count, 2)
        XCTAssertEqual(result.sessions[0].status, .skipped)
        XCTAssertEqual(result.sessions[1].plannedActivity, "Morning Run")
        XCTAssertEqual(result.sessions[1].status, .planned)
        XCTAssertEqual(result.trace.createdCount, 1)
        XCTAssertEqual(result.trace.updatedCount, 1)
        XCTAssertEqual(result.trace.changedItemIDs.count, 2)
    }

    func testHomeTaskRolloverResetsCompletedAndSkippedTasksWithTrace() {
        let day1 = makeDate("2026-04-01T09:00:00Z")
        let day8 = makeDate("2026-04-08T12:00:00Z")
        let completed = HomeTask(
            title: "Water plants",
            isCompleted: true,
            isRecurring: true,
            recurrenceIntervalDays: 7,
            lastCompleted: day1
        )
        let skipped = HomeTask(
            title: "Vacuum",
            isSkipped: true,
            isRecurring: true,
            recurrenceIntervalDays: 7,
            lastSkipped: day1
        )
        let active = HomeTask(
            title: "Dishes",
            isRecurring: true,
            recurrenceIntervalDays: 7
        )
        let oneTime = HomeTask(
            title: "Replace filter",
            isCompleted: true,
            lastCompleted: day1
        )

        let result = RecurringRolloverPlanner.rolloverHomeTasks(
            [completed, skipped, active, oneTime],
            asOf: day8,
            calendar: calendar
        )

        XCTAssertTrue(result.didChange)
        XCTAssertEqual(result.tasks.map(\.isCompleted), [false, false, false, true])
        XCTAssertEqual(result.tasks.map(\.isSkipped), [false, false, false, false])
        XCTAssertEqual(result.trace.evaluatedCount, 4)
        XCTAssertEqual(result.trace.resetCount, 2)
        XCTAssertEqual(result.trace.notReadyCount, 1)
        XCTAssertEqual(result.trace.notRecurringCount, 1)
        XCTAssertEqual(result.trace.changedItemIDs, [completed.id, skipped.id])
    }

    func testTraceMessageUsesStableRolloverMetadata() {
        let trace = RecurringRolloverTrace(
            scope: .trainingSessions,
            evaluatedCount: 4,
            createdCount: 1,
            resetCount: 0,
            updatedCount: 0,
            notRecurringCount: 1,
            notReadyCount: 1,
            missingScheduleCount: 0,
            notDueCount: 0,
            dedupedCount: 1,
            changedItemIDs: [UUID()]
        )

        XCTAssertEqual(
            trace.telemetryMessage,
            "recurrence.rollover scope=training.sessions evaluated=4 changed=1 created=1 reset=0 updated=0 skipped=3 notRecurring=1 notReady=1 missingSchedule=0 notDue=0 deduped=1"
        )
    }

    private func makeDate(_ string: String) -> Date {
        ISO8601DateFormatter().date(from: string)!
    }
}
