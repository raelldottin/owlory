import XCTest
#if SWIFT_PACKAGE
@testable import OwloryCore
#endif

final class DailyPlanningRulesTests: XCTestCase {
    private let planDate = ISO8601DateFormatter().date(from: "2026-04-18T00:00:00Z")!
    private let carriedDate = ISO8601DateFormatter().date(from: "2026-04-17T00:00:00Z")!

    func testSeedEntryUsesCarriedItemsAsInitialFocusPlanUpToLimit() {
        let carried = [
            makeItem("Write outline", domain: .writing),
            makeItem("Clean kitchen", domain: .home),
            makeItem("Review brag doc", domain: .career),
            makeItem("Mobility work", domain: .training),
        ]

        let entry = DailyPlanningRules.seedEntry(for: planDate, carryForward: carried)

        XCTAssertEqual(entry.date, planDate)
        XCTAssertEqual(entry.focusThree.map(\.title), ["Write outline", "Clean kitchen", "Review brag doc"])
        XCTAssertEqual(entry.carryForward.map(\.title), ["Write outline", "Clean kitchen", "Review brag doc", "Mobility work"])
        XCTAssertTrue(entry.domainIntentions.isEmpty)
    }

    func testSeedEntryHandlesEmptyCarryForward() {
        let entry = DailyPlanningRules.seedEntry(for: planDate, carryForward: [])

        XCTAssertTrue(entry.focusThree.isEmpty)
        XCTAssertTrue(entry.carryForward.isEmpty)
    }

    func testAddingFocusItemAppendsWhenThereIsRoom() {
        let linkedID = UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!
        let item = FocusItem(
            id: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!,
            title: "  Morning run  ",
            domain: .training,
            linkedRecordID: linkedID
        )
        let entry = DailyEntry(date: planDate)

        let updated = DailyPlanningRules.addingFocusItem(item, to: entry)

        XCTAssertEqual(updated.focusThree.map(\.id), [item.id])
        XCTAssertEqual(updated.focusThree.first?.title, "  Morning run  ")
        XCTAssertEqual(updated.focusThree.first?.linkedRecordID, linkedID)
    }

    func testAddingFocusItemRejectsBlankTitleOrFullPlan() {
        let blank = FocusItem(title: "   ", domain: .home)
        let openEntry = DailyEntry(date: planDate)
        XCTAssertEqual(DailyPlanningRules.addingFocusItem(blank, to: openEntry), openEntry)

        let fullEntry = DailyEntry(
            date: planDate,
            focusThree: [
                makeItem("One", domain: .home),
                makeItem("Two", domain: .career),
                makeItem("Three", domain: .writing),
            ]
        )
        let updated = DailyPlanningRules.addingFocusItem(makeItem("Four", domain: .training), to: fullEntry)
        XCTAssertEqual(updated, fullEntry)
    }

    func testRemovingFocusItemOnlyRemovesMatchingItem() {
        let keep = makeItem("Keep", domain: .home)
        let remove = makeItem("Remove", domain: .writing)
        let entry = DailyEntry(date: planDate, focusThree: [keep, remove])

        let updated = DailyPlanningRules.removingFocusItem(id: remove.id, from: entry)

        XCTAssertEqual(updated.focusThree.map(\.id), [keep.id])
    }

    func testUpdatingStatusOnlyMutatesMatchingItem() {
        let first = makeItem("First", domain: .home)
        let second = makeItem("Second", domain: .career)
        let entry = DailyEntry(date: planDate, focusThree: [first, second])

        let updated = DailyPlanningRules.updatingStatus(for: second.id, to: .done, in: entry)

        XCTAssertEqual(updated.focusThree[0].status, .planned)
        XCTAssertEqual(updated.focusThree[1].status, .done)
        XCTAssertEqual(
            DailyPlanningRules.updatingStatus(for: UUID(), to: .dropped, in: updated),
            updated
        )
    }

    private func makeItem(_ title: String, domain: LifeDomain) -> FocusItem {
        FocusItem(
            id: UUID(),
            title: title,
            domain: domain,
            status: .planned,
            createdFromDate: carriedDate
        )
    }
}
