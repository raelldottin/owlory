import Foundation

/// Localized formatting for Home protocol schedule labels and help text.
///
/// This file is compiled into both the Owlory app target and the
/// OwloryCoreTests target so the presentation contract is independently
/// testable without dragging SwiftUI into unit tests. Both consumers must
/// pass a run-aware `ScheduleSummary`; otherwise a passed window can render
/// "window passed" copy even when a run already satisfied the cadence.
enum HomeProtocolSchedulePresentationFormatting {
    static func summaryText(
        for summary: ProtocolScheduleRules.ScheduleSummary,
        calendar: Calendar
    ) -> String {
        scheduleText(
            preset: summary.preset,
            startDate: summary.startDate,
            endDate: summary.endDate,
            isOverdue: summary.status == .overdue,
            calendar: calendar
        )
    }

    static func helpText(
        for summary: ProtocolScheduleRules.ScheduleSummary?,
        calendar: Calendar
    ) -> String {
        guard let summary else {
            return NSLocalizedString(
                "home.protocol.schedule.help.anytime",
                comment: "Home protocol schedule help text when no schedule window is selected."
            )
        }

        let label = scheduleText(
            preset: summary.preset,
            startDate: summary.startDate,
            endDate: summary.endDate,
            isOverdue: summary.status == .overdue,
            calendar: calendar
        )

        return String.localizedStringWithFormat(
            NSLocalizedString(
                "home.protocol.schedule.help.scheduled",
                comment: "Home protocol schedule help text with the selected schedule label."
            ),
            label
        )
    }

    private static func scheduleText(
        preset: ProtocolSchedulePreset,
        startDate: Date,
        endDate: Date,
        isOverdue: Bool,
        calendar: Calendar
    ) -> String {
        switch preset {
        case .today:
            return NSLocalizedString(
                isOverdue
                    ? "home.protocol.schedule.today.passed"
                    : "home.protocol.schedule.today",
                comment: "Home protocol schedule label for a today window."
            )
        case .weekend:
            return NSLocalizedString(
                isOverdue
                    ? "home.protocol.schedule.weekend.passed"
                    : "home.protocol.schedule.weekend",
                comment: "Home protocol schedule label for a weekend window."
            )
        case .thisWeek:
            return NSLocalizedString(
                isOverdue
                    ? "home.protocol.schedule.thisWeek.passed"
                    : "home.protocol.schedule.thisWeek",
                comment: "Home protocol schedule label for a this-week window."
            )
        case .custom:
            let key = isOverdue
                ? "home.protocol.schedule.custom.passed"
                : "home.protocol.schedule.custom"
            return String.localizedStringWithFormat(
                NSLocalizedString(
                    key,
                    comment: "Home protocol schedule label for a custom date window."
                ),
                rangeLabel(start: startDate, end: endDate, calendar: calendar)
            )
        }
    }

    private static func rangeLabel(start: Date, end: Date, calendar: Calendar) -> String {
        if calendar.startOfDay(for: start) == calendar.startOfDay(for: end) {
            return dayLabel(start, calendar: calendar)
        }

        return "\(dayLabel(start, calendar: calendar)) - \(dayLabel(end, calendar: calendar))"
    }

    private static func dayLabel(_ date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = calendar.locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
