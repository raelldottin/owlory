import XCTest
#if SWIFT_PACKAGE
@testable import OwloryCore
#endif

final class DuskModeRulesTests: XCTestCase {
    func testActiveAtActivationHour() {
        XCTAssertTrue(DuskModeRules.isActive(at: time(18, 0), calendar: calendar))
    }

    func testInactiveJustBeforeActivation() {
        XCTAssertFalse(DuskModeRules.isActive(at: time(17, 59), calendar: calendar))
    }

    func testActiveAtMidnight() {
        XCTAssertTrue(DuskModeRules.isActive(at: time(0, 0), calendar: calendar))
    }

    func testActiveJustBeforeDeactivation() {
        XCTAssertTrue(DuskModeRules.isActive(at: time(4, 59), calendar: calendar))
    }

    func testInactiveAtDeactivationHour() {
        XCTAssertFalse(DuskModeRules.isActive(at: time(5, 0), calendar: calendar))
    }

    func testInactiveAtMidday() {
        XCTAssertFalse(DuskModeRules.isActive(at: time(12, 0), calendar: calendar))
    }

    func testCustomActivationHours() {
        let early = time(20, 0)
        XCTAssertFalse(
            DuskModeRules.isActive(
                at: early,
                calendar: calendar,
                activationHour: 21,
                deactivationHour: 5
            )
        )
        XCTAssertTrue(
            DuskModeRules.isActive(
                at: time(21, 0),
                calendar: calendar,
                activationHour: 21,
                deactivationHour: 5
            )
        )
    }

    // MARK: - Helpers

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    private func time(_ hour: Int, _ minute: Int) -> Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 5
        components.day = 29
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)!
    }
}
