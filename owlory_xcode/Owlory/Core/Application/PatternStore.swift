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
    private let homeRunRepository: (any ItemListRepository<ProtocolRun>)?
    private let clock: Clock
    private let calendar: Calendar
    var weeklyDigestCalendar: Calendar { calendar }

    init(
        entryRepository: any TodayEntryRangeRepository,
        snapshotRepository: any PatternSnapshotRepository,
        digestRepository: any ItemListRepository<WeeklyDigest>,
        writingRepository: (any ItemListRepository<WritingNote>)? = nil,
        trainingRepository: (any ItemListRepository<TrainingSession>)? = nil,
        homeRunRepository: (any ItemListRepository<ProtocolRun>)? = nil,
        clock: Clock,
        calendar: Calendar = .current
    ) {
        self.entryRepository = entryRepository
        self.snapshotRepository = snapshotRepository
        self.digestRepository = digestRepository
        self.writingRepository = writingRepository
        self.trainingRepository = trainingRepository
        self.homeRunRepository = homeRunRepository
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

                if let existingIndex = matchingDigestIndex(
                    in: existingDigests,
                    weekStarting: targetWindow.weekStarting
                ) {
                    if isLatestDigestIndex(existingIndex, in: existingDigests) {
                        latestDigest = try refreshLatestDigestIfNeeded(
                            existingDigests[existingIndex],
                            in: existingDigests
                        )
                    } else {
                        latestDigest = latestDigest(in: existingDigests)
                    }
                    return
                }

                if let digest = try makeDigest(
                    weekStarting: targetWindow.weekStarting,
                    weekEnding: targetWindow.weekEnding,
                    generatedAt: clock.now
                ) {
                    var all = existingDigests
                    all.append(digest)
                    try digestRepository.saveAll(all)
                    latestDigest = digest
                } else {
                    latestDigest = latestDigest(in: existingDigests)
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
                guard let latest = latestDigest(in: digests) else {
                    latestDigest = nil
                    return
                }

                latestDigest = try refreshLatestDigestIfNeeded(latest, in: digests)
            } catch {
                // Non-critical — digest display is optional
            }
        }
    }

    private func makeDigest(
        weekStarting: Date,
        weekEnding: Date,
        generatedAt: Date
    ) throws -> WeeklyDigest? {
        let entries = try entryRepository.loadEntries(from: weekStarting, through: weekEnding)
        let protocolRuns = try homeRunRepository?.loadAll() ?? []

        return WeeklyDigestRules.generate(
            entries: entries,
            weekStarting: weekStarting,
            weekEnding: weekEnding,
            generatedAt: generatedAt,
            protocolRuns: protocolRuns,
            calendar: calendar
        )
    }

    private func refreshLatestDigestIfNeeded(
        _ digest: WeeklyDigest,
        in digests: [WeeklyDigest]
    ) throws -> WeeklyDigest {
        guard isLatestDigest(digest, in: digests) else {
            return digest
        }

        guard let index = matchingDigestIndex(
            in: digests,
            weekStarting: digest.weekStarting
        ),
            let regenerated = try makeDigest(
                weekStarting: digest.weekStarting,
                weekEnding: digest.weekEnding,
                generatedAt: digest.generatedAt
            )
        else {
            return digest
        }

        let refreshed = regenerated.withStableID(digest.id)
        let isVersionStale = !WeeklyDigestRules.usesCurrentDigestRuleVersion(digest)
        guard isVersionStale || refreshed != digest else {
            return digest
        }

        var updated = digests
        updated[index] = refreshed
        try digestRepository.saveAll(updated)
        return refreshed
    }

    private func matchingDigestIndex(
        in digests: [WeeklyDigest],
        weekStarting: Date
    ) -> Int? {
        let targetStart = calendar.startOfDay(for: weekStarting)
        return digests.firstIndex {
            calendar.startOfDay(for: $0.weekStarting) == targetStart
        }
    }

    private func latestDigest(in digests: [WeeklyDigest]) -> WeeklyDigest? {
        guard let index = latestDigestIndex(in: digests) else { return nil }
        return digests[index]
    }

    private func latestDigestIndex(in digests: [WeeklyDigest]) -> Int? {
        digests.indices.max { lhs, rhs in
            calendar.startOfDay(for: digests[lhs].weekStarting)
                < calendar.startOfDay(for: digests[rhs].weekStarting)
        }
    }

    private func isLatestDigest(_ digest: WeeklyDigest, in digests: [WeeklyDigest]) -> Bool {
        guard let latest = latestDigest(in: digests) else { return false }
        return calendar.startOfDay(for: latest.weekStarting)
            == calendar.startOfDay(for: digest.weekStarting)
    }

    private func isLatestDigestIndex(_ index: Int, in digests: [WeeklyDigest]) -> Bool {
        guard digests.indices.contains(index),
            let latestIndex = latestDigestIndex(in: digests)
        else {
            return false
        }
        return latestIndex == index
    }
}
