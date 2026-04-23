import XCTest
#if SWIFT_PACKAGE
@testable import OwloryCore
#endif

final class PatternNudgeRulesTests: XCTestCase {

    func testStaleItemAlertsProjectCarryForwardStalledItems() {
        let snapshot = makeSnapshot(
            carryForward: CarryForwardPattern(
                averageCarriedPerDay: 1.5,
                stalledItems: [
                    CarryForwardPattern.StalledItem(
                        title: "Review PR",
                        domain: .career,
                        consecutiveDays: 4
                    )
                ]
            )
        )

        let alerts = PatternNudgeRules.staleItemAlerts(from: snapshot)

        XCTAssertEqual(alerts, [
            PatternNudgeRules.StaleItemAlert(
                title: "Review PR",
                domain: .career,
                consecutiveDays: 4
            )
        ])
    }

    func testStaleItemAlertsReturnEmptyWithoutCarryForwardPattern() {
        XCTAssertTrue(PatternNudgeRules.staleItemAlerts(from: nil).isEmpty)
        XCTAssertTrue(PatternNudgeRules.staleItemAlerts(from: makeSnapshot()).isEmpty)
    }

    func testDomainNudgeUsesFirstNeglectedDomain() {
        let snapshot = makeSnapshot(
            domainBalance: DomainBalancePattern(
                domainShares: [.training: 0.5, .writing: 0.5, .career: 0, .home: 0],
                neglectedDomains: [.career, .home]
            )
        )

        let nudge = PatternNudgeRules.domainNudge(from: snapshot)

        XCTAssertEqual(nudge?.domain, .career)
        XCTAssertEqual(nudge?.message, "Career has been quiet lately.")
    }

    func testDomainNudgeSkipsWritingAndUsesNextNeglectedDomain() {
        let snapshot = makeSnapshot(
            domainBalance: DomainBalancePattern(
                domainShares: [.training: 0.5, .writing: 0, .career: 0, .home: 0],
                neglectedDomains: [.writing, .home]
            )
        )

        let nudge = PatternNudgeRules.domainNudge(from: snapshot)

        XCTAssertEqual(nudge?.domain, .home)
        XCTAssertEqual(nudge?.message, "Home has been quiet lately.")
    }

    func testDomainNudgeReturnsNilWhenOnlyWritingIsNeglected() {
        let snapshot = makeSnapshot(
            domainBalance: DomainBalancePattern(
                domainShares: [.training: 0.4, .writing: 0, .career: 0.3, .home: 0.3],
                neglectedDomains: [.writing]
            )
        )

        XCTAssertNil(PatternNudgeRules.domainNudge(from: snapshot))
    }

    func testDomainNudgeReturnsNilWhenNoDomainIsNeglected() {
        let snapshot = makeSnapshot(
            domainBalance: DomainBalancePattern(
                domainShares: [.training: 0.25, .writing: 0.25, .career: 0.25, .home: 0.25],
                neglectedDomains: []
            )
        )

        XCTAssertNil(PatternNudgeRules.domainNudge(from: snapshot))
        XCTAssertNil(PatternNudgeRules.domainNudge(from: nil))
    }

    private func makeSnapshot(
        carryForward: CarryForwardPattern? = nil,
        domainBalance: DomainBalancePattern? = nil
    ) -> PatternSnapshot {
        PatternSnapshot(
            generatedAt: Date(),
            windowEnd: Date(),
            windowDays: 7,
            completionRate: CompletionRatePattern(
                doneCount: 1,
                totalCount: 2,
                deferredCount: 0,
                droppedCount: 0
            ),
            carryForward: carryForward,
            domainBalance: domainBalance
        )
    }
}
