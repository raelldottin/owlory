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
        Section(L("Overview")) {
            LabeledContent(
                "Days active",
                value: WeeklyDigestPresentationFormatting.daysActiveValue(digest.daysWithEntries)
            )
            LabeledContent(
                "Completion",
                value: WeeklyDigestPresentationFormatting.completionValue(for: digest)
            )
            if digest.averageReadiness > 0 {
                LabeledContent(
                    "Avg readiness",
                    value: WeeklyDigestPresentationFormatting.averageReadinessValue(digest.averageReadiness)
                )
            }
            if digest.streakDays > 0 {
                LabeledContent(
                    "Streak",
                    value: WeeklyDigestPresentationFormatting.streakDaysValue(digest.streakDays)
                )
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
            Section(L("Highlights")) {
                if let best = digest.bestDay {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundStyle(OwloryColor.brandPrimary)
                        VStack(alignment: .leading) {
                            Text("Best day")
                                .font(.caption.weight(.medium))
                            Text(WeeklyDigestPresentationFormatting.bestDayHighlightSummary(best, calendar: calendar))
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
                            Text(WeeklyDigestPresentationFormatting.hardestDayHighlightSummary(hardest, calendar: calendar))
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
            Section(L("Domain Activity")) {
                ForEach(active, id: \.key) { domain, count in
                    LabeledContent(
                        domain.localizedDisplayName,
                        value: WeeklyDigestPresentationFormatting.domainActivityItemCount(count)
                    )
                }
            }
        }
    }

    // MARK: - Insight

    @ViewBuilder
    private var insightSection: some View {
        if !digest.keyInsight.isEmpty {
            Section(L("Insight")) {
                Text(WeeklyDigestPresentationFormatting.keyInsightLabel(digest.keyInsight))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var weekLabel: String {
        WeeklyDigestPresentationFormatting.weekRangeLabel(for: digest, calendar: calendar, separator: "-")
    }
}

private extension LifeDomain {
    var localizedDisplayName: String {
        switch self {
        case .training:
            return String(localized: "display.lifeDomain.training")
        case .writing:
            return String(localized: "display.lifeDomain.writing")
        case .career:
            return String(localized: "display.lifeDomain.career")
        case .home:
            return String(localized: "display.lifeDomain.home")
        }
    }
}
