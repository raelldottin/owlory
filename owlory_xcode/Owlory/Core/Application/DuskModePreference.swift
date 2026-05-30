import Foundation

/// User-controlled override for Dusk Mode. Default is `.auto`, which defers
/// to the time-of-day rule. `.on` and `.off` force the corresponding state
/// regardless of time.
enum DuskModePreference: String, CaseIterable, Codable, Identifiable {
    case auto
    case on
    case off

    var id: String { rawValue }
}

enum DuskModePreferenceStorage {
    /// UserDefaults key for the persisted preference rawValue.
    static let key = "owlory.duskMode.preference"
}

/// Pure resolver that combines the user preference with the time-of-day rule.
/// Lives in Application because it composes a domain rule with an application-
/// owned preference; the rule itself stays in Domain.
enum DuskModeResolver {
    static func isActive(
        preference: DuskModePreference,
        at date: Date,
        calendar: Calendar = .current
    ) -> Bool {
        switch preference {
        case .auto: return DuskModeRules.isActive(at: date, calendar: calendar)
        case .on: return true
        case .off: return false
        }
    }
}
