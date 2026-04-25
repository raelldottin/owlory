import Foundation

/// Pure statistical engine that predicts expected completion time-of-day for
/// recurring items based on their historical completion timestamps.
///
/// **Algorithm**: Median time-of-day (seconds since midnight) with MAD
/// (Median Absolute Deviation) for confidence. Items with fewer than 3
/// observations return nil — not enough signal to predict.
///
/// This is the approved statistical role for timing/urgency enrichment in
/// Continue and Focus Suggestions. It does NOT generate user-facing content.
enum CompletionTimePredictor {

    /// A single historical completion event.
    struct CompletionRecord: Codable, Equatable, Identifiable {
        let id: UUID
        let itemKey: String          // Stable identifier: "home|<title>" or "train|<activity>"
        let domain: LifeDomain
        let completedAt: Date
        let itemTitle: String        // For display only

        init(
            id: UUID = UUID(),
            itemKey: String,
            domain: LifeDomain,
            completedAt: Date,
            itemTitle: String
        ) {
            self.id = id
            self.itemKey = itemKey
            self.domain = domain
            self.completedAt = completedAt
            self.itemTitle = itemTitle
        }
    }

    /// Predicted typical completion window for one item.
    struct Prediction: Equatable {
        let itemKey: String
        let medianTimeOfDay: TimeInterval     // Seconds since midnight
        let madSeconds: TimeInterval          // Median absolute deviation
        let sampleCount: Int

        /// The predicted completion time on a given calendar day.
        func expectedCompletionDate(on day: Date, calendar: Calendar = .current) -> Date {
            let start = calendar.startOfDay(for: day)
            return start.addingTimeInterval(medianTimeOfDay)
        }

        /// Whether the item is overdue relative to `now`.
        /// Returns true if `now` is past the median + 1 MAD window.
        func isOverdue(now: Date, on day: Date, calendar: Calendar = .current) -> Bool {
            let expected = expectedCompletionDate(on: day, calendar: calendar)
            let deadline = expected.addingTimeInterval(madSeconds)
            return now > deadline
        }

        /// Urgency score: how close (or past) the expected completion time we are.
        /// Returns a value from 0 (far from deadline) to 1+ (past deadline).
        /// Used to rank Continue items — higher urgency = higher priority.
        func urgencyScore(now: Date, on day: Date, calendar: Calendar = .current) -> Double {
            let elapsed = now.timeIntervalSince(calendar.startOfDay(for: day))

            // If no meaningful deviation, use a 1-hour default window
            let window = max(madSeconds, 3600)

            // Score: 0 at start-of-day, 1.0 at expected time, >1.0 when overdue
            guard medianTimeOfDay > 0 else { return 0 }
            // Boost past the expected time: add overshoot scaled by MAD window
            if elapsed > medianTimeOfDay {
                let overshoot = (elapsed - medianTimeOfDay) / window
                return 1.0 + overshoot
            }
            return max(0, elapsed / medianTimeOfDay)
        }
    }

    // MARK: - Key Generation

    /// Stable key for a recurring home task.
    static func key(forHomeTask title: String) -> String {
        "home|\(title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))"
    }

    /// Stable key for a recurring training session.
    static func key(forTrainingSession activity: String) -> String {
        "train|\(activity.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))"
    }

    /// Stable key for a protocol run.
    static func key(forProtocolRun title: String) -> String {
        "protocol|\(title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))"
    }

    // MARK: - Prediction

    /// Minimum observations required to produce a prediction.
    static let minimumSampleCount = 3

    /// Compute predictions for all items that have enough history.
    static func predict(from records: [CompletionRecord], calendar: Calendar = .current) -> [String: Prediction] {
        let grouped = Dictionary(grouping: records, by: \.itemKey)

        var predictions: [String: Prediction] = [:]
        for (key, group) in grouped {
            guard group.count >= minimumSampleCount else { continue }

            let timesOfDay = group.map { record -> TimeInterval in
                let start = calendar.startOfDay(for: record.completedAt)
                return record.completedAt.timeIntervalSince(start)
            }.sorted()

            let median = Self.median(timesOfDay)
            let deviations = timesOfDay.map { abs($0 - median) }.sorted()
            let mad = Self.median(deviations)

            predictions[key] = Prediction(
                itemKey: key,
                medianTimeOfDay: median,
                madSeconds: mad,
                sampleCount: group.count
            )
        }
        return predictions
    }

    /// Single-item prediction from a filtered set of records.
    static func predict(forKey key: String, from records: [CompletionRecord], calendar: Calendar = .current) -> Prediction? {
        let filtered = records.filter { $0.itemKey == key }
        guard filtered.count >= minimumSampleCount else { return nil }
        return predict(from: filtered, calendar: calendar)[key]
    }

    // MARK: - Private

    private static func median(_ sorted: [TimeInterval]) -> TimeInterval {
        guard !sorted.isEmpty else { return 0 }
        let mid = sorted.count / 2
        if sorted.count.isMultiple(of: 2) {
            return (sorted[mid - 1] + sorted[mid]) / 2
        }
        return sorted[mid]
    }
}
