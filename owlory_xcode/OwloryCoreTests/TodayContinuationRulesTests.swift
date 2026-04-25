import XCTest
#if SWIFT_PACKAGE
@testable import OwloryCore
#endif

final class TodayContinuationRulesTests: XCTestCase {
    func testDerivesStaleCarryForwardWithoutMutatingHistoricalCarryForward() {
        let today = makeDate("2026-04-08T10:00:00Z")
        let carried = FocusItem(title: "Write outline", domain: .writing, status: .planned)
        let entry = DailyEntry(
            date: today,
            focusThree: [carried],
            carryForward: [carried]
        )
        let originalEntry = entry
        let snapshot = PatternSnapshot(
            generatedAt: today,
            windowEnd: today,
            windowDays: 7,
            completionRate: CompletionRatePattern(doneCount: 3, totalCount: 6, deferredCount: 1, droppedCount: 0),
            carryForward: CarryForwardPattern(
                averageCarriedPerDay: 1,
                stalledItems: [
                    .init(title: "Write outline", domain: .writing, consecutiveDays: 4)
                ]
            )
        )

        let items = TodayContinuationRules.derive(
            todayEntry: entry,
            calibration: CalibrationRules.calibrate(todayEntry: entry, weeklySnapshot: snapshot),
            todaySessions: [],
            homeTasks: [],
            homeRuns: [],
            writingNotes: []
        )

        XCTAssertEqual(entry, originalEntry)
        XCTAssertEqual(entry.carryForward, [carried])
        XCTAssertEqual(items.map(\.title), ["Write outline"])
        XCTAssertEqual(items.first?.reason, "Carried forward")
        XCTAssertEqual(items.first?.staleDayCount, 4)
    }

    func testPlannedTrainingSessionsHavePriority() {
        let today = makeDate("2026-04-08T10:00:00Z")
        let entry = DailyEntry(date: today)
        let sessions = [
            TrainingSession(date: today, plannedActivity: "Intervals", status: .planned),
            TrainingSession(date: today, plannedActivity: "Skipped mobility", status: .skipped)
        ]
        let homeTasks = [
            HomeTask(title: "Clean kitchen")
        ]

        let items = TodayContinuationRules.derive(
            todayEntry: entry,
            calibration: CalibrationRules.calibrate(todayEntry: entry, weeklySnapshot: nil),
            todaySessions: sessions,
            homeTasks: homeTasks,
            homeRuns: [],
            writingNotes: []
        )

        XCTAssertEqual(items.map(\.title), ["Intervals", "Clean kitchen"])
        XCTAssertEqual(items.first?.domain, .training)
        XCTAssertFalse(items.contains { $0.title == "Skipped mobility" })
    }

    func testSkippedHomeTasksAreExcluded() {
        let today = makeDate("2026-04-08T10:00:00Z")
        let entry = DailyEntry(date: today)
        let homeTasks = [
            HomeTask(title: "Clean kitchen", isSkipped: true),
            HomeTask(title: "Laundry")
        ]

        let items = TodayContinuationRules.derive(
            todayEntry: entry,
            calibration: CalibrationRules.calibrate(todayEntry: entry, weeklySnapshot: nil),
            todaySessions: [],
            homeTasks: homeTasks,
            homeRuns: [],
            writingNotes: []
        )

        XCTAssertEqual(items.map(\.title), ["Laundry"])
    }

    func testContinueItemsUseOnlyConcreteRoutableDomains() {
        let today = makeDate("2026-04-08T10:00:00Z")
        let careerItem = FocusItem(title: "Follow up", domain: .career, status: .planned)
        let entry = DailyEntry(date: today, focusThree: [careerItem])
        let snapshot = PatternSnapshot(
            generatedAt: today,
            windowEnd: today,
            windowDays: 7,
            completionRate: CompletionRatePattern(doneCount: 1, totalCount: 3, deferredCount: 0, droppedCount: 0),
            carryForward: CarryForwardPattern(
                averageCarriedPerDay: 1,
                stalledItems: [
                    .init(title: "Follow up", domain: .career, consecutiveDays: 3)
                ]
            )
        )

        let items = TodayContinuationRules.derive(
            todayEntry: entry,
            calibration: CalibrationRules.calibrate(todayEntry: entry, weeklySnapshot: snapshot),
            todaySessions: [TrainingSession(date: today, plannedActivity: "Lift", status: .planned)],
            homeTasks: [HomeTask(title: "Laundry")],
            homeRuns: [],
            writingNotes: [WritingNote(title: "Essay source", body: "", stage: .source)]
        )

        XCTAssertEqual(Set(items.map(\.domain)), [.training, .career, .home, .writing])
    }

    func testRetiredScaffoldFocusItemsAreExcludedFromContinue() {
        let today = makeDate("2026-04-08T10:00:00Z")
        let carriedFrom = makeDate("2026-04-05T10:00:00Z")
        let writingScaffold = FocusItem(
            title: "Log one writing intention",
            domain: .writing,
            status: .planned,
            createdFromDate: carriedFrom
        )
        let careerScaffold = FocusItem(
            title: "Capture one career win",
            domain: .career,
            status: .planned,
            createdFromDate: carriedFrom
        )
        let validCarriedItem = FocusItem(
            title: "Draft essay outline",
            domain: .writing,
            status: .planned,
            createdFromDate: carriedFrom
        )
        let entry = DailyEntry(date: today, focusThree: [writingScaffold, careerScaffold, validCarriedItem])
        let snapshot = PatternSnapshot(
            generatedAt: today,
            windowEnd: today,
            windowDays: 7,
            completionRate: CompletionRatePattern(doneCount: 1, totalCount: 3, deferredCount: 0, droppedCount: 0),
            carryForward: CarryForwardPattern(
                averageCarriedPerDay: 3,
                stalledItems: [
                    .init(title: "Log one writing intention", domain: .writing, consecutiveDays: 3),
                    .init(title: "Capture one career win", domain: .career, consecutiveDays: 3),
                    .init(title: "Draft essay outline", domain: .writing, consecutiveDays: 3)
                ]
            )
        )

        let items = TodayContinuationRules.derive(
            todayEntry: entry,
            calibration: CalibrationRules.calibrate(todayEntry: entry, weeklySnapshot: snapshot),
            todaySessions: [],
            homeTasks: [],
            homeRuns: [],
            writingNotes: []
        )

        XCTAssertEqual(items.map(\.title), ["Draft essay outline"])
        XCTAssertEqual(items.first?.source, .carriedFocusItem(validCarriedItem.id))
    }

    func testRetiredScaffoldTitleSurfacesWhenLinkedToARecord() {
        let today = makeDate("2026-04-08T10:00:00Z")
        let linkedID = UUID()
        let linkedCareerItem = FocusItem(
            title: "Capture one career win",
            domain: .career,
            status: .planned,
            createdFromDate: makeDate("2026-04-05T10:00:00Z"),
            linkedRecordID: linkedID
        )
        let entry = DailyEntry(date: today, focusThree: [linkedCareerItem])
        let snapshot = PatternSnapshot(
            generatedAt: today,
            windowEnd: today,
            windowDays: 7,
            completionRate: CompletionRatePattern(doneCount: 1, totalCount: 3, deferredCount: 0, droppedCount: 0),
            carryForward: CarryForwardPattern(
                averageCarriedPerDay: 1,
                stalledItems: [
                    .init(title: "Capture one career win", domain: .career, consecutiveDays: 3)
                ]
            )
        )

        let items = TodayContinuationRules.derive(
            todayEntry: entry,
            calibration: CalibrationRules.calibrate(todayEntry: entry, weeklySnapshot: snapshot),
            todaySessions: [],
            homeTasks: [],
            homeRuns: [],
            writingNotes: []
        )

        XCTAssertEqual(items.map(\.title), ["Capture one career win"])
        XCTAssertEqual(items.first?.linkedRecordID, linkedID)
        XCTAssertEqual(items.first?.source, .carriedFocusItem(linkedCareerItem.id))
    }

    func testRetiredScaffoldTitleDoesNotSuppressSourceBackedWritingNote() {
        let today = makeDate("2026-04-08T10:00:00Z")
        let note = WritingNote(
            title: "Log one writing intention",
            body: "A real note with the same title should remain actionable.",
            stage: .capture
        )

        let items = TodayContinuationRules.derive(
            todayEntry: DailyEntry(date: today),
            calibration: CalibrationRules.calibrate(todayEntry: DailyEntry(date: today), weeklySnapshot: nil),
            todaySessions: [],
            homeTasks: [],
            homeRuns: [],
            writingNotes: [note]
        )

        XCTAssertEqual(items.map(\.title), ["Log one writing intention"])
        XCTAssertEqual(items.first?.source, .writingNote(note.id))
    }

    func testSourceBackedContinueItemsExposeHighlightTargets() {
        let today = makeDate("2026-04-08T10:00:00Z")
        let session = TrainingSession(date: today, plannedActivity: "Intervals", status: .planned)
        let run = ProtocolRun(
            protocolID: UUID(),
            protocolTitle: "Kitchen reset",
            createdAt: today
        )
        let task = HomeTask(title: "Laundry")
        let note = WritingNote(title: "Essay source", body: "", stage: .source)

        let items = TodayContinuationRules.derive(
            todayEntry: DailyEntry(date: today),
            calibration: CalibrationRules.calibrate(todayEntry: DailyEntry(date: today), weeklySnapshot: nil),
            todaySessions: [session],
            homeTasks: [task],
            homeRuns: [run],
            writingNotes: [note]
        )
        func target(title: String) -> TodayContinuationRules.HighlightTarget? {
            items.first(where: { $0.title == title })?.highlightTarget
        }

        XCTAssertEqual(target(title: "Intervals"), .trainingSession(session.id))
        XCTAssertEqual(target(title: "Kitchen reset"), .homeProtocolRun(run.id))
        XCTAssertEqual(target(title: "Laundry"), .homeTask(task.id))
        XCTAssertEqual(target(title: "Essay source"), .writingNote(note.id))
    }

    func testActiveProtocolRunsSurfaceBeforeStandaloneHomeTasks() {
        let today = makeDate("2026-04-08T10:00:00Z")
        let run = ProtocolRun(
            protocolID: UUID(),
            protocolTitle: "Kitchen reset",
            createdAt: today
        )
        let task = HomeTask(title: "Laundry")

        let items = TodayContinuationRules.derive(
            todayEntry: DailyEntry(date: today),
            calibration: CalibrationRules.calibrate(todayEntry: DailyEntry(date: today), weeklySnapshot: nil),
            todaySessions: [],
            homeTasks: [task],
            homeRuns: [run],
            writingNotes: []
        )

        XCTAssertEqual(items.map(\.title), ["Kitchen reset", "Laundry"])
    }

    func testProtocolTemplateArtifactsDoNotSurfaceAsCarriedForwardRows() {
        let today = makeDate("2026-04-08T10:00:00Z")
        let artifact = FocusItem(
            title: "Afternoon Routine",
            domain: .home,
            status: .planned
        )
        let entry = DailyEntry(date: today, focusThree: [artifact], carryForward: [artifact])
        let snapshot = PatternSnapshot(
            generatedAt: today,
            windowEnd: today,
            windowDays: 7,
            completionRate: CompletionRatePattern(doneCount: 1, totalCount: 4, deferredCount: 0, droppedCount: 0),
            carryForward: CarryForwardPattern(
                averageCarriedPerDay: 1,
                stalledItems: [
                    .init(title: "Afternoon Routine", domain: .home, consecutiveDays: 4)
                ]
            )
        )

        let items = TodayContinuationRules.derive(
            todayEntry: entry,
            calibration: CalibrationRules.calibrate(todayEntry: entry, weeklySnapshot: snapshot),
            todaySessions: [],
            homeTasks: [],
            homeRuns: [],
            homeProtocols: [
                HouseholdProtocol(title: "Afternoon Routine", steps: ["Reset kitchen"])
            ],
            writingNotes: []
        )

        XCTAssertTrue(items.isEmpty)
        XCTAssertEqual(entry.carryForward, [artifact])
    }

    func testLinkedCarriedFocusItemUsesDomainHighlightTarget() {
        let today = makeDate("2026-04-08T10:00:00Z")
        let linkedRecordID = UUID()
        let carriedItem = FocusItem(
            title: "Performance review story",
            domain: .career,
            status: .planned,
            linkedRecordID: linkedRecordID
        )
        let entry = DailyEntry(date: today, focusThree: [carriedItem])
        let snapshot = PatternSnapshot(
            generatedAt: today,
            windowEnd: today,
            windowDays: 7,
            completionRate: CompletionRatePattern(doneCount: 1, totalCount: 3, deferredCount: 0, droppedCount: 0),
            carryForward: CarryForwardPattern(
                averageCarriedPerDay: 1,
                stalledItems: [
                    .init(title: "Performance review story", domain: .career, consecutiveDays: 3)
                ]
            )
        )

        let items = TodayContinuationRules.derive(
            todayEntry: entry,
            calibration: CalibrationRules.calibrate(todayEntry: entry, weeklySnapshot: snapshot),
            todaySessions: [],
            homeTasks: [],
            homeRuns: [],
            writingNotes: []
        )

        XCTAssertEqual(items.first?.highlightTarget, .careerRecord(linkedRecordID))
    }

    func testCapsAtFiveTotalAndTwoPerDomain() {
        let today = makeDate("2026-04-08T10:00:00Z")
        let entry = DailyEntry(date: today)
        let sessions = [
            TrainingSession(date: today, plannedActivity: "Run", status: .planned),
            TrainingSession(date: today, plannedActivity: "Lift", status: .planned),
            TrainingSession(date: today, plannedActivity: "Mobility", status: .planned)
        ]
        let homeTasks = [
            HomeTask(title: "Clean kitchen"),
            HomeTask(title: "Laundry"),
            HomeTask(title: "Restock pantry")
        ]
        let notes = [
            WritingNote(title: "Essay source", body: "", stage: .source),
            WritingNote(title: "Draft idea", body: "", stage: .draftSeed),
            WritingNote(title: "Scene notes", body: "", stage: .draft)
        ]

        let items = TodayContinuationRules.derive(
            todayEntry: entry,
            calibration: CalibrationRules.calibrate(todayEntry: entry, weeklySnapshot: nil),
            todaySessions: sessions,
            homeTasks: homeTasks,
            homeRuns: [],
            writingNotes: notes
        )

        XCTAssertEqual(items.count, 5)
        XCTAssertEqual(items.map(\.title), ["Run", "Lift", "Clean kitchen", "Laundry", "Essay source"])
        XCTAssertEqual(items.filter { $0.domain == .training }.count, 2)
        XCTAssertEqual(items.filter { $0.domain == .home }.count, 2)
        XCTAssertEqual(items.filter { $0.domain == .writing }.count, 1)
    }

    func testTerminalWritingStagesAreExcluded() {
        let today = makeDate("2026-04-08T10:00:00Z")
        let entry = DailyEntry(date: today)
        let notes = [
            WritingNote(title: "Already published", body: "", stage: .published),
            WritingNote(title: "Archived note", body: "", stage: .archived),
            WritingNote(title: "Working draft", body: "", stage: .draft)
        ]

        let items = TodayContinuationRules.derive(
            todayEntry: entry,
            calibration: CalibrationRules.calibrate(todayEntry: entry, weeklySnapshot: nil),
            todaySessions: [],
            homeTasks: [],
            homeRuns: [],
            writingNotes: notes
        )

        XCTAssertEqual(items.map(\.title), ["Working draft"])
    }

    private func makeDate(_ value: String) -> Date {
        ISO8601DateFormatter().date(from: value)!
    }
}
