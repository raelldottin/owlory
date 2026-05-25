import Foundation

/// Decides which predictor keys must be suppressed when scheduling reminders
/// for today.
///
/// A prediction by itself is not enough to justify a reminder. The user only
/// expects a missed-window notification when there is something to act on right
/// now: a Train session for today still planned under that activity, or a Home
/// recurring task that is currently active under that title. Any prediction key
/// without a matching active item is treated as resolved-today.
///
/// This subsumes the prior policy of only adding terminal today-sessions to the
/// suppression set: a session in `.completed`, `.modified`, or `.skipped` is by
/// definition not `.planned`, so it falls out of the active set. It also closes
/// the stale-prediction gap, where a Train activity or Home recurring task that
/// has historical completions but no active item for today would still receive
/// a reminder.
enum ReminderSuppressionRules {
    static func suppressionKeys(
        predictionKeys: some Collection<String>,
        todayTrainingSessions: [TrainingSession],
        homeTasks: [HomeTask],
        completedHomeRuns: [ProtocolRun],
        now: Date,
        calendar: Calendar = .current
    ) -> Set<String> {
        let trainKeysWithActiveSession = Set(
            todayTrainingSessions
                .filter { $0.status == .planned }
                .map { CompletionTimePredictor.key(forTrainingSession: $0.plannedActivity) }
        )

        let homeKeysWithActiveTask = Set(
            homeTasks
                .filter { $0.isRecurring && !$0.isCompleted && !$0.isSkipped }
                .map { CompletionTimePredictor.key(forHomeTask: $0.title) }
        )

        let todayStart = calendar.startOfDay(for: now)
        let protocolKeysCompletedToday = Set(
            completedHomeRuns.compactMap { run -> String? in
                guard let completedAt = run.completedAt,
                      calendar.startOfDay(for: completedAt) == todayStart else { return nil }
                return CompletionTimePredictor.key(forProtocolRun: run.protocolTitle)
            }
        )

        var suppression = Set<String>()
        for key in predictionKeys {
            if key.hasPrefix("train|") {
                if !trainKeysWithActiveSession.contains(key) {
                    suppression.insert(key)
                }
            } else if key.hasPrefix("home|") {
                if !homeKeysWithActiveTask.contains(key) {
                    suppression.insert(key)
                }
            } else if key.hasPrefix("protocol|") {
                if protocolKeysCompletedToday.contains(key) {
                    suppression.insert(key)
                }
            }
        }
        return suppression
    }
}
