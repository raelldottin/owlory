import XCTest
#if SWIFT_PACKAGE
@testable import OwloryCore
#endif

final class WeeklyDigestCadenceRulesTests: XCTestCase {

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(_ string: String) -> Date {
        ISO8601DateFormatter().date(from: string)!
    }

    func testMondayTargetsPreviousCompletedMondayThroughSunday() {
        let now = date("2026-04-13T17:30:00Z")

        let window = WeeklyDigestCadenceRules.targetWindow(for: now, calendar: calendar)

        XCTAssertEqual(window?.weekStarting, date("2026-04-06T00:00:00Z"))
        XCTAssertEqual(window?.weekEnding, date("2026-04-12T00:00:00Z"))
    }

    func testNonMondayDoesNotTargetDigestGeneration() {
        let now = date("2026-04-14T09:00:00Z")

        let window = WeeklyDigestCadenceRules.targetWindow(for: now, calendar: calendar)

        XCTAssertNil(window)
    }

    func testPreviousCompletedWeekWindowWorksAfterMonday() {
        let now = date("2026-04-28T17:30:00Z")

        let window = WeeklyDigestCadenceRules.previousCompletedWeekWindow(for: now, calendar: calendar)

        XCTAssertEqual(window?.weekStarting, date("2026-04-20T00:00:00Z"))
        XCTAssertEqual(window?.weekEnding, date("2026-04-26T00:00:00Z"))
    }

    func testExistingDigestIsMatchedByNormalizedWeekStart() {
        let window = WeeklyDigestCadenceRules.WeekWindow(
            weekStarting: date("2026-04-06T00:00:00Z"),
            weekEnding: date("2026-04-12T00:00:00Z")
        )
        let digest = makeDigest(weekStarting: date("2026-04-06T15:45:00Z"))

        let result = WeeklyDigestCadenceRules.hasGeneratedDigest(
            for: window,
            existingDigests: [digest],
            calendar: calendar
        )

        XCTAssertTrue(result)
    }

    func testOtherWeeksDoNotSuppressDigestGeneration() {
        let window = WeeklyDigestCadenceRules.WeekWindow(
            weekStarting: date("2026-04-06T00:00:00Z"),
            weekEnding: date("2026-04-12T00:00:00Z")
        )
        let digest = makeDigest(weekStarting: date("2026-03-30T00:00:00Z"))

        let result = WeeklyDigestCadenceRules.hasGeneratedDigest(
            for: window,
            existingDigests: [digest],
            calendar: calendar
        )

        XCTAssertFalse(result)
    }

    private func makeDigest(weekStarting: Date) -> WeeklyDigest {
        WeeklyDigest(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            weekStarting: weekStarting,
            weekEnding: date("2026-04-12T00:00:00Z"),
            generatedAt: date("2026-04-13T09:00:00Z"),
            daysWithEntries: 1,
            completionRate: 1,
            totalPlanned: 1,
            totalDone: 1,
            averageReadiness: 3
        )
    }
}
