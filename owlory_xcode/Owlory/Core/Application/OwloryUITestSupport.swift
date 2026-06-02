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
    static let marketingSeedArgument = "--owlory-ui-seed-marketing"

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
        let shouldSeedMarketing = arguments.contains(marketingSeedArgument)
        guard shouldSeedFreshDay ||
                shouldSeedContinueItem ||
                shouldSeedHomeTaskContinueItem ||
                shouldSeedHomeProtocolRunContinueItem ||
                shouldSeedHomeProtocolTemplate ||
                shouldSeedDueTodayTrainingContinueItem ||
                shouldSeedCarriedForwardFocusContinueItem ||
                shouldSeedInProgressWritingContinueItem ||
                shouldSeedMarketing else { return }

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
        if shouldSeedMarketing {
            seedMarketing()
        }
        #endif
    }

    #if DEBUG
    private static func seedCopy(_ key: String) -> String {
        NSLocalizedString(key, tableName: "MarketingSeed", bundle: .main, value: key, comment: "Marketing screenshot seed copy")
    }

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

    /// Seed App Store-quality realistic data across every primary surface
    /// (Today/Focus, Write/Capture, Train, Home, Career). Used only by the
    /// marketing screenshot capture harness; not exercised by XCUITests.
    private static func seedMarketing(
        calendar: Calendar = .current,
        now: Date = Date()
    ) {
        let today = calendar.startOfDay(for: now)

        // Focus Three for today — a balanced mix across domains.
        let focusToday: [FocusItem] = [
            FocusItem(
                title: seedCopy("Finalize Q4 1:1 notes for direct reports"),
                domain: .career,
                status: .planned,
                createdFromDate: today
            ),
            FocusItem(
                title: seedCopy("30-min easy run before dinner"),
                domain: .training,
                status: .planned,
                createdFromDate: today
            ),
            FocusItem(
                title: seedCopy("Pick up dry cleaning by 6 pm"),
                domain: .home,
                status: .planned,
                createdFromDate: today
            )
        ]

        // Seven days of entries (6 prior + today) so the Weekly Digest has
        // material to summarize: varied energy/mood/sleep, two prior wins
        // marked done, one carried forward, one deferred.
        let energySeries = [3, 4, 4, 3, 5, 4, 4]
        let moodSeries = [3, 4, 4, 3, 4, 5, 4]
        let sleepSeries = [3, 4, 4, 3, 4, 4, 4]
        let priorFocusTitles = [
            seedCopy("Draft sprint retro talking points"),
            seedCopy("Strength: legs (3x8)"),
            seedCopy("Pay quarterly tax estimate"),
            seedCopy("Pull together onboarding metrics review"),
            seedCopy("5K easy run"),
            seedCopy("Schedule dentist appointment")
        ]
        let priorReflections = [
            seedCopy("Felt scattered — meetings ate the morning. Plan deep work earlier."),
            seedCopy("Energy held through evening. Run cleared the mental fog."),
            seedCopy("Hit all three. Good rhythm. Sleep mattered."),
            seedCopy("Lost momentum after lunch. Try lighter midday meal."),
            seedCopy("Best day this week. Protected morning paid off."),
            seedCopy("Solid. Career review prep moving the needle.")
        ]

        // priorEntries[i] describes the day i+1 days back (i in 0..5 → days back 1..6).
        let priorDomains: [LifeDomain] = [.career, .training, .home, .career, .training, .home]
        let priorStatuses: [FocusItemStatus] = [.done, .done, .done, .deferred, .done, .done]

        let entryRepository = FileTodayEntryRepository(calendar: calendar)

        // Today's entry (daysBack = 0).
        if let todayDay = calendar.date(byAdding: .day, value: 0, to: today) {
            let entry = DailyEntry(
                date: todayDay,
                focusThree: focusToday,
                energy: energySeries[6],
                mood: moodSeries[6],
                sleepQuality: sleepSeries[6]
            )
            try? entryRepository.saveEntry(entry)
        }

        // Six prior days, ordered most recent first.
        for daysBack in 1...6 {
            guard let day = calendar.date(byAdding: .day, value: -daysBack, to: today) else { continue }
            let i = daysBack - 1
            let focus = FocusItem(
                title: priorFocusTitles[i],
                domain: priorDomains[i],
                status: priorStatuses[i],
                createdFromDate: day
            )
            let entry = DailyEntry(
                date: day,
                focusThree: [focus],
                energy: energySeries[i],
                mood: moodSeries[i],
                sleepQuality: sleepSeries[i],
                eveningReflection: priorReflections[i]
            )
            try? entryRepository.saveEntry(entry)
        }

        // Writing inbox spanning all three stages: 2 fresh captures, 2 source
        // notes (worked-up drafts), 1 permanent (a synthesized insight).
        let writingNotes: [WritingNote] = [
            WritingNote(
                title: seedCopy("Idea: weekly batch errands on Saturdays"),
                body: seedCopy("Group DMV, dry cleaning, hardware-store loops into one Saturday block. Test for 3 weeks."),
                stage: .capture,
                createdDate: calendar.date(byAdding: .hour, value: -2, to: now) ?? now
            ),
            WritingNote(
                title: seedCopy("Watch: SwiftUI navigation patterns talk"),
                body: seedCopy("WWDC25 session on programmatic navigation. Compare NavigationStack vs SplitView trade-offs."),
                stage: .capture,
                createdDate: calendar.date(byAdding: .day, value: -1, to: now) ?? now
            ),
            WritingNote(
                title: seedCopy("Onboarding redesign — one-pager"),
                body: seedCopy("Problem: 41% of new users never reach Focus Three on day one. Hypothesis: reduce the capture-vs-plan choice during day 1. Test variant A swaps the empty-state to suggest 3 sample focus items."),
                stage: .source,
                createdDate: calendar.date(byAdding: .day, value: -2, to: now) ?? now
            ),
            WritingNote(
                title: seedCopy("Career conversation prep with manager"),
                body: seedCopy("Topics: scope expansion, mentorship of new hires, Q1 OKRs alignment. Win to lead with: shipped onboarding A/B with +12% activation."),
                stage: .source,
                createdDate: calendar.date(byAdding: .day, value: -3, to: now) ?? now
            ),
            WritingNote(
                title: seedCopy("Insight: deep work blocks shrink without protection"),
                body: seedCopy("Three consecutive weeks where morning blocks were broken by reactive Slack — output dropped measurably. Calendar the 9-11 block as immovable starting next week."),
                stage: .permanent,
                createdDate: calendar.date(byAdding: .day, value: -5, to: now) ?? now
            )
        ]
        try? FileItemListRepository<WritingNote>(
            directory: "Write",
            fileName: "notes"
        ).saveAll(writingNotes)

        // Train: 1 planned today + 2 completed past sessions for history.
        let trainingSessions: [TrainingSession] = [
            TrainingSession(
                date: today,
                plannedActivity: seedCopy("Strength: legs (3x8)"),
                status: .planned,
                readinessLevel: 4,
                readinessNote: seedCopy("Slept well. Light soreness from yesterday's run.")
            ),
            TrainingSession(
                date: calendar.date(byAdding: .day, value: -2, to: today) ?? today,
                plannedActivity: seedCopy("5K easy run"),
                actualActivity: seedCopy("5.2K easy run, 27 min"),
                status: .completed,
                readinessLevel: 4,
                reflection: seedCopy("Steady pace, breath in control. Could have pushed last K.")
            ),
            TrainingSession(
                date: calendar.date(byAdding: .day, value: -4, to: today) ?? today,
                plannedActivity: seedCopy("Yoga: hip mobility"),
                actualActivity: seedCopy("Yoga: hip mobility (35 min flow)"),
                status: .completed,
                readinessLevel: 3,
                reflection: seedCopy("Hips opening. Add this twice a week instead of one.")
            )
        ]
        try? FileItemListRepository<TrainingSession>(
            directory: "Train",
            fileName: "sessions"
        ).saveAll(trainingSessions)

        // Home: 1 protocol + 4 tasks. Mix of recurring + one-off.
        let mealPrepProtocol = HouseholdProtocol(
            title: seedCopy("Sunday meal prep"),
            steps: [
                seedCopy("Plan menu for the week"),
                seedCopy("Inventory pantry + write list"),
                seedCopy("Shop within 60 min"),
                seedCopy("Cook proteins + grains in bulk"),
                seedCopy("Portion lunches into 5 containers")
            ]
        )
        try? FileItemListRepository<HouseholdProtocol>(
            directory: "Home",
            fileName: "protocols"
        ).saveAll([mealPrepProtocol])

        let homeTasks: [HomeTask] = [
            HomeTask(
                title: seedCopy("Take out recycling"),
                isRecurring: true,
                recurrenceIntervalDays: 7,
                notes: seedCopy("Bin out before Tuesday 6 am pickup.")
            ),
            HomeTask(
                title: seedCopy("Refill dish soap")
            ),
            HomeTask(
                title: seedCopy("Schedule dentist appointment"),
                notes: seedCopy("Six-month checkup overdue by two weeks.")
            ),
            HomeTask(
                title: seedCopy("Pay quarterly tax estimate"),
                notes: seedCopy("Federal + state. Due 15th.")
            )
        ]
        try? FileItemListRepository<HomeTask>(
            directory: "Home",
            fileName: "tasks"
        ).saveAll(homeTasks)

        // Weekly Digest: seed a digest for the most recent full Monday-Sunday
        // window so the Today view's "Last Week Digest" section renders. The
        // digest itself is data the PatternEngine would compute on Monday;
        // pre-seeding lets the screenshot show the rendered reflection
        // surface on any day of the week.
        if let priorMonday = calendar.nextDate(
            after: today,
            matching: DateComponents(weekday: 2),
            matchingPolicy: .nextTime,
            direction: .backward
        ).flatMap({ calendar.date(byAdding: .day, value: -7, to: $0) }),
           let priorSunday = calendar.date(byAdding: .day, value: 6, to: priorMonday) {
            let bestDay = WeeklyDigest.DayHighlight(
                date: calendar.date(byAdding: .day, value: 4, to: priorMonday) ?? priorMonday,
                doneCount: 3,
                plannedCount: 3,
                readinessBand: "high"
            )
            let hardestDay = WeeklyDigest.DayHighlight(
                date: calendar.date(byAdding: .day, value: 1, to: priorMonday) ?? priorMonday,
                doneCount: 1,
                plannedCount: 3,
                readinessBand: "low"
            )
            let digest = WeeklyDigest(
                weekStarting: priorMonday,
                weekEnding: priorSunday,
                generatedAt: priorSunday,
                daysWithEntries: 6,
                completionRate: 0.67,
                totalPlanned: 18,
                totalDone: 12,
                averageReadiness: 3.5,
                bestDay: bestDay,
                hardestDay: hardestDay,
                domainActivity: [.career: 7, .training: 5, .home: 6],
                stalledItemCount: 1,
                streakDays: 4,
                keyInsight: seedCopy("Career follow-through climbed with protected morning blocks; energy dipped on the day with the lightest sleep.")
            )
            try? FileItemListRepository<WeeklyDigest>(
                directory: "Digests",
                fileName: "digests"
            ).saveAll([digest])
        }

        // Career: a recent win + an impact record so the Career tab isn't empty.
        let careerRecords: [CareerRecord] = [
            CareerRecord(
                date: calendar.date(byAdding: .day, value: -1, to: today) ?? today,
                type: .win,
                title: seedCopy("Shipped onboarding redesign A/B test"),
                body: seedCopy("Variant A (sample focus suggestions in empty state) launched to 50% of new users. Day-1 activation lifted +12% over control across the first 2,000 cohorts."),
                metrics: seedCopy("+12% activation; n=2,134")
            ),
            CareerRecord(
                date: calendar.date(byAdding: .day, value: -4, to: today) ?? today,
                type: .impact,
                title: seedCopy("Led migration kickoff with three teams"),
                body: seedCopy("Aligned backend, mobile, and platform on the schema migration plan. Walked through the rollback path, owners, and acceptance gates. No open blockers exiting the meeting."),
                metrics: seedCopy("3 teams aligned; 0 blockers")
            )
        ]
        try? FileItemListRepository<CareerRecord>(
            directory: "Career",
            fileName: "records"
        ).saveAll(careerRecords)
    }
    #endif
}
