import Foundation
#if canImport(Combine)
import Combine
#endif

/// Persists completion records and exposes predictions for Continue ranking
/// and overdue reminders.
///
/// This store is the bridge between domain stores (HomeStore, TrainStore) that
/// log completions and the TodayContinuationRules that rank Continue items.
@MainActor
final class CompletionHistoryStore: OwloryObservableObject {
    #if canImport(Combine)
    @Published private(set) var predictions: [String: CompletionTimePredictor.Prediction] = [:]
    #else
    private(set) var predictions: [String: CompletionTimePredictor.Prediction] = [:]
    #endif

    private var records: [CompletionTimePredictor.CompletionRecord] = []
    private let repository: any ItemListRepository<CompletionTimePredictor.CompletionRecord>
    private let clock: Clock

    /// Maximum records to retain per item key (rolling window).
    private let maxRecordsPerKey = 30

    init(
        repository: any ItemListRepository<CompletionTimePredictor.CompletionRecord>,
        clock: Clock
    ) {
        self.repository = repository
        self.clock = clock
        load()
    }

    func load() {
        records = (try? repository.loadAll()) ?? []
        recomputePredictions()
    }

    // MARK: - Logging

    /// Log a home task completion.
    func logHomeTaskCompletion(title: String, completedAt: Date? = nil) {
        let record = CompletionTimePredictor.CompletionRecord(
            itemKey: CompletionTimePredictor.key(forHomeTask: title),
            domain: .home,
            completedAt: completedAt ?? clock.now,
            itemTitle: title
        )
        appendRecord(record)
    }

    /// Log a training session completion.
    func logTrainingCompletion(activity: String, completedAt: Date? = nil) {
        let record = CompletionTimePredictor.CompletionRecord(
            itemKey: CompletionTimePredictor.key(forTrainingSession: activity),
            domain: .training,
            completedAt: completedAt ?? clock.now,
            itemTitle: activity
        )
        appendRecord(record)
    }

    /// Log a protocol run completion.
    func logProtocolRunCompletion(protocolTitle: String, completedAt: Date? = nil) {
        let record = CompletionTimePredictor.CompletionRecord(
            itemKey: CompletionTimePredictor.key(forProtocolRun: protocolTitle),
            domain: .home,
            completedAt: completedAt ?? clock.now,
            itemTitle: protocolTitle
        )
        appendRecord(record)
    }

    // MARK: - Queries

    /// Prediction for a specific item.
    func prediction(forKey key: String) -> CompletionTimePredictor.Prediction? {
        predictions[key]
    }

    /// Items that are overdue today based on their statistical completion window.
    func overdueItems(on day: Date? = nil) -> [CompletionTimePredictor.Prediction] {
        let today = day ?? clock.now
        let calendar = Calendar.current
        return predictions.values.filter { $0.isOverdue(now: clock.now, on: today, calendar: calendar) }
    }

    /// Urgency score for a specific item. Returns nil if no prediction exists.
    func urgencyScore(forKey key: String, on day: Date? = nil) -> Double? {
        guard let prediction = predictions[key] else { return nil }
        let today = day ?? clock.now
        return prediction.urgencyScore(now: clock.now, on: today)
    }

    // MARK: - Private

    private func appendRecord(_ record: CompletionTimePredictor.CompletionRecord) {
        records.append(record)
        pruneRecords(forKey: record.itemKey)
        persist()
        recomputePredictions()
    }

    private func pruneRecords(forKey key: String) {
        let keyRecords = records.filter { $0.itemKey == key }
        guard keyRecords.count > maxRecordsPerKey else { return }
        let sorted = keyRecords.sorted { $0.completedAt < $1.completedAt }
        let toRemove = Set(sorted.prefix(keyRecords.count - maxRecordsPerKey).map(\.id))
        records.removeAll { toRemove.contains($0.id) }
    }

    private func recomputePredictions() {
        predictions = CompletionTimePredictor.predict(from: records)
    }

    private func persist() {
        do {
            try repository.saveAll(records)
        } catch {
            PerformanceTelemetry.notice(
                "CompletionHistoryStore save failed: \(error.localizedDescription)",
                category: .persistence
            )
        }
    }
}
