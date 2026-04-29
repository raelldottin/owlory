import XCTest
#if SWIFT_PACKAGE
@testable import OwloryCore
#endif

final class TodayContinueSourceComposerTests: XCTestCase {
    private let today = Date(timeIntervalSinceReferenceDate: 0)

    func testSourceOrderIsExplicitAndStable() {
        XCTAssertEqual(
            TodayContinueSourceComposer.sourceOrder,
            [
                .currentFocus,
                .dueTodayTraining,
                .carriedForwardFocus,
                .activeHomeProtocolRun,
                .activeHomeTask,
                .inProgressWriting,
            ]
        )
    }

    func testComposesCandidatesInVisibleSourceOrder() {
        let session = TrainingSession(
            date: today,
            plannedActivity: "Intervals",
            status: .planned
        )
        let linkedRecordID = UUID()
        let currentFocus = FocusItem(
            title: "Plan launch",
            domain: .career,
            status: .planned
        )
        let focusItem = FocusItem(
            title: "Draft outline",
            domain: .writing,
            status: .planned,
            linkedRecordID: linkedRecordID
        )
        let homeTask = HomeTask(title: "Laundry")
        let run = ProtocolRun(
            protocolID: UUID(),
            protocolTitle: "Kitchen reset",
            createdAt: today
        )
        let note = WritingNote(title: "Essay source", body: "", stage: .source)

        let candidates = TodayContinueSourceComposer.compose(
            todayEntry: DailyEntry(date: today, focusThree: [currentFocus, focusItem]),
            calibration: calibration(
                staleItems: [
                    .init(title: "Draft outline", domain: .writing, consecutiveDays: 4)
                ]
            ),
            todaySessions: [session],
            homeTasks: [homeTask],
            homeRuns: [run],
            writingNotes: [note]
        )

        XCTAssertEqual(candidates.map(\.step), [
            .currentFocus,
            .dueTodayTraining,
            .carriedForwardFocus,
            .activeHomeProtocolRun,
            .activeHomeTask,
            .inProgressWriting,
        ])
        XCTAssertEqual(candidates.map(\.title), [
            "Plan launch",
            "Intervals",
            "Draft outline",
            "Kitchen reset",
            "Laundry",
            "Essay source",
        ])
        XCTAssertEqual(candidates.map(\.reason), [
            "Focus",
            "Due today",
            "Carried forward",
            "Protocol run",
            "Active",
            "In progress",
        ])
        XCTAssertEqual(candidates.map(\.priority), [
            .dueToday,
            .dueToday,
            .carriedForward,
            .active,
            .active,
            .inProgress,
        ])
        XCTAssertEqual(candidates[0].source, .focusItem(currentFocus.id))
        XCTAssertEqual(candidates[1].source, .trainingSession(session.id))
        XCTAssertEqual(candidates[2].source, .carriedFocusItem(focusItem.id))
        XCTAssertEqual(candidates[2].linkedRecordID, linkedRecordID)
        XCTAssertEqual(candidates[2].staleDayCount, 4)
        XCTAssertEqual(candidates[3].source, .homeProtocolRun(run.id))
        XCTAssertEqual(candidates[4].source, .homeTask(homeTask.id))
        XCTAssertEqual(candidates[5].source, .writingNote(note.id))
    }

    func testCompositionAppliesSourceEligibilityBeforeCandidateCreation() {
        let validFocus = FocusItem(title: "Draft outline", domain: .writing, status: .planned)
        let unstaleFocus = FocusItem(title: "Fresh outline", domain: .writing, status: .planned)
        let doneFocus = FocusItem(title: "Done outline", domain: .writing, status: .done)
        let activeRun = ProtocolRun(protocolID: UUID(), protocolTitle: "Kitchen reset", createdAt: today)
        let completedRun = ProtocolRun(
            protocolID: UUID(),
            protocolTitle: "Completed reset",
            status: .completed,
            createdAt: today
        )
        let validHomeTask = HomeTask(title: "Laundry")
        let skippedHomeTask = HomeTask(title: "Clean kitchen", isSkipped: true)
        let validNote = WritingNote(title: "Essay source", body: "", stage: .source)
        let publishedNote = WritingNote(title: "Published essay", body: "", stage: .published)

        let candidates = TodayContinueSourceComposer.compose(
            todayEntry: DailyEntry(
                date: today,
                focusThree: [validFocus, unstaleFocus, doneFocus]
            ),
            calibration: calibration(
                staleItems: [
                    .init(title: "Draft outline", domain: .writing, consecutiveDays: 3),
                    .init(title: "Done outline", domain: .writing, consecutiveDays: 3),
                ]
            ),
            todaySessions: [
                TrainingSession(date: today, plannedActivity: "Intervals", status: .planned),
                TrainingSession(date: today, plannedActivity: "Skipped", status: .skipped),
            ],
            homeTasks: [skippedHomeTask, validHomeTask],
            homeRuns: [completedRun, activeRun],
            writingNotes: [publishedNote, validNote]
        )

        XCTAssertEqual(candidates.map(\.title), [
            "Fresh outline",
            "Intervals",
            "Draft outline",
            "Kitchen reset",
            "Laundry",
            "Essay source",
        ])
    }

    func testCurrentFocusItemsSurfaceInContinueWithoutStaleCarryForward() {
        let focus = FocusItem(title: "Write pitch", domain: .career, status: .planned)

        let candidates = TodayContinueSourceComposer.compose(
            todayEntry: DailyEntry(date: today, focusThree: [focus]),
            calibration: calibration(),
            todaySessions: [],
            homeTasks: [],
            homeRuns: [],
            writingNotes: []
        )

        XCTAssertEqual(candidates.map(\.step), [.currentFocus])
        XCTAssertEqual(candidates.first?.source, .focusItem(focus.id))
        XCTAssertEqual(candidates.first?.reason, "Focus")
        XCTAssertNil(candidates.first?.staleDayCount)
    }

    func testFocusOriginIsPreservedForCurrentFocusCandidates() {
        let noteID = UUID()
        let originDate = today.addingTimeInterval(60)
        let origin = FocusItemOrigin(kind: .writingNote, id: noteID, createdAt: originDate)
        let focus = FocusItem(
            title: "Essay source",
            domain: .writing,
            status: .planned,
            linkedRecordID: noteID,
            origin: origin
        )

        let candidates = TodayContinueSourceComposer.compose(
            todayEntry: DailyEntry(date: today, focusThree: [focus]),
            calibration: calibration(),
            todaySessions: [],
            homeTasks: [],
            homeRuns: [],
            writingNotes: []
        )

        XCTAssertEqual(candidates.first?.origin, origin)
    }

    func testSourceBackedFocusItemUsesExistingContinueSourceInsteadOfDuplicateFocusRow() {
        let note = WritingNote(title: "Essay source", body: "", stage: .source)
        let focus = FocusItem(
            title: "Essay source",
            domain: .writing,
            status: .planned,
            linkedRecordID: note.id
        )

        let candidates = TodayContinueSourceComposer.compose(
            todayEntry: DailyEntry(date: today, focusThree: [focus]),
            calibration: calibration(),
            todaySessions: [],
            homeTasks: [],
            homeRuns: [],
            writingNotes: [note]
        )

        XCTAssertEqual(candidates.map(\.source), [.writingNote(note.id)])
    }

    func testCarriedHomeProtocolTemplateArtifactIsSuppressedWithoutActiveRun() {
        let artifact = FocusItem(
            title: "Afternoon Routine",
            domain: .home,
            status: .planned
        )

        let candidates = TodayContinueSourceComposer.compose(
            todayEntry: DailyEntry(date: today, focusThree: [artifact]),
            calibration: calibration(
                staleItems: [
                    .init(title: "Afternoon Routine", domain: .home, consecutiveDays: 4)
                ]
            ),
            todaySessions: [],
            homeTasks: [],
            homeRuns: [],
            homeProtocols: [
                HouseholdProtocol(title: "Afternoon Routine", steps: ["Reset kitchen"])
            ],
            writingNotes: []
        )

        XCTAssertTrue(candidates.isEmpty)
    }

    func testLinkedHomeProtocolTemplateArtifactIsSuppressedEvenWhenTitleChanged() {
        let protocolID = UUID()
        let artifact = FocusItem(
            title: "Afternoon Routine",
            domain: .home,
            status: .planned,
            linkedRecordID: protocolID
        )

        let candidates = TodayContinueSourceComposer.compose(
            todayEntry: DailyEntry(date: today, focusThree: [artifact]),
            calibration: calibration(
                staleItems: [
                    .init(title: "Afternoon Routine", domain: .home, consecutiveDays: 4)
                ]
            ),
            todaySessions: [],
            homeTasks: [],
            homeRuns: [],
            homeProtocols: [
                HouseholdProtocol(id: protocolID, title: "Evening Routine", steps: ["Reset kitchen"])
            ],
            writingNotes: []
        )

        XCTAssertTrue(candidates.isEmpty)
    }

    func testActiveHomeProtocolRunReplacesCarriedProtocolArtifact() {
        let run = ProtocolRun(
            protocolID: UUID(),
            protocolTitle: "Afternoon Routine",
            createdAt: today
        )
        let artifact = FocusItem(
            title: "Afternoon Routine",
            domain: .home,
            status: .planned,
            linkedRecordID: run.id
        )

        let candidates = TodayContinueSourceComposer.compose(
            todayEntry: DailyEntry(date: today, focusThree: [artifact]),
            calibration: calibration(
                staleItems: [
                    .init(title: "Afternoon Routine", domain: .home, consecutiveDays: 4)
                ]
            ),
            todaySessions: [],
            homeTasks: [],
            homeRuns: [run],
            homeProtocols: [
                HouseholdProtocol(id: run.protocolID, title: "Afternoon Routine", steps: ["Reset kitchen"])
            ],
            writingNotes: []
        )

        XCTAssertEqual(candidates.map(\.step), [.activeHomeProtocolRun])
        XCTAssertEqual(candidates.first?.source, .homeProtocolRun(run.id))
    }

    func testLinkedTrainingCarryForwardUsesActionableSourceWithoutDuplicateFocusRow() {
        let session = TrainingSession(
            date: today,
            plannedActivity: "Intervals",
            status: .planned
        )
        let artifact = FocusItem(
            title: "Intervals",
            domain: .training,
            status: .planned,
            linkedRecordID: session.id
        )

        let candidates = TodayContinueSourceComposer.compose(
            todayEntry: DailyEntry(date: today, focusThree: [artifact]),
            calibration: calibration(
                staleItems: [
                    .init(title: "Intervals", domain: .training, consecutiveDays: 4)
                ]
            ),
            todaySessions: [session],
            homeTasks: [],
            homeRuns: [],
            writingNotes: []
        )

        XCTAssertEqual(candidates.map(\.source), [.trainingSession(session.id)])
    }

    func testLinkedTrainingCarryForwardSuppressesResolvedOrMissingSessions() {
        let skipped = TrainingSession(
            date: today,
            plannedActivity: "Intervals",
            status: .skipped
        )
        let completed = TrainingSession(
            date: today,
            plannedActivity: "Strength",
            status: .completed
        )
        let modified = TrainingSession(
            date: today,
            plannedActivity: "Mobility",
            status: .modified
        )
        let skippedArtifact = FocusItem(
            title: "Intervals",
            domain: .training,
            status: .planned,
            linkedRecordID: skipped.id
        )
        let completedArtifact = FocusItem(
            title: "Strength",
            domain: .training,
            status: .planned,
            linkedRecordID: completed.id
        )
        let modifiedArtifact = FocusItem(
            title: "Mobility",
            domain: .training,
            status: .planned,
            linkedRecordID: modified.id
        )
        let missingArtifact = FocusItem(
            title: "Yoga",
            domain: .training,
            status: .planned,
            linkedRecordID: UUID()
        )

        let candidates = TodayContinueSourceComposer.compose(
            todayEntry: DailyEntry(
                date: today,
                focusThree: [
                    skippedArtifact,
                    completedArtifact,
                    modifiedArtifact,
                    missingArtifact,
                ]
            ),
            calibration: calibration(
                staleItems: [
                    .init(title: "Intervals", domain: .training, consecutiveDays: 4),
                    .init(title: "Strength", domain: .training, consecutiveDays: 4),
                    .init(title: "Mobility", domain: .training, consecutiveDays: 4),
                    .init(title: "Yoga", domain: .training, consecutiveDays: 4),
                ]
            ),
            todaySessions: [skipped, completed, modified],
            homeTasks: [],
            homeRuns: [],
            writingNotes: []
        )

        XCTAssertTrue(candidates.isEmpty)
    }

    func testCompositionDoesNotApplyAdmissionCaps() {
        let sessions = [
            TrainingSession(date: today, plannedActivity: "Run", status: .planned),
            TrainingSession(date: today, plannedActivity: "Lift", status: .planned),
            TrainingSession(date: today, plannedActivity: "Mobility", status: .planned),
        ]

        let candidates = TodayContinueSourceComposer.compose(
            todayEntry: DailyEntry(date: today),
            calibration: calibration(),
            todaySessions: sessions,
            homeTasks: [],
            homeRuns: [],
            writingNotes: []
        )

        XCTAssertEqual(candidates.map(\.title), ["Run", "Lift", "Mobility"])
    }

    func testPredictionKeysAreSourceSpecific() {
        let trainingFocus = FocusItem(
            title: "Strength",
            domain: .training,
            status: .planned
        )
        let homeFocus = FocusItem(
            title: "Laundry",
            domain: .home,
            status: .planned
        )
        let writingFocus = FocusItem(
            title: "Essay outline",
            domain: .writing,
            status: .planned
        )
        let run = ProtocolRun(
            protocolID: UUID(),
            protocolTitle: "Kitchen reset",
            createdAt: today
        )

        let candidates = TodayContinueSourceComposer.compose(
            todayEntry: DailyEntry(
                date: today,
                focusThree: [trainingFocus, homeFocus, writingFocus]
            ),
            calibration: calibration(
                staleItems: [
                    .init(title: "Strength", domain: .training, consecutiveDays: 3),
                    .init(title: "Laundry", domain: .home, consecutiveDays: 3),
                    .init(title: "Essay outline", domain: .writing, consecutiveDays: 3),
                ]
            ),
            todaySessions: [
                TrainingSession(date: today, plannedActivity: "Intervals", status: .planned)
            ],
            homeTasks: [HomeTask(title: "Dishes")],
            homeRuns: [run],
            writingNotes: [WritingNote(title: "Draft idea", body: "", stage: .draft)]
        )

        XCTAssertEqual(
            candidates.first(where: { $0.title == "Intervals" })?.predictionKey,
            CompletionTimePredictor.key(forTrainingSession: "Intervals")
        )
        XCTAssertEqual(
            candidates.first(where: { $0.title == "Strength" })?.predictionKey,
            CompletionTimePredictor.key(forTrainingSession: "Strength")
        )
        XCTAssertEqual(
            candidates.first(where: { $0.title == "Laundry" })?.predictionKey,
            CompletionTimePredictor.key(forHomeTask: "Laundry")
        )
        XCTAssertNil(candidates.first(where: { $0.title == "Essay outline" })?.predictionKey)
        XCTAssertEqual(
            candidates.first(where: { $0.title == "Dishes" })?.predictionKey,
            CompletionTimePredictor.key(forHomeTask: "Dishes")
        )
        XCTAssertEqual(
            candidates.first(where: { $0.title == "Kitchen reset" })?.predictionKey,
            CompletionTimePredictor.key(forProtocolRun: "Kitchen reset")
        )
        XCTAssertNil(candidates.first(where: { $0.title == "Draft idea" })?.predictionKey)
    }

    private func calibration(
        staleItems: [CalibrationRules.StaleItemAlert] = []
    ) -> CalibrationRules.Calibration {
        CalibrationRules.Calibration(
            enhancedNudge: nil,
            completionContext: nil,
            staleItems: staleItems,
            domainNudge: nil,
            suggestedFocusLoad: 3,
            writingNudge: nil,
            trainingSummary: nil
        )
    }
}
