import Foundation
import UserNotifications

/// Schedules local notifications for recurring items that are approaching
/// or past their statistically predicted completion time.
///
/// Notifications are re-scheduled when app wiring calls `reschedule`, currently
/// on launch and foreground entry. The scheduler clears existing Owlory
/// reminders before adding current ones, so it never leaves more than one
/// pending notification per item key.
@MainActor
final class ReminderScheduler {
    struct NotificationSpec: Codable, Equatable {
        let identifier: String
        let kind: String
        let title: String
        let body: String
        let deadline: Date
        let deepLinkURL: URL?
    }

    struct PlannedNotifications: Equatable {
        let specs: [NotificationSpec]
        let candidateCount: Int
        let completedSuppressedCount: Int
        let deadlinePassedSuppressedCount: Int
        var protocolScheduleCount: Int = 0
    }

    private let center = UNUserNotificationCenter.current()
    private let notificationCategoryID = "OWLORY_OVERDUE_REMINDER"

    func setNotificationResponseDelegate(_ delegate: UNUserNotificationCenterDelegate) {
        center.delegate = delegate
    }

    // MARK: - Authorization

    /// Request notification permission. Safe to call repeatedly — the OS
    /// only shows the prompt once.
    func requestAuthorization() {
        Task {
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                if granted {
                    await registerCategories()
                }
            } catch {
                PerformanceTelemetry.notice(
                    "Notification authorization failed: \(error.localizedDescription)",
                    category: .appLifecycle
                )
            }
        }
    }

    // MARK: - Scheduling

    /// Re-schedule notifications for all items with predictions.
    /// Cancels stale notifications and creates new ones for items that
    /// have not yet been completed today.
    func reschedule(
        predictions: [String: CompletionTimePredictor.Prediction],
        completedKeys: Set<String>,
        promptNotifications: [TodayStore.PromptNotification] = [],
        protocolSchedulePlans: [ProtocolScheduleNotificationRules.Plan] = [],
        now: Date = Date()
    ) {
        Task {
            let settings = await center.notificationSettings()
            guard settings.authorizationStatus == .authorized else { return }

            // Remove all Owlory-scheduled reminders, then re-add current ones.
            let pendingRequests = await center.pendingNotificationRequests()
            let owloryIDs = pendingRequests
                .filter {
                    $0.identifier.hasPrefix("owlory.reminder.")
                    || $0.identifier.hasPrefix("owlory.protocol-schedule.")
                }
                .map(\.identifier)
            center.removePendingNotificationRequests(withIdentifiers: owloryIDs)

            let calendar = Calendar.current
            let plan = plannedNotifications(
                predictions: predictions,
                completedKeys: completedKeys,
                promptNotifications: promptNotifications,
                protocolSchedulePlans: protocolSchedulePlans,
                now: now,
                calendar: calendar
            )
            var scheduledCount = 0
            var failedCount = 0

            for reminder in plan.specs {
                let content = UNMutableNotificationContent()
                content.title = reminder.title
                content.body = reminder.body
                content.sound = .default
                content.categoryIdentifier = notificationCategoryID
                if let deepLinkURL = reminder.deepLinkURL {
                    content.userInfo[OwloryDeepLink.notificationUserInfoKey] = deepLinkURL.absoluteString
                }

                let components = calendar.dateComponents(
                    [.year, .month, .day, .hour, .minute],
                    from: reminder.deadline
                )
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: components,
                    repeats: false
                )

                let request = UNNotificationRequest(
                    identifier: reminder.identifier,
                    content: content,
                    trigger: trigger
                )

                do {
                    try await center.add(request)
                    scheduledCount += 1
                } catch {
                    failedCount += 1
                    PerformanceTelemetry.notice(
                        "Failed to schedule reminder for \(reminder.identifier): \(error.localizedDescription)",
                        category: .appLifecycle
                    )
                }
            }

            let trace = ReminderScheduleTrace(
                candidateCount: plan.candidateCount,
                scheduledCount: scheduledCount,
                completedSuppressedCount: plan.completedSuppressedCount,
                deadlinePassedSuppressedCount: plan.deadlinePassedSuppressedCount,
                canceledPendingCount: owloryIDs.count,
                failedCount: failedCount,
                protocolScheduleCount: plan.protocolScheduleCount
            )
            PerformanceTelemetry.notice(trace.telemetryMessage, category: .reminders)
        }
    }

    /// Cancel a specific item's pending notification (e.g., when completed).
    func cancelReminder(forKey key: String) {
        center.removePendingNotificationRequests(
            withIdentifiers: [notificationIdentifier(for: key)]
        )
    }

    func plannedNotifications(
        predictions: [String: CompletionTimePredictor.Prediction],
        completedKeys: Set<String>,
        promptNotifications: [TodayStore.PromptNotification] = [],
        protocolSchedulePlans: [ProtocolScheduleNotificationRules.Plan] = [],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> PlannedNotifications {
        let overduePlan = ReminderSchedulingRules.plan(
            predictions: predictions,
            completedKeys: completedKeys,
            now: now,
            calendar: calendar
        )

        let filteredSchedulePlans = ReminderSchedulingRules.filteredProtocolSchedulePlans(
            protocolSchedulePlans,
            now: now
        )

        var specs = overduePlan.scheduledReminders.map { reminder in
            NotificationSpec(
                identifier: notificationIdentifier(for: reminder.key),
                kind: "prediction",
                title: "Reminder",
                body: readableTitle(from: reminder.key),
                deadline: reminder.deadline,
                deepLinkURL: OwloryDeepLink.url(for: .completionKey(reminder.key))
            )
        }

        specs.append(
            contentsOf: promptNotifications
                .filter { $0.deadline > now }
                .map { prompt in
                    NotificationSpec(
                        identifier: notificationIdentifier(for: prompt.id),
                        kind: prompt.kind.rawValue,
                        title: prompt.title,
                        body: prompt.body,
                        deadline: prompt.deadline,
                        deepLinkURL: OwloryDeepLink.url(
                            for: .todayPrompt(kind: prompt.kind.rawValue)
                        )
                    )
                }
        )

        specs.append(
            contentsOf: filteredSchedulePlans.map { plan in
                NotificationSpec(
                    identifier: plan.identifier,
                    kind: plan.kind.rawValue,
                    title: protocolScheduleTitle(for: plan.kind),
                    body: protocolScheduleBody(for: plan),
                    deadline: plan.fireDate,
                    deepLinkURL: nil
                )
            }
        )

        specs.sort {
            if $0.deadline == $1.deadline {
                return $0.identifier < $1.identifier
            }
            return $0.deadline < $1.deadline
        }

        return PlannedNotifications(
            specs: specs,
            candidateCount: predictions.count + promptNotifications.count
                + protocolSchedulePlans.count,
            completedSuppressedCount: overduePlan.completedTodaySuppressionCount,
            deadlinePassedSuppressedCount: overduePlan.deadlinePassedSuppressionCount,
            protocolScheduleCount: filteredSchedulePlans.count
        )
    }

    /// Cancel all Owlory reminders and protocol schedule notifications.
    func cancelAll() {
        Task {
            let pending = await center.pendingNotificationRequests()
            let ids = pending
                .filter {
                    $0.identifier.hasPrefix("owlory.reminder.")
                    || $0.identifier.hasPrefix("owlory.protocol-schedule.")
                }
                .map(\.identifier)
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    func cancelProtocolScheduleNotifications(forProtocolID protocolID: UUID) {
        let ids = ProtocolScheduleNotificationRules.Kind.allCases.map {
            ProtocolScheduleNotificationRules.identifier(protocolID: protocolID, kind: $0)
        }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - Private

    private func notificationIdentifier(for key: String) -> String {
        "owlory.reminder.\(key)"
    }

    /// Extract a human-readable title from the prediction key.
    /// Keys are formatted as "home|water plants" or "train|morning run".
    private func readableTitle(from key: String) -> String {
        let parts = key.split(separator: "|", maxSplits: 1)
        guard parts.count == 2 else { return "You have an overdue item." }

        let domain = parts[0]
        let title = String(parts[1])
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Capitalize the first letter of the title.
        let capitalizedTitle = title.prefix(1).uppercased() + title.dropFirst()

        switch domain {
        case "home":
            return "\(capitalizedTitle) — usually done by now."
        case "train":
            return "\(capitalizedTitle) — your usual training window passed."
        case "protocol":
            return "\(capitalizedTitle) — protocol run is overdue."
        default:
            return "\(capitalizedTitle) — still pending."
        }
    }

    private func protocolScheduleTitle(
        for kind: ProtocolScheduleNotificationRules.Kind
    ) -> String {
        switch kind {
        case .windowOpening:
            return "Protocol Window Opens"
        case .overdue:
            return "Protocol Window Passed"
        }
    }

    private func protocolScheduleBody(
        for plan: ProtocolScheduleNotificationRules.Plan
    ) -> String {
        switch plan.kind {
        case .windowOpening:
            return "\(plan.title) — scheduled window starts today."
        case .overdue:
            return "\(plan.title) — schedule window ended without a run."
        }
    }

    private func registerCategories() async {
        let category = UNNotificationCategory(
            identifier: notificationCategoryID,
            actions: [],
            intentIdentifiers: []
        )
        center.setNotificationCategories([category])
    }
}
