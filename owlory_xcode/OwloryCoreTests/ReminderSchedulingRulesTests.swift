import XCTest

final class ReminderSchedulingRulesTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testPlanSchedulesEligiblePredictionAtMedianPlusMAD() {
        let key = "home|water plants"
        let prediction = makePrediction(key: key, medianHour: 9, madMinutes: 30)
        let now = dateAt(hour: 8, minute: 0)

        let plan = ReminderSchedulingRules.plan(
            predictions: [key: prediction],
            completedKeys: [],
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(plan.scheduledReminders, [
            ReminderSchedulingRules.ScheduledReminder(
                key: key,
                deadline: dateAt(hour: 9, minute: 30)
            )
        ])
        XCTAssertTrue(plan.suppressedReminders.isEmpty)
    }

    func testCompletedTodaySuppressesBeforeDeadlineEvaluation() {
        let key = "train|morning run"
        let prediction = makePrediction(key: key, medianHour: 9, madMinutes: 30)
        let now = dateAt(hour: 12, minute: 0)

        let plan = ReminderSchedulingRules.plan(
            predictions: [key: prediction],
            completedKeys: [key],
            now: now,
            calendar: calendar
        )

        XCTAssertTrue(plan.scheduledReminders.isEmpty)
        XCTAssertEqual(plan.suppressedReminders, [
            ReminderSchedulingRules.SuppressedReminder(key: key, reason: .completedToday)
        ])
        XCTAssertEqual(plan.completedTodaySuppressionCount, 1)
        XCTAssertEqual(plan.deadlinePassedSuppressionCount, 0)
    }

    func testDeadlineAtOrBeforeNowIsSuppressed() {
        let key = "protocol|kitchen reset"
        let prediction = makePrediction(key: key, medianHour: 9, madMinutes: 30)

        let plan = ReminderSchedulingRules.plan(
            predictions: [key: prediction],
            completedKeys: [],
            now: dateAt(hour: 9, minute: 30),
            calendar: calendar
        )

        XCTAssertTrue(plan.scheduledReminders.isEmpty)
        XCTAssertEqual(plan.suppressedReminders, [
            ReminderSchedulingRules.SuppressedReminder(key: key, reason: .deadlinePassed)
        ])
        XCTAssertEqual(plan.deadlinePassedSuppressionCount, 1)
    }

    func testPlanOrdersScheduledRemindersByKey() {
        let predictions = [
            "train|morning run": makePrediction(key: "train|morning run", medianHour: 10),
            "home|laundry": makePrediction(key: "home|laundry", medianHour: 11),
        ]

        let plan = ReminderSchedulingRules.plan(
            predictions: predictions,
            completedKeys: [],
            now: dateAt(hour: 8, minute: 0),
            calendar: calendar
        )

        XCTAssertEqual(plan.scheduledReminders.map(\.key), [
            "home|laundry",
            "train|morning run",
        ])
    }

    func testReminderScheduleTraceUsesStableTelemetryMetadata() {
        let trace = ReminderScheduleTrace(
            candidateCount: 4,
            scheduledCount: 1,
            completedSuppressedCount: 1,
            deadlinePassedSuppressedCount: 1,
            canceledPendingCount: 2,
            failedCount: 1
        )

        XCTAssertEqual(
            trace.telemetryMessage,
            "reminder.schedule candidates=4 scheduled=1 suppressed=2 completed=1 deadlinePassed=1 canceledPending=2 failed=1 protocolSchedule=0"
        )
    }

    func testDeepLinkRoundTripsCompletionKey() throws {
        let key = "home|water plants"
        let url = try XCTUnwrap(OwloryDeepLink.url(for: .completionKey(key)))

        XCTAssertEqual(OwloryDeepLink.parse(url), .completionKey(key))
        XCTAssertEqual(OwloryDeepLink.completionKeyDomain(key), "home")
    }

    func testDeepLinkRoundTripsTodayPrompt() throws {
        let url = try XCTUnwrap(OwloryDeepLink.url(for: .todayPrompt(kind: "check-in")))

        XCTAssertEqual(OwloryDeepLink.parse(url), .todayPrompt(kind: "check-in"))
    }

    func testNotificationCopyUsesLocalizedPredictionMessages() {
        XCTAssertEqual(
            ReminderNotificationCopy.predictionCopy(for: "home|water plants"),
            ReminderNotificationCopy.Copy(
                title: "Reminder",
                body: "Water plants — usually done by now."
            )
        )
        XCTAssertEqual(
            ReminderNotificationCopy.predictionCopy(for: "train|morning run").body,
            "Morning run — your usual training window passed."
        )
        XCTAssertEqual(
            ReminderNotificationCopy.predictionCopy(for: "protocol|kitchen reset").body,
            "Kitchen reset — protocol run is overdue."
        )
        XCTAssertEqual(
            ReminderNotificationCopy.predictionCopy(for: "write|draft note").body,
            "Draft note — still pending."
        )
        XCTAssertEqual(
            ReminderNotificationCopy.predictionCopy(for: "malformed").body,
            "You have an overdue item."
        )
    }

    func testNotificationCopyUsesLocalizedPromptAndProtocolMessages() {
        XCTAssertEqual(
            ReminderNotificationCopy.promptCopy(for: .checkIn),
            ReminderNotificationCopy.Copy(
                title: "Check-in",
                body: "Take a quick read on energy, mood, and sleep."
            )
        )
        XCTAssertEqual(
            ReminderNotificationCopy.promptCopy(for: .homeWrappedReflection),
            ReminderNotificationCopy.Copy(
                title: "Home wrapped",
                body: "All home tasks are done. Close the day with one quick reflection."
            )
        )

        let protocolID = UUID()
        let opening = ProtocolScheduleNotificationRules.Plan(
            protocolID: protocolID,
            title: "Kitchen reset",
            kind: .windowOpening,
            fireDate: dateAt(hour: 8, minute: 0),
            identifier: ProtocolScheduleNotificationRules.identifier(
                protocolID: protocolID,
                kind: .windowOpening
            )
        )

        XCTAssertEqual(
            ReminderNotificationCopy.protocolScheduleCopy(for: opening),
            ReminderNotificationCopy.Copy(
                title: "Protocol Window Opens",
                body: "Kitchen reset — scheduled window starts today."
            )
        )
    }

    @MainActor
    func testPlannedNotificationsCarryDeepLinksForPredictionAndPrompt() throws {
        let key = "train|morning run"
        let prediction = makePrediction(key: key, medianHour: 10)
        let now = dateAt(hour: 8, minute: 0)
        let prompt = TodayStore.PromptNotification(
            id: "today.check-in",
            kind: .checkIn,
            title: "Check-in",
            body: "Take a quick read on energy, mood, and sleep.",
            deadline: dateAt(hour: 9, minute: 0)
        )

        let plan = ReminderScheduler().plannedNotifications(
            predictions: [key: prediction],
            completedKeys: [],
            promptNotifications: [prompt],
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(
            plan.specs.map(\.deepLinkURL).compactMap { $0 }.compactMap(OwloryDeepLink.parse),
            [
                .todayPrompt(kind: "check-in"),
                .completionKey(key),
            ]
        )
    }

    @MainActor
    func testPlannedNotificationsUseRuntimeNotificationCopy() throws {
        let key = "home|water plants"
        let prediction = makePrediction(key: key, medianHour: 10)
        let now = dateAt(hour: 8, minute: 0)
        let prompt = TodayStore.PromptNotification(
            id: "today.check-in",
            kind: .checkIn,
            title: "Unlocalized prompt title should not leak",
            body: "Unlocalized prompt body should not leak",
            deadline: dateAt(hour: 9, minute: 0)
        )
        let protocolID = UUID()
        let protocolPlan = ProtocolScheduleNotificationRules.Plan(
            protocolID: protocolID,
            title: "Kitchen reset",
            kind: .overdue,
            fireDate: dateAt(hour: 11, minute: 0),
            identifier: ProtocolScheduleNotificationRules.identifier(
                protocolID: protocolID,
                kind: .overdue
            )
        )

        let plan = ReminderScheduler().plannedNotifications(
            predictions: [key: prediction],
            completedKeys: [],
            promptNotifications: [prompt],
            protocolSchedulePlans: [protocolPlan],
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(plan.specs.map(\.title), [
            "Check-in",
            "Reminder",
            "Protocol Window Passed",
        ])
        XCTAssertEqual(plan.specs.map(\.body), [
            "Take a quick read on energy, mood, and sleep.",
            "Water plants — usually done by now.",
            "Kitchen reset — schedule window ended without a run.",
        ])
    }

    private func makePrediction(
        key: String,
        medianHour: Int,
        madMinutes: Int = 0
    ) -> CompletionTimePredictor.Prediction {
        CompletionTimePredictor.Prediction(
            itemKey: key,
            medianTimeOfDay: TimeInterval(medianHour * 3600),
            madSeconds: TimeInterval(madMinutes * 60),
            sampleCount: 3
        )
    }

    private func dateAt(hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = 2026
        components.month = 4
        components.day = 17
        components.hour = hour
        components.minute = minute
        return components.date!
    }
}
