import XCTest
#if SWIFT_PACKAGE
@testable import OwloryCore
#endif

@MainActor
final class TodayStorePruneInvalidFocusItemsTests: XCTestCase {
    func testPruneRemovesFocusItemWithDeletedHomeTaskLink() {
        let liveTaskID = UUID()
        let deletedTaskID = UUID()
        let today = day("2026-05-30T08:00:00Z")
        let entry = DailyEntry(
            date: today,
            focusThree: [
                FocusItem(title: "Mow lawn", domain: .home, linkedRecordID: liveTaskID),
                FocusItem(title: "Ghost task", domain: .home, linkedRecordID: deletedTaskID),
                FocusItem(title: "Plan birthday", domain: .home)
            ]
        )
        let store = makeStore(seeded: entry, now: today)

        store.pruneInvalidFocusItems(
            knownRecordIDs: .init(homeTasks: [liveTaskID])
        )

        XCTAssertEqual(
            store.currentEntryForTests?.focusThree.map(\.title),
            ["Mow lawn", "Plan birthday"],
            "Pruning must drop only the focus item linked to a deleted record; live links and user-authored items survive."
        )
    }

    func testPruneIsNoOpWhenAllItemsValid() {
        let taskID = UUID()
        let today = day("2026-05-30T08:00:00Z")
        let entry = DailyEntry(
            date: today,
            focusThree: [
                FocusItem(title: "Mow lawn", domain: .home, linkedRecordID: taskID),
                FocusItem(title: "Plan birthday", domain: .home)
            ]
        )
        let store = makeStore(seeded: entry, now: today)

        store.pruneInvalidFocusItems(
            knownRecordIDs: .init(homeTasks: [taskID])
        )

        XCTAssertEqual(
            store.currentEntryForTests?.focusThree.map(\.title),
            ["Mow lawn", "Plan birthday"]
        )
    }

    func testPruneRemovesItemsFromCarryForwardToo() {
        let deletedID = UUID()
        let today = day("2026-05-30T08:00:00Z")
        let entry = DailyEntry(
            date: today,
            focusThree: [],
            carryForward: [
                FocusItem(title: "Ghost", domain: .writing, linkedRecordID: deletedID),
                FocusItem(title: "Still valid", domain: .writing)
            ]
        )
        let store = makeStore(seeded: entry, now: today)

        store.pruneInvalidFocusItems(knownRecordIDs: .init(writingNotes: []))

        XCTAssertEqual(
            store.currentEntryForTests?.carryForward.map(\.title),
            ["Still valid"]
        )
    }

    func testPrunePreservesItemsWithOriginPointingToLiveRecord() {
        let noteID = UUID()
        let today = day("2026-05-30T08:00:00Z")
        let entry = DailyEntry(
            date: today,
            focusThree: [
                FocusItem(
                    title: "Essay",
                    domain: .writing,
                    origin: FocusItemOrigin(kind: .writingNote, id: noteID, createdAt: today)
                )
            ]
        )
        let store = makeStore(seeded: entry, now: today)

        store.pruneInvalidFocusItems(knownRecordIDs: .init(writingNotes: [noteID]))

        XCTAssertEqual(store.currentEntryForTests?.focusThree.count, 1)
    }

    // MARK: - Helpers

    private func makeStore(seeded entry: DailyEntry, now: Date) -> TodayStore {
        let repo = InMemoryTodayEntryRepository()
        try? repo.saveEntry(entry)
        return TodayStore(clock: FixedClock(now: now), repository: repo)
    }

    private func day(_ value: String) -> Date {
        ISO8601DateFormatter().date(from: value)!
    }

    private struct FixedClock: Clock {
        let now: Date
    }
}

private extension TodayStore {
    var currentEntryForTests: DailyEntry? {
        switch entryState {
        case .active(let e), .setupIncomplete(let e), .reflected(let e), .historical(let e):
            return e
        case .missing:
            return nil
        }
    }
}
