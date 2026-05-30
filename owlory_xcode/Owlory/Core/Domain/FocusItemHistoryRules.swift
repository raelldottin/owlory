import Foundation

/// Derives a per-day status arc for a `FocusItem` by walking persisted past
/// `DailyEntry` records. The arc spans from the item's `createdFromDate`
/// through the day before `today`. The current day's status is intentionally
/// excluded — the live row already represents "now".
enum FocusItemHistoryRules {
    struct DayStatus: Equatable {
        let date: Date
        let status: FocusItemStatus
    }

    /// Build the arc. Days with no matching item in their `DailyEntry` are
    /// represented as `.planned` so a missing record reads as "we held it"
    /// rather than as a gap in the ribbon.
    static func arc(
        for item: FocusItem,
        in pastEntries: [DailyEntry],
        today: Date,
        calendar: Calendar = .current
    ) -> [DayStatus] {
        guard let firstSeen = item.createdFromDate else { return [] }

        let firstSeenDay = calendar.startOfDay(for: firstSeen)
        let todayDay = calendar.startOfDay(for: today)
        guard firstSeenDay < todayDay else { return [] }

        let entriesByDay: [Date: DailyEntry] = pastEntries.reduce(into: [:]) { result, entry in
            let day = calendar.startOfDay(for: entry.date)
            if result[day] == nil { result[day] = entry }
        }

        var results: [DayStatus] = []
        var cursor = firstSeenDay
        while cursor < todayDay {
            let status = entriesByDay[cursor]
                .flatMap { matchingItem(for: item, in: $0.focusThree)?.status }
                ?? .planned
            results.append(DayStatus(date: cursor, status: status))
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return results
    }

    private static func matchingItem(
        for item: FocusItem,
        in candidates: [FocusItem]
    ) -> FocusItem? {
        if let origin = item.origin,
           let match = candidates.first(where: { $0.origin == origin }) {
            return match
        }
        if let linkedID = item.linkedRecordID,
           let match = candidates.first(where: {
               $0.linkedRecordID == linkedID && $0.domain == item.domain
           }) {
            return match
        }
        return candidates.first {
            $0.title == item.title && $0.domain == item.domain
        }
    }
}
