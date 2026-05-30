import Foundation

/// Decides whether Owlory's Dusk Mode should be active for a given moment.
/// When `sunset` and `sunrise` are supplied (via `SolarSunset`), the rule
/// uses astronomical transition times for the user's date and approximate
/// location. Otherwise it falls back to a fixed-hour window (18:00–05:00
/// local) so polar day/night and missing-coordinate cases still behave.
enum DuskModeRules {
    /// Default activation hour for the fixed-hour fallback.
    static let defaultActivationHour: Int = 18
    /// Default deactivation hour for the fixed-hour fallback.
    static let defaultDeactivationHour: Int = 5

    /// Returns true when `date` falls in the evening window. Prefers the
    /// astronomical transition pair when both `sunset` and `sunrise` are
    /// available, otherwise falls back to the local-hour window.
    static func isActive(
        at date: Date,
        sunset: Date? = nil,
        sunrise: Date? = nil,
        calendar: Calendar = .current,
        activationHour: Int = defaultActivationHour,
        deactivationHour: Int = defaultDeactivationHour
    ) -> Bool {
        if let sunset, let sunrise {
            return date >= sunset || date < sunrise
        }
        let hour = calendar.component(.hour, from: date)
        return hour >= activationHour || hour < deactivationHour
    }
}
