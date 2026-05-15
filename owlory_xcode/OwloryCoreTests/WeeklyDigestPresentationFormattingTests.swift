import XCTest
#if SWIFT_PACKAGE
@testable import OwloryCore
#endif

/// Domain-tested proof for the digest-insight + highlight sentence
/// rendering contract established by the
/// `app-localization-digest-insight-summary-formatting` slice.
///
/// `WeeklyDigest.InsightKind` raw values stored in `keyInsight` and the
/// structured `DayHighlight` fields (`doneCount`, `plannedCount`,
/// `readinessBand`) must resolve through `WeeklyDigestPresentationFormatting`
/// to the localized English sentences that DigestDetailView and
/// DigestListView render. Without this coverage the structured path could
/// regress silently to displaying the raw value (`"strongWeek"`) or the
/// legacy empty `summary` string.
final class WeeklyDigestPresentationFormattingTests: XCTestCase {
    private let calendar = Calendar.current

    // MARK: - keyInsightLabel

    func testKeyInsightLabelResolvesEveryKnownInsightKindToALocalizedSentence() {
        let expected: [WeeklyDigest.InsightKind: String] = [
            .lightWeek: "Light week. Showing up is the first step.",
            .strongWeek: "Strong week. High readiness translated into follow-through.",
            .finishedMost: "You finished most of what you planned.",
            .toughWeek: "Tough week with low reserves. Consider planning lighter next time.",
            .stalledCarryOver: "Some items carried over repeatedly. Worth deciding: commit, defer, or drop?",
            .severalDeferred: "Several items deferred. The plan may have been bigger than the week.",
            .lowCompletion: "Completion was under 50%. Fewer priorities might mean more follow-through.",
            .steady: "Steady week. Keep building the rhythm."
        ]

        for (kind, sentence) in expected {
            XCTAssertEqual(
                WeeklyDigestPresentationFormatting.keyInsightLabel(kind.rawValue),
                sentence,
                "InsightKind.\(kind.rawValue) should resolve to its localized sentence."
            )
        }
    }

    func testKeyInsightLabelFallsThroughForLegacyEnglishSentenceValues() {
        // Old stored digests carry the full English sentence in keyInsight
        // rather than an InsightKind rawValue. Presentation should render
        // those values verbatim instead of trying to map them.
        let legacy = "Some bespoke pre-refactor sentence."
        XCTAssertEqual(
            WeeklyDigestPresentationFormatting.keyInsightLabel(legacy),
            legacy
        )
    }

    func testKeyInsightLabelFallsThroughForEmptyValue() {
        XCTAssertEqual(
            WeeklyDigestPresentationFormatting.keyInsightLabel(""),
            ""
        )
    }

    // MARK: - bestDayHighlightSummary

    func testBestDayHighlightSummaryUsesStructuredCountsWhenPresent() {
        let monday = makeDate("2026-05-04T00:00:00Z")
        let highlight = WeeklyDigest.DayHighlight(
            date: monday,
            summary: "",
            doneCount: 2,
            plannedCount: 2,
            readinessBand: nil
        )
        let rendered = WeeklyDigestPresentationFormatting.bestDayHighlightSummary(
            highlight,
            calendar: calendar
        )
        XCTAssertTrue(
            rendered.contains("2 of 2 completed"),
            "Best-day highlight should render the localized 'N of M completed' substring from the structured fields. Actual: \(rendered)"
        )
    }

    func testBestDayHighlightSummaryFallsThroughToLegacySummaryWhenCountsAbsent() {
        let monday = makeDate("2026-05-04T00:00:00Z")
        let legacySentence = "Mon: 2 of 2 completed"
        let highlight = WeeklyDigest.DayHighlight(
            date: monday,
            summary: legacySentence,
            doneCount: nil,
            plannedCount: nil,
            readinessBand: nil
        )
        XCTAssertEqual(
            WeeklyDigestPresentationFormatting.bestDayHighlightSummary(
                highlight,
                calendar: calendar
            ),
            legacySentence
        )
    }

    // MARK: - hardestDayHighlightSummary

    func testHardestDayHighlightSummaryUsesLowReadinessBandWhenPresent() {
        let thursday = makeDate("2026-05-07T00:00:00Z")
        let highlight = WeeklyDigest.DayHighlight(
            date: thursday,
            summary: "",
            doneCount: nil,
            plannedCount: nil,
            readinessBand: WeeklyDigest.ReadinessBand.low.rawValue
        )
        let rendered = WeeklyDigestPresentationFormatting.hardestDayHighlightSummary(
            highlight,
            calendar: calendar
        )
        XCTAssertTrue(
            rendered.contains("low readiness"),
            "Hardest-day highlight should render the localized 'low readiness' substring for readinessBand=low. Actual: \(rendered)"
        )
    }

    func testHardestDayHighlightSummaryUsesModerateReadinessBandWhenPresent() {
        let thursday = makeDate("2026-05-07T00:00:00Z")
        let highlight = WeeklyDigest.DayHighlight(
            date: thursday,
            summary: "",
            doneCount: nil,
            plannedCount: nil,
            readinessBand: WeeklyDigest.ReadinessBand.moderate.rawValue
        )
        let rendered = WeeklyDigestPresentationFormatting.hardestDayHighlightSummary(
            highlight,
            calendar: calendar
        )
        XCTAssertTrue(
            rendered.contains("moderate readiness"),
            "Hardest-day highlight should render the localized 'moderate readiness' substring for readinessBand=moderate. Actual: \(rendered)"
        )
    }

    func testHardestDayHighlightSummaryFallsThroughToLegacySummaryWhenBandAbsent() {
        let thursday = makeDate("2026-05-07T00:00:00Z")
        let legacySentence = "Thu: low readiness"
        let highlight = WeeklyDigest.DayHighlight(
            date: thursday,
            summary: legacySentence,
            doneCount: nil,
            plannedCount: nil,
            readinessBand: nil
        )
        XCTAssertEqual(
            WeeklyDigestPresentationFormatting.hardestDayHighlightSummary(
                highlight,
                calendar: calendar
            ),
            legacySentence
        )
    }

    // MARK: - Helpers

    private func makeDate(_ iso: String) -> Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: iso) ?? Date()
    }
}
