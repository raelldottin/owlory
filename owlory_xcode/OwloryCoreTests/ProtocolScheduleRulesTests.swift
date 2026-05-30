import XCTest
#if SWIFT_PACKAGE
@testable import OwloryCore
#endif

final class ProtocolScheduleRulesTests: XCTestCase {
    private let formatter = ISO8601DateFormatter()

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.firstWeekday = 1
        return calendar
    }

    func testScheduleReturnsNilForAnytimeDraft() {
        let draft = ProtocolScheduleRules.Draft(referenceDate: date("2026-05-01T10:00:00Z"))

        XCTAssertNil(ProtocolScheduleRules.schedule(from: draft, calendar: calendar))
    }

    func testApplyingTodayPresetCreatesSingleDayWindow() {
        let reference = date("2026-05-01T10:00:00Z")
        let draft = ProtocolScheduleRules.draft(
            byApplying: .today,
            to: ProtocolScheduleRules.Draft(referenceDate: reference),
            referenceDate: reference,
            calendar: calendar
        )

        let schedule = ProtocolScheduleRules.schedule(from: draft, calendar: calendar)

        XCTAssertEqual(schedule?.preset, .today)
        XCTAssertEqual(schedule?.startDate, date("2026-05-01T00:00:00Z"))
        XCTAssertEqual(schedule?.endDate, date("2026-05-01T00:00:00Z"))
    }

    func testApplyingWeekendPresetUsesUpcomingWeekendFromWeekday() {
        let reference = date("2026-05-07T10:00:00Z")
        let draft = ProtocolScheduleRules.draft(
            byApplying: .weekend,
            to: ProtocolScheduleRules.Draft(referenceDate: reference),
            referenceDate: reference,
            calendar: calendar
        )

        let schedule = ProtocolScheduleRules.schedule(from: draft, calendar: calendar)

        XCTAssertEqual(schedule?.preset, .weekend)
        XCTAssertEqual(schedule?.startDate, date("2026-05-09T00:00:00Z"))
        XCTAssertEqual(schedule?.endDate, date("2026-05-10T00:00:00Z"))
    }

    func testApplyingWeekendPresetKeepsCurrentWeekendOnSunday() {
        let reference = date("2026-05-10T10:00:00Z")
        let draft = ProtocolScheduleRules.draft(
            byApplying: .weekend,
            to: ProtocolScheduleRules.Draft(referenceDate: reference),
            referenceDate: reference,
            calendar: calendar
        )

        let schedule = ProtocolScheduleRules.schedule(from: draft, calendar: calendar)

        XCTAssertEqual(schedule?.startDate, date("2026-05-09T00:00:00Z"))
        XCTAssertEqual(schedule?.endDate, date("2026-05-10T00:00:00Z"))
    }

    func testApplyingThisWeekPresetEndsAtWeekBoundary() {
        let reference = date("2026-05-06T10:00:00Z")
        let draft = ProtocolScheduleRules.draft(
            byApplying: .thisWeek,
            to: ProtocolScheduleRules.Draft(referenceDate: reference),
            referenceDate: reference,
            calendar: calendar
        )

        let schedule = ProtocolScheduleRules.schedule(from: draft, calendar: calendar)

        XCTAssertEqual(schedule?.preset, .thisWeek)
        XCTAssertEqual(schedule?.startDate, date("2026-05-06T00:00:00Z"))
        XCTAssertEqual(schedule?.endDate, date("2026-05-09T00:00:00Z"))
    }

    func testCustomScheduleNormalizesReversedRange() {
        let draft = ProtocolScheduleRules.Draft(
            preset: .custom,
            startDate: date("2026-05-12T12:00:00Z"),
            endDate: date("2026-05-10T12:00:00Z")
        )

        let schedule = ProtocolScheduleRules.schedule(from: draft, calendar: calendar)

        XCTAssertEqual(schedule?.preset, .custom)
        XCTAssertEqual(schedule?.startDate, date("2026-05-10T00:00:00Z"))
        XCTAssertEqual(schedule?.endDate, date("2026-05-12T00:00:00Z"))
    }

    func testSummaryMarksOverdueTodayWindow() {
        let schedule = HouseholdProtocolSchedule(
            preset: .today,
            startDate: date("2026-05-01T00:00:00Z"),
            endDate: date("2026-05-01T00:00:00Z")
        )

        let summary = ProtocolScheduleRules.summary(
            for: schedule,
            now: date("2026-05-02T09:00:00Z"),
            calendar: calendar
        )

        XCTAssertEqual(
            summary,
            ProtocolScheduleRules.Summary(
                preset: .today,
                startDate: date("2026-05-01T00:00:00Z"),
                endDate: date("2026-05-01T00:00:00Z"),
                state: .overdue
            )
        )
    }

    func testSummaryPreservesCustomRangeSemantics() {
        let schedule = HouseholdProtocolSchedule(
            preset: .custom,
            startDate: date("2026-05-01T00:00:00Z"),
            endDate: date("2026-05-03T00:00:00Z")
        )

        let summary = ProtocolScheduleRules.summary(
            for: schedule,
            now: date("2026-05-02T09:00:00Z"),
            calendar: calendar
        )

        XCTAssertEqual(
            summary,
            ProtocolScheduleRules.Summary(
                preset: .custom,
                startDate: date("2026-05-01T00:00:00Z"),
                endDate: date("2026-05-03T00:00:00Z"),
                state: .active
            )
        )
    }

    // MARK: - Run-aware schedule status

    func testScheduleStatusReturnsUpcomingForFutureWindow() {
        let schedule = HouseholdProtocolSchedule(
            preset: .today,
            startDate: date("2026-05-05T00:00:00Z"),
            endDate: date("2026-05-05T00:00:00Z")
        )

        let status = ProtocolScheduleRules.scheduleStatus(
            for: schedule,
            runs: [],
            now: date("2026-05-01T12:00:00Z"),
            calendar: calendar
        )

        XCTAssertEqual(status, .upcoming)
    }

    func testScheduleStatusReturnsActiveWhenInsideWindow() {
        let schedule = HouseholdProtocolSchedule(
            preset: .thisWeek,
            startDate: date("2026-05-04T00:00:00Z"),
            endDate: date("2026-05-09T00:00:00Z")
        )

        let status = ProtocolScheduleRules.scheduleStatus(
            for: schedule,
            runs: [],
            now: date("2026-05-06T09:00:00Z"),
            calendar: calendar
        )

        XCTAssertEqual(status, .active)
    }

    func testScheduleStatusReturnsOverdueWhenWindowPassedAndRunsEmpty() {
        let schedule = HouseholdProtocolSchedule(
            preset: .today,
            startDate: date("2026-05-01T00:00:00Z"),
            endDate: date("2026-05-01T00:00:00Z")
        )

        let status = ProtocolScheduleRules.scheduleStatus(
            for: schedule,
            runs: [],
            now: date("2026-05-03T09:00:00Z"),
            calendar: calendar
        )

        XCTAssertEqual(status, .overdue)
    }

    func testScheduleStatusReturnsSatisfiedWhenRunStartedDuringWindow() {
        let schedule = HouseholdProtocolSchedule(
            preset: .today,
            startDate: date("2026-05-01T00:00:00Z"),
            endDate: date("2026-05-01T00:00:00Z")
        )
        let runs = [
            ProtocolRun(
                protocolID: UUID(),
                protocolTitle: "Morning routine",
                createdAt: date("2026-05-01T08:00:00Z")
            )
        ]

        // 1-day cadence: a run on day X is within cadence on day X+1.
        let status = ProtocolScheduleRules.scheduleStatus(
            for: schedule,
            runs: runs,
            now: date("2026-05-02T09:00:00Z"),
            calendar: calendar
        )

        XCTAssertEqual(status, .satisfied)
    }

    func testScheduleStatusReturnsOverdueWhenInWindowRunIsOlderThanCadence() {
        // Same in-window run, but the cadence (1 day for `today` preset) has
        // elapsed twice over. Old behavior would have returned `.satisfied`
        // forever; the new contract resurfaces overdue once the cadence
        // window without a fresh run passes.
        let schedule = HouseholdProtocolSchedule(
            preset: .today,
            startDate: date("2026-05-01T00:00:00Z"),
            endDate: date("2026-05-01T00:00:00Z")
        )
        let runs = [
            ProtocolRun(
                protocolID: UUID(),
                protocolTitle: "Morning routine",
                createdAt: date("2026-05-01T08:00:00Z")
            )
        ]

        let status = ProtocolScheduleRules.scheduleStatus(
            for: schedule,
            runs: runs,
            now: date("2026-05-05T09:00:00Z"),
            calendar: calendar
        )

        XCTAssertEqual(status, .overdue)
    }

    func testScheduleStatusReturnsSatisfiedWhenRunWithinWeeklyCadence() {
        // The user's reported case: a `thisWeek` preset (7-day cadence) with
        // a run inside the rolling 7-day window before `now` must not flag
        // the schedule as overdue, even though the original window has passed.
        let schedule = HouseholdProtocolSchedule(
            preset: .thisWeek,
            startDate: date("2026-05-04T00:00:00Z"),
            endDate: date("2026-05-10T00:00:00Z")
        )
        let runs = [
            ProtocolRun(
                protocolID: UUID(),
                protocolTitle: "Weekly review",
                createdAt: date("2026-05-08T18:00:00Z")
            )
        ]

        let status = ProtocolScheduleRules.scheduleStatus(
            for: schedule,
            runs: runs,
            now: date("2026-05-14T12:00:00Z"),
            calendar: calendar
        )

        XCTAssertEqual(status, .satisfied)
    }

    func testScheduleStatusReturnsOverdueWhenLastRunPredatesWeeklyCadence() {
        let schedule = HouseholdProtocolSchedule(
            preset: .thisWeek,
            startDate: date("2026-05-04T00:00:00Z"),
            endDate: date("2026-05-10T00:00:00Z")
        )
        let runs = [
            ProtocolRun(
                protocolID: UUID(),
                protocolTitle: "Weekly review",
                createdAt: date("2026-05-05T18:00:00Z")
            )
        ]

        // 14 days after the original window end is well outside the 7-day
        // cadence, so the protocol must resurface as overdue.
        let status = ProtocolScheduleRules.scheduleStatus(
            for: schedule,
            runs: runs,
            now: date("2026-05-24T12:00:00Z"),
            calendar: calendar
        )

        XCTAssertEqual(status, .overdue)
    }

    func testRecurrenceCadenceDaysDerivesFromWindowWidth() {
        let oneDay = HouseholdProtocolSchedule(
            preset: .today,
            startDate: date("2026-05-01T00:00:00Z"),
            endDate: date("2026-05-01T00:00:00Z")
        )
        XCTAssertEqual(
            ProtocolScheduleRules.recurrenceCadenceDays(for: oneDay, calendar: calendar),
            1
        )

        let week = HouseholdProtocolSchedule(
            preset: .thisWeek,
            startDate: date("2026-05-04T00:00:00Z"),
            endDate: date("2026-05-10T00:00:00Z")
        )
        XCTAssertEqual(
            ProtocolScheduleRules.recurrenceCadenceDays(for: week, calendar: calendar),
            7
        )

        let weekend = HouseholdProtocolSchedule(
            preset: .weekend,
            startDate: date("2026-05-09T00:00:00Z"),
            endDate: date("2026-05-10T00:00:00Z")
        )
        XCTAssertEqual(
            ProtocolScheduleRules.recurrenceCadenceDays(for: weekend, calendar: calendar),
            2
        )

        let custom = HouseholdProtocolSchedule(
            preset: .custom,
            startDate: date("2026-05-01T00:00:00Z"),
            endDate: date("2026-05-14T00:00:00Z")
        )
        XCTAssertEqual(
            ProtocolScheduleRules.recurrenceCadenceDays(for: custom, calendar: calendar),
            14
        )
    }

    func testScheduleStatusReturnsSatisfiedWhenRunStartedAfterWindowStart() {
        let schedule = HouseholdProtocolSchedule(
            preset: .today,
            startDate: date("2026-05-01T00:00:00Z"),
            endDate: date("2026-05-01T00:00:00Z")
        )
        // Run started after the window's end day but still after window start.
        let runs = [
            ProtocolRun(
                protocolID: UUID(),
                protocolTitle: "Morning routine",
                createdAt: date("2026-05-02T08:00:00Z")
            )
        ]

        let status = ProtocolScheduleRules.scheduleStatus(
            for: schedule,
            runs: runs,
            now: date("2026-05-03T09:00:00Z"),
            calendar: calendar
        )

        XCTAssertEqual(status, .satisfied)
    }

    func testScheduleStatusReturnsOverdueWhenOnlyOldRunsExist() {
        let schedule = HouseholdProtocolSchedule(
            preset: .today,
            startDate: date("2026-05-01T00:00:00Z"),
            endDate: date("2026-05-01T00:00:00Z")
        )
        // Run from before the schedule's window must not count as satisfying.
        let runs = [
            ProtocolRun(
                protocolID: UUID(),
                protocolTitle: "Morning routine",
                createdAt: date("2026-04-25T08:00:00Z")
            )
        ]

        let status = ProtocolScheduleRules.scheduleStatus(
            for: schedule,
            runs: runs,
            now: date("2026-05-03T09:00:00Z"),
            calendar: calendar
        )

        XCTAssertEqual(status, .overdue)
    }

    func testRunAwareSummaryPreservesPresetAndRangeWhenSatisfied() {
        let schedule = HouseholdProtocolSchedule(
            preset: .today,
            startDate: date("2026-05-01T00:00:00Z"),
            endDate: date("2026-05-01T00:00:00Z")
        )
        let runs = [
            ProtocolRun(
                protocolID: UUID(),
                protocolTitle: "Morning routine",
                createdAt: date("2026-05-01T08:00:00Z")
            )
        ]

        let summary = ProtocolScheduleRules.summary(
            for: schedule,
            runs: runs,
            now: date("2026-05-02T09:00:00Z"),
            calendar: calendar
        )

        XCTAssertEqual(
            summary,
            ProtocolScheduleRules.ScheduleSummary(
                preset: .today,
                startDate: date("2026-05-01T00:00:00Z"),
                endDate: date("2026-05-01T00:00:00Z"),
                status: .satisfied
            )
        )
    }

    func testRunAwareSummaryPreservesPresetAndRangeWhenOverdue() {
        let schedule = HouseholdProtocolSchedule(
            preset: .today,
            startDate: date("2026-05-01T00:00:00Z"),
            endDate: date("2026-05-01T00:00:00Z")
        )

        let summary = ProtocolScheduleRules.summary(
            for: schedule,
            runs: [],
            now: date("2026-05-03T09:00:00Z"),
            calendar: calendar
        )

        XCTAssertEqual(
            summary,
            ProtocolScheduleRules.ScheduleSummary(
                preset: .today,
                startDate: date("2026-05-01T00:00:00Z"),
                endDate: date("2026-05-01T00:00:00Z"),
                status: .overdue
            )
        )
    }

    private func date(_ value: String) -> Date {
        formatter.date(from: value)!
    }
}
