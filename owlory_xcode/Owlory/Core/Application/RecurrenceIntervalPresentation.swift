import Foundation

enum RecurrenceIntervalPresentation {
    static func longLabel(days: Int) -> String {
        String.localizedStringWithFormat(
            NSLocalizedString(
                "recurrence.interval.days",
                comment: "Recurring task/session interval label such as Every 1 day / Every n days."
            ),
            days
        )
    }

    static func compactBadge(days: Int) -> String {
        String.localizedStringWithFormat(
            NSLocalizedString(
                "recurrence.interval.compact",
                comment: "Compact recurring badge label such as Every nd, displayed next to a recurring row title."
            ),
            days
        )
    }
}
