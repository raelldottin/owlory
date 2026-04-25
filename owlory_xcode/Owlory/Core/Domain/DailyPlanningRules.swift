import Foundation

enum DailyPlanningRules {
    static let focusItemLimit = 3

    static func seedEntry(
        for date: Date,
        carryForward: [FocusItem]
    ) -> DailyEntry {
        DailyEntry(
            date: date,
            focusThree: Array(carryForward.prefix(focusItemLimit)),
            domainIntentions: [:],
            carryForward: carryForward
        )
    }

    static func addingFocusItem(
        _ item: FocusItem,
        to entry: DailyEntry
    ) -> DailyEntry {
        guard canAddFocusItem(item, to: entry) else {
            return entry
        }

        var updated = entry
        updated.focusThree.append(item)
        return updated
    }

    static func removingFocusItem(
        id: UUID,
        from entry: DailyEntry
    ) -> DailyEntry {
        var updated = entry
        updated.focusThree.removeAll { $0.id == id }
        return updated
    }

    static func updatingStatus(
        for itemID: UUID,
        to status: FocusItemStatus,
        in entry: DailyEntry
    ) -> DailyEntry {
        guard let index = entry.focusThree.firstIndex(where: { $0.id == itemID }) else {
            return entry
        }

        var updated = entry
        updated.focusThree[index].status = status
        return updated
    }

    private static func canAddFocusItem(
        _ item: FocusItem,
        to entry: DailyEntry
    ) -> Bool {
        !item.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            entry.focusThree.count < focusItemLimit
    }
}
