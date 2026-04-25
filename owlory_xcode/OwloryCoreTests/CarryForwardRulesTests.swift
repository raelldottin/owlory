import XCTest
#if SWIFT_PACKAGE
@testable import OwloryCore
#endif

final class CarryForwardRulesTests: XCTestCase {
    func testDoneAndDroppedItemsDoNotCarryForward() {
        let entry = DailyEntry(
            date: makeDate("2026-04-07T09:00:00Z"),
            focusThree: [
                FocusItem(title: "Completed", domain: .home, status: .done),
                FocusItem(title: "Dropped", domain: .career, status: .dropped)
            ]
        )

        let carried = CarryForwardRules.nextDayItems(from: entry, into: makeDate("2026-04-08T09:00:00Z"))

        XCTAssertTrue(carried.isEmpty)
    }

    func testPlannedAndDeferredItemsCarryForwardAsPlanned() {
        let entryDate = makeDate("2026-04-07T09:00:00Z")
        let entry = DailyEntry(
            date: entryDate,
            focusThree: [
                FocusItem(title: "Still relevant", domain: .writing, status: .planned),
                FocusItem(title: "Intentionally deferred", domain: .home, status: .deferred)
            ]
        )

        let carried = CarryForwardRules.nextDayItems(from: entry, into: makeDate("2026-04-08T09:00:00Z"))

        XCTAssertEqual(carried.map(\.title), ["Still relevant", "Intentionally deferred"])
        XCTAssertTrue(carried.allSatisfy { $0.status == .planned })
        XCTAssertTrue(carried.allSatisfy { $0.createdFromDate == entryDate })
    }

    func testCarryForwardPreservesLinkedRecordIDs() {
        let linkedID = UUID()
        let entry = DailyEntry(
            date: makeDate("2026-04-07T09:00:00Z"),
            focusThree: [
                FocusItem(
                    title: "Laundry",
                    domain: .home,
                    status: .planned,
                    linkedRecordID: linkedID
                )
            ]
        )

        let carried = CarryForwardRules.nextDayItems(
            from: entry,
            into: makeDate("2026-04-08T09:00:00Z")
        )

        XCTAssertEqual(carried.count, 1)
        XCTAssertEqual(carried.first?.linkedRecordID, linkedID)
    }

    private func makeDate(_ value: String) -> Date {
        ISO8601DateFormatter().date(from: value)!
    }
}
