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

        XCTAssertEqual(summary, ProtocolScheduleRules.Summary(text: "Today window passed", state: .overdue))
    }

    func testSummaryFormatsCustomRange() {
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
                text: "Scheduled for May 1, 2026 - May 3, 2026",
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

        let status = ProtocolScheduleRules.scheduleStatus(
            for: schedule,
            runs: runs,
            now: date("2026-05-03T09:00:00Z"),
            calendar: calendar
        )

        XCTAssertEqual(status, .satisfied)
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

    func testRunAwareSummaryReusesScheduledTextWhenSatisfied() {
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
            now: date("2026-05-03T09:00:00Z"),
            calendar: calendar
        )

        XCTAssertEqual(
            summary,
            ProtocolScheduleRules.ScheduleSummary(text: "Scheduled for today", status: .satisfied)
        )
    }

    func testRunAwareSummaryReportsPassedTextWhenOverdue() {
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
            ProtocolScheduleRules.ScheduleSummary(text: "Today window passed", status: .overdue)
        )
    }

    private func date(_ value: String) -> Date {
        formatter.date(from: value)!
    }
}
