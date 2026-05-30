import XCTest
#if SWIFT_PACKAGE
@testable import OwloryCore
#endif

final class SkipForTodayRulesTests: XCTestCase {
    func testEmptySkippedKeysReturnsInputUnchanged() {
        let items = makeItems(["a", "b", "c"])
        let result = SkipForTodayRules.apply(to: items, skippedKeys: [])
        XCTAssertEqual(result.map(\.id), items.map(\.id))
    }

    func testSkippedKeysAreRemoved() {
        let items = makeItems(["a", "b", "c"])
        let skipped: Set<String> = [items[1].source.key]
        let result = SkipForTodayRules.apply(to: items, skippedKeys: skipped)
        XCTAssertEqual(result.map(\.id), [items[0].id, items[2].id])
    }

    func testOrderIsPreserved() {
        let items = makeItems(["a", "b", "c", "d", "e"])
        let skipped: Set<String> = [items[0].source.key, items[3].source.key]
        let result = SkipForTodayRules.apply(to: items, skippedKeys: skipped)
        XCTAssertEqual(result.map(\.id), [items[1].id, items[2].id, items[4].id])
    }

    // MARK: - Helpers

    private func makeItems(_ titles: [String]) -> [TodayContinuationRules.ContinueItem] {
        titles.enumerated().map { idx, title in
            TodayContinuationRules.ContinueItem(
                id: "test.\(title)",
                title: title,
                domain: .home,
                subtitleKind: .active,
                source: .homeTask(UUID()),
                linkedRecordID: nil,
                origin: nil,
                staleDayCount: nil,
                urgencyScore: nil,
                priority: .active,
                originalIndex: idx
            )
        }
    }
}
