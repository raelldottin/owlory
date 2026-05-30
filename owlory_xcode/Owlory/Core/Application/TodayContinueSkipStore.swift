import Foundation
#if canImport(Combine)
import Combine
#endif

/// Persists the set of Today Continue source keys the user has skipped for
/// the current day. Entries auto-expire on date rollover — the store prunes
/// stale day-stamped entries every time it loads.
@MainActor
final class TodayContinueSkipStore: OwloryObservableObject {
#if canImport(Combine)
    @Published private(set) var skippedKeysToday: Set<String> = []
#else
    private(set) var skippedKeysToday: Set<String> = []
#endif

    private let defaults: UserDefaults
    private let calendar: Calendar
    private static let storageKey = "owlory.todayContinue.skipForToday"

    init(
        defaults: UserDefaults = .standard,
        calendar: Calendar = .current,
        now: Date = Date()
    ) {
        self.defaults = defaults
        self.calendar = calendar
        refresh(now: now)
    }

    func isSkippedToday(_ sourceKey: String) -> Bool {
        skippedKeysToday.contains(sourceKey)
    }

    func skip(sourceKey: String, now: Date = Date()) {
        let todayKey = Self.dayKey(for: now, calendar: calendar)
        var stored = currentStoredMap()
        stored[sourceKey] = todayKey
        defaults.set(stored, forKey: Self.storageKey)
        skippedKeysToday.insert(sourceKey)
    }

    func refresh(now: Date = Date()) {
        let todayKey = Self.dayKey(for: now, calendar: calendar)
        let stored = currentStoredMap()
        skippedKeysToday = Set(
            stored.compactMap { sourceKey, dayKey in
                dayKey == todayKey ? sourceKey : nil
            }
        )
        if stored.count != skippedKeysToday.count {
            let pruned = stored.filter { $0.value == todayKey }
            defaults.set(pruned, forKey: Self.storageKey)
        }
    }

    private func currentStoredMap() -> [String: String] {
        (defaults.dictionary(forKey: Self.storageKey) as? [String: String]) ?? [:]
    }

    private static func dayKey(for date: Date, calendar: Calendar) -> String {
        let start = calendar.startOfDay(for: date)
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: start)
    }
}
