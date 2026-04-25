import Foundation

struct ReminderScheduleTrace: Equatable {
    let candidateCount: Int
    let scheduledCount: Int
    let completedSuppressedCount: Int
    let deadlinePassedSuppressedCount: Int
    let canceledPendingCount: Int
    let failedCount: Int

    var suppressedCount: Int {
        completedSuppressedCount + deadlinePassedSuppressedCount
    }

    var telemetryMessage: String {
        [
            "reminder.schedule",
            "candidates=\(candidateCount)",
            "scheduled=\(scheduledCount)",
            "suppressed=\(suppressedCount)",
            "completed=\(completedSuppressedCount)",
            "deadlinePassed=\(deadlinePassedSuppressedCount)",
            "canceledPending=\(canceledPendingCount)",
            "failed=\(failedCount)",
        ].joined(separator: " ")
    }
}
