import Foundation

enum OwloryUITestSupport {
    static let enabledArgument = "--owlory-ui-testing"
    static let freshDaySeedArgument = "--owlory-ui-seed-fresh-day"
    static let todayContinueSeedArgument = "--owlory-ui-seed-today-continue-item"

    static let continueFixtureItemID = UUID(uuidString: "9D215686-176C-4C13-936E-AB3092D62A96")!
    static let continueFixtureItemTitle = "Review seeded Continue item"

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
        guard shouldSeedFreshDay || shouldSeedContinueItem else { return }

        #if DEBUG
        resetAppSupport(fileManager: fileManager)
        if shouldSeedContinueItem {
            seedTodayContinueItem()
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
    #endif
}
