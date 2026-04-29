import XCTest
#if SWIFT_PACKAGE
@testable import OwloryCore
#endif

final class TodayStoreTests: XCTestCase {
    func testSeedsTodayFromYesterdayCarryForwardWhenNoTodayEntryExists() async {
        let repository = InMemoryTodayEntryRepository(calendar: makeCalendar())
        let yesterday = makeDate("2026-04-07T10:00:00Z")
        let today = makeDate("2026-04-08T10:00:00Z")

        try? repository.saveEntry(
            DailyEntry(
                date: yesterday,
                focusThree: [
                    FocusItem(title: "Write outline", domain: .writing, status: .planned),
                    FocusItem(title: "Clean kitchen", domain: .home, status: .deferred),
                    FocusItem(title: "Already done", domain: .career, status: .done)
                ]
            )
        )

        let store = await MainActor.run {
            TodayStore(
                clock: FixedClock(now: today),
                repository: repository,
                calendar: makeCalendar()
            )
        }

        let state = await MainActor.run { store.entryState }
        guard case .setupIncomplete(let entry) = state else {
            return XCTFail("Expected setupIncomplete state")
        }

        let usedCarryForward = await MainActor.run { store.lastLoadUsedCarryForward }
        XCTAssertTrue(usedCarryForward)
        XCTAssertEqual(entry.carryForward.map(\.title), ["Write outline", "Clean kitchen"])
        XCTAssertEqual(entry.focusThree.map(\.title), ["Write outline", "Clean kitchen"])
    }

    func testExistingTodayEntryLoadsAsActiveWithoutReseeding() async {
        let repository = InMemoryTodayEntryRepository(calendar: makeCalendar())
        let today = makeDate("2026-04-08T10:00:00Z")
        let saved = DailyEntry(
            date: today,
            focusThree: [FocusItem(title: "Preserved", domain: .home, status: .planned)]
        )
        try? repository.saveEntry(saved)

        let store = await MainActor.run {
            TodayStore(
                clock: FixedClock(now: today),
                repository: repository,
                calendar: makeCalendar()
            )
        }

        let state = await MainActor.run { store.entryState }
        guard case .active(let entry) = state else {
            return XCTFail("Expected active state")
        }

        let usedCarryForward = await MainActor.run { store.lastLoadUsedCarryForward }
        XCTAssertFalse(usedCarryForward)
        XCTAssertEqual(entry.focusThree.map(\.title), ["Preserved"])
    }

    func testDailyEntryDecodingDropsLegacyGeneralItems() throws {
        let json = """
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "date": "2026-04-08T00:00:00Z",
            "focusThree": [
                {
                    "id": "00000000-0000-0000-0000-000000000002",
                    "title": "Loose legacy item",
                    "domain": "general",
                    "status": "planned"
                },
                {
                    "id": "00000000-0000-0000-0000-000000000003",
                    "title": "Keep home item",
                    "domain": "home",
                    "status": "planned"
                }
            ],
            "domainIntentions": [
                "general",
                "Old uncategorized intention",
                "home",
                "Fix the sink"
            ],
            "energy": 3,
            "mood": 3,
            "sleepQuality": 3,
            "carryForward": [
                {
                    "id": "00000000-0000-0000-0000-000000000004",
                    "title": "Old carry",
                    "domain": "general",
                    "status": "planned"
                },
                {
                    "id": "00000000-0000-0000-0000-000000000005",
                    "title": "Keep writing carry",
                    "domain": "writing",
                    "status": "planned"
                }
            ],
            "eveningReflection": ""
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let entry = try decoder.decode(DailyEntry.self, from: json)

        XCTAssertEqual(entry.focusThree.map(\.title), ["Keep home item"])
        XCTAssertEqual(entry.carryForward.map(\.title), ["Keep writing carry"])
        XCTAssertEqual(entry.domainIntentions[.home], "Fix the sink")
        XCTAssertEqual(entry.domainIntentions.count, 1)
    }

    // MARK: - markSetupComplete

    func testMarkSetupCompleteTransitionsToActive() async {
        let repository = InMemoryTodayEntryRepository(calendar: makeCalendar())
        let today = makeDate("2026-04-08T10:00:00Z")

        let store = await MainActor.run {
            TodayStore(clock: FixedClock(now: today), repository: repository, calendar: makeCalendar())
        }

        // Fresh store with no prior entry → setupIncomplete
        let stateBefore = await MainActor.run { store.entryState }
        guard case .setupIncomplete = stateBefore else {
            return XCTFail("Expected setupIncomplete, got \(stateBefore)")
        }

        await MainActor.run { store.markSetupComplete() }

        let stateAfter = await MainActor.run { store.entryState }
        guard case .active(let entry) = stateAfter else {
            return XCTFail("Expected active after markSetupComplete")
        }
        XCTAssertEqual(entry.date, makeCalendar().startOfDay(for: today))
    }

    // MARK: - saveReflection

    func testSaveReflectionTransitionsActiveToReflected() async {
        let repository = InMemoryTodayEntryRepository(calendar: makeCalendar())
        let today = makeDate("2026-04-08T10:00:00Z")
        let saved = DailyEntry(date: today, focusThree: [FocusItem(title: "Test", domain: .home)])
        try? repository.saveEntry(saved)

        let store = await MainActor.run {
            TodayStore(clock: FixedClock(now: today), repository: repository, calendar: makeCalendar())
        }

        await MainActor.run { store.saveReflection("Good day overall") }

        let state = await MainActor.run { store.entryState }
        guard case .reflected(let entry) = state else {
            return XCTFail("Expected reflected state")
        }
        XCTAssertEqual(entry.eveningReflection, "Good day overall")
    }

    func testSaveReflectionRejectsEmptyText() async {
        let repository = InMemoryTodayEntryRepository(calendar: makeCalendar())
        let today = makeDate("2026-04-08T10:00:00Z")
        let saved = DailyEntry(date: today, focusThree: [FocusItem(title: "Test", domain: .home)])
        try? repository.saveEntry(saved)

        let store = await MainActor.run {
            TodayStore(clock: FixedClock(now: today), repository: repository, calendar: makeCalendar())
        }

        await MainActor.run { store.saveReflection("   ") }

        let state = await MainActor.run { store.entryState }
        guard case .active = state else {
            return XCTFail("Expected active state to remain after empty reflection")
        }
    }

    func testEveningReflectionNudgeAppearsAfterSixWhenReflectionMissing() {
        let now = makeDate("2026-04-08T18:01:00Z")
        let entry = DailyEntry(date: now)

        let nudge = TodayStore.eveningReflectionNudge(
            for: entry,
            homeTasks: [],
            now: now,
            calendar: makeCalendar()
        )

        XCTAssertEqual(nudge?.title, "Evening reflection")
    }

    func testEveningReflectionNudgeStaysHiddenBeforeEveningWhenAllHomeTasksCompleted() {
        let now = makeDate("2026-04-08T12:00:00Z")
        let entry = DailyEntry(date: now)

        let nudge = TodayStore.eveningReflectionNudge(
            for: entry,
            homeTasks: [
                HomeTask(title: "Clean bathroom", isCompleted: true),
                HomeTask(title: "Laundry", isCompleted: true)
            ],
            now: now,
            calendar: makeCalendar()
        )

        XCTAssertNil(nudge)
    }

    func testEveningReflectionNudgePrioritizesHomeWrappedAfterSixWhenAllHomeTasksCompleted() {
        let now = makeDate("2026-04-08T18:01:00Z")
        let entry = DailyEntry(date: now)

        let nudge = TodayStore.eveningReflectionNudge(
            for: entry,
            homeTasks: [
                HomeTask(title: "Clean bathroom", isCompleted: true),
                HomeTask(title: "Laundry", isCompleted: true)
            ],
            now: now,
            calendar: makeCalendar()
        )

        XCTAssertEqual(nudge?.title, "Home wrapped")
        XCTAssertEqual(nudge?.message, "All home tasks are done. Close the day with one quick reflection.")
    }

    func testEveningReflectionNudgeStaysHiddenWhenReflectionExists() {
        let now = makeDate("2026-04-08T20:00:00Z")
        let entry = DailyEntry(date: now, eveningReflection: "Closed the day.")

        let nudge = TodayStore.eveningReflectionNudge(
            for: entry,
            homeTasks: [HomeTask(title: "Clean bathroom", isCompleted: true)],
            now: now,
            calendar: makeCalendar()
        )

        XCTAssertNil(nudge)
    }

    func testPromptNotificationsIncludeCheckInDuringDayWhenMissing() {
        let now = makeDate("2026-04-08T10:05:00Z")
        let entry = DailyEntry(date: now)

        let prompts = TodayStore.promptNotifications(
            for: entry,
            homeTasks: [],
            now: now,
            calendar: makeCalendar()
        )

        XCTAssertEqual(prompts.first?.kind, .checkIn)
        XCTAssertEqual(prompts.first?.title, "Check-in")
    }

    func testPromptNotificationsScheduleGenericReflectionBeforeEveningWhenHomeTasksAreDone() {
        let now = makeDate("2026-04-08T12:05:00Z")
        let entry = DailyEntry(date: now)

        let prompts = TodayStore.promptNotifications(
            for: entry,
            homeTasks: [
                HomeTask(title: "Laundry", isCompleted: true),
                HomeTask(title: "Kitchen", isCompleted: true)
            ],
            now: now,
            calendar: makeCalendar()
        )

        XCTAssertTrue(prompts.contains(where: { $0.kind == .eveningReflection }))
        XCTAssertFalse(prompts.contains(where: { $0.kind == .homeWrappedReflection }))
    }

    func testPromptNotificationsPrioritizeHomeWrappedReflectionAfterEveningWhenHomeTasksAreDone() {
        let now = makeDate("2026-04-08T18:05:00Z")
        let entry = DailyEntry(date: now)

        let prompts = TodayStore.promptNotifications(
            for: entry,
            homeTasks: [
                HomeTask(title: "Laundry", isCompleted: true),
                HomeTask(title: "Kitchen", isCompleted: true)
            ],
            now: now,
            calendar: makeCalendar()
        )

        let homePrompt = prompts.first { $0.kind == .homeWrappedReflection }
        XCTAssertNotNil(homePrompt)
        XCTAssertEqual(homePrompt?.body, "All home tasks are done. Close the day with one quick reflection.")
    }

    // MARK: - addFocusItem

    func testAddFocusItemAppends() async {
        let repository = InMemoryTodayEntryRepository(calendar: makeCalendar())
        let today = makeDate("2026-04-08T10:00:00Z")
        let saved = DailyEntry(date: today, focusThree: [])
        try? repository.saveEntry(saved)

        let store = await MainActor.run {
            TodayStore(clock: FixedClock(now: today), repository: repository, calendar: makeCalendar())
        }

        await MainActor.run { store.addFocusItem(title: "New item", domain: .training) }

        let state = await MainActor.run { store.entryState }
        guard case .active(let entry) = state else {
            return XCTFail("Expected active state")
        }
        XCTAssertEqual(entry.focusThree.count, 1)
        XCTAssertEqual(entry.focusThree[0].title, "New item")
        XCTAssertEqual(entry.focusThree[0].domain, .training)
    }

    func testAddFocusItemCapsAtThree() async {
        let repository = InMemoryTodayEntryRepository(calendar: makeCalendar())
        let today = makeDate("2026-04-08T10:00:00Z")
        let saved = DailyEntry(date: today, focusThree: [
            FocusItem(title: "A", domain: .home),
            FocusItem(title: "B", domain: .home),
            FocusItem(title: "C", domain: .home)
        ])
        try? repository.saveEntry(saved)

        let store = await MainActor.run {
            TodayStore(clock: FixedClock(now: today), repository: repository, calendar: makeCalendar())
        }

        await MainActor.run { store.addFocusItem(title: "D", domain: .home) }

        let state = await MainActor.run { store.entryState }
        guard case .active(let entry) = state else {
            return XCTFail("Expected active state")
        }
        XCTAssertEqual(entry.focusThree.count, 3)
        XCTAssertFalse(entry.focusThree.contains(where: { $0.title == "D" }))
    }

    func testAddFocusItemWithLinkedRecordID() async {
        let repository = InMemoryTodayEntryRepository(calendar: makeCalendar())
        let today = makeDate("2026-04-08T10:00:00Z")
        let saved = DailyEntry(date: today, focusThree: [])
        try? repository.saveEntry(saved)

        let store = await MainActor.run {
            TodayStore(clock: FixedClock(now: today), repository: repository, calendar: makeCalendar())
        }

        let linkedID = UUID()
        await MainActor.run { store.addFocusItem(title: "Morning run", domain: .training, linkedRecordID: linkedID) }

        let state = await MainActor.run { store.entryState }
        guard case .active(let entry) = state else {
            return XCTFail("Expected active state")
        }
        XCTAssertEqual(entry.focusThree.count, 1)
        XCTAssertEqual(entry.focusThree[0].linkedRecordID, linkedID)
        XCTAssertEqual(entry.focusThree[0].domain, .training)
    }

    func testPromoteWritingNoteToTodayCreatesLinkedFocusItemAndPreservesRouteTarget() async {
        let repository = InMemoryTodayEntryRepository(calendar: makeCalendar())
        let today = makeDate("2026-04-08T10:00:00Z")
        try? repository.saveEntry(DailyEntry(date: today, focusThree: []))
        let note = WritingNote(
            id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!,
            title: "Email John about AWS billing",
            body: "Send estimate before noon.",
            stage: .capture
        )

        let store = await MainActor.run {
            TodayStore(clock: FixedClock(now: today), repository: repository, calendar: makeCalendar())
        }

        let promoted = await MainActor.run { store.promoteWritingNoteToToday(note) }

        XCTAssertTrue(promoted)
        let state = await MainActor.run { store.entryState }
        guard case .active(let entry) = state else {
            return XCTFail("Expected active state")
        }

        guard let focus = entry.focusThree.first else {
            return XCTFail("Expected promoted focus item")
        }
        XCTAssertEqual(focus.title, "Email John about AWS billing")
        XCTAssertEqual(focus.domain, .writing)
        XCTAssertEqual(focus.linkedRecordID, note.id)
        XCTAssertEqual(focus.origin?.kind, .writingNote)
        XCTAssertEqual(focus.origin?.id, note.id)
        XCTAssertEqual(focus.origin?.createdAt, today)

        let continueItem = TodayContinuationRules.derive(
            todayEntry: entry,
            calibration: CalibrationRules.Calibration(
                enhancedNudge: nil,
                completionContext: nil,
                staleItems: [],
                domainNudge: nil,
                suggestedFocusLoad: 3,
                writingNudge: nil,
                trainingSummary: nil
            ),
            todaySessions: [],
            homeTasks: [],
            homeRuns: [],
            writingNotes: [note]
        ).first

        XCTAssertEqual(continueItem?.highlightTarget, .writingNote(note.id))
        let loaded = try? repository.loadEntry(for: today)
        XCTAssertEqual(loaded?.focusThree.first?.origin, focus.origin)
    }

    func testPromoteWritingNoteToTodayRejectsDuplicatePromotion() async {
        let repository = InMemoryTodayEntryRepository(calendar: makeCalendar())
        let today = makeDate("2026-04-08T10:00:00Z")
        let note = WritingNote(title: "Email John", body: "")
        try? repository.saveEntry(
            DailyEntry(
                date: today,
                focusThree: [
                    FocusItem(title: "Email John", domain: .writing, linkedRecordID: note.id)
                ]
            )
        )

        let store = await MainActor.run {
            TodayStore(clock: FixedClock(now: today), repository: repository, calendar: makeCalendar())
        }

        let canPromote = await MainActor.run { store.canPromoteWritingNoteToToday(note) }
        let promoted = await MainActor.run { store.promoteWritingNoteToToday(note) }

        XCTAssertFalse(canPromote)
        XCTAssertFalse(promoted)
        let state = await MainActor.run { store.entryState }
        guard case .active(let entry) = state else {
            return XCTFail("Expected active state")
        }
        XCTAssertEqual(entry.focusThree.count, 1)
    }

    func testSourceBackedContinueItemCanBeAddedToFocusWithSourceLink() async {
        let repository = InMemoryTodayEntryRepository(calendar: makeCalendar())
        let today = makeDate("2026-04-08T10:00:00Z")
        try? repository.saveEntry(DailyEntry(date: today))

        let store = await MainActor.run {
            TodayStore(clock: FixedClock(now: today), repository: repository, calendar: makeCalendar())
        }

        let sourceID = UUID()
        let item = TodayContinuationRules.ContinueItem(
            id: "home-task",
            title: "Laundry",
            domain: .home,
            reason: "Active",
            source: .homeTask(sourceID),
            linkedRecordID: nil,
            staleDayCount: nil,
            urgencyScore: nil,
            priority: .active,
            originalIndex: 0
        )

        let canAdd = await MainActor.run { store.canAddContinueItemToFocus(item) }
        XCTAssertTrue(canAdd)

        await MainActor.run { store.addContinueItemToFocus(item) }

        let state = await MainActor.run { store.entryState }
        guard case .active(let entry) = state else {
            return XCTFail("Expected active state")
        }
        XCTAssertEqual(entry.focusThree.map(\.title), ["Laundry"])
        XCTAssertEqual(entry.focusThree.first?.domain, .home)
        XCTAssertEqual(entry.focusThree.first?.linkedRecordID, sourceID)

        let loaded = try? repository.loadEntry(for: today)
        XCTAssertEqual(loaded?.focusThree.first?.linkedRecordID, sourceID)
    }

    func testContinueAddToFocusIsUnavailableForActiveHomeProtocolRuns() async {
        let repository = InMemoryTodayEntryRepository(calendar: makeCalendar())
        let today = makeDate("2026-04-08T10:00:00Z")
        try? repository.saveEntry(DailyEntry(date: today))

        let store = await MainActor.run {
            TodayStore(clock: FixedClock(now: today), repository: repository, calendar: makeCalendar())
        }

        let runID = UUID()
        let item = TodayContinuationRules.ContinueItem(
            id: "home-run",
            title: "Kitchen reset",
            domain: .home,
            reason: "Protocol run",
            source: .homeProtocolRun(runID),
            linkedRecordID: nil,
            staleDayCount: nil,
            urgencyScore: nil,
            priority: .active,
            originalIndex: 0
        )

        let canAdd = await MainActor.run { store.canAddContinueItemToFocus(item) }
        XCTAssertFalse(canAdd)

        await MainActor.run { store.addContinueItemToFocus(item) }

        let state = await MainActor.run { store.entryState }
        guard case .active(let entry) = state else {
            return XCTFail("Expected active state")
        }
        XCTAssertTrue(entry.focusThree.isEmpty)
    }

    func testContinueAddToFocusIsUnavailableForCarriedFocusItems() async {
        let repository = InMemoryTodayEntryRepository(calendar: makeCalendar())
        let today = makeDate("2026-04-08T10:00:00Z")
        let carried = FocusItem(title: "Draft outline", domain: .writing, status: .planned)
        try? repository.saveEntry(DailyEntry(date: today, focusThree: [carried], carryForward: [carried]))

        let store = await MainActor.run {
            TodayStore(clock: FixedClock(now: today), repository: repository, calendar: makeCalendar())
        }

        let item = TodayContinuationRules.ContinueItem(
            id: "carried",
            title: "Draft outline",
            domain: .writing,
            reason: "Carried forward",
            source: .carriedFocusItem(carried.id),
            linkedRecordID: nil,
            staleDayCount: 3,
            urgencyScore: nil,
            priority: .carriedForward,
            originalIndex: 0
        )

        let canAdd = await MainActor.run { store.canAddContinueItemToFocus(item) }
        XCTAssertFalse(canAdd)

        await MainActor.run { store.addContinueItemToFocus(item) }

        let state = await MainActor.run { store.entryState }
        guard case .active(let entry) = state else {
            return XCTFail("Expected active state")
        }
        XCTAssertEqual(entry.focusThree.count, 1)
        XCTAssertEqual(entry.focusThree.first?.id, carried.id)
    }

    func testContinueAddToFocusIsUnavailableWhenMatchingFocusAlreadyExists() async {
        let repository = InMemoryTodayEntryRepository(calendar: makeCalendar())
        let today = makeDate("2026-04-08T10:00:00Z")
        try? repository.saveEntry(
            DailyEntry(
                date: today,
                focusThree: [FocusItem(title: "Laundry", domain: .home)]
            )
        )

        let store = await MainActor.run {
            TodayStore(clock: FixedClock(now: today), repository: repository, calendar: makeCalendar())
        }

        let item = TodayContinuationRules.ContinueItem(
            id: "home-task",
            title: "Laundry",
            domain: .home,
            reason: "Active",
            source: .homeTask(UUID()),
            linkedRecordID: nil,
            staleDayCount: nil,
            urgencyScore: nil,
            priority: .active,
            originalIndex: 0
        )

        let canAdd = await MainActor.run { store.canAddContinueItemToFocus(item) }
        XCTAssertFalse(canAdd)
    }

    func testGarbageCollectHomeProtocolFocusArtifactsRemovesInvalidProtocolLinks() async {
        let repository = InMemoryTodayEntryRepository(calendar: makeCalendar())
        let today = makeDate("2026-04-08T10:00:00Z")
        let protocolTemplateID = UUID()
        let protocolRunID = UUID()
        let protocolTemplateArtifact = FocusItem(
            title: "Afternoon routine",
            domain: .home,
            status: .planned,
            linkedRecordID: protocolTemplateID
        )
        let protocolArtifact = FocusItem(
            title: "Kitchen reset",
            domain: .home,
            status: .planned,
            linkedRecordID: protocolRunID
        )
        let keepFocus = FocusItem(
            title: "Laundry",
            domain: .home,
            status: .planned,
            linkedRecordID: UUID()
        )
        let keepCarry = FocusItem(
            title: "Essay draft",
            domain: .writing,
            status: .planned,
            linkedRecordID: UUID()
        )
        try? repository.saveEntry(
            DailyEntry(
                date: today,
                focusThree: [protocolTemplateArtifact, protocolArtifact, keepFocus],
                carryForward: [protocolTemplateArtifact, protocolArtifact, keepCarry]
            )
        )

        let store = await MainActor.run {
            TodayStore(clock: FixedClock(now: today), repository: repository, calendar: makeCalendar())
        }

        await MainActor.run {
            store.garbageCollectHomeProtocolFocusArtifacts(
                protocolRecordIDs: Set([protocolTemplateID, protocolRunID])
            )
        }

        let state = await MainActor.run { store.entryState }
        guard case .active(let entry) = state else {
            return XCTFail("Expected active state")
        }
        XCTAssertEqual(entry.focusThree.map(\.title), ["Laundry"])
        XCTAssertEqual(entry.carryForward.map(\.title), ["Essay draft"])

        let loaded = try? repository.loadEntry(for: today)
        XCTAssertEqual(loaded?.focusThree.map(\.title), ["Laundry"])
        XCTAssertEqual(loaded?.carryForward.map(\.title), ["Essay draft"])
    }

    func testContinueAddToFocusIsUnavailableWhenFocusThreeIsFull() async {
        let repository = InMemoryTodayEntryRepository(calendar: makeCalendar())
        let today = makeDate("2026-04-08T10:00:00Z")
        try? repository.saveEntry(
            DailyEntry(
                date: today,
                focusThree: [
                    FocusItem(title: "One", domain: .home),
                    FocusItem(title: "Two", domain: .career),
                    FocusItem(title: "Three", domain: .writing),
                ]
            )
        )

        let store = await MainActor.run {
            TodayStore(clock: FixedClock(now: today), repository: repository, calendar: makeCalendar())
        }

        let item = TodayContinuationRules.ContinueItem(
            id: "training",
            title: "Intervals",
            domain: .training,
            reason: "Due today",
            source: .trainingSession(UUID()),
            linkedRecordID: nil,
            staleDayCount: nil,
            urgencyScore: nil,
            priority: .dueToday,
            originalIndex: 0
        )

        let canAdd = await MainActor.run { store.canAddContinueItemToFocus(item) }
        XCTAssertFalse(canAdd)
    }

    // MARK: - focusSuggestionDrafts

    func testFocusSuggestionsRespectCalibrationLoadAndCapAtThree() async {
        let repository = InMemoryTodayEntryRepository(calendar: makeCalendar())
        let today = makeDate("2026-04-08T10:00:00Z")
        let saved = DailyEntry(
            date: today,
            energy: 2,
            mood: 2,
            sleepQuality: 3
        )
        try? repository.saveEntry(saved)

        let store = await MainActor.run {
            TodayStore(clock: FixedClock(now: today), repository: repository, calendar: makeCalendar())
        }

        let snapshot = PatternSnapshot(
            generatedAt: today,
            windowEnd: today,
            windowDays: 7,
            completionRate: CompletionRatePattern(doneCount: 2, totalCount: 5, deferredCount: 0, droppedCount: 0),
            readinessOutcome: ReadinessOutcomePattern(
                lowReadinessAvgCompletion: 0.2,
                highReadinessAvgCompletion: 0.8,
                overplanningOnLowDays: true,
                sampleCount: 3
            )
        )

        let candidates: [TodayStore.FocusSuggestionCandidate] = [
            .init(title: "Write outline", domain: .writing, reason: "In progress", priority: 0),
            .init(title: "Clean kitchen", domain: .home, reason: "Active", priority: 1),
            .init(title: "Morning run", domain: .training, reason: "Due today", priority: 2),
            .init(title: "Review notes", domain: .career, reason: "Active", priority: 3)
        ]

        await MainActor.run {
            store.refreshFocusSuggestions(todayEntry: saved, weeklySnapshot: snapshot, candidates: candidates)
        }

        let drafts = await MainActor.run { store.focusSuggestionDrafts }
        XCTAssertEqual(drafts.count, 1)
        XCTAssertEqual(drafts.first?.title, "Write outline")
        XCTAssertEqual(drafts.first?.domain, .writing)
    }

    func testFocusSuggestionsDoNotDraftWhenFocusThreeIsFull() async {
        let repository = InMemoryTodayEntryRepository(calendar: makeCalendar())
        let today = makeDate("2026-04-08T10:00:00Z")
        let saved = DailyEntry(
            date: today,
            focusThree: [
                FocusItem(title: "Done", domain: .training, status: .done),
                FocusItem(title: "Deferred", domain: .writing, status: .deferred),
                FocusItem(title: "Dropped", domain: .home, status: .dropped)
            ]
        )
        try? repository.saveEntry(saved)

        let store = await MainActor.run {
            TodayStore(clock: FixedClock(now: today), repository: repository, calendar: makeCalendar())
        }

        await MainActor.run {
            store.refreshFocusSuggestions(
                todayEntry: saved,
                weeklySnapshot: nil,
                candidates: [
                    .init(title: "Morning run", domain: .training, reason: "Due today", priority: 0)
                ]
            )
        }

        let drafts = await MainActor.run { store.focusSuggestionDrafts }
        XCTAssertTrue(drafts.isEmpty)
    }

    func testAcceptFocusSuggestionUsesAddFocusItemAndPersists() async {
        let repository = InMemoryTodayEntryRepository(calendar: makeCalendar())
        let today = makeDate("2026-04-08T10:00:00Z")
        let saved = DailyEntry(date: today)
        try? repository.saveEntry(saved)

        let store = await MainActor.run {
            TodayStore(clock: FixedClock(now: today), repository: repository, calendar: makeCalendar())
        }

        let candidates: [TodayStore.FocusSuggestionCandidate] = [
            .init(title: "Morning run", domain: .training, reason: "Due today", priority: 0)
        ]

        await MainActor.run {
            store.refreshFocusSuggestions(todayEntry: saved, weeklySnapshot: nil, candidates: candidates)
        }

        let draftID = await MainActor.run { store.focusSuggestionDrafts.first?.id }
        guard let draftID else {
            return XCTFail("Expected a focus suggestion draft")
        }

        await MainActor.run { store.acceptFocusSuggestion(id: draftID) }

        let state = await MainActor.run { store.entryState }
        guard case .active(let entry) = state else {
            return XCTFail("Expected active state")
        }
        XCTAssertEqual(entry.focusThree.map(\.title), ["Morning run"])

        let loaded = try? repository.loadEntry(for: today)
        XCTAssertEqual(loaded?.focusThree.map(\.title), ["Morning run"])
        let draftsRemaining = await MainActor.run { store.focusSuggestionDrafts.isEmpty }
        XCTAssertTrue(draftsRemaining)
    }

    func testDismissFocusSuggestionDoesNotPersist() async {
        let repository = InMemoryTodayEntryRepository(calendar: makeCalendar())
        let today = makeDate("2026-04-08T10:00:00Z")
        let saved = DailyEntry(date: today)
        try? repository.saveEntry(saved)

        let store = await MainActor.run {
            TodayStore(clock: FixedClock(now: today), repository: repository, calendar: makeCalendar())
        }

        let candidates: [TodayStore.FocusSuggestionCandidate] = [
            .init(title: "Clean kitchen", domain: .home, reason: "Active", priority: 0)
        ]

        await MainActor.run {
            store.refreshFocusSuggestions(todayEntry: saved, weeklySnapshot: nil, candidates: candidates)
        }

        let draftID = await MainActor.run { store.focusSuggestionDrafts.first?.id }
        guard let draftID else {
            return XCTFail("Expected a focus suggestion draft")
        }

        await MainActor.run { store.dismissFocusSuggestion(id: draftID) }

        let draftsCleared = await MainActor.run { store.focusSuggestionDrafts.isEmpty }
        XCTAssertTrue(draftsCleared)
        let loaded = try? repository.loadEntry(for: today)
        XCTAssertTrue(loaded?.focusThree.isEmpty ?? true)

        await MainActor.run {
            store.refreshFocusSuggestions(todayEntry: saved, weeklySnapshot: nil, candidates: candidates)
        }
        let draftsStillCleared = await MainActor.run { store.focusSuggestionDrafts.isEmpty }
        XCTAssertTrue(draftsStillCleared)
    }

    func testFocusSuggestionCandidatesUsePastCompletionsAndCheckInStatus() {
        let today = DailyEntry(
            date: makeDate("2026-04-08T10:00:00Z"),
            energy: 2,
            mood: 2,
            sleepQuality: 2
        )
        let recentEntries = [
            DailyEntry(
                date: makeDate("2026-04-07T10:00:00Z"),
                focusThree: [
                    FocusItem(title: "Water plants", domain: .home, status: .done),
                    FocusItem(title: "Draft pitch", domain: .career, status: .planned)
                ],
                energy: 2,
                mood: 2,
                sleepQuality: 2
            ),
            DailyEntry(
                date: makeDate("2026-04-06T10:00:00Z"),
                focusThree: [
                    FocusItem(title: "Water plants", domain: .home, status: .done)
                ],
                energy: 4,
                mood: 4,
                sleepQuality: 4
            )
        ]

        let candidates = TodayStore.makeFocusSuggestionCandidates(
            todayEntry: today,
            recentEntries: recentEntries,
            predictions: [:],
            now: makeDate("2026-04-08T10:00:00Z"),
            calendar: makeCalendar()
        )

        XCTAssertEqual(candidates.map(\.title), ["Water plants"])
        XCTAssertEqual(candidates.first?.domain, .home)
        XCTAssertTrue(candidates.first?.reason.contains("low-readiness") ?? false)
        XCTAssertFalse(candidates.contains { $0.title == "Draft pitch" })
    }

    func testFocusSuggestionCandidatesExcludeThingsAlreadyActiveToday() {
        let today = DailyEntry(
            date: makeDate("2026-04-08T10:00:00Z"),
            focusThree: [
                FocusItem(title: "Water plants", domain: .home)
            ]
        )
        let recentEntries = [
            DailyEntry(
                date: makeDate("2026-04-07T10:00:00Z"),
                focusThree: [
                    FocusItem(title: "Water plants", domain: .home, status: .done),
                    FocusItem(title: "Morning run", domain: .training, status: .done)
                ]
            )
        ]

        let candidates = TodayStore.makeFocusSuggestionCandidates(
            todayEntry: today,
            recentEntries: recentEntries,
            predictions: [
                CompletionTimePredictor.key(forTrainingSession: "Morning run"): CompletionTimePredictor.Prediction(
                    itemKey: CompletionTimePredictor.key(forTrainingSession: "Morning run"),
                    medianTimeOfDay: 7 * 3600,
                    madSeconds: 0,
                    sampleCount: 4
                )
            ],
            now: makeDate("2026-04-08T10:00:00Z"),
            calendar: makeCalendar(),
            activeItems: [
                TodayStore.FocusSuggestionActiveItem(title: "Morning run", domain: .training)
            ]
        )

        XCTAssertTrue(candidates.isEmpty)
    }

    func testFocusSuggestionCandidatesFallbackToCompletionTimePredictions() {
        let today = DailyEntry(date: makeDate("2026-04-08T10:00:00Z"))
        let predictionKey = CompletionTimePredictor.key(forProtocolRun: "Kitchen Reset")

        let candidates = TodayStore.makeFocusSuggestionCandidates(
            todayEntry: today,
            recentEntries: [],
            predictions: [
                predictionKey: CompletionTimePredictor.Prediction(
                    itemKey: predictionKey,
                    medianTimeOfDay: 19 * 3600,
                    madSeconds: 30 * 60,
                    sampleCount: 5
                )
            ],
            now: makeDate("2026-04-08T18:30:00Z"),
            calendar: makeCalendar()
        )

        XCTAssertEqual(candidates.map(\.title), ["Kitchen Reset"])
        XCTAssertEqual(candidates.first?.domain, .home)
        XCTAssertTrue(candidates.first?.reason.contains("Usually completed around 7 PM") ?? false)
    }

    // MARK: - removeFocusItem

    func testRemoveFocusItem() async {
        let repository = InMemoryTodayEntryRepository(calendar: makeCalendar())
        let today = makeDate("2026-04-08T10:00:00Z")
        let item = FocusItem(title: "Remove me", domain: .home)
        let saved = DailyEntry(date: today, focusThree: [item])
        try? repository.saveEntry(saved)

        let store = await MainActor.run {
            TodayStore(clock: FixedClock(now: today), repository: repository, calendar: makeCalendar())
        }

        await MainActor.run { store.removeFocusItem(id: item.id) }

        let state = await MainActor.run { store.entryState }
        guard case .active(let entry) = state else {
            return XCTFail("Expected active state")
        }
        XCTAssertTrue(entry.focusThree.isEmpty)
    }

    // MARK: - updateStatus

    func testUpdateStatusChangesItemStatus() async {
        let repository = InMemoryTodayEntryRepository(calendar: makeCalendar())
        let today = makeDate("2026-04-08T10:00:00Z")
        let item = FocusItem(title: "Do this", domain: .career, status: .planned)
        let saved = DailyEntry(date: today, focusThree: [item])
        try? repository.saveEntry(saved)

        let store = await MainActor.run {
            TodayStore(clock: FixedClock(now: today), repository: repository, calendar: makeCalendar())
        }

        await MainActor.run { store.updateStatus(for: item.id, to: .done) }

        let state = await MainActor.run { store.entryState }
        guard case .active(let entry) = state else {
            return XCTFail("Expected active state")
        }
        XCTAssertEqual(entry.focusThree[0].status, .done)

        let loaded = try? repository.loadEntry(for: today)
        XCTAssertEqual(loaded?.focusThree.first?.status, .done)
    }

    func testMarkLinkedFocusItemsDoneCompletesPlannedSourceBackedItems() async {
        let repository = InMemoryTodayEntryRepository(calendar: makeCalendar())
        let today = makeDate("2026-04-08T10:00:00Z")
        let trainingID = UUID()
        let homeID = UUID()
        let unrelatedID = UUID()
        let saved = DailyEntry(
            date: today,
            focusThree: [
                FocusItem(title: "Morning run", domain: .training, status: .planned, linkedRecordID: trainingID),
                FocusItem(title: "Laundry", domain: .home, status: .planned, linkedRecordID: homeID),
                FocusItem(title: "Draft", domain: .writing, status: .planned, linkedRecordID: unrelatedID),
                FocusItem(title: "Standalone", domain: .career, status: .planned)
            ]
        )
        try? repository.saveEntry(saved)

        let store = await MainActor.run {
            TodayStore(clock: FixedClock(now: today), repository: repository, calendar: makeCalendar())
        }

        await MainActor.run {
            store.markLinkedFocusItemsDone(for: [
                TodayFocusCompletionSource(domain: .training, linkedRecordID: trainingID),
                TodayFocusCompletionSource(domain: .home, linkedRecordID: homeID)
            ])
        }

        let loaded = try? repository.loadEntry(for: today)
        XCTAssertEqual(loaded?.focusThree.map(\.status) ?? [], [.done, .done, .planned, .planned])
    }

    func testMarkLinkedFocusItemsDoneDoesNotOverrideDeferredOrDroppedItems() async {
        let repository = InMemoryTodayEntryRepository(calendar: makeCalendar())
        let today = makeDate("2026-04-08T10:00:00Z")
        let deferredID = UUID()
        let droppedID = UUID()
        let saved = DailyEntry(
            date: today,
            focusThree: [
                FocusItem(title: "Deferred source", domain: .home, status: .deferred, linkedRecordID: deferredID),
                FocusItem(title: "Dropped source", domain: .training, status: .dropped, linkedRecordID: droppedID)
            ]
        )
        try? repository.saveEntry(saved)

        let store = await MainActor.run {
            TodayStore(clock: FixedClock(now: today), repository: repository, calendar: makeCalendar())
        }

        await MainActor.run {
            store.markLinkedFocusItemsDone(for: [
                TodayFocusCompletionSource(domain: .home, linkedRecordID: deferredID),
                TodayFocusCompletionSource(domain: .training, linkedRecordID: droppedID)
            ])
        }

        let loaded = try? repository.loadEntry(for: today)
        XCTAssertEqual(loaded?.focusThree.map(\.status) ?? [], [.deferred, .dropped])
    }

    func testCarriedContinueItemSourceCanDeferOriginalFocusItem() async {
        let repository = InMemoryTodayEntryRepository(calendar: makeCalendar())
        let today = makeDate("2026-04-08T10:00:00Z")
        let item = FocusItem(title: "Draft outline", domain: .writing, status: .planned)
        let saved = DailyEntry(date: today, focusThree: [item], carryForward: [item])
        try? repository.saveEntry(saved)

        let store = await MainActor.run {
            TodayStore(clock: FixedClock(now: today), repository: repository, calendar: makeCalendar())
        }

        let snapshot = PatternSnapshot(
            generatedAt: today,
            windowEnd: today,
            windowDays: 7,
            completionRate: CompletionRatePattern(doneCount: 1, totalCount: 3, deferredCount: 0, droppedCount: 0),
            carryForward: CarryForwardPattern(
                averageCarriedPerDay: 1,
                stalledItems: [
                    .init(title: "Draft outline", domain: .writing, consecutiveDays: 3)
                ]
            )
        )
        let continueItems = TodayContinuationRules.derive(
            todayEntry: saved,
            calibration: CalibrationRules.calibrate(todayEntry: saved, weeklySnapshot: snapshot),
            todaySessions: [],
            homeTasks: [],
            homeRuns: [],
            writingNotes: []
        )
        guard case .carriedFocusItem(let itemID) = continueItems.first?.source else {
            return XCTFail("Expected carried focus item source")
        }

        await MainActor.run { store.updateStatus(for: itemID, to: .deferred) }

        let state = await MainActor.run { store.entryState }
        guard case .active(let entry) = state else {
            return XCTFail("Expected active state")
        }
        XCTAssertEqual(entry.focusThree.first?.status, .deferred)

        let loaded = try? repository.loadEntry(for: today)
        XCTAssertEqual(loaded?.focusThree.first?.status, .deferred)
    }

    // MARK: - updateReadiness

    func testUpdateReadinessSetsValues() async {
        let repository = InMemoryTodayEntryRepository(calendar: makeCalendar())
        let today = makeDate("2026-04-08T10:00:00Z")
        let saved = DailyEntry(date: today)
        try? repository.saveEntry(saved)

        let store = await MainActor.run {
            TodayStore(clock: FixedClock(now: today), repository: repository, calendar: makeCalendar())
        }

        await MainActor.run { store.updateReadiness(energy: 4, mood: 3, sleepQuality: 5) }

        let state = await MainActor.run { store.entryState }
        guard case .active(let entry) = state else {
            return XCTFail("Expected active state")
        }
        XCTAssertEqual(entry.energy, 4)
        XCTAssertEqual(entry.mood, 3)
        XCTAssertEqual(entry.sleepQuality, 5)
    }

    // MARK: - updateDomainIntention

    func testUpdateDomainIntentionSetsText() async {
        let repository = InMemoryTodayEntryRepository(calendar: makeCalendar())
        let today = makeDate("2026-04-08T10:00:00Z")
        let saved = DailyEntry(date: today)
        try? repository.saveEntry(saved)

        let store = await MainActor.run {
            TodayStore(clock: FixedClock(now: today), repository: repository, calendar: makeCalendar())
        }

        await MainActor.run { store.updateDomainIntention(domain: .training, text: "Run 5K today") }

        let state = await MainActor.run { store.entryState }
        guard case .active(let entry) = state else {
            return XCTFail("Expected active state")
        }
        XCTAssertEqual(entry.domainIntentions[.training], "Run 5K today")
    }

    func testLoadRecentEntriesSortsNewestFirstAndExcludesToday() async {
        let repository = InMemoryTodayEntryRepository(calendar: makeCalendar())
        let threeDaysAgo = makeDate("2026-04-05T10:00:00Z")
        let yesterday = makeDate("2026-04-07T10:00:00Z")
        let today = makeDate("2026-04-08T10:00:00Z")

        try? repository.saveEntry(
            DailyEntry(date: threeDaysAgo, focusThree: [FocusItem(title: "Oldest", domain: .home)])
        )
        try? repository.saveEntry(
            DailyEntry(date: yesterday, focusThree: [FocusItem(title: "Newest prior", domain: .home)])
        )
        try? repository.saveEntry(
            DailyEntry(date: today, focusThree: [FocusItem(title: "Today", domain: .home)])
        )

        let store = await MainActor.run {
            TodayStore(clock: FixedClock(now: today), repository: repository, calendar: makeCalendar())
        }

        let recentEntries = await MainActor.run { store.recentEntries }
        XCTAssertEqual(recentEntries.map { $0.focusThree.first?.title ?? "" }, ["Newest prior", "Oldest"])
        XCTAssertFalse(recentEntries.contains { makeCalendar().startOfDay(for: $0.date) == makeCalendar().startOfDay(for: today) })
    }

    func testFileTodayEntryRepositoryLoadsLegacyTrajectoryEntryAndSavesIntoOwloryDirectory() throws {
        let appSupport = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: appSupport) }

        let date = makeDate("2026-04-08T10:00:00Z")
        let legacyURL = OwloryAppSupportPath.legacyFileURL(
            in: appSupport,
            subdirectory: "TodayEntries",
            fileName: "2026-04-08.json"
        )
        try FileManager.default.createDirectory(
            at: legacyURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let entry = DailyEntry(
            date: date,
            focusThree: [FocusItem(title: "Legacy plan", domain: .home)]
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(entry).write(to: legacyURL, options: .atomic)

        let repository = FileTodayEntryRepository(
            appSupportDirectory: appSupport,
            calendar: makeCalendar()
        )

        let loaded = try repository.loadEntry(for: date)
        XCTAssertEqual(loaded?.focusThree.map(\.title), ["Legacy plan"])

        let currentURL = OwloryAppSupportPath.currentFileURL(
            in: appSupport,
            subdirectory: "TodayEntries",
            fileName: "2026-04-08.json"
        )
        XCTAssertFalse(FileManager.default.fileExists(atPath: currentURL.path))

        try repository.saveEntry(entry)

        XCTAssertTrue(FileManager.default.fileExists(atPath: currentURL.path))
    }

    // MARK: - Helpers

    private func makeCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func makeDate(_ value: String) -> Date {
        ISO8601DateFormatter().date(from: value)!
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
