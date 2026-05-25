import XCTest
import UserNotifications
#if SWIFT_PACKAGE
@testable import OwloryCore
#endif

/// Simulator integration proof for the user-reported bug where Train and Home
/// items still received "missed window" notifications after their status went
/// terminal. Domain tests only verified that the stores call the
/// `onItemCompleted` callback for terminal statuses; this suite drives the real
/// `UNUserNotificationCenter` on the iOS simulator to prove the cancel chain
/// actually removes the pending request.
///
/// Skipped automatically (not failed) when the simulator's notification settings
/// will not authorize the test process — for example, on a clean simulator that
/// has never granted authorization for the host bundle. Run on a simulator with
/// notifications allowed for the Owlory test host.
@MainActor
final class ReminderSchedulerTerminalStatusCancelIntegrationTests: XCTestCase {

    private let center = UNUserNotificationCenter.current()
    private let scheduler = ReminderScheduler()

    override func setUp() async throws {
        try await super.setUp()
        let granted = try await center.requestAuthorization(options: [.provisional])
        try XCTSkipUnless(
            granted,
            "Provisional notification authorization was denied for the test host. "
                + "Grant notifications for the Owlory test bundle on the simulator and re-run."
        )
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    override func tearDown() async throws {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
        try await super.tearDown()
    }

    // MARK: - Train

    func testSkippingTrainSessionRemovesPendingReminder() async throws {
        try await assertTerminalTrainStatusRemovesPendingReminder(.skipped)
    }

    func testCompletingTrainSessionRemovesPendingReminder() async throws {
        try await assertTerminalTrainStatusRemovesPendingReminder(.completed)
    }

    func testModifyingTrainSessionRemovesPendingReminder() async throws {
        try await assertTerminalTrainStatusRemovesPendingReminder(.modified)
    }

    func testRevertingTrainSessionToPlannedLeavesPendingReminder() async throws {
        let activity = uniqueActivity("Reverted morning run")
        let identifier = try await schedulePendingReminderForTrainSession(named: activity)

        let store = makeTrainStore()
        store.addSession(plannedActivity: activity)
        let sessionId = store.sessions[0].id

        store.updateSession(
            id: sessionId,
            actualActivity: "",
            status: .planned,
            reflection: ""
        )

        try await waitForCancelTask()

        let pending = await center.pendingNotificationRequests()
        XCTAssertTrue(
            pending.contains { $0.identifier == identifier },
            ".planned is non-terminal and must leave the pending reminder in place."
        )
    }

    // MARK: - Home

    func testSkippingRecurringHomeTaskRemovesPendingReminder() async throws {
        try await assertTerminalHomeTaskActionRemovesPendingReminder { store, id in
            store.skipTask(id: id)
        }
    }

    func testCompletingRecurringHomeTaskRemovesPendingReminder() async throws {
        try await assertTerminalHomeTaskActionRemovesPendingReminder { store, id in
            store.toggleComplete(id: id)
        }
    }

    // MARK: - Shared assertions

    private func assertTerminalTrainStatusRemovesPendingReminder(
        _ status: TrainingStatus,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let activity = uniqueActivity("Morning run \(status.rawValue)")
        let identifier = try await schedulePendingReminderForTrainSession(named: activity)

        let store = makeTrainStore()
        store.addSession(plannedActivity: activity)
        let sessionId = store.sessions[0].id

        store.updateSession(
            id: sessionId,
            actualActivity: "",
            status: status,
            reflection: ""
        )

        try await waitForCancelTask()

        let pending = await center.pendingNotificationRequests()
        XCTAssertFalse(
            pending.contains { $0.identifier == identifier },
            "Train status .\(status.rawValue) is a terminal user disposition and must remove the pending reminder. "
                + "The pending list still contains \(identifier).",
            file: file,
            line: line
        )
    }

    private func assertTerminalHomeTaskActionRemovesPendingReminder(
        action: (HomeStore, UUID) -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let title = uniqueActivity("Water plants")
        let identifier = try await schedulePendingReminderForHomeTask(titled: title)

        let store = makeHomeStore()
        store.addTask(title: title, isRecurring: true)
        let taskId = store.tasks[0].id

        action(store, taskId)

        try await waitForCancelTask()

        let pending = await center.pendingNotificationRequests()
        XCTAssertFalse(
            pending.contains { $0.identifier == identifier },
            "Home recurring task action that resolves the task must remove the pending reminder. "
                + "The pending list still contains \(identifier).",
            file: file,
            line: line
        )
    }

    // MARK: - Fixture helpers

    private func uniqueActivity(_ base: String) -> String {
        "\(base) \(UUID().uuidString.prefix(8))"
    }

    private func schedulePendingReminderForTrainSession(named activity: String) async throws -> String {
        let key = CompletionTimePredictor.key(forTrainingSession: activity)
        return try await schedulePendingReminder(forKey: key)
    }

    private func schedulePendingReminderForHomeTask(titled title: String) async throws -> String {
        let key = CompletionTimePredictor.key(forHomeTask: title)
        return try await schedulePendingReminder(forKey: key)
    }

    private func schedulePendingReminder(forKey key: String) async throws -> String {
        let identifier = "owlory.reminder.\(key)"
        let content = UNMutableNotificationContent()
        content.title = "Integration test pending reminder"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        try await center.add(request)

        let pending = await center.pendingNotificationRequests()
        try XCTSkipUnless(
            pending.contains { $0.identifier == identifier },
            "Setup did not register the pending request \(identifier). "
                + "Authorization may have silently dropped it on this simulator."
        )
        return identifier
    }

    private func makeTrainStore() -> TrainStore {
        let scheduler = self.scheduler
        return TrainStore(
            repository: InMemoryItemListRepository<TrainingSession>(),
            clock: FixedClock(now: Date()),
            onItemCompleted: { key in
                Task { @MainActor in scheduler.cancelReminder(forKey: key) }
            }
        )
    }

    private func makeHomeStore() -> HomeStore {
        let scheduler = self.scheduler
        return HomeStore(
            taskRepository: InMemoryItemListRepository<HomeTask>(),
            protocolRepository: InMemoryItemListRepository<HouseholdProtocol>(),
            runRepository: InMemoryItemListRepository<ProtocolRun>(),
            clock: FixedClock(now: Date()),
            onItemCompleted: { key in
                Task { @MainActor in scheduler.cancelReminder(forKey: key) }
            }
        )
    }

    private func waitForCancelTask() async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
    }
}
