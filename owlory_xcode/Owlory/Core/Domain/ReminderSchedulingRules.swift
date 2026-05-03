import Foundation

enum ReminderSchedulingRules {
    enum SuppressionReason: Equatable {
        case completedToday
        case deadlinePassed
    }

    struct ScheduledReminder: Equatable {
        let key: String
        let deadline: Date
    }

    struct SuppressedReminder: Equatable {
        let key: String
        let reason: SuppressionReason
    }

    struct Plan: Equatable {
        let scheduledReminders: [ScheduledReminder]
        let suppressedReminders: [SuppressedReminder]

        var completedTodaySuppressionCount: Int {
            suppressionCount(for: .completedToday)
        }

        var deadlinePassedSuppressionCount: Int {
            suppressionCount(for: .deadlinePassed)
        }

        private func suppressionCount(for reason: SuppressionReason) -> Int {
            suppressedReminders.filter { $0.reason == reason }.count
        }
    }

    static func plan(
        predictions: [String: CompletionTimePredictor.Prediction],
        completedKeys: Set<String>,
        now: Date,
        calendar: Calendar = .current
    ) -> Plan {
        let todayStart = calendar.startOfDay(for: now)
        var scheduled: [ScheduledReminder] = []
        var suppressed: [SuppressedReminder] = []

        for key in predictions.keys.sorted() {
            guard let prediction = predictions[key] else { continue }

            if completedKeys.contains(key) {
                suppressed.append(SuppressedReminder(key: key, reason: .completedToday))
                continue
            }

            let deadline = reminderDeadline(
                for: prediction,
                on: todayStart,
                calendar: calendar
            )

            guard deadline > now else {
                suppressed.append(SuppressedReminder(key: key, reason: .deadlinePassed))
                continue
            }

            scheduled.append(ScheduledReminder(key: key, deadline: deadline))
        }

        return Plan(
            scheduledReminders: scheduled,
            suppressedReminders: suppressed
        )
    }

    static func reminderDeadline(
        for prediction: CompletionTimePredictor.Prediction,
        on day: Date,
        calendar: Calendar = .current
    ) -> Date {
        prediction.expectedCompletionDate(on: day, calendar: calendar)
            .addingTimeInterval(prediction.madSeconds)
    }

    static func filteredProtocolSchedulePlans(
        _ plans: [ProtocolScheduleNotificationRules.Plan],
        now: Date
    ) -> [ProtocolScheduleNotificationRules.Plan] {
        plans.filter { $0.fireDate > now }
    }
}
