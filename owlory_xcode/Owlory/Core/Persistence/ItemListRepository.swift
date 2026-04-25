import Foundation

protocol ItemListRepository<Item> {
    associatedtype Item: Codable
    func loadAll() throws -> [Item]
    func saveAll(_ items: [Item]) throws
}

enum OwloryAppSupportPath {
    static let currentRootDirectory = "Owlory"
    static let legacyRootDirectory = "Trajectory"

    static func appSupportDirectory(fileManager: FileManager = .default) -> URL {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
    }

    static func currentDirectory(in appSupportDirectory: URL, subdirectory: String) -> URL {
        appSupportDirectory
            .appendingPathComponent(currentRootDirectory, isDirectory: true)
            .appendingPathComponent(subdirectory, isDirectory: true)
    }

    static func legacyDirectory(in appSupportDirectory: URL, subdirectory: String) -> URL {
        appSupportDirectory
            .appendingPathComponent(legacyRootDirectory, isDirectory: true)
            .appendingPathComponent(subdirectory, isDirectory: true)
    }

    static func currentFileURL(in appSupportDirectory: URL, subdirectory: String, fileName: String)
        -> URL
    {
        currentDirectory(in: appSupportDirectory, subdirectory: subdirectory)
            .appendingPathComponent(fileName)
    }

    static func legacyFileURL(in appSupportDirectory: URL, subdirectory: String, fileName: String)
        -> URL
    {
        legacyDirectory(in: appSupportDirectory, subdirectory: subdirectory)
            .appendingPathComponent(fileName)
    }

    static func preferredFileURL(
        in appSupportDirectory: URL,
        subdirectory: String,
        fileName: String,
        fileManager: FileManager = .default
    ) -> URL {
        let currentURL = currentFileURL(
            in: appSupportDirectory, subdirectory: subdirectory, fileName: fileName)
        if fileManager.fileExists(atPath: currentURL.path) {
            return currentURL
        }

        let legacyURL = legacyFileURL(
            in: appSupportDirectory, subdirectory: subdirectory, fileName: fileName)
        if fileManager.fileExists(atPath: legacyURL.path) {
            return legacyURL
        }

        return currentURL
    }
}

final class FileItemListRepository<Item: Codable>: ItemListRepository {
    private let fileURL: URL
    private let appSupportDirectory: URL
    private let directory: String
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let fileManager: FileManager

    init(
        directory: String,
        fileName: String,
        appSupportDirectory: URL? = nil,
        fileManager: FileManager = .default
    ) {
        self.directory = directory
        self.fileManager = fileManager
        self.appSupportDirectory =
            appSupportDirectory
            ?? OwloryAppSupportPath.appSupportDirectory(fileManager: fileManager)
        self.fileURL = OwloryAppSupportPath.currentFileURL(
            in: self.appSupportDirectory,
            subdirectory: directory,
            fileName: "\(fileName).json"
        )

        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        enc.dateEncodingStrategy = .iso8601
        self.encoder = enc

        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        self.decoder = dec
    }

    func loadAll() throws -> [Item] {
        try PerformanceTelemetry.measure("FileItemListRepository.loadAll", category: .persistence) {
            let sourceURL = OwloryAppSupportPath.preferredFileURL(
                in: appSupportDirectory,
                subdirectory: directory,
                fileName: fileURL.lastPathComponent,
                fileManager: fileManager
            )
            guard fileManager.fileExists(atPath: sourceURL.path) else { return [] }
            let data = try Data(contentsOf: sourceURL)
            return try decoder.decode([Item].self, from: data)
        }
    }

    func saveAll(_ items: [Item]) throws {
        try PerformanceTelemetry.measure("FileItemListRepository.saveAll", category: .persistence) {
            let dir = fileURL.deletingLastPathComponent()
            try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
            let data = try encoder.encode(items)
            try data.write(to: fileURL, options: .atomic)
        }
    }
}

final class InMemoryItemListRepository<Item: Codable>: ItemListRepository {
    private var items: [Item] = []

    func loadAll() throws -> [Item] { items }
    func saveAll(_ items: [Item]) throws { self.items = items }
}
