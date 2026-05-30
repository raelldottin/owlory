import XCTest
#if SWIFT_PACKAGE
@testable import OwloryCore
#endif

final class SolarSunsetTests: XCTestCase {
    func testEquatorEquinoxSunsetIsAroundEighteenUTC() throws {
        // Vernal equinox 2026-03-21 at the equator, longitude 0.
        // Expected: sunset ≈ 18:00 UTC ± 30 minutes.
        let date = utcDate(year: 2026, month: 3, day: 21)
        let sunset = try XCTUnwrap(SolarSunset.localSunset(date: date, latitude: 0, longitude: 0))
        let utcHour = utcCalendar.component(.hour, from: sunset)
        XCTAssertGreaterThanOrEqual(utcHour, 17)
        XCTAssertLessThanOrEqual(utcHour, 18)
    }

    func testEquatorEquinoxSunriseIsAroundSixUTC() throws {
        let date = utcDate(year: 2026, month: 3, day: 21)
        let sunrise = try XCTUnwrap(SolarSunset.localSunrise(date: date, latitude: 0, longitude: 0))
        let utcHour = utcCalendar.component(.hour, from: sunrise)
        XCTAssertGreaterThanOrEqual(utcHour, 5)
        XCTAssertLessThanOrEqual(utcHour, 6)
    }

    func testNewYorkSummerSolsticeSunsetIsLateEvening() throws {
        // NYC summer solstice 2026-06-21, latitude 40.71, longitude -74.
        // Expected: sunset around 00:23 UTC the following day
        // (≈ 20:23 EDT). Allow a half-hour window for algorithmic drift.
        let date = utcDate(year: 2026, month: 6, day: 21)
        let sunset = try XCTUnwrap(
            SolarSunset.localSunset(date: date, latitude: 40.71, longitude: -74.0)
        )
        let interval = sunset.timeIntervalSince(date) / 3600.0
        XCTAssertGreaterThan(interval, 23.5, "Sunset should land in the late evening UTC.")
        XCTAssertLessThan(interval, 25.0)
    }

    func testNewYorkWinterSolsticeSunsetIsEarlyEvening() throws {
        // NYC winter solstice 2026-12-21. Expected: sunset around 21:33 UTC
        // (≈ 16:33 EST).
        let date = utcDate(year: 2026, month: 12, day: 21)
        let sunset = try XCTUnwrap(
            SolarSunset.localSunset(date: date, latitude: 40.71, longitude: -74.0)
        )
        let interval = sunset.timeIntervalSince(date) / 3600.0
        XCTAssertGreaterThan(interval, 21.0)
        XCTAssertLessThan(interval, 22.5)
    }

    func testPolarLatitudeSolsticeReturnsNil() {
        // North Pole on summer solstice: sun never sets → polar day → nil.
        let date = utcDate(year: 2026, month: 6, day: 21)
        XCTAssertNil(SolarSunset.localSunset(date: date, latitude: 89.0, longitude: 0))
    }

    func testSouthernHemisphereSummerSolsticeSunsetIsLate() throws {
        // Sydney (-33.87) on December solstice 2026-12-21 is summer there.
        // Expected: sunset around 09:05 UTC (≈ 20:05 AEDT).
        let date = utcDate(year: 2026, month: 12, day: 21)
        let sunset = try XCTUnwrap(
            SolarSunset.localSunset(date: date, latitude: -33.87, longitude: 151.21)
        )
        let interval = sunset.timeIntervalSince(date) / 3600.0
        XCTAssertGreaterThan(interval, 8.0)
        XCTAssertLessThan(interval, 10.0)
    }

    // MARK: - Helpers

    private var utcCalendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    private func utcDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 0
        components.minute = 0
        return utcCalendar.date(from: components)!
    }
}
