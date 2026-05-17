import XCTest
#if SWIFT_PACKAGE
@testable import OwloryCore
#endif

final class TrainingConsistencyTests: XCTestCase {

    // MARK: - TrainingConsistencyPattern

    func testEmptySessionsReturnsZeros() {
        let result = PatternEngine.computeTrainingConsistency(sessions: [])
        XCTAssertEqual(result.sessionsPlanned, 0)
        XCTAssertEqual(result.sessionsCompleted, 0)
        XCTAssertEqual(result.sessionsModified, 0)
        XCTAssertEqual(result.sessionsSkipped, 0)
        XCTAssertEqual(result.completionRate, 0)
    }

    func testAllCompletedReturns100Percent() {
        let sessions = [
            makeSession(status: .completed),
            makeSession(status: .completed),
            makeSession(status: .completed),
        ]
        let result = PatternEngine.computeTrainingConsistency(sessions: sessions)
        XCTAssertEqual(result.sessionsCompleted, 3)
        XCTAssertEqual(result.completionRate, 1.0)
    }

    func testModifiedCountsAsCompleted() {
        let sessions = [
            makeSession(status: .completed),
            makeSession(status: .modified),
            makeSession(status: .skipped),
            makeSession(status: .planned),
        ]
        let result = PatternEngine.computeTrainingConsistency(sessions: sessions)
        XCTAssertEqual(result.sessionsCompleted, 1)
        XCTAssertEqual(result.sessionsModified, 1)
        XCTAssertEqual(result.sessionsSkipped, 1)
        XCTAssertEqual(result.sessionsPlanned, 1)
        // completionRate = (completed + modified) / total = 2/4 = 0.5
        XCTAssertEqual(result.completionRate, 0.5)
    }

    func testSnapshotIncludesTrainingConsistencyWithSessions() {
        let sessions = [makeSession(status: .completed)]
        let snapshot = PatternEngine.computeSnapshot(
            entries: [],
            windowEnd: Date(),
            windowDays: 7,
            generatedAt: Date(),
            trainingSessions: sessions
        )
        XCTAssertNotNil(snapshot.trainingConsistency)
    }

    func testSnapshotExcludesTrainingConsistencyWithNoSessions() {
        let snapshot = PatternEngine.computeSnapshot(
            entries: [],
            windowEnd: Date(),
            windowDays: 7,
            generatedAt: Date(),
            trainingSessions: []
        )
        XCTAssertNil(snapshot.trainingConsistency)
    }

    // MARK: - CalibrationRules Training Summary

    func testTrainingSummaryWithHighCompletion() throws {
        let entry = DailyEntry(date: Date(), energy: 3, mood: 3, sleepQuality: 3)
        let snapshot = PatternSnapshot(
            generatedAt: Date(),
            windowEnd: Date(),
            windowDays: 7,
            completionRate: CompletionRatePattern(doneCount: 3, totalCount: 5, deferredCount: 0, droppedCount: 0),
            trainingConsistency: TrainingConsistencyPattern(
                sessionsPlanned: 0, sessionsCompleted: 4, sessionsModified: 1, sessionsSkipped: 0
            )
        )
        let cal = CalibrationRules.calibrate(todayEntry: entry, weeklySnapshot: snapshot)
        let summary = try XCTUnwrap(cal.trainingSummary)
        XCTAssertEqual(summary.band, .strong)
        XCTAssertEqual(summary.completionRate, 1.0)
        XCTAssertEqual(summary.completionPercent, 100)
    }

    func testTrainingSummaryWithMidCompletion() throws {
        let entry = DailyEntry(date: Date(), energy: 3, mood: 3, sleepQuality: 3)
        let snapshot = PatternSnapshot(
            generatedAt: Date(),
            windowEnd: Date(),
            windowDays: 7,
            completionRate: CompletionRatePattern(doneCount: 3, totalCount: 5, deferredCount: 0, droppedCount: 0),
            trainingConsistency: TrainingConsistencyPattern(
                sessionsPlanned: 1, sessionsCompleted: 1, sessionsModified: 1, sessionsSkipped: 1
            )
        )
        let cal = CalibrationRules.calibrate(todayEntry: entry, weeklySnapshot: snapshot)
        let summary = try XCTUnwrap(cal.trainingSummary)
        XCTAssertEqual(summary.band, .solid)
        XCTAssertEqual(summary.completionRate, 0.5)
        XCTAssertEqual(summary.completionPercent, 50)
    }

    func testTrainingSummaryWithLowCompletion() throws {
        let entry = DailyEntry(date: Date(), energy: 3, mood: 3, sleepQuality: 3)
        let snapshot = PatternSnapshot(
            generatedAt: Date(),
            windowEnd: Date(),
            windowDays: 7,
            completionRate: CompletionRatePattern(doneCount: 1, totalCount: 5, deferredCount: 0, droppedCount: 0),
            trainingConsistency: TrainingConsistencyPattern(
                sessionsPlanned: 1, sessionsCompleted: 1, sessionsModified: 0, sessionsSkipped: 3
            )
        )
        let cal = CalibrationRules.calibrate(todayEntry: entry, weeklySnapshot: snapshot)
        let summary = try XCTUnwrap(cal.trainingSummary)
        XCTAssertEqual(summary.band, .low)
        XCTAssertEqual(summary.completionRate, 0.2, accuracy: 0.0001)
        XCTAssertEqual(summary.completionPercent, 20)
    }

    func testTrainingSummaryNilWithFewSessions() {
        let entry = DailyEntry(date: Date(), energy: 3, mood: 3, sleepQuality: 3)
        let snapshot = PatternSnapshot(
            generatedAt: Date(),
            windowEnd: Date(),
            windowDays: 7,
            completionRate: CompletionRatePattern(doneCount: 1, totalCount: 2, deferredCount: 0, droppedCount: 0),
            trainingConsistency: TrainingConsistencyPattern(
                sessionsPlanned: 1, sessionsCompleted: 1, sessionsModified: 0, sessionsSkipped: 0
            )
        )
        let cal = CalibrationRules.calibrate(todayEntry: entry, weeklySnapshot: snapshot)
        XCTAssertNil(cal.trainingSummary) // only 2 sessions, need 3+
    }

    // MARK: - CalibrationRules Writing Pipeline Nudge

    func testWritingNudgeFires() throws {
        let entry = DailyEntry(date: Date(), energy: 3, mood: 3, sleepQuality: 3)
        let snapshot = PatternSnapshot(
            generatedAt: Date(),
            windowEnd: Date(),
            windowDays: 7,
            completionRate: CompletionRatePattern(doneCount: 3, totalCount: 5, deferredCount: 0, droppedCount: 0),
            writingVelocity: WritingVelocityPattern(
                stageDistribution: [.capture: 12],
                bottleneckStage: .capture,
                captureToSourceAvgDays: nil
            )
        )
        let cal = CalibrationRules.calibrate(todayEntry: entry, weeklySnapshot: snapshot)
        let nudge = try XCTUnwrap(cal.writingNudge)
        XCTAssertEqual(nudge.kind, .captureBacklog)
        XCTAssertEqual(nudge.captureCount, 12)
        XCTAssertEqual(nudge.bottleneckStage, .capture)
    }

    func testWritingNudgeDoesNotFireUnder10Captures() {
        let entry = DailyEntry(date: Date(), energy: 3, mood: 3, sleepQuality: 3)
        let snapshot = PatternSnapshot(
            generatedAt: Date(),
            windowEnd: Date(),
            windowDays: 7,
            completionRate: CompletionRatePattern(doneCount: 3, totalCount: 5, deferredCount: 0, droppedCount: 0),
            writingVelocity: WritingVelocityPattern(
                stageDistribution: [.capture: 8],
                bottleneckStage: .capture,
                captureToSourceAvgDays: nil
            )
        )
        let cal = CalibrationRules.calibrate(todayEntry: entry, weeklySnapshot: snapshot)
        XCTAssertNil(cal.writingNudge)
    }

    // MARK: - Helpers

    private func makeSession(status: TrainingStatus) -> TrainingSession {
        TrainingSession(date: Date(), plannedActivity: "Test", status: status)
    }
}
