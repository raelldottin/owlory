import XCTest
#if SWIFT_PACKAGE
@testable import OwloryCore
#endif

final class WeeklyDigestRulesTests: XCTestCase {

    private let calendar = Calendar.current

    private func makeDate(_ string: String) -> Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: string)!
    }

    private func makeEntry(
        date: Date,
        items: [FocusItem] = [],
        energy: Int = 3,
        mood: Int = 3,
        sleepQuality: Int = 3
    ) -> DailyEntry {
        DailyEntry(
            date: date,
            focusThree: items,
            energy: energy,
            mood: mood,
            sleepQuality: sleepQuality
        )
    }

    // MARK: - Generation

    func testEmptyEntriesReturnsNil() {
        let result = WeeklyDigestRules.generate(
            entries: [],
            weekStarting: Date(),
            weekEnding: Date(),
            generatedAt: Date()
        )
        XCTAssertNil(result)
    }

    func testSingleEntryProducesDigest() {
        let monday = makeDate("2026-04-06T09:00:00Z")
        let sunday = makeDate("2026-04-12T09:00:00Z")
        let entry = makeEntry(
            date: makeDate("2026-04-07T09:00:00Z"),
            items: [
                FocusItem(title: "Run", domain: .training, status: .done),
                FocusItem(title: "Write", domain: .writing, status: .planned)
            ],
            energy: 4, mood: 4, sleepQuality: 3
        )

        let digest = WeeklyDigestRules.generate(
            entries: [entry],
            weekStarting: monday,
            weekEnding: sunday,
            generatedAt: Date()
        )

        XCTAssertNotNil(digest)
        XCTAssertEqual(digest!.daysWithEntries, 1)
        XCTAssertEqual(digest!.totalPlanned, 2)
        XCTAssertEqual(digest!.totalDone, 1)
        XCTAssertEqual(digest!.completionRate, 0.5)
    }

    func testGeneratedDigestRecordsCurrentRuleVersionAndLinkedFocusCompletion() {
        let linkedRecordID = UUID()
        let digest = WeeklyDigestRules.generate(
            entries: [
                makeEntry(
                    date: makeDate("2026-04-07T09:00:00Z"),
                    items: [
                        FocusItem(
                            title: "Complete linked train session",
                            domain: .training,
                            status: .done,
                            linkedRecordID: linkedRecordID
                        )
                    ]
                )
            ],
            weekStarting: makeDate("2026-04-06T00:00:00Z"),
            weekEnding: makeDate("2026-04-12T00:00:00Z"),
            generatedAt: makeDate("2026-04-13T12:00:00Z")
        )

        XCTAssertEqual(digest?.digestRuleVersion, WeeklyDigestRules.currentDigestRuleVersion)
        XCTAssertEqual(digest?.totalPlanned, 1)
        XCTAssertEqual(digest?.totalDone, 1)
    }

    func testLegacyDigestWithoutRuleVersionRemainsReadable() throws {
        let json = """
        [
          {
            "id": "11111111-1111-1111-1111-111111111111",
            "weekStarting": "2026-04-06T00:00:00Z",
            "weekEnding": "2026-04-12T00:00:00Z",
            "generatedAt": "2026-04-13T12:00:00Z",
            "daysWithEntries": 7,
            "completionRate": 0,
            "totalPlanned": 21,
            "totalDone": 0,
            "averageReadiness": 0,
            "domainActivity": [],
            "stalledItemCount": 0,
            "streakDays": 0,
            "keyInsight": "Legacy digest"
          }
        ]
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let digests = try decoder.decode([WeeklyDigest].self, from: Data(json.utf8))

        XCTAssertNil(digests[0].digestRuleVersion)
        XCTAssertTrue(digests[0].isLegacyDigestRuleVersion)
        XCTAssertEqual(digests[0].totalPlanned, 21)
    }

    func testCompletedProtocolStepsCountAsCompletedHomeWork() {
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let monday = makeDate("2026-04-06T00:00:00Z")
        let sunday = makeDate("2026-04-12T00:00:00Z")
        let entry = makeEntry(
            date: makeDate("2026-04-07T09:00:00Z"),
            items: [
                FocusItem(title: "Draft", domain: .writing, status: .done),
                FocusItem(title: "Edit", domain: .writing, status: .planned),
                FocusItem(title: "Publish", domain: .writing, status: .planned)
            ]
        )
        let protocolRun = ProtocolRun(
            protocolID: UUID(),
            protocolTitle: "Kitchen Reset",
            createdAt: makeDate("2026-04-06T08:00:00Z"),
            steps: [
                ProtocolStepInstance(
                    stepNumber: 1,
                    title: "Clear sink",
                    status: .completed,
                    completedAt: makeDate("2026-04-08T12:00:00Z")
                ),
                ProtocolStepInstance(
                    stepNumber: 2,
                    title: "Wipe counters",
                    status: .completed,
                    completedAt: makeDate("2026-04-12T23:00:00Z")
                ),
                ProtocolStepInstance(
                    stepNumber: 3,
                    title: "Mop floor",
                    status: .skipped,
                    completedAt: makeDate("2026-04-09T12:00:00Z")
                ),
                ProtocolStepInstance(
                    stepNumber: 4,
                    title: "Take out trash",
                    status: .pending
                ),
                ProtocolStepInstance(
                    stepNumber: 5,
                    title: "Old prep",
                    status: .completed,
                    completedAt: makeDate("2026-04-05T12:00:00Z")
                )
            ]
        )

        let digest = WeeklyDigestRules.generate(
            entries: [entry],
            weekStarting: monday,
            weekEnding: sunday,
            generatedAt: makeDate("2026-04-13T12:00:00Z"),
            protocolRuns: [protocolRun],
            calendar: utcCalendar
        )!

        XCTAssertEqual(digest.totalPlanned, 5)
        XCTAssertEqual(digest.totalDone, 3)
        XCTAssertEqual(digest.completionRate, 0.6)
        XCTAssertEqual(digest.domainActivity[.writing], 3)
        XCTAssertEqual(digest.domainActivity[.home], 2)
    }

    func testProtocolStepCompletionsCanProduceDigestWithoutTodayEntries() {
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let run = ProtocolRun(
            protocolID: UUID(),
            protocolTitle: "Evening Routine",
            createdAt: makeDate("2026-04-06T08:00:00Z"),
            steps: [
                ProtocolStepInstance(
                    stepNumber: 1,
                    title: "Reset kitchen",
                    status: .completed,
                    completedAt: makeDate("2026-04-10T20:00:00Z")
                )
            ]
        )

        let digest = WeeklyDigestRules.generate(
            entries: [],
            weekStarting: makeDate("2026-04-06T00:00:00Z"),
            weekEnding: makeDate("2026-04-12T00:00:00Z"),
            generatedAt: makeDate("2026-04-13T12:00:00Z"),
            protocolRuns: [run],
            calendar: utcCalendar
        )

        XCTAssertNotNil(digest)
        XCTAssertEqual(digest?.daysWithEntries, 0)
        XCTAssertEqual(digest?.totalPlanned, 1)
        XCTAssertEqual(digest?.totalDone, 1)
        XCTAssertEqual(digest?.completionRate, 1.0)
        XCTAssertEqual(digest?.domainActivity[.home], 1)
    }

    func testFullWeekCompletionRate() {
        let monday = makeDate("2026-04-06T09:00:00Z")
        let sunday = makeDate("2026-04-12T09:00:00Z")
        var entries: [DailyEntry] = []

        for i in 0..<5 {
            let date = calendar.date(byAdding: .day, value: i, to: monday)!
            entries.append(makeEntry(
                date: date,
                items: [
                    FocusItem(title: "Task \(i)", domain: .training, status: .done),
                    FocusItem(title: "Task \(i)b", domain: .writing, status: .done)
                ],
                energy: 4, mood: 4, sleepQuality: 4
            ))
        }

        let digest = WeeklyDigestRules.generate(
            entries: entries,
            weekStarting: monday,
            weekEnding: sunday,
            generatedAt: Date()
        )!

        XCTAssertEqual(digest.daysWithEntries, 5)
        XCTAssertEqual(digest.totalDone, 10)
        XCTAssertEqual(digest.totalPlanned, 10)
        XCTAssertEqual(digest.completionRate, 1.0)
    }

    func testAverageReadinessCalculation() {
        let monday = makeDate("2026-04-06T09:00:00Z")
        let sunday = makeDate("2026-04-12T09:00:00Z")
        let entries = [
            makeEntry(date: monday, energy: 2, mood: 2, sleepQuality: 2), // avg 2.0
            makeEntry(date: calendar.date(byAdding: .day, value: 1, to: monday)!, energy: 4, mood: 4, sleepQuality: 4), // avg 4.0
        ]

        let digest = WeeklyDigestRules.generate(
            entries: entries,
            weekStarting: monday,
            weekEnding: sunday,
            generatedAt: Date()
        )!

        // (2.0 + 4.0) / 2 = 3.0
        XCTAssertEqual(digest.averageReadiness, 3.0)
    }

    func testNoCheckinExcludedFromReadiness() {
        let monday = makeDate("2026-04-06T09:00:00Z")
        let sunday = makeDate("2026-04-12T09:00:00Z")
        let entries = [
            makeEntry(date: monday, energy: 0, mood: 0, sleepQuality: 0), // no check-in
            makeEntry(date: calendar.date(byAdding: .day, value: 1, to: monday)!, energy: 4, mood: 4, sleepQuality: 4),
        ]

        let digest = WeeklyDigestRules.generate(
            entries: entries,
            weekStarting: monday,
            weekEnding: sunday,
            generatedAt: Date()
        )!

        // Only second entry counted: 4.0
        XCTAssertEqual(digest.averageReadiness, 4.0)
    }

    func testBestDayHighlight() {
        let monday = makeDate("2026-04-06T09:00:00Z")
        let sunday = makeDate("2026-04-12T09:00:00Z")
        let entries = [
            makeEntry(
                date: monday,
                items: [FocusItem(title: "A", domain: .home, status: .planned)]
            ),
            makeEntry(
                date: calendar.date(byAdding: .day, value: 2, to: monday)!,
                items: [
                    FocusItem(title: "B", domain: .home, status: .done),
                    FocusItem(title: "C", domain: .home, status: .done)
                ]
            )
        ]

        let digest = WeeklyDigestRules.generate(
            entries: entries,
            weekStarting: monday,
            weekEnding: sunday,
            generatedAt: Date()
        )!

        XCTAssertNotNil(digest.bestDay)
        XCTAssertTrue(digest.bestDay!.summary.contains("2 of 2"))
    }

    func testDayHighlightLabelsUseExplicitCalendar() {
        var localCalendar = Calendar(identifier: .gregorian)
        localCalendar.timeZone = TimeZone(secondsFromGMT: 14 * 60 * 60)!

        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let boundaryDate = makeDate("2026-04-05T12:30:00Z")
        let entry = makeEntry(
            date: boundaryDate,
            items: [FocusItem(title: "Plan week", domain: .home, status: .done)],
            energy: 1,
            mood: 1,
            sleepQuality: 1
        )

        let localDigest = WeeklyDigestRules.generate(
            entries: [entry],
            weekStarting: makeDate("2026-04-05T00:00:00Z"),
            weekEnding: makeDate("2026-04-11T00:00:00Z"),
            generatedAt: makeDate("2026-04-12T12:00:00Z"),
            calendar: localCalendar
        )!
        let utcDigest = WeeklyDigestRules.generate(
            entries: [entry],
            weekStarting: makeDate("2026-04-05T00:00:00Z"),
            weekEnding: makeDate("2026-04-11T00:00:00Z"),
            generatedAt: makeDate("2026-04-12T12:00:00Z"),
            calendar: utcCalendar
        )!

        let localDay = expectedLabel(for: boundaryDate, calendar: localCalendar, dateFormat: "EEEE")
        let utcDay = expectedLabel(for: boundaryDate, calendar: utcCalendar, dateFormat: "EEEE")

        XCTAssertNotEqual(localDay, utcDay)
        XCTAssertTrue(localDigest.bestDay!.summary.hasPrefix("\(localDay):"))
        XCTAssertTrue(localDigest.hardestDay!.summary.hasPrefix("\(localDay):"))
        XCTAssertTrue(utcDigest.bestDay!.summary.hasPrefix("\(utcDay):"))
        XCTAssertTrue(utcDigest.hardestDay!.summary.hasPrefix("\(utcDay):"))
    }

    func testDomainActivityCounts() {
        let monday = makeDate("2026-04-06T09:00:00Z")
        let sunday = makeDate("2026-04-12T09:00:00Z")
        let entries = [
            makeEntry(
                date: monday,
                items: [
                    FocusItem(title: "Run", domain: .training, status: .done),
                    FocusItem(title: "Write", domain: .writing, status: .done),
                    FocusItem(title: "Run 2", domain: .training, status: .planned)
                ]
            )
        ]

        let digest = WeeklyDigestRules.generate(
            entries: entries,
            weekStarting: monday,
            weekEnding: sunday,
            generatedAt: Date()
        )!

        XCTAssertEqual(digest.domainActivity[.training], 2)
        XCTAssertEqual(digest.domainActivity[.writing], 1)
    }

    func testStreakCountsFromEndOfWeek() {
        let monday = makeDate("2026-04-06T09:00:00Z")
        let sunday = makeDate("2026-04-12T09:00:00Z")

        // Entries on Fri, Sat, Sun = 3-day streak from end
        let entries = [
            makeEntry(date: calendar.date(byAdding: .day, value: 4, to: monday)!), // Fri
            makeEntry(date: calendar.date(byAdding: .day, value: 5, to: monday)!), // Sat
            makeEntry(date: sunday), // Sun
        ]

        let digest = WeeklyDigestRules.generate(
            entries: entries,
            weekStarting: monday,
            weekEnding: sunday,
            generatedAt: Date()
        )!

        XCTAssertEqual(digest.streakDays, 3)
    }

    func testStalledItemCountUsesExplicitCalendar() {
        var localCalendar = Calendar(identifier: .gregorian)
        localCalendar.timeZone = TimeZone(secondsFromGMT: 14 * 60 * 60)!

        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let entries = [
            makeEntry(
                date: makeDate("2026-04-06T09:30:00Z"),
                items: [
                    carriedItem(
                        title: "Draft outline",
                        carriedFrom: makeDate("2026-04-05T09:30:00Z")
                    )
                ]
            ),
            makeEntry(
                date: makeDate("2026-04-06T10:30:00Z"),
                items: [
                    carriedItem(
                        title: "Draft outline",
                        carriedFrom: makeDate("2026-04-06T09:30:00Z")
                    )
                ]
            ),
            makeEntry(
                date: makeDate("2026-04-07T10:30:00Z"),
                items: [
                    carriedItem(
                        title: "Draft outline",
                        carriedFrom: makeDate("2026-04-06T10:30:00Z")
                    )
                ]
            )
        ]

        let localDigest = WeeklyDigestRules.generate(
            entries: entries,
            weekStarting: makeDate("2026-04-06T00:00:00Z"),
            weekEnding: makeDate("2026-04-12T00:00:00Z"),
            generatedAt: makeDate("2026-04-13T12:00:00Z"),
            calendar: localCalendar
        )!
        let utcDigest = WeeklyDigestRules.generate(
            entries: entries,
            weekStarting: makeDate("2026-04-06T00:00:00Z"),
            weekEnding: makeDate("2026-04-12T00:00:00Z"),
            generatedAt: makeDate("2026-04-13T12:00:00Z"),
            calendar: utcCalendar
        )!

        XCTAssertEqual(localDigest.stalledItemCount, 1)
        XCTAssertEqual(utcDigest.stalledItemCount, 0)
    }

    func testWeekRangeLabelUsesExplicitCalendar() {
        var localCalendar = Calendar(identifier: .gregorian)
        localCalendar.timeZone = TimeZone(secondsFromGMT: 14 * 60 * 60)!

        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let weekStarting = makeDate("2026-04-05T12:30:00Z")
        let weekEnding = makeDate("2026-04-11T12:30:00Z")
        let digest = makeDigest(weekStarting: weekStarting, weekEnding: weekEnding)

        let localStart = expectedLabel(for: weekStarting, calendar: localCalendar, dateFormat: "MMM d")
        let localEnd = expectedLabel(for: weekEnding, calendar: localCalendar, dateFormat: "MMM d")
        let utcStart = expectedLabel(for: weekStarting, calendar: utcCalendar, dateFormat: "MMM d")
        let utcEnd = expectedLabel(for: weekEnding, calendar: utcCalendar, dateFormat: "MMM d")

        XCTAssertNotEqual("\(localStart) – \(localEnd)", "\(utcStart) – \(utcEnd)")
        XCTAssertEqual(
            WeeklyDigestRules.weekRangeLabel(for: digest, calendar: localCalendar),
            "\(localStart) – \(localEnd)"
        )
        XCTAssertEqual(
            WeeklyDigestRules.weekRangeLabel(for: digest, calendar: utcCalendar),
            "\(utcStart) – \(utcEnd)"
        )
        XCTAssertEqual(
            WeeklyDigestRules.weekRangeLabel(for: digest, calendar: localCalendar, separator: "-"),
            "\(localStart) - \(localEnd)"
        )
    }

    func testCollapsedCompletionSummaryUsesCountsWhenPlannedItemsExist() {
        let digest = makeDigest(
            weekStarting: makeDate("2026-04-20T00:00:00Z"),
            weekEnding: makeDate("2026-04-26T00:00:00Z"),
            totalPlanned: 3,
            totalDone: 0
        )

        XCTAssertEqual(WeeklyDigestRules.collapsedCompletionSummary(for: digest), "0 of 3 done")
    }

    func testCollapsedCompletionSummaryAvoidsZeroPercentForEmptyPlanning() {
        let digest = makeDigest(
            weekStarting: makeDate("2026-04-20T00:00:00Z"),
            weekEnding: makeDate("2026-04-26T00:00:00Z"),
            totalPlanned: 0,
            totalDone: 0
        )

        XCTAssertEqual(
            WeeklyDigestRules.collapsedCompletionSummary(for: digest),
            "No planned Focus items"
        )
    }

    func testRelativeWeekLabelUsesLastWeekOnlyForImmediatelyPreviousWeek() {
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let digest = makeDigest(
            weekStarting: makeDate("2026-04-20T00:00:00Z"),
            weekEnding: makeDate("2026-04-26T00:00:00Z")
        )

        let label = WeeklyDigestRules.relativeWeekLabel(
            for: digest,
            now: makeDate("2026-04-28T17:30:00Z"),
            calendar: utcCalendar
        )

        XCTAssertEqual(label, "Last Week")
    }

    func testRelativeWeekLabelFallsBackForOlderStoredDigest() {
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let digest = makeDigest(
            weekStarting: makeDate("2026-04-13T00:00:00Z"),
            weekEnding: makeDate("2026-04-19T00:00:00Z")
        )

        let label = WeeklyDigestRules.relativeWeekLabel(
            for: digest,
            now: makeDate("2026-04-28T17:30:00Z"),
            calendar: utcCalendar
        )

        XCTAssertEqual(label, "Most Recent Week")
    }

    func testKeyInsightForStrongWeek() {
        let monday = makeDate("2026-04-06T09:00:00Z")
        let sunday = makeDate("2026-04-12T09:00:00Z")

        let entries = (0..<5).map { i in
            makeEntry(
                date: calendar.date(byAdding: .day, value: i, to: monday)!,
                items: [FocusItem(title: "T\(i)", domain: .home, status: .done)],
                energy: 4, mood: 4, sleepQuality: 4
            )
        }

        let digest = WeeklyDigestRules.generate(
            entries: entries,
            weekStarting: monday,
            weekEnding: sunday,
            generatedAt: Date()
        )!

        XCTAssertTrue(digest.keyInsight.contains("Strong week"))
    }

    func testKeyInsightForLightWeek() {
        let monday = makeDate("2026-04-06T09:00:00Z")
        let sunday = makeDate("2026-04-12T09:00:00Z")

        let entries = [
            makeEntry(date: monday, items: [FocusItem(title: "A", domain: .home, status: .done)])
        ]

        let digest = WeeklyDigestRules.generate(
            entries: entries,
            weekStarting: monday,
            weekEnding: sunday,
            generatedAt: Date()
        )!

        XCTAssertTrue(digest.keyInsight.contains("Light week"))
    }

    private func carriedItem(title: String, carriedFrom: Date) -> FocusItem {
        FocusItem(
            title: title,
            domain: .writing,
            status: .planned,
            createdFromDate: carriedFrom
        )
    }

    private func makeDigest(
        weekStarting: Date,
        weekEnding: Date,
        totalPlanned: Int = 0,
        totalDone: Int = 0
    ) -> WeeklyDigest {
        WeeklyDigest(
            weekStarting: weekStarting,
            weekEnding: weekEnding,
            generatedAt: makeDate("2026-04-13T12:00:00Z"),
            daysWithEntries: 0,
            completionRate: totalPlanned > 0 ? Double(totalDone) / Double(totalPlanned) : 0,
            totalPlanned: totalPlanned,
            totalDone: totalDone,
            averageReadiness: 0
        )
    }

    private func expectedLabel(for date: Date, calendar: Calendar, dateFormat: String) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = dateFormat
        return formatter.string(from: date)
    }
}
