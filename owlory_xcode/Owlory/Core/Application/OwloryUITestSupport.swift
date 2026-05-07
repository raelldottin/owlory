import Foundation

enum OwloryUITestSupport {
    static let enabledArgument = "--owlory-ui-testing"
    static let freshDaySeedArgument = "--owlory-ui-seed-fresh-day"

    static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains(enabledArgument)
    }

    static func prepareLaunchEnvironmentIfNeeded(
        fileManager: FileManager = .default
    ) {
        guard isUITesting,
            ProcessInfo.processInfo.arguments.contains(freshDaySeedArgument)
        else {
            return
        }

        #if DEBUG
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
        #endif
    }
}
