import Foundation

enum OwloryUITestSupport {
    static let enabledArgument = "--owlory-ui-testing"
    static let freshDaySeedArgument = "--owlory-ui-seed-fresh-day"
    static let todayContinueSeedArgument = "--owlory-ui-seed-today-continue-item"
    static let homeTaskContinueSeedArgument = "--owlory-ui-seed-home-task-continue-item"
    static let homeProtocolRunContinueSeedArgument = "--owlory-ui-seed-home-protocol-run-continue-item"
    static let homeProtocolTemplateSeedArgument = "--owlory-ui-seed-home-protocol-template"
    static let dueTodayTrainingContinueSeedArgument = "--owlory-ui-seed-due-today-training-continue-item"
    static let carriedForwardFocusContinueSeedArgument = "--owlory-ui-seed-carried-forward-focus-continue-item"
    static let inProgressWritingContinueSeedArgument = "--owlory-ui-seed-in-progress-writing-continue-item"

    static let continueFixtureItemID = UUID(uuidString: "9D215686-176C-4C13-936E-AB3092D62A96")!
    static let continueFixtureItemTitle = "Review seeded Continue item"
    static let homeTaskContinueFixtureItemID = UUID(uuidString: "4D890346-1DE3-4A1E-A55F-FBD97FD08D4E")!
    static let homeTaskContinueFixtureItemTitle = "Review seeded Home task"
    static let homeProtocolRunContinueFixtureProtocolID = UUID(uuidString: "4493FF3F-4388-4FB9-B1D7-E9875C427C60")!
    static let homeProtocolRunContinueFixtureRunID = UUID(uuidString: "C9B98DD8-9AA9-4D8C-B0F7-8E82CF280A5A")!
    static let homeProtocolRunContinueFixtureStepID = UUID(uuidString: "079B060C-76D4-466A-82FB-22D69F65E8DE")!
    static let homeProtocolRunContinueFixtureTitle = "Review seeded protocol run"
    static let homeProtocolRunContinueFixtureStepTitle = "Check seeded protocol step"
    static let homeProtocolTemplateFixtureProtocolID = UUID(uuidString: "8B82E9F0-7A18-4B5D-A23E-3CF9C61C7A1D")!
    static let homeProtocolTemplateFixtureTitle = "Review seeded protocol template"
    static let homeProtocolTemplateFixtureStepTitle = "Archive template proof step"
    static let dueTodayTrainingContinueFixtureSessionID = UUID(uuidString: "B7E14C81-6D2A-4F3E-9C0B-5A8D2E1F4C9D")!
    static let dueTodayTrainingContinueFixtureTitle = "Review seeded Training session"
    static let carriedForwardFocusContinueFixtureItemID = UUID(uuidString: "A5B7C9D1-3E5F-4A9B-8D6F-0E2C4A6B8D0F")!
    static let carriedForwardFocusContinueFixtureTitle = "Review seeded carried Focus"
    static let inProgressWritingContinueFixtureNoteID = UUID(uuidString: "3D5F7A91-1E2F-4C5D-86A7-9C8D0E1F2A3B")!
    static let inProgressWritingContinueFixtureTitle = "Review seeded Writing note"

    static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains(enabledArgument)
    }

    static func prepareLaunchEnvironmentIfNeeded(
        fileManager: FileManager = .default
    ) {
        guard isUITesting else {
            return
        }

        let arguments = ProcessInfo.processInfo.arguments
        let shouldSeedFreshDay = arguments.contains(freshDaySeedArgument)
        let shouldSeedContinueItem = arguments.contains(todayContinueSeedArgument)
        let shouldSeedHomeTaskContinueItem = arguments.contains(homeTaskContinueSeedArgument)
        let shouldSeedHomeProtocolRunContinueItem = arguments.contains(homeProtocolRunContinueSeedArgument)
        let shouldSeedHomeProtocolTemplate = arguments.contains(homeProtocolTemplateSeedArgument)
        let shouldSeedDueTodayTrainingContinueItem = arguments.contains(dueTodayTrainingContinueSeedArgument)
        let shouldSeedCarriedForwardFocusContinueItem = arguments.contains(carriedForwardFocusContinueSeedArgument)
        let shouldSeedInProgressWritingContinueItem = arguments.contains(inProgressWritingContinueSeedArgument)
        guard shouldSeedFreshDay ||
                shouldSeedContinueItem ||
                shouldSeedHomeTaskContinueItem ||
                shouldSeedHomeProtocolRunContinueItem ||
                shouldSeedHomeProtocolTemplate ||
                shouldSeedDueTodayTrainingContinueItem ||
                shouldSeedCarriedForwardFocusContinueItem ||
                shouldSeedInProgressWritingContinueItem else { return }

        #if DEBUG
        resetAppSupport(fileManager: fileManager)
        if shouldSeedContinueItem {
            seedTodayContinueItem()
        }
        if shouldSeedHomeTaskContinueItem {
            seedHomeTaskContinueItem()
        }
        if shouldSeedHomeProtocolRunContinueItem {
            seedHomeProtocolRunContinueItem()
        }
        if shouldSeedHomeProtocolTemplate {
            seedHomeProtocolTemplate()
        }
        if shouldSeedDueTodayTrainingContinueItem {
            seedDueTodayTrainingContinueItem()
        }
        if shouldSeedCarriedForwardFocusContinueItem {
            seedCarriedForwardFocusContinueItem()
        }
        if shouldSeedInProgressWritingContinueItem {
            seedInProgressWritingContinueItem()
        }
        #endif
    }

    #if DEBUG
    private static func resetAppSupport(fileManager: FileManager) {
        let appSupport = OwloryAppSupportPath.appSupportDirectory(fileManager: fileManager)
        for rootDirectory in [
            OwloryAppSupportPath.currentRootDirectory,
            OwloryAppSupportPath.legacyRootDirectory
        ] {
            let url = appSupport.appendingPathComponent(rootDirectory, isDirectory: true)
            if fileManager.fileExists(atPath: url.path) {
                try? fileManager.removeItem(at: url)
            }
        }
    }

    private static func seedTodayContinueItem(
        calendar: Calendar = .current,
        now: Date = Date()
    ) {
        let today = calendar.startOfDay(for: now)
        let entry = DailyEntry(
            date: today,
            focusThree: [
                FocusItem(
                    id: continueFixtureItemID,
                    title: continueFixtureItemTitle,
                    domain: .home,
                    status: .planned,
                    createdFromDate: today
                )
            ],
            energy: 4,
            mood: 4,
            sleepQuality: 4
        )
        try? FileTodayEntryRepository(calendar: calendar).saveEntry(entry)
    }

    private static func seedHomeTaskContinueItem() {
        let task = HomeTask(
            id: homeTaskContinueFixtureItemID,
            title: homeTaskContinueFixtureItemTitle,
            notes: "Seeded by Owlory UI smoke."
        )
        try? FileItemListRepository<HomeTask>(
            directory: "Home",
            fileName: "tasks"
        ).saveAll([task])
    }

    private static func seedHomeProtocolRunContinueItem(now: Date = Date()) {
        let proto = HouseholdProtocol(
            id: homeProtocolRunContinueFixtureProtocolID,
            title: homeProtocolRunContinueFixtureTitle,
            steps: [homeProtocolRunContinueFixtureStepTitle]
        )
        let run = ProtocolRun(
            id: homeProtocolRunContinueFixtureRunID,
            protocolID: homeProtocolRunContinueFixtureProtocolID,
            protocolTitle: homeProtocolRunContinueFixtureTitle,
            createdAt: now,
            steps: [
                ProtocolStepInstance(
                    id: homeProtocolRunContinueFixtureStepID,
                    stepNumber: 1,
                    title: homeProtocolRunContinueFixtureStepTitle
                )
            ]
        )

        try? FileItemListRepository<HouseholdProtocol>(
            directory: "Home",
            fileName: "protocols"
        ).saveAll([proto])
        try? FileItemListRepository<ProtocolRun>(
            directory: "Home",
            fileName: "runs"
        ).saveAll([run])
    }

    private static func seedHomeProtocolTemplate() {
        let proto = HouseholdProtocol(
            id: homeProtocolTemplateFixtureProtocolID,
            title: homeProtocolTemplateFixtureTitle,
            steps: [homeProtocolTemplateFixtureStepTitle]
        )
        try? FileItemListRepository<HouseholdProtocol>(
            directory: "Home",
            fileName: "protocols"
        ).saveAll([proto])
    }

    private static func seedDueTodayTrainingContinueItem(
        calendar: Calendar = .current,
        now: Date = Date()
    ) {
        let session = TrainingSession(
            id: dueTodayTrainingContinueFixtureSessionID,
            date: calendar.startOfDay(for: now),
            plannedActivity: dueTodayTrainingContinueFixtureTitle,
            status: .planned
        )
        try? FileItemListRepository<TrainingSession>(
            directory: "Train",
            fileName: "sessions"
        ).saveAll([session])
    }

    private static func seedCarriedForwardFocusContinueItem(
        calendar: Calendar = .current,
        now: Date = Date()
    ) {
        // Build 4 consecutive daily entries (3 prior + today) all containing a
        // FocusItem with the same title/domain and `createdFromDate` set. This
        // is what `PatternEngine.computeCarryForward` reads to produce a
        // stalled-item streak >= 3, which becomes a calibration staleItem and
        // re-routes today's focus item from the currentFocus composer step
        // into the carriedFocusItem step.
        let today = calendar.startOfDay(for: now)
        let origin = calendar.date(byAdding: .day, value: -3, to: today) ?? today
        let entryRepository = FileTodayEntryRepository(calendar: calendar)
        for daysBack in stride(from: 3, through: 0, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: -daysBack, to: today) else { continue }
            // Today's item carries the fixture ID so the XCUITest can assert
            // the deterministic accessibility identifier. Prior days only
            // contribute to the streak via matching title+domain.
            let itemID: UUID = (daysBack == 0)
                ? carriedForwardFocusContinueFixtureItemID
                : UUID()
            let focusItem = FocusItem(
                id: itemID,
                title: carriedForwardFocusContinueFixtureTitle,
                domain: .home,
                status: .planned,
                createdFromDate: origin
            )
            let entry = DailyEntry(
                date: day,
                focusThree: [focusItem],
                energy: 4,
                mood: 4,
                sleepQuality: 4
            )
            try? entryRepository.saveEntry(entry)
        }
    }

    private static func seedInProgressWritingContinueItem(now: Date = Date()) {
        let note = WritingNote(
            id: inProgressWritingContinueFixtureNoteID,
            title: inProgressWritingContinueFixtureTitle,
            body: "Seeded by Owlory UI smoke.",
            stage: .capture,
            createdDate: now
        )
        try? FileItemListRepository<WritingNote>(
            directory: "Write",
            fileName: "notes"
        ).saveAll([note])
    }
    #endif
}
