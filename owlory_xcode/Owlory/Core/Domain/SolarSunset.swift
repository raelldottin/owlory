import Foundation

/// Astronomical sunrise/sunset calculator using the NOAA simplified formulae.
/// Pure rule — no I/O, no APIs. Accuracy is roughly ±5 minutes for most
/// inhabited latitudes; results are not suitable for navigation or
/// religious-observance timing, but are sufficient for ambient UI.
enum SolarSunset {
    /// Returns the local sunset moment for the supplied calendar date.
    /// Returns `nil` during polar day or polar night where no transition
    /// occurs — callers should fall back to a fixed-hour rule in that case.
    static func localSunset(
        date: Date,
        latitude: Double,
        longitude: Double
    ) -> Date? {
        transition(date: date, latitude: latitude, longitude: longitude, isSunrise: false)
    }

    /// Returns the local sunrise moment for the supplied calendar date.
    /// Returns `nil` during polar day or polar night.
    static func localSunrise(
        date: Date,
        latitude: Double,
        longitude: Double
    ) -> Date? {
        transition(date: date, latitude: latitude, longitude: longitude, isSunrise: true)
    }

    private static func transition(
        date: Date,
        latitude: Double,
        longitude: Double,
        isSunrise: Bool
    ) -> Date? {
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!
        guard let dayOfYear = utcCalendar.ordinality(of: .day, in: .year, for: date) else {
            return nil
        }

        let n = Double(dayOfYear)
        let declinationDegrees = 23.45 * sin((360.0 / 365.0) * (284.0 + n) * .pi / 180.0)
        let latRad = latitude * .pi / 180.0
        let declRad = declinationDegrees * .pi / 180.0

        let cosH = -tan(latRad) * tan(declRad)
        guard cosH >= -1, cosH <= 1 else { return nil } // polar night/day

        let hourAngleDegrees = acos(cosH) * 180.0 / .pi
        let halfDayHours = hourAngleDegrees / 15.0

        let solarNoonUTCHour = 12.0 - (longitude / 15.0)
        let transitionUTCHour = isSunrise
            ? solarNoonUTCHour - halfDayHours
            : solarNoonUTCHour + halfDayHours

        let startOfDayUTC = utcCalendar.startOfDay(for: date)
        return startOfDayUTC.addingTimeInterval(transitionUTCHour * 3600)
    }
}
