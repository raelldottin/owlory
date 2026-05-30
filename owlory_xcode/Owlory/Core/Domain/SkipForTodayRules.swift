import Foundation

/// Pure rule for hiding Today Continue rows that the user has chosen to skip
/// for the day. Non-mutating with respect to source records — skipped rows
/// reappear automatically when the day rolls over.
enum SkipForTodayRules {
    /// Returns `items` with any row whose `source.key` is in `skippedKeys`
    /// removed. Preserves the input order of remaining items.
    static func apply(
        to items: [TodayContinuationRules.ContinueItem],
        skippedKeys: Set<String>
    ) -> [TodayContinuationRules.ContinueItem] {
        guard !skippedKeys.isEmpty else { return items }
        return items.filter { !skippedKeys.contains($0.source.key) }
    }
}
