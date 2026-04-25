import XCTest
#if SWIFT_PACKAGE
@testable import OwloryCore
#endif

@MainActor
final class CareerStoreTests: XCTestCase {

    private func makeStore() -> CareerStore {
        CareerStore(repository: InMemoryItemListRepository<CareerRecord>())
    }

    func testAddRecordAppendsToList() {
        let store = makeStore()
        store.addRecord(type: .win, title: "Shipped feature X", body: "Delivered on time", metrics: "2 weeks ahead")
        XCTAssertEqual(store.records.count, 1)
        XCTAssertEqual(store.records[0].type, .win)
        XCTAssertEqual(store.records[0].title, "Shipped feature X")
        XCTAssertEqual(store.records[0].metrics, "2 weeks ahead")
    }

    func testAddRecordReturnsUUID() {
        let store = makeStore()
        let id = store.addRecord(type: .win, title: "Linked Win")
        XCTAssertEqual(store.records[0].id, id)
    }

    func testRecordsOfTypeFiltersCorrectly() {
        let store = makeStore()
        store.addRecord(type: .win, title: "Win 1")
        store.addRecord(type: .impact, title: "Impact 1")
        store.addRecord(type: .story, title: "Story 1")
        store.addRecord(type: .win, title: "Win 2")

        XCTAssertEqual(store.records(ofType: .win).count, 2)
        XCTAssertEqual(store.records(ofType: .impact).count, 1)
        XCTAssertEqual(store.records(ofType: .story).count, 1)
    }

    func testUpdateRecordChangesContent() {
        let store = makeStore()
        store.addRecord(type: .win, title: "Original")
        let id = store.records[0].id

        store.updateRecord(id: id, title: "Updated", body: "New body", metrics: "New metrics")
        XCTAssertEqual(store.records[0].title, "Updated")
        XCTAssertEqual(store.records[0].body, "New body")
        XCTAssertEqual(store.records[0].metrics, "New metrics")
    }

    func testDeleteRecordRemovesIt() {
        let store = makeStore()
        store.addRecord(type: .win, title: "To delete")
        let id = store.records[0].id

        store.deleteRecord(id: id)
        XCTAssertTrue(store.records.isEmpty)
    }
}
