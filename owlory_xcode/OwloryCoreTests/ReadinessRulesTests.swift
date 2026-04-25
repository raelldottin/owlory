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
        XCTAssertEqual(nudge?.suggestedMaxPriorities, 1)
        XCTAssertTrue(nudge?.message.contains("Tough") == true)
    }

    func testTwoLowReturnsLowReserves() {
        let nudge = ReadinessRules.nudge(energy: 2, mood: 1, sleepQuality: 4)
        XCTAssertNotNil(nudge)
        XCTAssertEqual(nudge?.suggestedMaxPriorities, 2)
        XCTAssertTrue(nudge?.message.contains("Low reserves") == true)
    }

    func testLowEnergySingleReturnsEasyWins() {
        let nudge = ReadinessRules.nudge(energy: 2, mood: 4, sleepQuality: 4)
        XCTAssertNotNil(nudge)
        XCTAssertEqual(nudge?.suggestedMaxPriorities, 2)
        XCTAssertTrue(nudge?.message.contains("Low energy") == true)
    }

    func testPoorSleepSingleReturnsFocusWarning() {
        let nudge = ReadinessRules.nudge(energy: 4, mood: 4, sleepQuality: 1)
        XCTAssertNotNil(nudge)
        XCTAssertEqual(nudge?.suggestedMaxPriorities, 2)
        XCTAssertTrue(nudge?.message.contains("Sleep") == true)
    }

    func testRoughMoodSingleReturnsHonesty() {
        let nudge = ReadinessRules.nudge(energy: 4, mood: 2, sleepQuality: 4)
        XCTAssertNotNil(nudge)
        XCTAssertEqual(nudge?.suggestedMaxPriorities, 2)
        XCTAssertTrue(nudge?.message.contains("mood") == true)
    }

    func testAllHighReturnsStrongSignals() {
        let nudge = ReadinessRules.nudge(energy: 5, mood: 4, sleepQuality: 5)
        XCTAssertNotNil(nudge)
        XCTAssertEqual(nudge?.suggestedMaxPriorities, 3)
        XCTAssertTrue(nudge?.message.contains("Strong") == true)
    }

    func testTwoHighReturnsSolidDay() {
        let nudge = ReadinessRules.nudge(energy: 4, mood: 3, sleepQuality: 5)
        XCTAssertNotNil(nudge)
        XCTAssertEqual(nudge?.suggestedMaxPriorities, 3)
        XCTAssertTrue(nudge?.message.contains("Solid") == true)
    }

    func testAllModerateReturnsSteadyDay() {
        let nudge = ReadinessRules.nudge(energy: 3, mood: 3, sleepQuality: 3)
        XCTAssertNotNil(nudge)
        XCTAssertEqual(nudge?.suggestedMaxPriorities, 3)
        XCTAssertTrue(nudge?.message.contains("Steady") == true)
    }
}
