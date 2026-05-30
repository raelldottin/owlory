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
    }

    func testDomainNudgeCanReturnTrainingDomain() {
        let snapshot = makeSnapshot(
            domainBalance: DomainBalancePattern(
                domainShares: [.training: 0, .writing: 0.4, .career: 0.3, .home: 0.3],
                neglectedDomains: [.training]
            )
        )

        let nudge = PatternNudgeRules.domainNudge(from: snapshot)

        XCTAssertEqual(nudge?.domain, .training)
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

    func testDomainNudgeSuppressesTrainingWhenStandaloneSessionsExist() {
        let snapshot = makeSnapshot(
            domainBalance: DomainBalancePattern(
                domainShares: [.training: 0, .writing: 0.4, .career: 0.3, .home: 0.3],
                neglectedDomains: [.training]
            ),
            trainingConsistency: TrainingConsistencyPattern(
                sessionsPlanned: 3,
                sessionsCompleted: 1,
                sessionsModified: 0,
                sessionsSkipped: 0
            )
        )

        XCTAssertNil(
            PatternNudgeRules.domainNudge(from: snapshot),
            "Training nudge must not fire when training has standalone sessions outside Focus."
        )
    }

    func testDomainNudgeFiresTrainingWhenNoTrainingActivityAndNoConsistencyPattern() {
        let snapshot = makeSnapshot(
            domainBalance: DomainBalancePattern(
                domainShares: [.training: 0, .writing: 0.4, .career: 0.3, .home: 0.3],
                neglectedDomains: [.training]
            )
        )

        XCTAssertEqual(
            PatternNudgeRules.domainNudge(from: snapshot)?.domain,
            .training,
            "Training nudge must still fire when neither Focus nor standalone training activity exists."
        )
    }

    func testDomainNudgeFiresTrainingWhenConsistencyPatternIsAllZero() {
        let snapshot = makeSnapshot(
            domainBalance: DomainBalancePattern(
                domainShares: [.training: 0, .writing: 0.4, .career: 0.3, .home: 0.3],
                neglectedDomains: [.training]
            ),
            trainingConsistency: TrainingConsistencyPattern(
                sessionsPlanned: 0,
                sessionsCompleted: 0,
                sessionsModified: 0,
                sessionsSkipped: 0
            )
        )

        XCTAssertEqual(
            PatternNudgeRules.domainNudge(from: snapshot)?.domain,
            .training,
            "A zero-activity consistency pattern must not suppress the training nudge."
        )
    }

    private func makeSnapshot(
        carryForward: CarryForwardPattern? = nil,
        domainBalance: DomainBalancePattern? = nil,
        trainingConsistency: TrainingConsistencyPattern? = nil
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
            domainBalance: domainBalance,
            trainingConsistency: trainingConsistency
        )
    }
}
