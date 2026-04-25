import XCTest
#if SWIFT_PACKAGE
@testable import OwloryCore
#endif

final class CalibrationRulesTests: XCTestCase {

    // MARK: - No pattern data (graceful degradation)

    func testWithoutSnapshotReturnsBaseNudge() {
        let entry = DailyEntry(date: Date(), energy: 3, mood: 2, sleepQuality: 3)
        let cal = CalibrationRules.calibrate(todayEntry: entry, weeklySnapshot: nil)
        XCTAssertNotNil(cal.enhancedNudge)
        XCTAssertNil(cal.completionContext)
        XCTAssertEqual(cal.enhancedNudge?.suggestedMaxPriorities, 2)
    }

    func testNoCheckinReturnsNilNudge() {
        let entry = DailyEntry(date: Date(), energy: 0, mood: 0, sleepQuality: 0)
        let cal = CalibrationRules.calibrate(todayEntry: entry, weeklySnapshot: nil)
        XCTAssertNil(cal.enhancedNudge)
        XCTAssertNil(cal.completionContext)
    }

    // MARK: - With pattern data

    func testWithSnapshotProducesCompletionContextSeparately() {
        let entry = DailyEntry(date: Date(), energy: 3, mood: 3, sleepQuality: 3)
        let snapshot = PatternSnapshot(
            generatedAt: Date(),
            windowEnd: Date(),
            windowDays: 7,
            completionRate: CompletionRatePattern(doneCount: 4, totalCount: 9, deferredCount: 2, droppedCount: 1),
            carryForward: nil,
            domainBalance: nil,
            readinessOutcome: nil
        )
        let cal = CalibrationRules.calibrate(todayEntry: entry, weeklySnapshot: snapshot)
        XCTAssertNotNil(cal.enhancedNudge)
        XCTAssertNotNil(cal.completionContext)
        // Nudge is pure daily read — does NOT contain weekly stats
        XCTAssertFalse(cal.enhancedNudge!.message.contains("4 of 9"))
        // Completion context exists separately for digest use
        XCTAssertTrue(cal.completionContext!.contains("44%"))
    }

    func testSparseSnapshotDoesNotAppendContext() {
        let entry = DailyEntry(date: Date(), energy: 4, mood: 4, sleepQuality: 4)
        let snapshot = PatternSnapshot(
            generatedAt: Date(),
            windowEnd: Date(),
            windowDays: 7,
            completionRate: CompletionRatePattern(doneCount: 1, totalCount: 2, deferredCount: 0, droppedCount: 0),
            carryForward: nil,
            domainBalance: nil,
            readinessOutcome: nil
        )
        let cal = CalibrationRules.calibrate(todayEntry: entry, weeklySnapshot: snapshot)
        XCTAssertNotNil(cal.enhancedNudge)
        XCTAssertNil(cal.completionContext)
    }

    func testNudgeMessagePreservesPrioritySuggestion() {
        let entry = DailyEntry(date: Date(), energy: 1, mood: 1, sleepQuality: 1)
        let snapshot = PatternSnapshot(
            generatedAt: Date(),
            windowEnd: Date(),
            windowDays: 7,
            completionRate: CompletionRatePattern(doneCount: 2, totalCount: 6, deferredCount: 2, droppedCount: 0),
            carryForward: nil,
            domainBalance: nil,
            readinessOutcome: nil
        )
        let cal = CalibrationRules.calibrate(todayEntry: entry, weeklySnapshot: snapshot)
        XCTAssertEqual(cal.enhancedNudge?.suggestedMaxPriorities, 1)
        // Nudge is pure daily — no weekly stats mixed in
        XCTAssertFalse(cal.enhancedNudge!.message.contains("2 of 6"))
        // But completion context is available separately
        XCTAssertNotNil(cal.completionContext)
    }

    // MARK: - Stale Item Alerts

    func testStaleItemsReturnedFromCarryForward() {
        let entry = DailyEntry(date: Date(), energy: 3, mood: 3, sleepQuality: 3)
        let snapshot = PatternSnapshot(
            generatedAt: Date(),
            windowEnd: Date(),
            windowDays: 7,
            completionRate: CompletionRatePattern(doneCount: 3, totalCount: 6, deferredCount: 1, droppedCount: 0),
            carryForward: CarryForwardPattern(
                averageCarriedPerDay: 1.5,
                stalledItems: [
                    CarryForwardPattern.StalledItem(title: "Review PR", domain: .career, consecutiveDays: 4),
                    CarryForwardPattern.StalledItem(title: "Fix sink", domain: .home, consecutiveDays: 3)
                ]
            ),
            domainBalance: nil,
            readinessOutcome: nil
        )
        let cal = CalibrationRules.calibrate(todayEntry: entry, weeklySnapshot: snapshot)
        XCTAssertEqual(cal.staleItems.count, 2)
        XCTAssertEqual(cal.staleItems[0].title, "Review PR")
        XCTAssertEqual(cal.staleItems[0].consecutiveDays, 4)
        XCTAssertEqual(cal.staleItems[1].domain, .home)
    }

    func testNoCarryForwardReturnsEmptyStaleItems() {
        let entry = DailyEntry(date: Date(), energy: 3, mood: 3, sleepQuality: 3)
        let cal = CalibrationRules.calibrate(todayEntry: entry, weeklySnapshot: nil)
        XCTAssertTrue(cal.staleItems.isEmpty)
    }

    // MARK: - Domain Nudge

    func testDomainNudgeForNeglectedDomain() {
        let entry = DailyEntry(date: Date(), energy: 3, mood: 3, sleepQuality: 3)
        let snapshot = PatternSnapshot(
            generatedAt: Date(),
            windowEnd: Date(),
            windowDays: 7,
            completionRate: CompletionRatePattern(doneCount: 3, totalCount: 5, deferredCount: 0, droppedCount: 0),
            carryForward: nil,
            domainBalance: DomainBalancePattern(
                domainShares: [.training: 0.5, .writing: 0.3, .career: 0.2, .home: 0],
                neglectedDomains: [.home]
            ),
            readinessOutcome: nil
        )
        let cal = CalibrationRules.calibrate(todayEntry: entry, weeklySnapshot: snapshot)
        XCTAssertNotNil(cal.domainNudge)
        XCTAssertEqual(cal.domainNudge?.domain, .home)
        XCTAssertEqual(cal.domainNudge?.message, "Home hasn't shown up in Focus lately.")
    }

    func testNoDomainNudgeWhenAllDomainsActive() {
        let entry = DailyEntry(date: Date(), energy: 3, mood: 3, sleepQuality: 3)
        let snapshot = PatternSnapshot(
            generatedAt: Date(),
            windowEnd: Date(),
            windowDays: 7,
            completionRate: CompletionRatePattern(doneCount: 4, totalCount: 8, deferredCount: 0, droppedCount: 0),
            carryForward: nil,
            domainBalance: DomainBalancePattern(
                domainShares: [.training: 0.25, .writing: 0.25, .career: 0.25, .home: 0.25],
                neglectedDomains: []
            ),
            readinessOutcome: nil
        )
        let cal = CalibrationRules.calibrate(todayEntry: entry, weeklySnapshot: snapshot)
        XCTAssertNil(cal.domainNudge)
    }

    func testNoDomainNudgeWithoutSnapshot() {
        let entry = DailyEntry(date: Date(), energy: 4, mood: 4, sleepQuality: 4)
        let cal = CalibrationRules.calibrate(todayEntry: entry, weeklySnapshot: nil)
        XCTAssertNil(cal.domainNudge)
    }

    // MARK: - Suggested Focus Load

    func testFocusLoadDefaultsToBaseNudge() {
        let entry = DailyEntry(date: Date(), energy: 3, mood: 3, sleepQuality: 3)
        let cal = CalibrationRules.calibrate(todayEntry: entry, weeklySnapshot: nil)
        XCTAssertEqual(cal.suggestedFocusLoad, 3)
    }

    func testFocusLoadReducedOnLowReadinessWithOverplanning() {
        let entry = DailyEntry(date: Date(), energy: 1, mood: 1, sleepQuality: 1)
        let snapshot = PatternSnapshot(
            generatedAt: Date(),
            windowEnd: Date(),
            windowDays: 7,
            completionRate: CompletionRatePattern(doneCount: 2, totalCount: 9, deferredCount: 3, droppedCount: 0),
            carryForward: nil,
            domainBalance: nil,
            readinessOutcome: ReadinessOutcomePattern(
                lowReadinessAvgCompletion: 0.2,
                highReadinessAvgCompletion: 0.8,
                overplanningOnLowDays: true,
                sampleCount: 5
            )
        )
        let cal = CalibrationRules.calibrate(todayEntry: entry, weeklySnapshot: snapshot)
        // Base nudge for all-low is 1, overplanning doesn't reduce below 1
        XCTAssertEqual(cal.suggestedFocusLoad, 1)
    }

    func testFocusLoadWithoutReadinessOutcome() {
        let entry = DailyEntry(date: Date(), energy: 2, mood: 2, sleepQuality: 4)
        let snapshot = PatternSnapshot(
            generatedAt: Date(),
            windowEnd: Date(),
            windowDays: 7,
            completionRate: CompletionRatePattern(doneCount: 5, totalCount: 10, deferredCount: 0, droppedCount: 0),
            carryForward: nil,
            domainBalance: nil,
            readinessOutcome: nil
        )
        let cal = CalibrationRules.calibrate(todayEntry: entry, weeklySnapshot: snapshot)
        // Falls back to base nudge suggestion
        XCTAssertEqual(cal.suggestedFocusLoad, 2)
    }
}
