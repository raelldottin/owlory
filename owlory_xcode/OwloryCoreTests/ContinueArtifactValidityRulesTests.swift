import XCTest
#if SWIFT_PACKAGE
@testable import OwloryCore
#endif

final class ContinueArtifactValidityRulesTests: XCTestCase {
    func testUserAuthoredItemIsAlwaysValid() {
        let item = FocusItem(title: "Plan birthday party", domain: .home)
        XCTAssertTrue(
            ContinueArtifactValidityRules.isValid(
                item,
                against: ContinueArtifactValidityRules.KnownRecordIDs()
            )
        )
    }

    func testHomeTaskLinkResolvesWhenIDIsKnown() {
        let taskID = UUID()
        let item = FocusItem(
            title: "Mow lawn",
            domain: .home,
            linkedRecordID: taskID
        )
        let ids = ContinueArtifactValidityRules.KnownRecordIDs(homeTasks: [taskID])

        XCTAssertTrue(ContinueArtifactValidityRules.isValid(item, against: ids))
    }

    func testHomeTaskLinkIsInvalidWhenRecordWasDeleted() {
        let deletedID = UUID()
        let item = FocusItem(
            title: "Mow lawn",
            domain: .home,
            linkedRecordID: deletedID
        )
        let ids = ContinueArtifactValidityRules.KnownRecordIDs(homeTasks: [UUID()])

        XCTAssertFalse(ContinueArtifactValidityRules.isValid(item, against: ids))
    }

    func testHomeDomainAlsoResolvesViaRunsOrProtocols() {
        let runID = UUID()
        let runLinked = FocusItem(
            title: "Sunday meal prep",
            domain: .home,
            linkedRecordID: runID
        )
        let ids = ContinueArtifactValidityRules.KnownRecordIDs(homeRuns: [runID])

        XCTAssertTrue(ContinueArtifactValidityRules.isValid(runLinked, against: ids))
    }

    func testWritingNoteLinkIsInvalidWhenRecordMissing() {
        let item = FocusItem(
            title: "Essay draft",
            domain: .writing,
            linkedRecordID: UUID()
        )
        XCTAssertFalse(
            ContinueArtifactValidityRules.isValid(
                item,
                against: ContinueArtifactValidityRules.KnownRecordIDs()
            )
        )
    }

    func testOriginPathTakesPrecedenceOverLinkedRecordID() {
        let originID = UUID()
        let differentLinkedID = UUID()
        let item = FocusItem(
            title: "Essay note",
            domain: .writing,
            linkedRecordID: differentLinkedID,
            origin: FocusItemOrigin(kind: .writingNote, id: originID, createdAt: Date())
        )
        let ids = ContinueArtifactValidityRules.KnownRecordIDs(
            writingNotes: [originID]
        )

        XCTAssertTrue(ContinueArtifactValidityRules.isValid(item, against: ids))
    }

    func testOriginPathDetectsDeletedRecord() {
        let item = FocusItem(
            title: "Essay note",
            domain: .writing,
            origin: FocusItemOrigin(kind: .writingNote, id: UUID(), createdAt: Date())
        )
        let ids = ContinueArtifactValidityRules.KnownRecordIDs(
            writingNotes: [UUID()]
        )

        XCTAssertFalse(ContinueArtifactValidityRules.isValid(item, against: ids))
    }

    func testTrainingTreatedAsValidWhenSessionSetIsNil() {
        // Composer currently sees only todaySessions; passing nil
        // preserves the existing "do not ghost-suppress training" behavior.
        let item = FocusItem(
            title: "5K run",
            domain: .training,
            linkedRecordID: UUID()
        )
        XCTAssertTrue(
            ContinueArtifactValidityRules.isValid(
                item,
                against: ContinueArtifactValidityRules.KnownRecordIDs(
                    trainingSessions: nil
                )
            )
        )
    }

    func testTrainingSuppressedWhenSessionSetIsKnownAndMissing() {
        let item = FocusItem(
            title: "5K run",
            domain: .training,
            linkedRecordID: UUID()
        )
        let ids = ContinueArtifactValidityRules.KnownRecordIDs(
            trainingSessions: [UUID()]
        )
        XCTAssertFalse(ContinueArtifactValidityRules.isValid(item, against: ids))
    }
}
