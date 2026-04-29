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

    static func canPromoteWritingNoteToFocus(
        _ note: WritingNote,
        in entry: DailyEntry
    ) -> Bool {
        let title = note.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty,
              entry.focusThree.count < focusItemLimit else {
            return false
        }

        return !entry.focusThree.contains { item in
            isFocusItemLinkedToWritingNote(item, noteID: note.id)
        }
    }

    static func promotingWritingNoteToFocus(
        _ note: WritingNote,
        in entry: DailyEntry,
        promotedAt: Date
    ) -> DailyEntry {
        guard canPromoteWritingNoteToFocus(note, in: entry) else {
            return entry
        }

        let item = FocusItem(
            title: note.title.trimmingCharacters(in: .whitespacesAndNewlines),
            domain: .writing,
            linkedRecordID: note.id,
            origin: FocusItemOrigin(
                kind: .writingNote,
                id: note.id,
                createdAt: promotedAt
            )
        )
        return addingFocusItem(item, to: entry)
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

    private static func isFocusItemLinkedToWritingNote(_ item: FocusItem, noteID: UUID) -> Bool {
        if item.origin?.kind == .writingNote && item.origin?.id == noteID {
            return true
        }

        return item.domain == .writing && item.linkedRecordID == noteID
    }
}
