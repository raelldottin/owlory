import XCTest
#if SWIFT_PACKAGE
@testable import OwloryCore
#endif

final class ReadinessRulesTests: XCTestCase {

    func testAllZerosReturnsNil() {
        XCTAssertNil(ReadinessRules.nudge(energy: 0, mood: 0, sleepQuality: 0))
    }

    func testAllLowReturnsToughSignals() {
        let nudge = ReadinessRules.nudge(energy: 1, mood: 2, sleepQuality: 1)
        XCTAssertNotNil(nudge)
        XCTAssertEqual(nudge?.kind, .toughSignals)
        XCTAssertEqual(nudge?.suggestedMaxPriorities, 1)
    }

    func testTwoLowReturnsLowReserves() {
        let nudge = ReadinessRules.nudge(energy: 2, mood: 1, sleepQuality: 4)
        XCTAssertNotNil(nudge)
        XCTAssertEqual(nudge?.kind, .lowReserves)
        XCTAssertEqual(nudge?.suggestedMaxPriorities, 2)
    }

    func testLowEnergySingleReturnsEasyWins() {
        let nudge = ReadinessRules.nudge(energy: 2, mood: 4, sleepQuality: 4)
        XCTAssertNotNil(nudge)
        XCTAssertEqual(nudge?.kind, .lowEnergy)
        XCTAssertEqual(nudge?.suggestedMaxPriorities, 2)
    }

    func testPoorSleepSingleReturnsFocusWarning() {
        let nudge = ReadinessRules.nudge(energy: 4, mood: 4, sleepQuality: 1)
        XCTAssertNotNil(nudge)
        XCTAssertEqual(nudge?.kind, .sleepWasRough)
        XCTAssertEqual(nudge?.suggestedMaxPriorities, 2)
    }

    func testRoughMoodSingleReturnsHonesty() {
        let nudge = ReadinessRules.nudge(energy: 4, mood: 2, sleepQuality: 4)
        XCTAssertNotNil(nudge)
        XCTAssertEqual(nudge?.kind, .roughMood)
        XCTAssertEqual(nudge?.suggestedMaxPriorities, 2)
    }

    func testAllHighReturnsStrongSignals() {
        let nudge = ReadinessRules.nudge(energy: 5, mood: 4, sleepQuality: 5)
        XCTAssertNotNil(nudge)
        XCTAssertEqual(nudge?.kind, .strongSignals)
        XCTAssertEqual(nudge?.suggestedMaxPriorities, 3)
    }

    func testTwoHighReturnsSolidDay() {
        let nudge = ReadinessRules.nudge(energy: 4, mood: 3, sleepQuality: 5)
        XCTAssertNotNil(nudge)
        XCTAssertEqual(nudge?.kind, .solidDay)
        XCTAssertEqual(nudge?.suggestedMaxPriorities, 3)
    }

    func testAllModerateReturnsSteadyDay() {
        let nudge = ReadinessRules.nudge(energy: 3, mood: 3, sleepQuality: 3)
        XCTAssertNotNil(nudge)
        XCTAssertEqual(nudge?.kind, .steadyDay)
        XCTAssertEqual(nudge?.suggestedMaxPriorities, 3)
    }

    func testSlightlyAboveAverageReturnsDecentDay() {
        let nudge = ReadinessRules.nudge(energy: 3, mood: 3, sleepQuality: 5)
        XCTAssertNotNil(nudge)
        XCTAssertEqual(nudge?.kind, .decentDay)
        XCTAssertEqual(nudge?.suggestedMaxPriorities, 3)
    }
}
