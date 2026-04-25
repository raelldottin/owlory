import XCTest
#if SWIFT_PACKAGE
@testable import OwloryCore
#endif

final class ContinuePipelineTraceTests: XCTestCase {
    private let now = ISO8601DateFormatter().date(from: "2026-04-08T16:00:00Z")!

    func testDeriveWithTraceCapturesContinuePipelineDiagnostics() {
        let result = tracedScenario()
        let trace = result.trace

        XCTAssertEqual(
            trace.sourceCounts.map { "\($0.step.rawValue):\($0.count)" },
            [
                "dueTodayTraining:3",
                "carriedForwardFocus:1",
                "activeHomeProtocolRun:0",
                "activeHomeTask:1",
                "inProgressWriting:1",
            ]
        )
        XCTAssertEqual(trace.inputCandidateCount, 6)
        XCTAssertEqual(trace.admission.admittedCount, 5)
        XCTAssertEqual(trace.admission.rejectedCount, 1)
        XCTAssertEqual(trace.admission.emptyTitleRejectedCount, 0)
        XCTAssertEqual(trace.admission.totalLimitRejectedCount, 0)
        XCTAssertEqual(trace.admission.domainLimitRejectedCount, 1)
        XCTAssertEqual(trace.admission.cappedOutCount, 1)
        XCTAssertEqual(trace.finalItemCount, 5)
    }

    func testTraceIdentifiesUrgencyScoredItemsAndRankingChanges() {
        let result = tracedScenario()
        let trace = result.trace
        let laundry = result.items.first { $0.title == "Laundry" }

        XCTAssertEqual(trace.urgencyScoredItemIDs, [laundry?.id].compactMap { $0 })
        XCTAssertEqual(trace.urgencyScoredItemCount, 1)
        XCTAssertTrue(trace.rankingChanged)
        XCTAssertEqual(trace.rankedItemIDs, result.items.map(\.id))
        XCTAssertEqual(result.items.first?.title, "Laundry")
    }

    func testTelemetryMessageUsesStableContinuePipelineMetadata() {
        let trace = tracedScenario().trace

        XCTAssertEqual(
            trace.telemetryMessage,
            "continue.pipeline sourceCounts=dueTodayTraining:3,carriedForwardFocus:1,activeHomeProtocolRun:0,activeHomeTask:1,inProgressWriting:1 candidates=6 admitted=5 rejected=1 emptyTitleRejected=0 totalCapRejected=0 domainCapRejected=1 urgencyScored=1 rankingChanged=true emitted=5"
        )
    }

    func testDeriveReturnsSameItemsAsDeriveWithTrace() {
        let scenario = makeScenario()

        let traced = TodayContinuationRules.deriveWithTrace(
            todayEntry: scenario.entry,
            calibration: scenario.calibration,
            todaySessions: scenario.sessions,
            homeTasks: scenario.homeTasks,
            homeRuns: [],
            writingNotes: scenario.notes,
            predictions: scenario.predictions,
            now: now
        )
        let plain = TodayContinuationRules.derive(
            todayEntry: scenario.entry,
            calibration: scenario.calibration,
            todaySessions: scenario.sessions,
            homeTasks: scenario.homeTasks,
            homeRuns: [],
            writingNotes: scenario.notes,
            predictions: scenario.predictions,
            now: now
        )

        XCTAssertEqual(plain, traced.items)
    }

    private func tracedScenario() -> TodayContinuationRules.DerivationResult {
        let scenario = makeScenario()
        return TodayContinuationRules.deriveWithTrace(
            todayEntry: scenario.entry,
            calibration: scenario.calibration,
            todaySessions: scenario.sessions,
            homeTasks: scenario.homeTasks,
            homeRuns: [],
            writingNotes: scenario.notes,
            predictions: scenario.predictions,
            now: now
        )
    }

    private func makeScenario() -> Scenario {
        let carried = FocusItem(
            id: stableID("11111111-1111-1111-1111-111111111111"),
            title: "Performance review story",
            domain: .career,
            status: .planned
        )
        let entry = DailyEntry(date: now, focusThree: [carried])
        let snapshot = PatternSnapshot(
            generatedAt: now,
            windowEnd: now,
            windowDays: 7,
            completionRate: CompletionRatePattern(
                doneCount: 2,
                totalCount: 6,
                deferredCount: 1,
                droppedCount: 0
            ),
            carryForward: CarryForwardPattern(
                averageCarriedPerDay: 1,
                stalledItems: [
                    .init(
                        title: "Performance review story",
                        domain: .career,
                        consecutiveDays: 3
                    )
                ]
            )
        )
        let laundryKey = CompletionTimePredictor.key(forHomeTask: "Laundry")

        return Scenario(
            entry: entry,
            calibration: CalibrationRules.calibrate(
                todayEntry: entry,
                weeklySnapshot: snapshot
            ),
            sessions: [
                TrainingSession(date: now, plannedActivity: "Run", status: .planned),
                TrainingSession(date: now, plannedActivity: "Lift", status: .planned),
                TrainingSession(date: now, plannedActivity: "Mobility", status: .planned),
            ],
            homeTasks: [
                HomeTask(title: "Laundry"),
            ],
            notes: [
                WritingNote(title: "Draft idea", body: "", stage: .draft),
            ],
            predictions: [
                laundryKey: CompletionTimePredictor.Prediction(
                    itemKey: laundryKey,
                    medianTimeOfDay: 10 * 60 * 60,
                    madSeconds: 60 * 60,
                    sampleCount: 4
                ),
            ]
        )
    }

    private func stableID(_ value: String) -> UUID {
        UUID(uuidString: value)!
    }

    private struct Scenario {
        let entry: DailyEntry
        let calibration: CalibrationRules.Calibration
        let sessions: [TrainingSession]
        let homeTasks: [HomeTask]
        let notes: [WritingNote]
        let predictions: [String: CompletionTimePredictor.Prediction]
    }
}
