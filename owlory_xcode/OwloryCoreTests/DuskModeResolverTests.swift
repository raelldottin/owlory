import XCTest
#if SWIFT_PACKAGE
@testable import OwloryCore
#endif

final class DuskModeResolverTests: XCTestCase {
    func testAutoDefersToTimeRuleAtNight() {
        XCTAssertTrue(
            DuskModeResolver.isActive(preference: .auto, at: time(20, 0), calendar: calendar)
        )
    }

    func testAutoDefersToTimeRuleAtNoon() {
        XCTAssertFalse(
            DuskModeResolver.isActive(preference: .auto, at: time(12, 0), calendar: calendar)
        )
    }

    func testOnForcesActiveAtNoon() {
        XCTAssertTrue(
            DuskModeResolver.isActive(preference: .on, at: time(12, 0), calendar: calendar)
        )
    }

    func testOffForcesInactiveAtMidnight() {
        XCTAssertFalse(
            DuskModeResolver.isActive(preference: .off, at: time(0, 0), calendar: calendar)
        )
    }

    func testPreferenceRoundTripsThroughRawValue() {
        for value in DuskModePreference.allCases {
            XCTAssertEqual(DuskModePreference(rawValue: value.rawValue), value)
        }
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
