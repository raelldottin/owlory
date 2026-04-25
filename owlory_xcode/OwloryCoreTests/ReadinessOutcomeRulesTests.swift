import XCTest
#if SWIFT_PACKAGE
@testable import OwloryCore
#endif

final class ReadinessOutcomeRulesTests: XCTestCase {

    func testPairsLowAndHighReadinessWithCompletionRates() {
        let lowDay = makeEntry(
            statuses: [.done, .planned, .planned],
            energy: 1,
            mood: 2,
            sleepQuality: 1
        )
        let highDay = makeEntry(
            statuses: [.done, .done],
            energy: 4,
            mood: 5,
            sleepQuality: 4
        )

        let result = ReadinessOutcomeRules.pattern(from: [lowDay, highDay])

        XCTAssertEqual(result.sampleCount, 2)
        XCTAssertEqual(result.lowReadinessAvgCompletion, 0.33)
        XCTAssertEqual(result.highReadinessAvgCompletion, 1.0)
        XCTAssertFalse(result.overplanningOnLowDays)
    }

    func testMissingReadinessAndMissingOutcomeEntriesAreIgnored() {
        let noCheckIn = makeEntry(
            statuses: [.done],
            energy: 0,
            mood: 0,
            sleepQuality: 0
        )
        let noFocusItems = DailyEntry(
            date: Date(),
            focusThree: [],
            energy: 5,
            mood: 5,
            sleepQuality: 5
        )

        let result = ReadinessOutcomeRules.pattern(from: [noCheckIn, noFocusItems])

        XCTAssertEqual(result.sampleCount, 0)
        XCTAssertEqual(result.lowReadinessAvgCompletion, 0)
        XCTAssertEqual(result.highReadinessAvgCompletion, 0)
    }

    func testMiddleReadinessDoesNotBecomeOutcomeSample() {
        let middleDay = makeEntry(
            statuses: [.done, .done, .done],
            energy: 3,
            mood: 3,
            sleepQuality: 3
        )

        let result = ReadinessOutcomeRules.pattern(from: [middleDay])

        XCTAssertEqual(result.sampleCount, 0)
        XCTAssertEqual(ReadinessOutcomeRules.samples(from: [middleDay]), [])
    }

    func testReadinessBandBoundariesAreExplicit() {
        XCTAssertEqual(
            ReadinessOutcomeRules.readinessBand(energy: 2, mood: 2, sleepQuality: 2),
            .low
        )
        XCTAssertEqual(
            ReadinessOutcomeRules.readinessBand(energy: 4, mood: 4, sleepQuality: 4),
            .high
        )
        XCTAssertEqual(
            ReadinessOutcomeRules.readinessBand(energy: 3, mood: 3, sleepQuality: 3),
            .middle
        )
        XCTAssertEqual(
            ReadinessOutcomeRules.readinessBand(energy: 0, mood: 0, sleepQuality: 0),
            .missing
        )
    }

    func testOverplanningRequiresStrictMajorityOfLowReadinessSamples() {
        let overplanned = makeEntry(
            statuses: [.planned, .planned, .dropped],
            energy: 1,
            mood: 1,
            sleepQuality: 2
        )
        let notOverplanned = makeEntry(
            statuses: [.done, .done, .planned],
            energy: 2,
            mood: 1,
            sleepQuality: 1
        )

        let splitResult = ReadinessOutcomeRules.pattern(from: [overplanned, notOverplanned])
        XCTAssertFalse(splitResult.overplanningOnLowDays)

        let majorityResult = ReadinessOutcomeRules.pattern(from: [
            overplanned,
            overplanned,
            notOverplanned,
        ])
        XCTAssertTrue(majorityResult.overplanningOnLowDays)
    }

    func testOnlyDoneStatusCountsAsCompletedOutcome() {
        let lowDay = makeEntry(
            statuses: [.done, .deferred, .dropped, .planned],
            energy: 1,
            mood: 1,
            sleepQuality: 2
        )

        let result = ReadinessOutcomeRules.pattern(from: [lowDay])

        XCTAssertEqual(result.sampleCount, 1)
        XCTAssertEqual(result.lowReadinessAvgCompletion, 0.25)
    }

    func testSnapshotPatternRequiresMinimumOutcomeSamples() {
        let twoSamples = [
            makeEntry(statuses: [.done], energy: 4, mood: 4, sleepQuality: 4),
            makeEntry(statuses: [.done], energy: 4, mood: 4, sleepQuality: 4),
        ]
        let threeSamples = twoSamples + [
            makeEntry(statuses: [.done], energy: 4, mood: 4, sleepQuality: 4),
        ]

        XCTAssertNil(ReadinessOutcomeRules.snapshotPattern(from: twoSamples))
        XCTAssertNotNil(ReadinessOutcomeRules.snapshotPattern(from: threeSamples))
    }

    private func makeEntry(
        statuses: [FocusItemStatus],
        energy: Int,
        mood: Int,
        sleepQuality: Int
    ) -> DailyEntry {
        DailyEntry(
            date: Date(),
            focusThree: statuses.map { status in
                FocusItem(title: "Focus \(status)", domain: .home, status: status)
            },
            energy: energy,
            mood: mood,
            sleepQuality: sleepQuality
        )
    }
}
