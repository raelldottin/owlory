import XCTest
#if SWIFT_PACKAGE
@testable import OwloryCore
#endif

final class ContinueRankingRulesTests: XCTestCase {
    func testRanksMixedItemsByContinuePriorityBuckets() {
        let ranked = ContinueRankingRules.rank([
            candidate("home-active", .active, originalIndex: 0),
            candidate("write-progress", .inProgress, originalIndex: 1),
            candidate("carried-focus", .carriedForward, originalIndex: 2),
            candidate("train-due", .dueToday, originalIndex: 3)
        ])

        XCTAssertEqual(ranked.map(\.id), [
            "train-due",
            "carried-focus",
            "home-active",
            "write-progress"
        ])
    }

    func testPreservesOriginalOrderWithinSamePriorityBucket() {
        let ranked = ContinueRankingRules.rank([
            candidate("laundry", .active, originalIndex: 0),
            candidate("dishes", .active, originalIndex: 1),
            candidate("pantry", .active, originalIndex: 2)
        ])

        XCTAssertEqual(ranked.map(\.id), ["laundry", "dishes", "pantry"])
    }

    func testEmptyInputReturnsEmptyOutput() {
        XCTAssertEqual(ContinueRankingRules.rank([]), [])
    }

    func testAlreadySortedInputRemainsStable() {
        let alreadySorted = [
            candidate("morning-run", .dueToday, originalIndex: 0),
            candidate("draft-outline", .carriedForward, originalIndex: 1),
            candidate("clean-kitchen", .active, originalIndex: 2),
            candidate("essay-source", .inProgress, originalIndex: 3)
        ]

        XCTAssertEqual(ContinueRankingRules.rank(alreadySorted), alreadySorted)
    }

    func testOwloryContinueRegressionKeepsDefaultDomainFlowWithoutUrgency() {
        let ranked = ContinueRankingRules.rank([
            candidate("training-session", .dueToday, originalIndex: 1),
            candidate("stale-focus-item", .carriedForward, originalIndex: 2),
            candidate("home-task", .active, originalIndex: 3),
            candidate("writing-note", .inProgress, originalIndex: 4)
        ])

        XCTAssertEqual(ranked.map(\.id), [
            "training-session",
            "stale-focus-item",
            "home-task",
            "writing-note"
        ])
    }

    func testDueTodayWinsWhenItemCouldAlsoAppearAsCarriedForward() {
        let ranked = ContinueRankingRules.rank([
            candidate("run-carried-forward", .carriedForward, originalIndex: 0),
            candidate("run-due-today", .dueToday, originalIndex: 1)
        ])

        XCTAssertEqual(ranked.map(\.id), ["run-due-today", "run-carried-forward"])
    }

    func testUrgencyPreservesExistingCompletionHistoryReranking() {
        let ranked = ContinueRankingRules.rank([
            candidate("train-due", .dueToday, urgencyScore: 0.25, originalIndex: 0),
            candidate("home-overdue", .active, urgencyScore: 1.4, originalIndex: 1),
            candidate("write-progress", .inProgress, originalIndex: 2)
        ])

        XCTAssertEqual(ranked.map(\.id), ["home-overdue", "train-due", "write-progress"])
    }

    func testEqualUrgencyFallsBackToPriorityThenOriginalOrder() {
        let ranked = ContinueRankingRules.rank([
            candidate("home-second", .active, urgencyScore: 1, originalIndex: 2),
            candidate("carried-first", .carriedForward, urgencyScore: 1, originalIndex: 0),
            candidate("home-first", .active, urgencyScore: 1, originalIndex: 1)
        ])

        XCTAssertEqual(ranked.map(\.id), ["carried-first", "home-first", "home-second"])
    }

    private func candidate(
        _ id: String,
        _ priority: ContinuePriority,
        urgencyScore: Double? = nil,
        originalIndex: Int
    ) -> ContinueCandidate {
        ContinueCandidate(
            id: id,
            priority: priority,
            urgencyScore: urgencyScore,
            originalIndex: originalIndex
        )
    }
}
