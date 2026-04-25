import Foundation

enum AudioFileStore {
    private static let audioSubdirectory = "Audio"

    static func audioDirectory(
        appSupportDirectory: URL? = nil,
        fileManager: FileManager = .default
    ) -> URL {
        let appSupport = appSupportDirectory ?? OwloryAppSupportPath.appSupportDirectory(fileManager: fileManager)
        return OwloryAppSupportPath.currentDirectory(in: appSupport, subdirectory: audioSubdirectory)
    }

    static func audioFileURL(
        named fileName: String,
        appSupportDirectory: URL? = nil,
        fileManager: FileManager = .default
    ) -> URL {
        let appSupport = appSupportDirectory ?? OwloryAppSupportPath.appSupportDirectory(fileManager: fileManager)
        return OwloryAppSupportPath.preferredFileURL(
            in: appSupport,
            subdirectory: audioSubdirectory,
            fileName: fileName,
            fileManager: fileManager
        )
    }

    static func deleteAudioFile(
        named fileName: String,
        appSupportDirectory: URL? = nil,
        fileManager: FileManager = .default
    ) {
        let appSupport = appSupportDirectory ?? OwloryAppSupportPath.appSupportDirectory(fileManager: fileManager)
        let currentURL = OwloryAppSupportPath.currentFileURL(
            in: appSupport,
            subdirectory: audioSubdirectory,
            fileName: fileName
        )
        let legacyURL = OwloryAppSupportPath.legacyFileURL(
            in: appSupport,
            subdirectory: audioSubdirectory,
            fileName: fileName
        )
        try? fileManager.removeItem(at: currentURL)
        if legacyURL != currentURL {
            try? fileManager.removeItem(at: legacyURL)
        }
    }
}
