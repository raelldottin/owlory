import XCTest
#if SWIFT_PACKAGE
@testable import OwloryCore
#endif

final class WritingVelocityTests: XCTestCase {

    // MARK: - WritingVelocityPattern

    func testEmptyNotesReturnsEmptyDistribution() {
        let result = PatternEngine.computeWritingVelocity(notes: [])
        XCTAssertTrue(result.stageDistribution.isEmpty)
        XCTAssertNil(result.bottleneckStage)
        XCTAssertNil(result.captureToSourceAvgDays)
    }

    func testStageDistributionCountsCorrectly() {
        let notes = [
            makeNote(stage: .capture),
            makeNote(stage: .capture),
            makeNote(stage: .capture),
            makeNote(stage: .source),
            makeNote(stage: .draft),
        ]
        let result = PatternEngine.computeWritingVelocity(notes: notes)
        XCTAssertEqual(result.stageDistribution[.capture], 3)
        XCTAssertEqual(result.stageDistribution[.source], 1)
        XCTAssertEqual(result.stageDistribution[.draft], 1)
        XCTAssertNil(result.stageDistribution[.published])
    }

    func testBottleneckIsStageWithMostNotes() {
        let notes = [
            makeNote(stage: .capture),
            makeNote(stage: .source),
            makeNote(stage: .source),
            makeNote(stage: .source),
            makeNote(stage: .draft),
        ]
        let result = PatternEngine.computeWritingVelocity(notes: notes)
        XCTAssertEqual(result.bottleneckStage, .source)
    }

    func testBottleneckExcludesTerminalStages() {
        let notes = [
            makeNote(stage: .published),
            makeNote(stage: .published),
            makeNote(stage: .published),
            makeNote(stage: .capture),
        ]
        let result = PatternEngine.computeWritingVelocity(notes: notes)
        XCTAssertEqual(result.bottleneckStage, .capture)
    }

    func testCaptureToSourceAvgDaysComputed() {
        let now = Date()
        let tenDaysAgo = Calendar.current.date(byAdding: .day, value: -10, to: now)!
        let notes = [
            makeNote(stage: .capture, createdDate: tenDaysAgo),
            makeNote(stage: .source, createdDate: now),
        ]
        let result = PatternEngine.computeWritingVelocity(notes: notes)
        XCTAssertNotNil(result.captureToSourceAvgDays)
        XCTAssertTrue(result.captureToSourceAvgDays! > 0)
    }

    func testSnapshotIncludesWritingVelocityWithEnoughNotes() {
        let notes = [
            makeNote(stage: .capture),
            makeNote(stage: .capture),
            makeNote(stage: .source),
        ]
        let snapshot = PatternEngine.computeSnapshot(
            entries: [],
            windowEnd: Date(),
            windowDays: 7,
            generatedAt: Date(),
            writingNotes: notes
        )
        XCTAssertNotNil(snapshot.writingVelocity)
    }

    func testSnapshotExcludesWritingVelocityWithFewNotes() {
        let notes = [makeNote(stage: .capture), makeNote(stage: .source)]
        let snapshot = PatternEngine.computeSnapshot(
            entries: [],
            windowEnd: Date(),
            windowDays: 7,
            generatedAt: Date(),
            writingNotes: notes
        )
        XCTAssertNil(snapshot.writingVelocity)
    }

    // MARK: - Helpers

    private func makeNote(stage: WritingStage, createdDate: Date = Date()) -> WritingNote {
        WritingNote(title: "Test", body: "", stage: stage, createdDate: createdDate)
    }
}
