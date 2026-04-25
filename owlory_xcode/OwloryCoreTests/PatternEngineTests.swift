import XCTest
#if SWIFT_PACKAGE
@testable import OwloryCore
#endif

final class PatternEngineTests: XCTestCase {

    // MARK: - Completion Rate

    func testEmptyEntriesReturnsZeroRate() {
        let rate = PatternEngine.computeCompletionRate(entries: [])
        XCTAssertEqual(rate.totalCount, 0)
        XCTAssertEqual(rate.doneCount, 0)
        XCTAssertEqual(rate.rate, 0)
    }

    func testAllDoneReturns100Percent() {
        let entry = makeEntry(items: [
            makeFocus(status: .done),
            makeFocus(status: .done),
            makeFocus(status: .done)
        ])
        let rate = PatternEngine.computeCompletionRate(entries: [entry])
        XCTAssertEqual(rate.totalCount, 3)
        XCTAssertEqual(rate.doneCount, 3)
        XCTAssertEqual(rate.rate, 1.0)
    }

    func testNoneDoneReturns0Percent() {
        let entry = makeEntry(items: [
            makeFocus(status: .planned),
            makeFocus(status: .deferred),
            makeFocus(status: .dropped)
        ])
        let rate = PatternEngine.computeCompletionRate(entries: [entry])
        XCTAssertEqual(rate.totalCount, 3)
        XCTAssertEqual(rate.doneCount, 0)
        XCTAssertEqual(rate.deferredCount, 1)
        XCTAssertEqual(rate.droppedCount, 1)
        XCTAssertEqual(rate.rate, 0)
    }

    func testMixedStatusesAcrossMultipleDays() {
        let day1 = makeEntry(items: [
            makeFocus(status: .done),
            makeFocus(status: .planned)
        ])
        let day2 = makeEntry(items: [
            makeFocus(status: .done),
            makeFocus(status: .done),
            makeFocus(status: .deferred)
        ])
        let rate = PatternEngine.computeCompletionRate(entries: [day1, day2])
        XCTAssertEqual(rate.totalCount, 5)
        XCTAssertEqual(rate.doneCount, 3)
        XCTAssertEqual(rate.deferredCount, 1)
        XCTAssertEqual(rate.rate, 0.6)
    }

    func testEntryWithNoFocusItemsContributesNothing() {
        let empty = makeEntry(items: [])
        let full = makeEntry(items: [makeFocus(status: .done)])
        let rate = PatternEngine.computeCompletionRate(entries: [empty, full])
        XCTAssertEqual(rate.totalCount, 1)
        XCTAssertEqual(rate.doneCount, 1)
    }

    // MARK: - Snapshot

    func testComputeSnapshotContainsCompletionRate() {
        let entry = makeEntry(items: [
            makeFocus(status: .done),
            makeFocus(status: .planned)
        ])
        let now = Date()
        let snapshot = PatternEngine.computeSnapshot(
            entries: [entry],
            windowEnd: now,
            windowDays: 7,
            generatedAt: now
        )
        XCTAssertEqual(snapshot.windowDays, 7)
        XCTAssertEqual(snapshot.completionRate.totalCount, 2)
        XCTAssertEqual(snapshot.completionRate.doneCount, 1)
    }

    // MARK: - Carry-Forward Detection

    func testFewerThanThreeEntriesReturnsEmptyCarryForward() {
        let entry1 = makeEntry(items: [makeFocus(status: .done)])
        let entry2 = makeEntry(items: [makeFocus(status: .planned)])
        let result = PatternEngine.computeCarryForward(entries: [entry1, entry2])
        XCTAssertEqual(result.averageCarriedPerDay, 0)
        XCTAssertTrue(result.stalledItems.isEmpty)
    }

    func testStalledItemDetectedAfterThreeConsecutiveDays() {
        let baseDate = Date()
        let cal = Calendar.current
        let day1 = DailyEntry(date: cal.date(byAdding: .day, value: -2, to: baseDate)!, focusThree: [
            FocusItem(title: "Fix sink", domain: .home, status: .planned, createdFromDate: cal.date(byAdding: .day, value: -3, to: baseDate))
        ])
        let day2 = DailyEntry(date: cal.date(byAdding: .day, value: -1, to: baseDate)!, focusThree: [
            FocusItem(title: "Fix sink", domain: .home, status: .planned, createdFromDate: cal.date(byAdding: .day, value: -2, to: baseDate))
        ])
        let day3 = DailyEntry(date: baseDate, focusThree: [
            FocusItem(title: "Fix sink", domain: .home, status: .planned, createdFromDate: cal.date(byAdding: .day, value: -1, to: baseDate))
        ])

        let result = PatternEngine.computeCarryForward(entries: [day1, day2, day3])
        XCTAssertEqual(result.stalledItems.count, 1)
        XCTAssertEqual(result.stalledItems.first?.title, "Fix sink")
        XCTAssertEqual(result.stalledItems.first?.consecutiveDays, 3)
    }

    func testNoStalledItemWhenCarriedOnlyTwoDays() {
        let baseDate = Date()
        let cal = Calendar.current
        let day1 = DailyEntry(date: cal.date(byAdding: .day, value: -2, to: baseDate)!, focusThree: [
            FocusItem(title: "Call dentist", domain: .home, status: .done)
        ])
        let day2 = DailyEntry(date: cal.date(byAdding: .day, value: -1, to: baseDate)!, focusThree: [
            FocusItem(title: "Write blog", domain: .writing, status: .planned, createdFromDate: cal.date(byAdding: .day, value: -2, to: baseDate))
        ])
        let day3 = DailyEntry(date: baseDate, focusThree: [
            FocusItem(title: "Write blog", domain: .writing, status: .planned, createdFromDate: cal.date(byAdding: .day, value: -1, to: baseDate))
        ])

        let result = PatternEngine.computeCarryForward(entries: [day1, day2, day3])
        XCTAssertTrue(result.stalledItems.isEmpty)
    }

    func testStalledItemRequiresConsecutiveCarriedEntries() {
        let baseDate = Date()
        let cal = Calendar.current
        let day1 = DailyEntry(date: cal.date(byAdding: .day, value: -4, to: baseDate)!, focusThree: [
            FocusItem(title: "Write outline", domain: .writing, status: .planned, createdFromDate: cal.date(byAdding: .day, value: -5, to: baseDate))
        ])
        let day2 = DailyEntry(date: cal.date(byAdding: .day, value: -3, to: baseDate)!, focusThree: [
            FocusItem(title: "Review PR", domain: .career, status: .planned)
        ])
        let day3 = DailyEntry(date: cal.date(byAdding: .day, value: -2, to: baseDate)!, focusThree: [
            FocusItem(title: "Write outline", domain: .writing, status: .planned, createdFromDate: cal.date(byAdding: .day, value: -3, to: baseDate))
        ])
        let day4 = DailyEntry(date: cal.date(byAdding: .day, value: -1, to: baseDate)!, focusThree: [
            FocusItem(title: "Write outline", domain: .writing, status: .planned, createdFromDate: cal.date(byAdding: .day, value: -2, to: baseDate))
        ])

        let result = PatternEngine.computeCarryForward(entries: [day1, day2, day3, day4])

        XCTAssertTrue(result.stalledItems.isEmpty)
    }

    func testMissingCalendarDateBreaksStalledItemCarryStreak() {
        let calendar = makeCalendar()
        let day1 = carriedEntry(
            title: "Write outline",
            domain: .writing,
            date: makeDate(year: 2026, month: 4, day: 13, calendar: calendar),
            carriedFrom: makeDate(year: 2026, month: 4, day: 12, calendar: calendar)
        )
        let day3 = carriedEntry(
            title: "Write outline",
            domain: .writing,
            date: makeDate(year: 2026, month: 4, day: 15, calendar: calendar),
            carriedFrom: makeDate(year: 2026, month: 4, day: 14, calendar: calendar)
        )
        let day4 = carriedEntry(
            title: "Write outline",
            domain: .writing,
            date: makeDate(year: 2026, month: 4, day: 16, calendar: calendar),
            carriedFrom: makeDate(year: 2026, month: 4, day: 15, calendar: calendar)
        )

        let result = PatternEngine.computeCarryForward(
            entries: [day1, day3, day4],
            calendar: calendar
        )

        XCTAssertTrue(result.stalledItems.isEmpty)
    }

    func testSameDayDuplicateEntriesDoNotInflateStalledItemCarryStreak() {
        let calendar = makeCalendar()
        let day1 = makeDate(year: 2026, month: 4, day: 13, calendar: calendar)
        let firstDuplicate = carriedEntry(
            title: "Write outline",
            domain: .writing,
            date: day1,
            carriedFrom: makeDate(year: 2026, month: 4, day: 12, calendar: calendar)
        )
        let secondDuplicate = carriedEntry(
            title: "Write outline",
            domain: .writing,
            date: calendar.date(byAdding: .hour, value: 6, to: day1)!,
            carriedFrom: makeDate(year: 2026, month: 4, day: 12, calendar: calendar)
        )
        let day2 = carriedEntry(
            title: "Write outline",
            domain: .writing,
            date: makeDate(year: 2026, month: 4, day: 14, calendar: calendar),
            carriedFrom: day1
        )

        let result = PatternEngine.computeCarryForward(
            entries: [firstDuplicate, secondDuplicate, day2],
            calendar: calendar
        )

        XCTAssertTrue(result.stalledItems.isEmpty)
        XCTAssertEqual(result.averageCarriedPerDay, 1.0)
    }

    func testCarryForwardAverageCountsCorrectly() {
        let baseDate = Date()
        let cal = Calendar.current
        // Day 1: 0 carried, Day 2: 1 carried, Day 3: 2 carried
        let day1 = DailyEntry(date: cal.date(byAdding: .day, value: -2, to: baseDate)!, focusThree: [
            FocusItem(title: "Task A", domain: .home, status: .done)
        ])
        let day2 = DailyEntry(date: cal.date(byAdding: .day, value: -1, to: baseDate)!, focusThree: [
            FocusItem(title: "Task B", domain: .career, status: .planned, createdFromDate: cal.date(byAdding: .day, value: -2, to: baseDate))
        ])
        let day3 = DailyEntry(date: baseDate, focusThree: [
            FocusItem(title: "Task B", domain: .career, status: .planned, createdFromDate: cal.date(byAdding: .day, value: -1, to: baseDate)),
            FocusItem(title: "Task C", domain: .home, status: .planned, createdFromDate: cal.date(byAdding: .day, value: -1, to: baseDate))
        ])

        let result = PatternEngine.computeCarryForward(entries: [day1, day2, day3])
        // 3 carried total across 3 days with items = 1.0
        XCTAssertEqual(result.averageCarriedPerDay, 1.0)
    }

    // MARK: - Domain Balance

    func testEmptyEntriesReturnsEmptyBalance() {
        let result = PatternEngine.computeDomainBalance(entries: [])
        XCTAssertTrue(result.domainShares.isEmpty)
        XCTAssertTrue(result.neglectedDomains.isEmpty)
    }

    func testAllItemsInOneDomainNeglectsOthers() {
        let entries = [
            makeEntry(items: [
                FocusItem(title: "Run", domain: .training, status: .done),
                FocusItem(title: "Swim", domain: .training, status: .planned)
            ])
        ]
        let result = PatternEngine.computeDomainBalance(entries: entries)
        XCTAssertEqual(result.domainShares[.training], 1.0)
        XCTAssertEqual(result.domainShares[.writing], 0)
        XCTAssertTrue(result.neglectedDomains.contains(.writing))
        XCTAssertTrue(result.neglectedDomains.contains(.career))
        XCTAssertTrue(result.neglectedDomains.contains(.home))
        XCTAssertFalse(result.neglectedDomains.contains(.training))
    }

    func testBalancedDomainsHasNoNeglected() {
        let entries = [
            makeEntry(items: [
                FocusItem(title: "Run", domain: .training, status: .done),
                FocusItem(title: "Write", domain: .writing, status: .done),
                FocusItem(title: "Interview", domain: .career, status: .planned)
            ]),
            makeEntry(items: [
                FocusItem(title: "Clean", domain: .home, status: .done)
            ])
        ]
        let result = PatternEngine.computeDomainBalance(entries: entries)
        XCTAssertTrue(result.neglectedDomains.isEmpty)
        XCTAssertEqual(result.domainShares[.training], 0.25)
        XCTAssertEqual(result.domainShares[.home], 0.25)
    }

    // MARK: - Snapshot includes new patterns

    func testSnapshotIncludesCarryForwardWhenEnoughData() {
        let cal = Calendar.current
        let baseDate = Date()
        let entries = (0..<3).map { i in
            DailyEntry(
                date: cal.date(byAdding: .day, value: -i, to: baseDate)!,
                focusThree: [FocusItem(title: "Task", domain: .home, status: .done)]
            )
        }
        let snapshot = PatternEngine.computeSnapshot(entries: entries, windowEnd: baseDate, windowDays: 7, generatedAt: baseDate)
        XCTAssertNotNil(snapshot.carryForward)
        XCTAssertNil(snapshot.domainBalance) // needs 7+ entries
    }

    func testSnapshotIncludesDomainBalanceWhenEnoughData() {
        let cal = Calendar.current
        let baseDate = Date()
        let entries = (0..<7).map { i in
            DailyEntry(
                date: cal.date(byAdding: .day, value: -i, to: baseDate)!,
                focusThree: [FocusItem(title: "Task \(i)", domain: .training, status: .done)]
            )
        }
        let snapshot = PatternEngine.computeSnapshot(entries: entries, windowEnd: baseDate, windowDays: 7, generatedAt: baseDate)
        XCTAssertNotNil(snapshot.carryForward)
        XCTAssertNotNil(snapshot.domainBalance)
    }

    // MARK: - Readiness-to-Outcome

    func testReadinessOutcomeWithNoCheckins() {
        let entries = [
            DailyEntry(date: Date(), focusThree: [makeFocus(status: .done)], energy: 0, mood: 0, sleepQuality: 0)
        ]
        let result = PatternEngine.computeReadinessOutcome(entries: entries)
        XCTAssertEqual(result.sampleCount, 0)
        XCTAssertEqual(result.lowReadinessAvgCompletion, 0)
        XCTAssertEqual(result.highReadinessAvgCompletion, 0)
    }

    func testLowReadinessLowCompletion() {
        let entries = [
            DailyEntry(date: Date(), focusThree: [
                makeFocus(status: .done),
                makeFocus(status: .planned),
                makeFocus(status: .planned)
            ], energy: 1, mood: 2, sleepQuality: 1),
            DailyEntry(date: Date(), focusThree: [
                makeFocus(status: .planned),
                makeFocus(status: .planned),
                makeFocus(status: .dropped)
            ], energy: 2, mood: 1, sleepQuality: 2),
        ]
        let result = PatternEngine.computeReadinessOutcome(entries: entries)
        XCTAssertEqual(result.sampleCount, 2)
        XCTAssertTrue(result.lowReadinessAvgCompletion < 0.5)
    }

    func testHighReadinessHighCompletion() {
        let entries = [
            DailyEntry(date: Date(), focusThree: [
                makeFocus(status: .done),
                makeFocus(status: .done),
                makeFocus(status: .done)
            ], energy: 5, mood: 4, sleepQuality: 5),
            DailyEntry(date: Date(), focusThree: [
                makeFocus(status: .done),
                makeFocus(status: .done)
            ], energy: 4, mood: 5, sleepQuality: 4),
        ]
        let result = PatternEngine.computeReadinessOutcome(entries: entries)
        XCTAssertEqual(result.sampleCount, 2)
        XCTAssertEqual(result.highReadinessAvgCompletion, 1.0)
    }

    func testOverplanningDetectedOnLowDays() {
        // 3+ items on low readiness days with <50% completion
        let entries = [
            DailyEntry(date: Date(), focusThree: [
                makeFocus(status: .done),
                makeFocus(status: .planned),
                makeFocus(status: .planned)
            ], energy: 1, mood: 1, sleepQuality: 2),
            DailyEntry(date: Date(), focusThree: [
                makeFocus(status: .planned),
                makeFocus(status: .planned),
                makeFocus(status: .dropped)
            ], energy: 2, mood: 1, sleepQuality: 1),
            DailyEntry(date: Date(), focusThree: [
                makeFocus(status: .done),
                makeFocus(status: .planned),
                makeFocus(status: .planned)
            ], energy: 1, mood: 2, sleepQuality: 1),
        ]
        let result = PatternEngine.computeReadinessOutcome(entries: entries)
        XCTAssertTrue(result.overplanningOnLowDays)
    }

    func testSnapshotIncludesReadinessOutcomeWhenEnoughSamples() {
        let cal = Calendar.current
        let baseDate = Date()
        // Need at least 3 samples with readiness check-ins
        let entries = (0..<5).map { i in
            DailyEntry(
                date: cal.date(byAdding: .day, value: -i, to: baseDate)!,
                focusThree: [FocusItem(title: "Task", domain: .home, status: .done)],
                energy: 4, mood: 4, sleepQuality: 4
            )
        }
        let snapshot = PatternEngine.computeSnapshot(entries: entries, windowEnd: baseDate, windowDays: 7, generatedAt: baseDate)
        XCTAssertNotNil(snapshot.readinessOutcome)
    }

    func testSnapshotExcludesReadinessOutcomeWithFewSamples() {
        let baseDate = Date()
        let entries = [
            DailyEntry(date: baseDate, focusThree: [makeFocus(status: .done)], energy: 4, mood: 4, sleepQuality: 4)
        ]
        let snapshot = PatternEngine.computeSnapshot(entries: entries, windowEnd: baseDate, windowDays: 7, generatedAt: baseDate)
        XCTAssertNil(snapshot.readinessOutcome)
    }

    // MARK: - Helpers

    private func makeEntry(items: [FocusItem]) -> DailyEntry {
        DailyEntry(date: Date(), focusThree: items)
    }

    private func makeFocus(status: FocusItemStatus) -> FocusItem {
        FocusItem(title: "Test", domain: .home, status: status)
    }

    private func carriedEntry(
        title: String,
        domain: LifeDomain,
        date: Date,
        carriedFrom: Date
    ) -> DailyEntry {
        DailyEntry(
            date: date,
            focusThree: [
                FocusItem(
                    title: title,
                    domain: domain,
                    status: .planned,
                    createdFromDate: carriedFrom
                )
            ]
        )
    }

    private func makeDate(
        year: Int,
        month: Int,
        day: Int,
        calendar: Calendar
    ) -> Date {
        calendar.date(from: DateComponents(
            year: year,
            month: month,
            day: day,
            hour: 12
        ))!
    }

    private func makeCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
}
