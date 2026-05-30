import XCTest
#if SWIFT_PACKAGE
@testable import OwloryCore
#endif

/// Regression coverage for the run-aware "(passed)" rendering contract.
///
/// `HomeProtocolSchedulePresentationFormatting.helpText` and `summaryText`
/// must consume a run-aware `ScheduleSummary` so that a passed window with
/// a qualifying run renders as `.satisfied` (no "(passed)" copy) instead
/// of falling back to pure `WindowState`-based copy. A previous bug in the
/// schedule editor passed a non-run-aware `Summary`, causing the editor's
/// help text to display "window passed" even after the user had already
/// completed a Protocol run within the cadence.
final class HomeProtocolSchedulePresentationFormattingTests: XCTestCase {
    private let formatter = ISO8601DateFormatter()

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.firstWeekday = 1
        return calendar
    }

    // MARK: - helpText

    func testHelpTextOmitsPassedCopyWhenRunSatisfiesPassedWindow() {
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

        let helpText = HomeProtocolSchedulePresentationFormatting.helpText(
            for: summary,
            calendar: calendar
        )

        XCTAssertFalse(
            helpText.contains("passed"),
            "Help text must not surface 'passed' copy when a run satisfied the window; got: \(helpText)"
        )
    }

    func testHelpTextShowsPassedCopyWhenNoRunSatisfiesPassedWindow() {
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

        let helpText = HomeProtocolSchedulePresentationFormatting.helpText(
            for: summary,
            calendar: calendar
        )

        XCTAssertTrue(
            helpText.contains("passed"),
            "Help text must surface 'passed' copy when the window passed without a satisfying run; got: \(helpText)"
        )
    }

    func testHelpTextReturnsAnytimeCopyWhenSummaryIsNil() {
        let helpText = HomeProtocolSchedulePresentationFormatting.helpText(
            for: nil,
            calendar: calendar
        )

        XCTAssertTrue(
            helpText.contains("Anytime"),
            "Help text must return the Anytime copy when no schedule is set; got: \(helpText)"
        )
    }

    // MARK: - summaryText

    func testSummaryTextOmitsPassedCopyWhenRunSatisfiesPassedWindow() {
        let summary = ProtocolScheduleRules.ScheduleSummary(
            preset: .today,
            startDate: date("2026-05-01T00:00:00Z"),
            endDate: date("2026-05-01T00:00:00Z"),
            status: .satisfied
        )

        let text = HomeProtocolSchedulePresentationFormatting.summaryText(
            for: summary,
            calendar: calendar
        )

        XCTAssertFalse(
            text.contains("passed"),
            "Summary text must not surface 'passed' copy for a satisfied schedule; got: \(text)"
        )
    }

    func testSummaryTextShowsPassedCopyWhenOverdue() {
        let summary = ProtocolScheduleRules.ScheduleSummary(
            preset: .today,
            startDate: date("2026-05-01T00:00:00Z"),
            endDate: date("2026-05-01T00:00:00Z"),
            status: .overdue
        )

        let text = HomeProtocolSchedulePresentationFormatting.summaryText(
            for: summary,
            calendar: calendar
        )

        XCTAssertTrue(
            text.contains("passed"),
            "Summary text must surface 'passed' copy for an overdue schedule; got: \(text)"
        )
    }

    func testDaysOverdueReturnsNilWhenStatusNotOverdue() {
        let summary = ProtocolScheduleRules.ScheduleSummary(
            preset: .today,
            startDate: date("2026-05-01T00:00:00Z"),
            endDate: date("2026-05-01T00:00:00Z"),
            status: .active
        )

        XCTAssertNil(
            HomeProtocolSchedulePresentationFormatting.daysOverdue(
                for: summary,
                now: date("2026-05-05T12:00:00Z"),
                calendar: calendar
            )
        )
    }

    func testDaysOverdueCountsWholeDaysSinceEnd() {
        let summary = ProtocolScheduleRules.ScheduleSummary(
            preset: .today,
            startDate: date("2026-05-01T00:00:00Z"),
            endDate: date("2026-05-01T00:00:00Z"),
            status: .overdue
        )

        XCTAssertEqual(
            HomeProtocolSchedulePresentationFormatting.daysOverdue(
                for: summary,
                now: date("2026-05-04T12:00:00Z"),
                calendar: calendar
            ),
            3
        )
    }

    func testDaysOverdueClampsToOneWhenWindowEndedToday() {
        let summary = ProtocolScheduleRules.ScheduleSummary(
            preset: .today,
            startDate: date("2026-05-05T00:00:00Z"),
            endDate: date("2026-05-05T00:00:00Z"),
            status: .overdue
        )

        XCTAssertEqual(
            HomeProtocolSchedulePresentationFormatting.daysOverdue(
                for: summary,
                now: date("2026-05-05T18:00:00Z"),
                calendar: calendar
            ),
            1
        )
    }

    // MARK: - Helpers

    private func date(_ value: String) -> Date {
        formatter.date(from: value)!
    }
}
