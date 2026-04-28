import XCTest
#if SWIFT_PACKAGE
@testable import OwloryCore
#endif

final class WeeklyDigestCadenceRulesTests: XCTestCase {

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(_ string: String) -> Date {
        ISO8601DateFormatter().date(from: string)!
    }

    func testMondayTargetsPreviousCompletedMondayThroughSunday() {
        let now = date("2026-04-13T17:30:00Z")

        let window = WeeklyDigestCadenceRules.targetWindow(for: now, calendar: calendar)

        XCTAssertEqual(window?.weekStarting, date("2026-04-06T00:00:00Z"))
        XCTAssertEqual(window?.weekEnding, date("2026-04-12T00:00:00Z"))
    }

    func testNonMondayDoesNotTargetDigestGeneration() {
        let now = date("2026-04-14T09:00:00Z")

        let window = WeeklyDigestCadenceRules.targetWindow(for: now, calendar: calendar)

        XCTAssertNil(window)
    }

    func testPreviousCompletedWeekWindowWorksAfterMonday() {
        let now = date("2026-04-28T17:30:00Z")

        let window = WeeklyDigestCadenceRules.previousCompletedWeekWindow(for: now, calendar: calendar)

        XCTAssertEqual(window?.weekStarting, date("2026-04-20T00:00:00Z"))
        XCTAssertEqual(window?.weekEnding, date("2026-04-26T00:00:00Z"))
    }

    func testExistingDigestIsMatchedByNormalizedWeekStart() {
        let window = WeeklyDigestCadenceRules.WeekWindow(
            weekStarting: date("2026-04-06T00:00:00Z"),
            weekEnding: date("2026-04-12T00:00:00Z")
        )
        let digest = makeDigest(weekStarting: date("2026-04-06T15:45:00Z"))

        let result = WeeklyDigestCadenceRules.hasGeneratedDigest(
            for: window,
            existingDigests: [digest],
            calendar: calendar
        )

        XCTAssertTrue(result)
    }

    func testOtherWeeksDoNotSuppressDigestGeneration() {
        let window = WeeklyDigestCadenceRules.WeekWindow(
            weekStarting: date("2026-04-06T00:00:00Z"),
            weekEnding: date("2026-04-12T00:00:00Z")
        )
        let digest = makeDigest(weekStarting: date("2026-03-30T00:00:00Z"))

        let result = WeeklyDigestCadenceRules.hasGeneratedDigest(
            for: window,
            existingDigests: [digest],
            calendar: calendar
        )

        XCTAssertFalse(result)
    }

    private func makeDigest(weekStarting: Date) -> WeeklyDigest {
        WeeklyDigest(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            weekStarting: weekStarting,
            weekEnding: date("2026-04-12T00:00:00Z"),
            generatedAt: date("2026-04-13T09:00:00Z"),
            daysWithEntries: 1,
            completionRate: 1,
            totalPlanned: 1,
            totalDone: 1,
            averageReadiness: 3
        )
    }

    @MainActor
    func testLatestStaleDigestIsRegeneratedWithCurrentRuleVersion() throws {
        let digestRepository = InMemoryItemListRepository<WeeklyDigest>()
        let protocolRepository = InMemoryItemListRepository<ProtocolRun>()
        let weekStart = date("2026-04-06T00:00:00Z")
        let weekEnd = date("2026-04-12T00:00:00Z")
        let staleDigest = makeDigest(
            digestRuleVersion: nil,
            weekStarting: weekStart,
            weekEnding: weekEnd,
            totalPlanned: 21,
            totalDone: 0
        )

        try digestRepository.saveAll([staleDigest])
        try protocolRepository.saveAll([
            makeProtocolRun(
                completedAt: date("2026-04-10T20:00:00Z"),
                skippedAt: date("2026-04-11T20:00:00Z")
            )
        ])

        let store = makeStore(
            entries: [
                DailyEntry(
                    date: date("2026-04-08T12:00:00Z"),
                    focusThree: [
                        FocusItem(
                            title: "Finish linked train session",
                            domain: .training,
                            status: .done,
                            linkedRecordID: UUID()
                        )
                    ]
                )
            ],
            digestRepository: digestRepository,
            protocolRepository: protocolRepository,
            now: date("2026-04-13T09:00:00Z")
        )

        store.refresh()

        let saved = try digestRepository.loadAll()
        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(saved[0].id, staleDigest.id)
        XCTAssertEqual(saved[0].digestRuleVersion, WeeklyDigestRules.currentDigestRuleVersion)
        XCTAssertEqual(saved[0].totalPlanned, 2)
        XCTAssertEqual(saved[0].totalDone, 2)
        XCTAssertEqual(saved[0].domainActivity[.training], 1)
        XCTAssertEqual(saved[0].domainActivity[.home], 1)
        XCTAssertEqual(store.latestDigest, saved[0])
    }

    @MainActor
    func testOlderStaleDigestIsPreservedWhenLatestDigestRefreshes() throws {
        let digestRepository = InMemoryItemListRepository<WeeklyDigest>()
        let protocolRepository = InMemoryItemListRepository<ProtocolRun>()
        let olderDigest = makeDigest(
            digestRuleVersion: nil,
            weekStarting: date("2026-03-30T00:00:00Z"),
            weekEnding: date("2026-04-05T00:00:00Z"),
            totalPlanned: 21,
            totalDone: 0
        )
        let latestDigest = makeDigest(
            digestRuleVersion: nil,
            weekStarting: date("2026-04-06T00:00:00Z"),
            weekEnding: date("2026-04-12T00:00:00Z"),
            totalPlanned: 21,
            totalDone: 0
        )

        try digestRepository.saveAll([olderDigest, latestDigest])
        try protocolRepository.saveAll([
            makeProtocolRun(completedAt: date("2026-04-10T20:00:00Z"))
        ])

        let store = makeStore(
            entries: [
                DailyEntry(
                    date: date("2026-04-08T12:00:00Z"),
                    focusThree: [
                        FocusItem(title: "Complete focus", domain: .home, status: .done)
                    ]
                )
            ],
            digestRepository: digestRepository,
            protocolRepository: protocolRepository,
            now: date("2026-04-13T09:00:00Z")
        )

        store.refresh()

        let saved = try digestRepository.loadAll()
        XCTAssertEqual(saved.count, 2)
        XCTAssertEqual(saved[0], olderDigest)
        XCTAssertNil(saved[0].digestRuleVersion)
        XCTAssertEqual(saved[1].digestRuleVersion, WeeklyDigestRules.currentDigestRuleVersion)
        XCTAssertEqual(saved[1].totalPlanned, 2)
        XCTAssertEqual(saved[1].totalDone, 2)
    }

    @MainActor
    private func makeStore(
        entries: [DailyEntry],
        digestRepository: InMemoryItemListRepository<WeeklyDigest>,
        protocolRepository: InMemoryItemListRepository<ProtocolRun>,
        now: Date
    ) -> PatternStore {
        PatternStore(
            entryRepository: StaticTodayEntryRangeRepository(entries: entries),
            snapshotRepository: InMemoryPatternSnapshotRepository(),
            digestRepository: digestRepository,
            homeRunRepository: protocolRepository,
            clock: FixedClock(now: now),
            calendar: calendar
        )
    }

    private func makeDigest(
        digestRuleVersion: Int?,
        weekStarting: Date,
        weekEnding: Date,
        totalPlanned: Int,
        totalDone: Int
    ) -> WeeklyDigest {
        WeeklyDigest(
            id: UUID(),
            digestRuleVersion: digestRuleVersion,
            weekStarting: weekStarting,
            weekEnding: weekEnding,
            generatedAt: date("2026-04-13T09:00:00Z"),
            daysWithEntries: 7,
            completionRate: totalPlanned > 0 ? Double(totalDone) / Double(totalPlanned) : 0,
            totalPlanned: totalPlanned,
            totalDone: totalDone,
            averageReadiness: 0
        )
    }

    private func makeProtocolRun(
        completedAt: Date,
        skippedAt: Date? = nil
    ) -> ProtocolRun {
        ProtocolRun(
            protocolID: UUID(),
            protocolTitle: "Kitchen Reset",
            createdAt: date("2026-04-06T09:00:00Z"),
            steps: [
                ProtocolStepInstance(
                    stepNumber: 1,
                    title: "Reset counters",
                    status: .completed,
                    completedAt: completedAt
                ),
                ProtocolStepInstance(
                    stepNumber: 2,
                    title: "Optional mop",
                    status: .skipped,
                    completedAt: skippedAt
                ),
                ProtocolStepInstance(
                    stepNumber: 3,
                    title: "Restock towels",
                    status: .pending
                )
            ]
        )
    }
}

private struct StaticTodayEntryRangeRepository: TodayEntryRangeRepository {
    let entries: [DailyEntry]

    func loadEntries(from startDate: Date, through endDate: Date) throws -> [DailyEntry] {
        entries.filter { entry in
            entry.date >= startDate && entry.date <= endDate
        }
    }
}
