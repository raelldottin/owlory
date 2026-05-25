import XCTest
#if SWIFT_PACKAGE
@testable import OwloryCore
#endif

final class ReminderSuppressionRulesTests: XCTestCase {

    private func makeDate(_ string: String) -> Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: string)!
    }

    private let now = ISO8601DateFormatter().date(from: "2026-04-08T09:00:00Z")!

    // MARK: - Train

    func testTrainPredictionWithoutActivePlannedSessionIsSuppressed() {
        let key = CompletionTimePredictor.key(forTrainingSession: "Morning Run")
        let suppression = ReminderSuppressionRules.suppressionKeys(
            predictionKeys: [key],
            todayTrainingSessions: [],
            homeTasks: [],
            completedHomeRuns: [],
            now: now
        )
        XCTAssertEqual(
            suppression,
            [key],
            "A Train prediction with no planned today session must be suppressed; the user has nothing to act on."
        )
    }

    func testTrainPredictionFiresWhenPlannedSessionExistsForToday() {
        let key = CompletionTimePredictor.key(forTrainingSession: "Morning Run")
        let suppression = ReminderSuppressionRules.suppressionKeys(
            predictionKeys: [key],
            todayTrainingSessions: [
                TrainingSession(date: now, plannedActivity: "Morning Run", status: .planned)
            ],
            homeTasks: [],
            completedHomeRuns: [],
            now: now
        )
        XCTAssertTrue(
            suppression.isEmpty,
            "A Train prediction with a planned today session must not be suppressed; the reminder remains the user's nudge."
        )
    }

    func testTrainPredictionIsSuppressedForResolvedTodaySession() {
        let key = CompletionTimePredictor.key(forTrainingSession: "Morning Run")
        for terminalStatus: TrainingStatus in [.completed, .modified, .skipped] {
            let suppression = ReminderSuppressionRules.suppressionKeys(
                predictionKeys: [key],
                todayTrainingSessions: [
                    TrainingSession(date: now, plannedActivity: "Morning Run", status: terminalStatus)
                ],
                homeTasks: [],
                completedHomeRuns: [],
                now: now
            )
            XCTAssertEqual(
                suppression,
                [key],
                "A Train prediction whose only today session is .\(terminalStatus.rawValue) must be suppressed."
            )
        }
    }

    func testTrainPredictionFiresWhenAnyTodaySessionIsPlannedEvenIfAnotherIsResolved() {
        let key = CompletionTimePredictor.key(forTrainingSession: "Morning Run")
        let suppression = ReminderSuppressionRules.suppressionKeys(
            predictionKeys: [key],
            todayTrainingSessions: [
                TrainingSession(date: now, plannedActivity: "Morning Run", status: .completed),
                TrainingSession(date: now, plannedActivity: "Morning Run", status: .planned)
            ],
            homeTasks: [],
            completedHomeRuns: [],
            now: now
        )
        XCTAssertTrue(
            suppression.isEmpty,
            "If any today session for the activity is still planned, the reminder must still fire."
        )
    }

    // MARK: - Home

    func testHomePredictionWithoutActiveRecurringTaskIsSuppressed() {
        let key = CompletionTimePredictor.key(forHomeTask: "Water plants")
        let suppression = ReminderSuppressionRules.suppressionKeys(
            predictionKeys: [key],
            todayTrainingSessions: [],
            homeTasks: [],
            completedHomeRuns: [],
            now: now
        )
        XCTAssertEqual(
            suppression,
            [key],
            "A Home prediction with no recurring task today must be suppressed."
        )
    }

    func testHomePredictionFiresWhenActiveRecurringTaskMatchesTitle() {
        let key = CompletionTimePredictor.key(forHomeTask: "Water plants")
        let suppression = ReminderSuppressionRules.suppressionKeys(
            predictionKeys: [key],
            todayTrainingSessions: [],
            homeTasks: [
                HomeTask(title: "Water plants", isRecurring: true)
            ],
            completedHomeRuns: [],
            now: now
        )
        XCTAssertTrue(
            suppression.isEmpty,
            "A Home prediction whose recurring task is active today must not be suppressed."
        )
    }

    func testHomePredictionIsSuppressedWhenRecurringTaskIsCompletedToday() {
        let key = CompletionTimePredictor.key(forHomeTask: "Water plants")
        var task = HomeTask(title: "Water plants", isRecurring: true)
        task.isCompleted = true
        let suppression = ReminderSuppressionRules.suppressionKeys(
            predictionKeys: [key],
            todayTrainingSessions: [],
            homeTasks: [task],
            completedHomeRuns: [],
            now: now
        )
        XCTAssertEqual(suppression, [key])
    }

    func testHomePredictionIsSuppressedWhenRecurringTaskIsSkipped() {
        let key = CompletionTimePredictor.key(forHomeTask: "Water plants")
        var task = HomeTask(title: "Water plants", isRecurring: true)
        task.isSkipped = true
        let suppression = ReminderSuppressionRules.suppressionKeys(
            predictionKeys: [key],
            todayTrainingSessions: [],
            homeTasks: [task],
            completedHomeRuns: [],
            now: now
        )
        XCTAssertEqual(suppression, [key])
    }

    func testHomePredictionIsSuppressedWhenMatchingTaskIsNotRecurring() {
        let key = CompletionTimePredictor.key(forHomeTask: "Water plants")
        let suppression = ReminderSuppressionRules.suppressionKeys(
            predictionKeys: [key],
            todayTrainingSessions: [],
            homeTasks: [
                HomeTask(title: "Water plants", isRecurring: false)
            ],
            completedHomeRuns: [],
            now: now
        )
        XCTAssertEqual(
            suppression,
            [key],
            "Only a recurring task can carry a prediction key; a one-off task with the same title must not save the reminder."
        )
    }

    // MARK: - Protocol runs

    func testProtocolPredictionIsSuppressedForRunCompletedToday() {
        let title = "Wind down"
        let key = CompletionTimePredictor.key(forProtocolRun: title)
        let run = ProtocolRun(
            protocolID: UUID(),
            protocolTitle: title,
            createdAt: now,
            completedAt: now,
            steps: []
        )
        let suppression = ReminderSuppressionRules.suppressionKeys(
            predictionKeys: [key],
            todayTrainingSessions: [],
            homeTasks: [],
            completedHomeRuns: [run],
            now: now
        )
        XCTAssertEqual(suppression, [key])
    }

    func testProtocolPredictionIsNotSuppressedWhenNoRunCompletedToday() {
        let key = CompletionTimePredictor.key(forProtocolRun: "Wind down")
        let suppression = ReminderSuppressionRules.suppressionKeys(
            predictionKeys: [key],
            todayTrainingSessions: [],
            homeTasks: [],
            completedHomeRuns: [],
            now: now
        )
        XCTAssertTrue(
            suppression.isEmpty,
            "Protocol suppression hinges on a run completed today; with no completed run, the reminder is allowed to fire."
        )
    }
}
