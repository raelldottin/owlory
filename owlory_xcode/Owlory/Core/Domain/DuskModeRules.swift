import Foundation

/// Decides whether Owlory's Dusk Mode should be active based on local time.
/// Pure rule — no asynchronous APIs, no geolocation. v1 uses fixed hour
/// thresholds; future work may replace this with astronomical sunset.
enum DuskModeRules {
    /// Default activation hour (inclusive). Dusk Mode turns on at 18:00 local.
    static let defaultActivationHour: Int = 18
    /// Default deactivation hour (exclusive). Dusk Mode turns off at 05:00 local.
    static let defaultDeactivationHour: Int = 5

    /// Returns true when the supplied date falls within the dusk window
    /// (activationHour ... 24) ∪ (00 ..< deactivationHour).
    static func isActive(
        at date: Date,
        calendar: Calendar = .current,
        activationHour: Int = defaultActivationHour,
        deactivationHour: Int = defaultDeactivationHour
    ) -> Bool {
        let hour = calendar.component(.hour, from: date)
        return hour >= activationHour || hour < deactivationHour
    }
}
