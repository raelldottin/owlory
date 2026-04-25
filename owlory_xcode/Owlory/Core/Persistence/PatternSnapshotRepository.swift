import Foundation

protocol PatternSnapshotRepository {
    func loadSnapshot(windowDays: Int) throws -> PatternSnapshot?
    func saveSnapshot(_ snapshot: PatternSnapshot) throws
}

struct FilePatternSnapshotRepository: PatternSnapshotRepository {
    private let baseURL: URL
    private let legacyBaseURL: URL?
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let fileManager: FileManager

    init(
        baseURL: URL? = nil,
        appSupportDirectory: URL? = nil,
        fileManager: FileManager = .default
    ) {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        enc.dateEncodingStrategy = .iso8601
        self.encoder = enc
        self.fileManager = fileManager

        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        self.decoder = dec

        if let baseURL {
            self.baseURL = baseURL
            self.legacyBaseURL = nil
        } else {
            let appSupport =
                appSupportDirectory
                ?? OwloryAppSupportPath.appSupportDirectory(fileManager: fileManager)
            self.baseURL = OwloryAppSupportPath.currentDirectory(
                in: appSupport, subdirectory: "Patterns")
            self.legacyBaseURL = OwloryAppSupportPath.legacyDirectory(
                in: appSupport, subdirectory: "Patterns")
        }
    }

    func loadSnapshot(windowDays: Int) throws -> PatternSnapshot? {
        try PerformanceTelemetry.measure(
            "FilePatternSnapshotRepository.loadSnapshot", category: .persistence
        ) {
            guard let url = existingFileURL(windowDays: windowDays) else { return nil }
            let data = try Data(contentsOf: url)
            return try decoder.decode(PatternSnapshot.self, from: data)
        }
    }

    func saveSnapshot(_ snapshot: PatternSnapshot) throws {
        try PerformanceTelemetry.measure(
            "FilePatternSnapshotRepository.saveSnapshot", category: .persistence
        ) {
            try fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true)
            let data = try encoder.encode(snapshot)
            try data.write(to: fileURL(windowDays: snapshot.windowDays), options: .atomic)
        }
    }

    private func fileURL(windowDays: Int) -> URL {
        fileURL(windowDays: windowDays, baseURL: baseURL)
    }

    private func fileURL(windowDays: Int, baseURL: URL) -> URL {
        baseURL.appendingPathComponent("snapshot-\(windowDays)d").appendingPathExtension("json")
    }

    private func existingFileURL(windowDays: Int) -> URL? {
        let currentURL = fileURL(windowDays: windowDays, baseURL: baseURL)
        if fileManager.fileExists(atPath: currentURL.path) {
            return currentURL
        }

        guard let legacyBaseURL else {
            return nil
        }

        let legacyURL = fileURL(windowDays: windowDays, baseURL: legacyBaseURL)
        if fileManager.fileExists(atPath: legacyURL.path) {
            return legacyURL
        }

        return nil
    }
}

final class InMemoryPatternSnapshotRepository: PatternSnapshotRepository {
    private var storage: [Int: PatternSnapshot] = [:]

    func loadSnapshot(windowDays: Int) throws -> PatternSnapshot? {
        storage[windowDays]
    }

    func saveSnapshot(_ snapshot: PatternSnapshot) throws {
        storage[snapshot.windowDays] = snapshot
    }
}
