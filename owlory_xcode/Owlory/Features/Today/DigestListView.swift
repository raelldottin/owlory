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
            HStack(spacing: AppTheme.rowSpacing) {
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
                Text(WeeklyDigestPresentationFormatting.keyInsightLabel(digest.keyInsight))
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
