import XCTest
#if SWIFT_PACKAGE
@testable import OwloryCore
#endif

final class FocusItemHistoryRulesTests: XCTestCase {
    func testItemWithoutCreatedFromDateReturnsEmptyArc() {
        let item = FocusItem(title: "Today only", domain: .writing, status: .planned)

        let arc = FocusItemHistoryRules.arc(
            for: item,
            in: [],
            today: day("2026-05-10"),
            calendar: calendar
        )

        XCTAssertEqual(arc, [])
    }

    func testCreatedTodayReturnsEmptyArc() {
        let today = day("2026-05-10")
        let item = FocusItem(
            title: "Fresh",
            domain: .home,
            status: .planned,
            createdFromDate: today
        )

        let arc = FocusItemHistoryRules.arc(
            for: item,
            in: [],
            today: today,
            calendar: calendar
        )

        XCTAssertEqual(arc, [])
    }

    func testMatchByOriginAcrossDays() {
        let originID = UUID()
        let originDate = day("2026-05-07T08:00:00Z")
        let origin = FocusItemOrigin(kind: .writingNote, id: originID, createdAt: originDate)

        let monday = DailyEntry(
            date: day("2026-05-07"),
            focusThree: [
                FocusItem(
                    title: "Draft essay",
                    domain: .writing,
                    status: .deferred,
                    origin: origin
                )
            ]
        )
        let tuesday = DailyEntry(
            date: day("2026-05-08"),
            focusThree: [
                FocusItem(
                    title: "Draft essay",
                    domain: .writing,
                    status: .planned,
                    createdFromDate: day("2026-05-07"),
                    origin: origin
                )
            ]
        )

        let today = FocusItem(
            title: "Draft essay",
            domain: .writing,
            status: .planned,
            createdFromDate: day("2026-05-07"),
            origin: origin
        )

        let arc = FocusItemHistoryRules.arc(
            for: today,
            in: [monday, tuesday],
            today: day("2026-05-09"),
            calendar: calendar
        )

        XCTAssertEqual(arc.count, 2)
        XCTAssertEqual(arc[0].status, .deferred)
        XCTAssertEqual(arc[1].status, .planned)
    }

    func testMatchByLinkedRecordIDWhenOriginMissing() {
        let linkedID = UUID()
        let yesterday = DailyEntry(
            date: day("2026-05-07"),
            focusThree: [
                FocusItem(
                    title: "Old title",
                    domain: .home,
                    status: .deferred,
                    linkedRecordID: linkedID
                )
            ]
        )

        let today = FocusItem(
            title: "Renamed",
            domain: .home,
            status: .planned,
            createdFromDate: day("2026-05-07"),
            linkedRecordID: linkedID
        )

        let arc = FocusItemHistoryRules.arc(
            for: today,
            in: [yesterday],
            today: day("2026-05-08"),
            calendar: calendar
        )

        XCTAssertEqual(arc, [.init(date: day("2026-05-07"), status: .deferred)])
    }

    func testMatchByTitleAndDomainFallback() {
        let yesterday = DailyEntry(
            date: day("2026-05-07"),
            focusThree: [
                FocusItem(title: "Mow lawn", domain: .home, status: .deferred)
            ]
        )

        let today = FocusItem(
            title: "Mow lawn",
            domain: .home,
            status: .planned,
            createdFromDate: day("2026-05-07")
        )

        let arc = FocusItemHistoryRules.arc(
            for: today,
            in: [yesterday],
            today: day("2026-05-08"),
            calendar: calendar
        )

        XCTAssertEqual(arc, [.init(date: day("2026-05-07"), status: .deferred)])
    }

    func testMissingDayFillsWithPlanned() {
        let item = FocusItem(
            title: "Ghost",
            domain: .career,
            status: .planned,
            createdFromDate: day("2026-05-05")
        )

        let arc = FocusItemHistoryRules.arc(
            for: item,
            in: [],
            today: day("2026-05-08"),
            calendar: calendar
        )

        XCTAssertEqual(arc.count, 3)
        XCTAssertTrue(arc.allSatisfy { $0.status == .planned })
        XCTAssertEqual(arc.map(\.date), [
            day("2026-05-05"),
            day("2026-05-06"),
            day("2026-05-07")
        ])
    }

    func testDeferredAndPlannedAreCaptured() {
        let monday = DailyEntry(
            date: day("2026-05-04"),
            focusThree: [FocusItem(title: "X", domain: .training, status: .planned)]
        )
        let tuesday = DailyEntry(
            date: day("2026-05-05"),
            focusThree: [FocusItem(title: "X", domain: .training, status: .deferred)]
        )
        let wednesday = DailyEntry(
            date: day("2026-05-06"),
            focusThree: [FocusItem(title: "X", domain: .training, status: .planned)]
        )

        let item = FocusItem(
            title: "X",
            domain: .training,
            status: .planned,
            createdFromDate: day("2026-05-04")
        )

        let arc = FocusItemHistoryRules.arc(
            for: item,
            in: [monday, tuesday, wednesday],
            today: day("2026-05-07"),
            calendar: calendar
        )

        XCTAssertEqual(arc.map(\.status), [.planned, .deferred, .planned])
    }

    // MARK: - Helpers

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    private func day(_ value: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: value) {
            return date
        }
        // Plain yyyy-MM-dd form
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(identifier: "UTC")
        df.dateFormat = "yyyy-MM-dd"
        return df.date(from: value)!
    }
}
