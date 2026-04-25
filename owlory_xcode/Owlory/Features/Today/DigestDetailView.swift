import SwiftUI

struct DigestDetailView: View {
    let digest: WeeklyDigest
    let calendar: Calendar

    init(digest: WeeklyDigest, calendar: Calendar = .current) {
        self.digest = digest
        self.calendar = calendar
    }

    var body: some View {
        List {
            overviewSection
            highlightsSection
            domainActivitySection
            insightSection
        }
        .navigationTitle(weekLabel)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Overview

    private var overviewSection: some View {
        Section("Overview") {
            LabeledContent("Days active", value: "\(digest.daysWithEntries) of 7")
            LabeledContent("Completion", value: "\(digest.totalDone) of \(digest.totalPlanned) (\(Int(digest.completionRate * 100))%)")
            if digest.averageReadiness > 0 {
                LabeledContent("Avg readiness", value: String(format: "%.1f / 5", digest.averageReadiness))
            }
            if digest.streakDays > 0 {
                LabeledContent("Streak", value: "\(digest.streakDays) \(digest.streakDays == 1 ? "day" : "days")")
            }
            if digest.stalledItemCount > 0 {
                LabeledContent("Stalled items", value: "\(digest.stalledItemCount)")
            }
        }
    }

    // MARK: - Highlights

    @ViewBuilder
    private var highlightsSection: some View {
        if digest.bestDay != nil || digest.hardestDay != nil {
            Section("Highlights") {
                if let best = digest.bestDay {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundStyle(OwloryColor.brandPrimary)
                        VStack(alignment: .leading) {
                            Text("Best day")
                                .font(.caption.weight(.medium))
                            Text(best.summary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                if let hardest = digest.hardestDay {
                    HStack {
                        Image(systemName: "cloud.rain")
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading) {
                            Text("Hardest day")
                                .font(.caption.weight(.medium))
                            Text(hardest.summary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Domain Activity

    @ViewBuilder
    private var domainActivitySection: some View {
        let active = digest.domainActivity.filter { $0.value > 0 }.sorted { $0.value > $1.value }
        if !active.isEmpty {
            Section("Domain Activity") {
                ForEach(active, id: \.key) { domain, count in
                    LabeledContent(domain.title, value: "\(count) \(count == 1 ? "item" : "items")")
                }
            }
        }
    }

    // MARK: - Insight

    @ViewBuilder
    private var insightSection: some View {
        if !digest.keyInsight.isEmpty {
            Section("Insight") {
                Text(digest.keyInsight)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var weekLabel: String {
        WeeklyDigestRules.weekRangeLabel(for: digest, calendar: calendar, separator: "-")
    }
}
