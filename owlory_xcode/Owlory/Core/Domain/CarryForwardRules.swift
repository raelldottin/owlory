import Foundation

enum CarryForwardRules {
    static func nextDayItems(from entry: DailyEntry, into date: Date) -> [FocusItem] {
        entry.focusThree.compactMap { item in
            switch item.status {
            case .done, .dropped:
                return nil
            case .planned, .deferred:
                return FocusItem(
                    title: item.title,
                    domain: item.domain,
                    status: .planned,
                    createdFromDate: entry.date,
                    linkedRecordID: item.linkedRecordID,
                    origin: item.origin
                )
            }
        }
    }
}
