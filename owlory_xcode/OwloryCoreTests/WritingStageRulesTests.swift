import XCTest
#if SWIFT_PACKAGE
@testable import OwloryCore
#endif

final class WritingStageRulesTests: XCTestCase {
    func testAdvanceMovesThroughCanonicalNextStage() throws {
        let note = WritingNote(title: "Prototype notes", body: "Initial capture", stage: .capture)

        let advanced = try WritingStageRules.advance(note)

        XCTAssertEqual(advanced.stage, .source)
        XCTAssertEqual(advanced.title, note.title)
        XCTAssertEqual(advanced.body, note.body)
    }

    func testTransitionAllowsExplicitArchiveFromDraft() throws {
        let note = WritingNote(title: "Almost done", body: "Draft body", stage: .draft)

        let archived = try WritingStageRules.transition(note, to: .archived)

        XCTAssertEqual(archived.stage, .archived)
    }

    func testTransitionRejectsSkippingStraightFromCaptureToDraft() {
        let note = WritingNote(title: "Idea", body: "Too early", stage: .capture)

        XCTAssertThrowsError(try WritingStageRules.transition(note, to: .draft)) { error in
            XCTAssertEqual(
                error as? WritingStageTransitionError,
                .invalidTransition(from: .capture, to: .draft)
            )
        }
    }

    func testPublishedNoteCannotAdvanceFurther() {
        let note = WritingNote(title: "Published", body: "Done", stage: .published)

        XCTAssertThrowsError(try WritingStageRules.advance(note)) { error in
            XCTAssertEqual(
                error as? WritingStageTransitionError,
                .invalidTransition(from: .published, to: .published)
            )
        }
    }
}
