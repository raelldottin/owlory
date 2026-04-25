import SwiftUI

@main
struct OwloryApp: App {
    private let metricKitTelemetrySubscriber = MetricKitTelemetrySubscriber()
    private let reminderScheduler = ReminderScheduler()

    @StateObject private var deepLinkRouter: OwloryDeepLinkRouter
    @StateObject private var completionHistory: CompletionHistoryStore
    @StateObject private var todayStore: TodayStore
    @StateObject private var trainStore: TrainStore
    @StateObject private var writeStore: WriteStore
    @StateObject private var careerStore: CareerStore
    @StateObject private var homeStore: HomeStore
    @StateObject private var patternStore: PatternStore

    init() {
        let router = OwloryDeepLinkRouter()
        _deepLinkRouter = StateObject(wrappedValue: router)

        metricKitTelemetrySubscriber.start()

        let history = CompletionHistoryStore(
            repository: FileItemListRepository<CompletionTimePredictor.CompletionRecord>(
                directory: "Completion", fileName: "records"),
            clock: SystemClock()
        )
        _completionHistory = StateObject(wrappedValue: history)

        _todayStore = StateObject(wrappedValue: TodayStore(
            clock: SystemClock(),
            repository: FileTodayEntryRepository()
        ))

        _trainStore = StateObject(wrappedValue: TrainStore(
            repository: FileItemListRepository<TrainingSession>(
                directory: "Train", fileName: "sessions"),
            clock: SystemClock(),
            completionHistory: history
        ))

        _writeStore = StateObject(wrappedValue: WriteStore(
            repository: FileItemListRepository<WritingNote>(
                directory: "Write", fileName: "notes")
        ))

        _careerStore = StateObject(wrappedValue: CareerStore(
            repository: FileItemListRepository<CareerRecord>(
                directory: "Career", fileName: "records")
        ))

        _homeStore = StateObject(wrappedValue: HomeStore(
            taskRepository: FileItemListRepository<HomeTask>(
                directory: "Home", fileName: "tasks"),
            protocolRepository: FileItemListRepository<HouseholdProtocol>(
                directory: "Home", fileName: "protocols"),
            runRepository: FileItemListRepository<ProtocolRun>(
                directory: "Home", fileName: "runs"),
            clock: SystemClock(),
            completionHistory: history
        ))

        _patternStore = StateObject(wrappedValue: PatternStore(
            entryRepository: FileTodayEntryRepository(),
            snapshotRepository: FilePatternSnapshotRepository(),
            digestRepository: FileItemListRepository<WeeklyDigest>(
                directory: "Digests", fileName: "digests"),
            writingRepository: FileItemListRepository<WritingNote>(
                directory: "Write", fileName: "notes"),
            trainingRepository: FileItemListRepository<TrainingSession>(
                directory: "Train", fileName: "sessions"),
            clock: SystemClock()
        ))

        reminderScheduler.setNotificationResponseDelegate(router)
        reminderScheduler.requestAuthorization()

        PerformanceTelemetry.notice(
            "Owlory app initialized — \(BuildInfo.current.summary) [\(BuildInfo.current.buildConfiguration)]",
            category: .appLifecycle
        )
    }

    var body: some Scene {
        WindowGroup {
            RootTabView(
                todayStore: todayStore,
                trainStore: trainStore,
                writeStore: writeStore,
                careerStore: careerStore,
                homeStore: homeStore,
                patternStore: patternStore,
                completionHistory: completionHistory,
                reminderScheduler: reminderScheduler,
                deepLinkRouter: deepLinkRouter
            )
        }
    }
}
