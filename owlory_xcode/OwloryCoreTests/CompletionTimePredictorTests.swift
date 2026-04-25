import XCTest

@MainActor
final class CompletionTimePredictorTests: XCTestCase {

    private let calendar = Calendar.current

    private func makeRecord(
        key: String,
        domain: LifeDomain = .home,
        completedAt: Date,
        title: String = "Test"
    ) -> CompletionTimePredictor.CompletionRecord {
        CompletionTimePredictor.CompletionRecord(
            itemKey: key,
            domain: domain,
            completedAt: completedAt,
            itemTitle: title
        )
    }

    private func dateAt(hour: Int, minute: Int = 0, day: Int = 1) -> Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 4
        components.day = day
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)!
    }

    // MARK: - Key Generation

    func testKeyForHomeTaskNormalizesCase() {
        let key = CompletionTimePredictor.key(forHomeTask: "  Water Plants  ")
        XCTAssertEqual(key, "home|water plants")
    }

    func testKeyForTrainingSessionNormalizesCase() {
        let key = CompletionTimePredictor.key(forTrainingSession: "Morning Run")
        XCTAssertEqual(key, "train|morning run")
    }

    func testKeyForProtocolRunNormalizesCase() {
        let key = CompletionTimePredictor.key(forProtocolRun: "Kitchen Reset")
        XCTAssertEqual(key, "protocol|kitchen reset")
    }

    // MARK: - Minimum Sample Requirement

    func testPredictReturnsNilWithFewerThanThreeRecords() {
        let key = "home|water plants"
        let records = [
            makeRecord(key: key, completedAt: dateAt(hour: 9, day: 1)),
            makeRecord(key: key, completedAt: dateAt(hour: 9, day: 2)),
        ]
        let result = CompletionTimePredictor.predict(forKey: key, from: records)
        XCTAssertNil(result)
    }

    func testPredictReturnsValueWithThreeRecords() {
        let key = "home|water plants"
        let records = [
            makeRecord(key: key, completedAt: dateAt(hour: 9, day: 1)),
            makeRecord(key: key, completedAt: dateAt(hour: 9, day: 2)),
            makeRecord(key: key, completedAt: dateAt(hour: 9, day: 3)),
        ]
        let result = CompletionTimePredictor.predict(forKey: key, from: records)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.sampleCount, 3)
    }

    // MARK: - Median Computation

    func testMedianTimeOfDayWithConsistentTimes() {
        let key = "home|water plants"
        let records = [
            makeRecord(key: key, completedAt: dateAt(hour: 9, minute: 0, day: 1)),
            makeRecord(key: key, completedAt: dateAt(hour: 9, minute: 0, day: 2)),
            makeRecord(key: key, completedAt: dateAt(hour: 9, minute: 0, day: 3)),
        ]
        let prediction = CompletionTimePredictor.predict(forKey: key, from: records)!

        // Median should be exactly 9:00 AM = 9 * 3600 seconds
        XCTAssertEqual(prediction.medianTimeOfDay, 9 * 3600, accuracy: 1)
    }

    func testMedianTimeOfDayWithVariedTimes() {
        let key = "train|morning run"
        let records = [
            makeRecord(key: key, domain: .training, completedAt: dateAt(hour: 7, day: 1)),
            makeRecord(key: key, domain: .training, completedAt: dateAt(hour: 8, day: 2)),
            makeRecord(key: key, domain: .training, completedAt: dateAt(hour: 9, day: 3)),
            makeRecord(key: key, domain: .training, completedAt: dateAt(hour: 10, day: 4)),
            makeRecord(key: key, domain: .training, completedAt: dateAt(hour: 11, day: 5)),
        ]
        let prediction = CompletionTimePredictor.predict(forKey: key, from: records)!

        // Median of [7, 8, 9, 10, 11] hours = 9:00 AM
        XCTAssertEqual(prediction.medianTimeOfDay, 9 * 3600, accuracy: 1)
    }

    func testMedianWithEvenSampleCountAveragesMiddleTwo() {
        let key = "home|laundry"
        let records = [
            makeRecord(key: key, completedAt: dateAt(hour: 8, day: 1)),
            makeRecord(key: key, completedAt: dateAt(hour: 9, day: 2)),
            makeRecord(key: key, completedAt: dateAt(hour: 11, day: 3)),
            makeRecord(key: key, completedAt: dateAt(hour: 12, day: 4)),
        ]
        let prediction = CompletionTimePredictor.predict(forKey: key, from: records)!

        // Median of [8, 9, 11, 12] = (9 + 11) / 2 = 10:00 AM
        XCTAssertEqual(prediction.medianTimeOfDay, 10 * 3600, accuracy: 1)
    }

    // MARK: - MAD (Median Absolute Deviation)

    func testMADIsZeroForIdenticalTimes() {
        let key = "home|water plants"
        let records = [
            makeRecord(key: key, completedAt: dateAt(hour: 9, day: 1)),
            makeRecord(key: key, completedAt: dateAt(hour: 9, day: 2)),
            makeRecord(key: key, completedAt: dateAt(hour: 9, day: 3)),
        ]
        let prediction = CompletionTimePredictor.predict(forKey: key, from: records)!
        XCTAssertEqual(prediction.madSeconds, 0, accuracy: 1)
    }

    func testMADReflectsSpread() {
        let key = "home|vacuuming"
        let records = [
            makeRecord(key: key, completedAt: dateAt(hour: 8, day: 1)),
            makeRecord(key: key, completedAt: dateAt(hour: 10, day: 2)),
            makeRecord(key: key, completedAt: dateAt(hour: 12, day: 3)),
        ]
        let prediction = CompletionTimePredictor.predict(forKey: key, from: records)!

        // Median = 10:00, deviations = [2h, 0, 2h], median deviation = 2h
        XCTAssertEqual(prediction.madSeconds, 2 * 3600, accuracy: 1)
    }

    // MARK: - Batch Predictions

    func testPredictAllGroupsByKey() {
        let key1 = "home|water plants"
        let key2 = "train|morning run"
        let records = [
            makeRecord(key: key1, completedAt: dateAt(hour: 9, day: 1)),
            makeRecord(key: key1, completedAt: dateAt(hour: 9, day: 2)),
            makeRecord(key: key1, completedAt: dateAt(hour: 9, day: 3)),
            makeRecord(key: key2, domain: .training, completedAt: dateAt(hour: 7, day: 1)),
            makeRecord(key: key2, domain: .training, completedAt: dateAt(hour: 7, day: 2)),
            makeRecord(key: key2, domain: .training, completedAt: dateAt(hour: 7, day: 3)),
        ]
        let predictions = CompletionTimePredictor.predict(from: records)
        XCTAssertEqual(predictions.count, 2)
        XCTAssertNotNil(predictions[key1])
        XCTAssertNotNil(predictions[key2])
    }

    func testPredictAllSkipsItemsBelowMinimum() {
        let key1 = "home|water plants"
        let key2 = "home|rare task"
        let records = [
            makeRecord(key: key1, completedAt: dateAt(hour: 9, day: 1)),
            makeRecord(key: key1, completedAt: dateAt(hour: 9, day: 2)),
            makeRecord(key: key1, completedAt: dateAt(hour: 9, day: 3)),
            makeRecord(key: key2, completedAt: dateAt(hour: 14, day: 1)),
        ]
        let predictions = CompletionTimePredictor.predict(from: records)
        XCTAssertEqual(predictions.count, 1)
        XCTAssertNil(predictions[key2])
    }

    // MARK: - Overdue Detection

    func testIsOverdueWhenPastDeadline() {
        let key = "home|water plants"
        let records = [
            makeRecord(key: key, completedAt: dateAt(hour: 9, day: 1)),
            makeRecord(key: key, completedAt: dateAt(hour: 9, day: 2)),
            makeRecord(key: key, completedAt: dateAt(hour: 9, day: 3)),
        ]
        let prediction = CompletionTimePredictor.predict(forKey: key, from: records)!

        // MAD is 0, so deadline = median (9:00 AM).
        // At 10:00 AM, item is overdue.
        let now = dateAt(hour: 10, day: 4)
        let today = dateAt(hour: 0, day: 4)
        XCTAssertTrue(prediction.isOverdue(now: now, on: today))
    }

    func testIsNotOverdueBeforeDeadline() {
        let key = "home|water plants"
        let records = [
            makeRecord(key: key, completedAt: dateAt(hour: 9, day: 1)),
            makeRecord(key: key, completedAt: dateAt(hour: 9, day: 2)),
            makeRecord(key: key, completedAt: dateAt(hour: 9, day: 3)),
        ]
        let prediction = CompletionTimePredictor.predict(forKey: key, from: records)!

        let now = dateAt(hour: 8, day: 4)
        let today = dateAt(hour: 0, day: 4)
        XCTAssertFalse(prediction.isOverdue(now: now, on: today))
    }

    // MARK: - Urgency Score

    func testUrgencyScoreIsZeroAtStartOfDay() {
        let key = "home|water plants"
        let records = [
            makeRecord(key: key, completedAt: dateAt(hour: 14, day: 1)),
            makeRecord(key: key, completedAt: dateAt(hour: 14, day: 2)),
            makeRecord(key: key, completedAt: dateAt(hour: 14, day: 3)),
        ]
        let prediction = CompletionTimePredictor.predict(forKey: key, from: records)!

        let now = dateAt(hour: 0, minute: 1, day: 4)
        let today = dateAt(hour: 0, day: 4)
        let score = prediction.urgencyScore(now: now, on: today)
        XCTAssertLessThan(score, 0.1)
    }

    func testUrgencyScoreIsOneAtExpectedTime() {
        let key = "home|water plants"
        let records = [
            makeRecord(key: key, completedAt: dateAt(hour: 14, day: 1)),
            makeRecord(key: key, completedAt: dateAt(hour: 14, day: 2)),
            makeRecord(key: key, completedAt: dateAt(hour: 14, day: 3)),
        ]
        let prediction = CompletionTimePredictor.predict(forKey: key, from: records)!

        let now = dateAt(hour: 14, day: 4)
        let today = dateAt(hour: 0, day: 4)
        let score = prediction.urgencyScore(now: now, on: today)
        XCTAssertEqual(score, 1.0, accuracy: 0.01)
    }

    func testUrgencyScoreExceedsOneWhenOverdue() {
        let key = "home|water plants"
        let records = [
            makeRecord(key: key, completedAt: dateAt(hour: 9, day: 1)),
            makeRecord(key: key, completedAt: dateAt(hour: 9, day: 2)),
            makeRecord(key: key, completedAt: dateAt(hour: 9, day: 3)),
        ]
        let prediction = CompletionTimePredictor.predict(forKey: key, from: records)!

        let now = dateAt(hour: 12, day: 4)
        let today = dateAt(hour: 0, day: 4)
        let score = prediction.urgencyScore(now: now, on: today)
        XCTAssertGreaterThan(score, 1.0)
    }

    // MARK: - Expected Completion Date

    func testExpectedCompletionDateOnGivenDay() {
        let key = "home|water plants"
        let records = [
            makeRecord(key: key, completedAt: dateAt(hour: 15, minute: 30, day: 1)),
            makeRecord(key: key, completedAt: dateAt(hour: 15, minute: 30, day: 2)),
            makeRecord(key: key, completedAt: dateAt(hour: 15, minute: 30, day: 3)),
        ]
        let prediction = CompletionTimePredictor.predict(forKey: key, from: records)!

        let queryDay = dateAt(hour: 0, day: 10)
        let expected = prediction.expectedCompletionDate(on: queryDay)
        let components = calendar.dateComponents([.hour, .minute, .day], from: expected)
        XCTAssertEqual(components.day, 10)
        XCTAssertEqual(components.hour, 15)
        XCTAssertEqual(components.minute, 30)
    }

    // MARK: - CompletionHistoryStore

    func testCompletionHistoryStoreLogAndPredict() {
        let repo = InMemoryItemListRepository<CompletionTimePredictor.CompletionRecord>()
        let store = CompletionHistoryStore(
            repository: repo,
            clock: FixedClock(now: dateAt(hour: 9, day: 4))
        )

        // Log 3 completions at 9 AM
        store.logHomeTaskCompletion(title: "Water plants", completedAt: dateAt(hour: 9, day: 1))
        store.logHomeTaskCompletion(title: "Water plants", completedAt: dateAt(hour: 9, day: 2))
        store.logHomeTaskCompletion(title: "Water plants", completedAt: dateAt(hour: 9, day: 3))

        let key = CompletionTimePredictor.key(forHomeTask: "Water plants")
        XCTAssertNotNil(store.predictions[key])
        XCTAssertEqual(store.predictions[key]?.sampleCount, 3)
    }

    func testCompletionHistoryStorePrunesOldRecords() {
        let repo = InMemoryItemListRepository<CompletionTimePredictor.CompletionRecord>()
        let store = CompletionHistoryStore(
            repository: repo,
            clock: FixedClock(now: dateAt(hour: 9, day: 40))
        )

        // Log 35 completions (exceeds maxRecordsPerKey of 30)
        for day in 1...35 {
            store.logHomeTaskCompletion(
                title: "Water plants",
                completedAt: dateAt(hour: 9, day: day)
            )
        }

        let key = CompletionTimePredictor.key(forHomeTask: "Water plants")
        XCTAssertEqual(store.predictions[key]?.sampleCount, 30)
    }
}
