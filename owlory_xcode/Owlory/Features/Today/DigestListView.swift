import SwiftUI

struct DigestListView: View {
    @ObservedObject var patternStore: PatternStore
    private let calendar: Calendar

    init(patternStore: PatternStore, calendar: Calendar? = nil) {
        self.patternStore = patternStore
        self.calendar = calendar ?? patternStore.weeklyDigestCalendar
    }

    private var digests: [WeeklyDigest] {
        (try? patternStore.loadAllDigests()) ?? []
    }

    var body: some View {
        List {
            if digests.isEmpty {
                Text("No weekly digests yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(digests.reversed()) { digest in
                    NavigationLink {
                        DigestDetailView(digest: digest, calendar: calendar)
                    } label: {
                        DigestRowView(digest: digest, calendar: calendar)
                    }
                }
            }
        }
        .navigationTitle("Weekly Digests")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct DigestRowView: View {
    let digest: WeeklyDigest
    let calendar: Calendar

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(weekLabel)
                .font(.subheadline.weight(.medium))
            HStack(spacing: 12) {
                Label(
                    WeeklyDigestPresentationFormatting.rowDaysActiveValue(digest.daysWithEntries),
                    systemImage: "calendar"
                )
                Label(
                    WeeklyDigestPresentationFormatting.completionPercentValue(digest.completionRate),
                    systemImage: "checkmark.circle"
                )
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            if !digest.keyInsight.isEmpty {
                Text(digest.keyInsight)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
    }

    private var weekLabel: String {
        WeeklyDigestPresentationFormatting.weekRangeLabel(for: digest, calendar: calendar)
    }
}

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
}
