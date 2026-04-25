import XCTest
#if SWIFT_PACKAGE
@testable import OwloryCore
#endif

final class VoiceTranscriptionRoutingRulesTests: XCTestCase {
    func testDefaultTargetsMapVoiceContextsToApplicableFields() {
        XCTAssertEqual(
            VoiceTranscriptionRoutingRules.target(for: .todayReflection),
            .init(context: .todayReflection, field: .reflection)
        )
        XCTAssertEqual(
            VoiceTranscriptionRoutingRules.target(for: .todayQuickNote),
            .init(context: .todayQuickNote, field: .body)
        )
        XCTAssertEqual(
            VoiceTranscriptionRoutingRules.target(for: .todayQuickCareer),
            .init(context: .todayQuickCareer, field: .details)
        )
        XCTAssertEqual(
            VoiceTranscriptionRoutingRules.target(for: .trainSessionReflection),
            .init(context: .trainSessionReflection, field: .reflection)
        )
        XCTAssertEqual(
            VoiceTranscriptionRoutingRules.target(for: .writeCapture),
            .init(context: .writeCapture, field: .body)
        )
        XCTAssertEqual(
            VoiceTranscriptionRoutingRules.target(for: .careerRecord),
            .init(context: .careerRecord, field: .details)
        )
        XCTAssertEqual(
            VoiceTranscriptionRoutingRules.target(for: .homeTask),
            .init(context: .homeTask, field: .notes)
        )
    }

    func testRequestedSupportedTargetOverridesDefaultTarget() {
        XCTAssertEqual(
            VoiceTranscriptionRoutingRules.target(for: .todayQuickNote, requestedField: .title),
            .init(context: .todayQuickNote, field: .title)
        )
        XCTAssertEqual(
            VoiceTranscriptionRoutingRules.target(for: .todayQuickCareer, requestedField: .title),
            .init(context: .todayQuickCareer, field: .title)
        )
    }

    func testInvalidTargetsAreRejectedAndDoNotMutateText() {
        XCTAssertNil(VoiceTranscriptionRoutingRules.target(for: .homeTask, requestedField: .title))
        XCTAssertNil(VoiceTranscriptionRoutingRules.target(for: .writeCapture, requestedField: .notes))

        let invalidTarget = VoiceTranscriptionRoutingRules.Target(context: .homeTask, field: .title)
        XCTAssertEqual(
            VoiceTranscriptionRoutingRules.apply("Voice text", to: "Existing notes", target: invalidTarget),
            "Existing notes"
        )
    }

    func testBodyLikeFieldsAppendTrimmedTranscriptionWithNewLine() {
        let emptyResult = VoiceTranscriptionRoutingRules.apply(
            "  First voice note  ",
            to: "   ",
            in: .homeTask
        )
        XCTAssertEqual(emptyResult, "First voice note")

        let appendedResult = VoiceTranscriptionRoutingRules.apply(
            "  second voice note  ",
            to: "Existing notes",
            in: .homeTask
        )
        XCTAssertEqual(appendedResult, "Existing notes\nsecond voice note")
    }

    func testEmptyTranscriptionLeavesCurrentTextUnchanged() {
        XCTAssertEqual(
            VoiceTranscriptionRoutingRules.apply("   ", to: "Existing reflection", in: .todayReflection),
            "Existing reflection"
        )
    }

    func testTitleFieldsUseDeterministicOneHundredCharacterLimit() {
        let longTranscription = String(repeating: "a", count: 120)

        XCTAssertEqual(
            VoiceTranscriptionRoutingRules.apply(
                longTranscription,
                to: "",
                in: .todayQuickNote,
                requestedField: .title
            ).count,
            100
        )

        let existingTitle = String(repeating: "b", count: 99)
        XCTAssertEqual(
            VoiceTranscriptionRoutingRules.apply(
                "extra",
                to: existingTitle,
                in: .todayQuickNote,
                requestedField: .title
            ),
            existingTitle
        )
    }

    func testFallbackFillsOnlyWhenTargetFieldIsEmpty() {
        XCTAssertEqual(
            VoiceTranscriptionRoutingRules.applyFallback(
                "  Voice reflection  ",
                to: "   ",
                in: .trainSessionReflection
            ),
            "Voice reflection"
        )

        XCTAssertEqual(
            VoiceTranscriptionRoutingRules.applyFallback(
                "Voice reflection",
                to: "Typed reflection",
                in: .trainSessionReflection
            ),
            "Typed reflection"
        )
    }
}
