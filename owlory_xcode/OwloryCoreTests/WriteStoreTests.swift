import XCTest
#if SWIFT_PACKAGE
@testable import OwloryCore
#endif

@MainActor
final class WriteStoreTests: XCTestCase {

    private func makeStore() -> WriteStore {
        WriteStore(
            repository: InMemoryItemListRepository<WritingNote>()
        )
    }

    func testAddNoteAppendsToList() {
        let store = makeStore()
        store.addNote(title: "Test Note", body: "Body text")
        XCTAssertEqual(store.notes.count, 1)
        XCTAssertEqual(store.notes.first?.title, "Test Note")
        XCTAssertEqual(store.notes.first?.body, "Body text")
        XCTAssertEqual(store.notes.first?.stage, .capture)
    }

    func testAddNoteReturnsUUID() {
        let store = makeStore()
        let id = store.addNote(title: "Linked Note", body: "From Today")
        XCTAssertEqual(store.notes[0].id, id)
    }

    func testAdvanceStageMovesNoteForward() {
        let store = makeStore()
        store.addNote(title: "Note", body: "")
        let id = store.notes[0].id

        store.advanceStage(id: id)
        XCTAssertEqual(store.notes[0].stage, .source)

        store.advanceStage(id: id)
        XCTAssertEqual(store.notes[0].stage, .permanent)
    }

    func testTransitionStageToArchivedFromCapture() {
        let store = makeStore()
        store.addNote(title: "Discard", body: "")
        let id = store.notes[0].id

        store.transitionStage(id: id, to: .archived)
        XCTAssertEqual(store.notes[0].stage, .archived)
    }

    func testInvalidTransitionIsIgnored() {
        let store = makeStore()
        store.addNote(title: "Note", body: "")
        let id = store.notes[0].id

        store.transitionStage(id: id, to: .draft)
        XCTAssertEqual(store.notes[0].stage, .capture, "Capture cannot skip to draft")
    }

    func testDeleteNoteRemovesFromList() {
        let store = makeStore()
        store.addNote(title: "A", body: "")
        store.addNote(title: "B", body: "")
        let idA = store.notes[0].id

        store.deleteNote(id: idA)
        XCTAssertEqual(store.notes.count, 1)
        XCTAssertEqual(store.notes[0].title, "B")
    }

    func testNotesByStageGroupsCorrectly() {
        let store = makeStore()
        store.addNote(title: "Capture1", body: "")
        store.addNote(title: "Capture2", body: "")
        store.addNote(title: "Source1", body: "")
        store.advanceStage(id: store.notes[2].id)

        let grouped = store.notesByStage
        XCTAssertEqual(grouped[.capture]?.count, 2)
        XCTAssertEqual(grouped[.source]?.count, 1)
    }

    func testUpdateNoteChangesContent() {
        let store = makeStore()
        store.addNote(title: "Original", body: "Old")
        let id = store.notes[0].id

        store.updateNote(id: id, title: "Updated", body: "New")
        XCTAssertEqual(store.notes[0].title, "Updated")
        XCTAssertEqual(store.notes[0].body, "New")
    }

    func testHighlightedNoteToPresentReturnsNoteForNewRequest() {
        let noteID = UUID()

        let highlightedNote = WriteContinueRouting.highlightedNoteToPresent(
            highlightedNoteID: noteID,
            requestID: UUID(),
            lastPresentedRequestID: nil,
            availableNoteIDs: Set([noteID])
        )

        XCTAssertEqual(highlightedNote, noteID)
    }

    func testHighlightedNoteToPresentRejectsRepeatedOrMissingRequests() {
        let noteID = UUID()
        let requestID = UUID()

        XCTAssertNil(
            WriteContinueRouting.highlightedNoteToPresent(
                highlightedNoteID: noteID,
                requestID: requestID,
                lastPresentedRequestID: requestID,
                availableNoteIDs: Set([noteID])
            )
        )

        XCTAssertNil(
            WriteContinueRouting.highlightedNoteToPresent(
                highlightedNoteID: noteID,
                requestID: nil,
                lastPresentedRequestID: nil,
                availableNoteIDs: Set([noteID])
            )
        )

        XCTAssertNil(
            WriteContinueRouting.highlightedNoteToPresent(
                highlightedNoteID: noteID,
                requestID: UUID(),
                lastPresentedRequestID: nil,
                availableNoteIDs: Set<UUID>()
            )
        )
    }

    func testFileItemListRepositoryLoadsLegacyTrajectoryDataAndSavesIntoOwloryDirectory() throws {
        let appSupport = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: appSupport) }

        let note = WritingNote(
            title: "Legacy note",
            body: "Still readable after the rename",
            stage: .source
        )
        let legacyURL = OwloryAppSupportPath.legacyFileURL(
            in: appSupport,
            subdirectory: "Write",
            fileName: "notes.json"
        )
        try FileManager.default.createDirectory(
            at: legacyURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode([note]).write(to: legacyURL, options: .atomic)

        let repository = FileItemListRepository<WritingNote>(
            directory: "Write",
            fileName: "notes",
            appSupportDirectory: appSupport
        )

        let loaded = try repository.loadAll()
        XCTAssertEqual(loaded.map(\.title), ["Legacy note"])

        let currentURL = OwloryAppSupportPath.currentFileURL(
            in: appSupport,
            subdirectory: "Write",
            fileName: "notes.json"
        )
        XCTAssertFalse(FileManager.default.fileExists(atPath: currentURL.path))

        try repository.saveAll(loaded)

        XCTAssertTrue(FileManager.default.fileExists(atPath: currentURL.path))
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
