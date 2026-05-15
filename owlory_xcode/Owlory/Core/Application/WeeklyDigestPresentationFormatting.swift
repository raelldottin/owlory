import Foundation

/// Localized formatting for weekly digest counts, ratios, week labels, and
/// — since the 2026-05-14 `app-localization-digest-insight-summary-formatting`
/// slice — for `InsightKind` and structured `DayHighlight` rendering.
///
/// This file is compiled into both the Owlory app target and the
/// OwloryCoreTests target so the presentation contract is independently
/// testable without dragging SwiftUI into unit tests.
enum WeeklyDigestPresentationFormatting {
    private static let daysInDigestWeek = 7

    static func daysActiveValue(_ count: Int) -> String {
        String.localizedStringWithFormat(
            NSLocalizedString(
                "weeklyDigest.daysActive.value",
                comment: "Weekly digest detail value showing active days out of the week."
            ),
            count,
            daysInDigestWeek
        )
    }

    static func rowDaysActiveValue(_ count: Int) -> String {
        String.localizedStringWithFormat(
            NSLocalizedString(
                "weeklyDigest.row.daysActive",
                comment: "Weekly digest row compact active-day count."
            ),
            count
        )
    }

    static func completionValue(for digest: WeeklyDigest) -> String {
        String.localizedStringWithFormat(
            NSLocalizedString(
                "weeklyDigest.completion.value",
                comment: "Weekly digest detail completion value with done, planned, and percent."
            ),
            digest.totalDone,
            digest.totalPlanned,
            completionPercent(digest.completionRate)
        )
    }

    static func completionRatioValue(done: Int, planned: Int) -> String {
        String.localizedStringWithFormat(
            NSLocalizedString(
                "weeklyDigest.completion.ratio",
                comment: "Weekly digest compact completion ratio."
            ),
            done,
            planned
        )
    }

    static func completionPercentValue(_ completionRate: Double) -> String {
        String.localizedStringWithFormat(
            NSLocalizedString(
                "weeklyDigest.completion.percent",
                comment: "Weekly digest completion percentage."
            ),
            completionPercent(completionRate)
        )
    }

    static func averageReadinessValue(_ averageReadiness: Double) -> String {
        let value = averageReadiness.formatted(.number.precision(.fractionLength(1)))
        return String.localizedStringWithFormat(
            NSLocalizedString(
                "weeklyDigest.averageReadiness.value",
                comment: "Weekly digest average readiness value out of five."
            ),
            value
        )
    }

    static func streakDaysValue(_ count: Int) -> String {
        String.localizedStringWithFormat(
            NSLocalizedString(
                "weeklyDigest.streak.days",
                comment: "Weekly digest full streak length in days."
            ),
            count
        )
    }

    static func compactStreakDaysValue(_ count: Int) -> String {
        String.localizedStringWithFormat(
            NSLocalizedString(
                "weeklyDigest.streak.compact",
                comment: "Weekly digest compact streak length."
            ),
            count
        )
    }

    static func domainActivityItemCount(_ count: Int) -> String {
        String.localizedStringWithFormat(
            NSLocalizedString(
                "weeklyDigest.domainActivity.items",
                comment: "Weekly digest domain activity item count."
            ),
            count
        )
    }

    static func collapsedCompletionSummary(for digest: WeeklyDigest) -> String {
        guard digest.totalPlanned > 0 else {
            return NSLocalizedString(
                "weeklyDigest.summary.empty",
                comment: "Weekly digest summary when no Focus items were planned."
            )
        }

        return String.localizedStringWithFormat(
            NSLocalizedString(
                "weeklyDigest.summary.doneOfPlanned",
                comment: "Weekly digest collapsed completion summary with done and planned counts."
            ),
            digest.totalDone,
            digest.totalPlanned
        )
    }

    static func relativeWeekLabel(
        for digest: WeeklyDigest,
        now: Date,
        calendar: Calendar
    ) -> String {
        guard let previousWeek = WeeklyDigestCadenceRules.previousCompletedWeekWindow(
            for: now,
            calendar: calendar
        ) else {
            return mostRecentWeekLabel
        }

        let digestStart = calendar.startOfDay(for: digest.weekStarting)
        let digestEnd = calendar.startOfDay(for: digest.weekEnding)
        let previousStart = calendar.startOfDay(for: previousWeek.weekStarting)
        let previousEnd = calendar.startOfDay(for: previousWeek.weekEnding)

        if digestStart == previousStart && digestEnd == previousEnd {
            return NSLocalizedString(
                "weeklyDigest.relative.lastWeek",
                comment: "Weekly digest relative label for the previous completed week."
            )
        }

        return mostRecentWeekLabel
    }

    static func weekRangeLabel(
        for digest: WeeklyDigest,
        calendar: Calendar,
        separator: String = "–"
    ) -> String {
        let start = monthDayLabel(for: digest.weekStarting, calendar: calendar)
        let end = monthDayLabel(for: digest.weekEnding, calendar: calendar)
        return "\(start) \(separator) \(end)"
    }

    static func bestDayHighlightSummary(
        _ highlight: WeeklyDigest.DayHighlight,
        calendar: Calendar
    ) -> String {
        guard let doneCount = highlight.doneCount,
              let plannedCount = highlight.plannedCount else {
            return highlight.summary
        }
        let weekday = weekdayName(for: highlight.date, calendar: calendar)
        return String.localizedStringWithFormat(
            NSLocalizedString(
                "weeklyDigest.highlight.bestDay.summary",
                comment: "Weekly digest best-day highlight summary with weekday, done count, and planned count."
            ),
            weekday,
            doneCount,
            plannedCount
        )
    }

    static func hardestDayHighlightSummary(
        _ highlight: WeeklyDigest.DayHighlight,
        calendar: Calendar
    ) -> String {
        guard let bandRawValue = highlight.readinessBand,
              let band = WeeklyDigest.ReadinessBand(rawValue: bandRawValue) else {
            return highlight.summary
        }
        let weekday = weekdayName(for: highlight.date, calendar: calendar)
        let key: String
        switch band {
        case .low: key = "weeklyDigest.highlight.hardestDay.summary.low"
        case .moderate: key = "weeklyDigest.highlight.hardestDay.summary.moderate"
        }
        return String.localizedStringWithFormat(
            NSLocalizedString(
                key,
                comment: "Weekly digest hardest-day highlight summary with weekday and readiness band."
            ),
            weekday
        )
    }

    static func keyInsightLabel(_ keyInsight: String) -> String {
        guard let kind = WeeklyDigest.InsightKind(rawValue: keyInsight) else {
            return keyInsight
        }
        let key: String
        switch kind {
        case .lightWeek: key = "weeklyDigest.insight.lightWeek"
        case .strongWeek: key = "weeklyDigest.insight.strongWeek"
        case .finishedMost: key = "weeklyDigest.insight.finishedMost"
        case .toughWeek: key = "weeklyDigest.insight.toughWeek"
        case .stalledCarryOver: key = "weeklyDigest.insight.stalledCarryOver"
        case .severalDeferred: key = "weeklyDigest.insight.severalDeferred"
        case .lowCompletion: key = "weeklyDigest.insight.lowCompletion"
        case .steady: key = "weeklyDigest.insight.steady"
        }
        return NSLocalizedString(
            key,
            comment: "Weekly digest insight sentence for a deterministic insight kind."
        )
    }

    private static var mostRecentWeekLabel: String {
        NSLocalizedString(
            "weeklyDigest.relative.mostRecentWeek",
            comment: "Weekly digest relative label for the latest available digest when it is not last week."
        )
    }

    private static func completionPercent(_ completionRate: Double) -> Int {
        Int(completionRate * 100)
    }

    private static func monthDayLabel(for date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.setLocalizedDateFormatFromTemplate("MMM d")
        return formatter.string(from: date)
    }

    private static func weekdayName(for date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.setLocalizedDateFormatFromTemplate("EEEE")
        return formatter.string(from: date)
    }
}
