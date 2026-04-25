import Foundation

#if canImport(Combine)
    import Combine
#endif

@MainActor
final class PatternStore: OwloryObservableObject {
    #if canImport(Combine)
        @Published private(set) var weeklySnapshot: PatternSnapshot?
        @Published private(set) var latestDigest: WeeklyDigest?
        @Published var lastError: String?
    #else
        private(set) var weeklySnapshot: PatternSnapshot?
        private(set) var latestDigest: WeeklyDigest?
        var lastError: String?
    #endif

    private let entryRepository: any TodayEntryRangeRepository
    private let snapshotRepository: any PatternSnapshotRepository
    private let digestRepository: any ItemListRepository<WeeklyDigest>
    private let writingRepository: (any ItemListRepository<WritingNote>)?
    private let trainingRepository: (any ItemListRepository<TrainingSession>)?
    private let clock: Clock
    private let calendar: Calendar
    var weeklyDigestCalendar: Calendar { calendar }

    init(
        entryRepository: any TodayEntryRangeRepository,
        snapshotRepository: any PatternSnapshotRepository,
        digestRepository: any ItemListRepository<WeeklyDigest>,
        writingRepository: (any ItemListRepository<WritingNote>)? = nil,
        trainingRepository: (any ItemListRepository<TrainingSession>)? = nil,
        clock: Clock,
        calendar: Calendar = .current
    ) {
        self.entryRepository = entryRepository
        self.snapshotRepository = snapshotRepository
        self.digestRepository = digestRepository
        self.writingRepository = writingRepository
        self.trainingRepository = trainingRepository
        self.clock = clock
        self.calendar = calendar
    }

    func refresh() {
        PerformanceTelemetry.measure("PatternStore.refresh", category: .patterns) {
            do {
                let today = calendar.startOfDay(for: clock.now)
                guard let weekAgo = calendar.date(byAdding: .day, value: -6, to: today) else {
                    return
                }

                let entries = try entryRepository.loadEntries(from: weekAgo, through: today)

                let notes = try writingRepository?.loadAll()
                let sessions = try trainingRepository?.loadAll()

                let snapshot = PatternEngine.computeSnapshot(
                    entries: entries,
                    windowEnd: today,
                    windowDays: 7,
                    generatedAt: clock.now,
                    writingNotes: notes,
                    trainingSessions: sessions,
                    calendar: calendar
                )

                try snapshotRepository.saveSnapshot(snapshot)
                weeklySnapshot = snapshot
                lastError = nil

                // Generate weekly digest on Monday for previous Mon-Sun
                generateDigestIfNeeded()
            } catch {
                lastError = "Failed to compute patterns: \(error.localizedDescription)"
            }
        }
    }

    private func generateDigestIfNeeded() {
        PerformanceTelemetry.measure("PatternStore.generateDigestIfNeeded", category: .patterns) {
            guard let targetWindow = WeeklyDigestCadenceRules.targetWindow(
                for: clock.now,
                calendar: calendar
            ) else {
                loadLatestDigest()
                return
            }

            do {
                let existingDigests = try digestRepository.loadAll()

                if WeeklyDigestCadenceRules.hasGeneratedDigest(
                    for: targetWindow,
                    existingDigests: existingDigests,
                    calendar: calendar
                ) {
                    latestDigest = existingDigests.last
                    return
                }

                let entries = try entryRepository.loadEntries(
                    from: targetWindow.weekStarting,
                    through: targetWindow.weekEnding
                )

                if let digest = WeeklyDigestRules.generate(
                    entries: entries,
                    weekStarting: targetWindow.weekStarting,
                    weekEnding: targetWindow.weekEnding,
                    generatedAt: clock.now,
                    calendar: calendar
                ) {
                    var all = existingDigests
                    all.append(digest)
                    try digestRepository.saveAll(all)
                    latestDigest = digest
                } else {
                    latestDigest = existingDigests.last
                }
            } catch {
                lastError = "Failed to generate digest: \(error.localizedDescription)"
            }
        }
    }

    func loadAllDigests() throws -> [WeeklyDigest] {
        try PerformanceTelemetry.measure("PatternStore.loadAllDigests", category: .patterns) {
            try digestRepository.loadAll()
        }
    }

    private func loadLatestDigest() {
        PerformanceTelemetry.measure("PatternStore.loadLatestDigest", category: .patterns) {
            do {
                let digests = try digestRepository.loadAll()
                latestDigest = digests.last
            } catch {
                // Non-critical — digest display is optional
            }
        }
    }
}
