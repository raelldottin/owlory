import XCTest
#if SWIFT_PACKAGE
@testable import OwloryCore
#endif

final class TodayContinueItemAssemblerTests: XCTestCase {
    private let now = ISO8601DateFormatter().date(from: "2026-04-08T16:00:00Z")!

    func testAssemblesVisibleContinueItemMetadata() {
        let linkedRecordID = stableID("11111111-1111-1111-1111-111111111111")
        let candidate = candidate(
            title: "Performance review story",
            domain: .career,
            source: .carriedFocusItem(stableID("22222222-2222-2222-2222-222222222222")),
            linkedRecordID: linkedRecordID,
            staleDayCount: 4,
            step: .carriedForwardFocus
        )

        let items = TodayContinueItemAssembler.assemble(
            candidates: [candidate],
            now: now
        )

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.title, "Performance review story")
        XCTAssertEqual(items.first?.domain, .career)
        XCTAssertEqual(items.first?.reason, "Carried forward")
        XCTAssertEqual(items.first?.source, candidate.source)
        XCTAssertEqual(items.first?.linkedRecordID, linkedRecordID)
        XCTAssertEqual(items.first?.staleDayCount, 4)
        XCTAssertEqual(items.first?.priority, .carriedForward)
        XCTAssertEqual(items.first?.originalIndex, 1)
        XCTAssertEqual(items.first?.highlightTarget, .careerRecord(linkedRecordID))
    }

    func testUrgencyScoreComesFromMatchingPredictionKeyOnly() {
        let matchingKey = CompletionTimePredictor.key(forHomeTask: "Laundry")
        let prediction = CompletionTimePredictor.Prediction(
            itemKey: matchingKey,
            medianTimeOfDay: 10 * 60 * 60,
            madSeconds: 60 * 60,
            sampleCount: 4
        )
        let predictedCandidate = candidate(
            title: "Laundry",
            domain: .home,
            source: .homeTask(stableID("33333333-3333-3333-3333-333333333333")),
            predictionKey: matchingKey,
            step: .activeHomeTask
        )
        let unpredictedCandidate = candidate(
            title: "Draft idea",
            domain: .writing,
            source: .writingNote(stableID("44444444-4444-4444-4444-444444444444")),
            predictionKey: nil,
            step: .inProgressWriting
        )

        let items = TodayContinueItemAssembler.assemble(
            candidates: [predictedCandidate, unpredictedCandidate],
            predictions: [matchingKey: prediction],
            now: now
        )

        XCTAssertEqual(
            items.first(where: { $0.title == "Laundry" })?.urgencyScore,
            prediction.urgencyScore(now: now, on: now)
        )
        XCTAssertNil(items.first(where: { $0.title == "Draft idea" })?.urgencyScore)
    }

    func testAdmissionCapsPreserveExistingSourceOrderMembership() {
        let candidates = [
            candidate(
                title: "Run",
                domain: .training,
                source: .trainingSession(stableID("55555555-5555-5555-5555-555555555555")),
                step: .dueTodayTraining
            ),
            candidate(
                title: "Lift",
                domain: .training,
                source: .trainingSession(stableID("66666666-6666-6666-6666-666666666666")),
                step: .dueTodayTraining
            ),
            candidate(
                title: "Mobility",
                domain: .training,
                source: .trainingSession(stableID("77777777-7777-7777-7777-777777777777")),
                step: .dueTodayTraining
            ),
            candidate(
                title: "Laundry",
                domain: .home,
                source: .homeTask(stableID("88888888-8888-8888-8888-888888888888")),
                step: .activeHomeTask
            ),
            candidate(
                title: "Dishes",
                domain: .home,
                source: .homeTask(stableID("99999999-9999-9999-9999-999999999999")),
                step: .activeHomeTask
            ),
            candidate(
                title: "Essay",
                domain: .writing,
                source: .writingNote(stableID("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")),
                step: .inProgressWriting
            ),
        ]

        let items = TodayContinueItemAssembler.assemble(
            candidates: candidates,
            now: now
        )

        XCTAssertEqual(items.map(\.title), ["Run", "Lift", "Laundry", "Dishes", "Essay"])
        XCTAssertEqual(items.map(\.originalIndex), [1, 2, 3, 4, 5])
        XCTAssertEqual(items.filter { $0.domain == .training }.count, 2)
        XCTAssertEqual(items.filter { $0.domain == .home }.count, 2)
    }

    func testDeterministicIDsUseAdmittedIndexSourceDomainAndTitle() {
        let skippedByDomainCap = candidate(
            title: "Mobility",
            domain: .training,
            source: .trainingSession(stableID("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")),
            step: .dueTodayTraining
        )
        let candidates = [
            candidate(
                title: "Run",
                domain: .training,
                source: .trainingSession(stableID("cccccccc-cccc-cccc-cccc-cccccccccccc")),
                step: .dueTodayTraining
            ),
            candidate(
                title: "Lift",
                domain: .training,
                source: .trainingSession(stableID("dddddddd-dddd-dddd-dddd-dddddddddddd")),
                step: .dueTodayTraining
            ),
            skippedByDomainCap,
            candidate(
                title: "Laundry",
                domain: .home,
                source: .homeTask(stableID("eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee")),
                step: .activeHomeTask
            ),
        ]

        let items = TodayContinueItemAssembler.assemble(candidates: candidates, now: now)

        XCTAssertEqual(
            items.map(\.id),
            [
                "1|trainingSession|CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC|training|Run",
                "2|trainingSession|DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD|training|Lift",
                "3|homeTask|EEEEEEEE-EEEE-EEEE-EEEE-EEEEEEEEEEEE|home|Laundry",
            ]
        )
    }

    private func candidate(
        title: String,
        domain: LifeDomain,
        source: TodayContinuationRules.ContinueSource,
        linkedRecordID: UUID? = nil,
        staleDayCount: Int? = nil,
        predictionKey: String? = nil,
        step: TodayContinueSourceComposer.Step
    ) -> TodayContinueSourceComposer.Candidate {
        TodayContinueSourceComposer.Candidate(
            step: step,
            title: title,
            domain: domain,
            source: source,
            linkedRecordID: linkedRecordID,
            staleDayCount: staleDayCount,
            predictionKey: predictionKey
        )
    }

    private func stableID(_ value: String) -> UUID {
        UUID(uuidString: value)!
    }
}
