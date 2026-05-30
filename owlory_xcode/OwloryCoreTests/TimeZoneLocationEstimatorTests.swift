import XCTest
#if SWIFT_PACKAGE
@testable import OwloryCore
#endif

final class TimeZoneLocationEstimatorTests: XCTestCase {
    func testKnownNorthernCityReturnsLookupCoordinates() {
        let nyc = TimeZone(identifier: "America/New_York")!
        let coords = TimeZoneLocationEstimator.estimate(for: nyc)
        XCTAssertEqual(coords.latitude, 40.71, accuracy: 0.5)
        XCTAssertEqual(coords.longitude, -74.0, accuracy: 0.5)
    }

    func testKnownSouthernCityReturnsNegativeLatitude() {
        let sydney = TimeZone(identifier: "Australia/Sydney")!
        let coords = TimeZoneLocationEstimator.estimate(for: sydney)
        XCTAssertLessThan(coords.latitude, 0)
        XCTAssertGreaterThan(coords.longitude, 140)
    }

    func testUnknownTimezoneFallsBackUsingGMTOffset() {
        let utc = TimeZone(identifier: "Etc/GMT")!
        let coords = TimeZoneLocationEstimator.estimate(for: utc)
        XCTAssertEqual(coords.longitude, 0, accuracy: 0.001)
        XCTAssertEqual(coords.latitude, 40, accuracy: 0.001)
    }

    func testSouthernHemispherePrefixDefaultsLatitudeNegative() {
        // Use an unmapped southern-hemisphere identifier to confirm the
        // prefix-based hemisphere detection fires before the latitude
        // default.
        if let tz = TimeZone(identifier: "Antarctica/Vostok") {
            let coords = TimeZoneLocationEstimator.estimate(for: tz)
            XCTAssertLessThan(coords.latitude, 0)
        }
    }
}
