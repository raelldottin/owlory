import Foundation

struct FileTodayEntryRepository: TodayEntryRepository {
    private let baseURL: URL
    private let legacyBaseURL: URL?
    private let calendar: Calendar
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let fileManager: FileManager

    init(
        baseURL: URL? = nil,
        appSupportDirectory: URL? = nil,
        calendar: Calendar = .current,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder(),
        fileManager: FileManager = .default
    ) {
        self.calendar = calendar
        self.encoder = encoder
        self.decoder = decoder
        self.fileManager = fileManager
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder.dateDecodingStrategy = .iso8601

        if let baseURL {
            self.baseURL = baseURL
            self.legacyBaseURL = nil
        } else {
            let appSupport =
                appSupportDirectory
                ?? OwloryAppSupportPath.appSupportDirectory(fileManager: fileManager)
            self.baseURL = OwloryAppSupportPath.currentDirectory(
                in: appSupport, subdirectory: "TodayEntries")
            self.legacyBaseURL = OwloryAppSupportPath.legacyDirectory(
                in: appSupport, subdirectory: "TodayEntries")
        }
    }

    func loadEntry(for date: Date) throws -> DailyEntry? {
        try PerformanceTelemetry.measure(
            "FileTodayEntryRepository.loadEntry", category: .persistence
        ) {
            guard let url = existingFileURL(for: date) else {
                return nil
            }
            let data = try Data(contentsOf: url)
            return try decoder.decode(DailyEntry.self, from: data)
        }
    }

    func saveEntry(_ entry: DailyEntry) throws {
        try PerformanceTelemetry.measure(
            "FileTodayEntryRepository.saveEntry", category: .persistence
        ) {
            let directory = baseURL
            try fileManager.createDirectory(
                at: directory, withIntermediateDirectories: true, attributes: nil)
            let data = try encoder.encode(entry)
            try data.write(to: fileURL(for: entry.date), options: .atomic)
        }
    }

    private func fileURL(for date: Date) -> URL {
        fileURL(for: date, baseURL: baseURL)
    }

    private func fileURL(for date: Date, baseURL: URL) -> URL {
        let day = calendar.startOfDay(for: date)
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return baseURL.appendingPathComponent(formatter.string(from: day)).appendingPathExtension(
            "json")
    }

    private func existingFileURL(for date: Date) -> URL? {
        let currentURL = fileURL(for: date, baseURL: baseURL)
        if fileManager.fileExists(atPath: currentURL.path) {
            return currentURL
        }

        guard let legacyBaseURL else {
            return nil
        }

        let legacyURL = fileURL(for: date, baseURL: legacyBaseURL)
        if fileManager.fileExists(atPath: legacyURL.path) {
            return legacyURL
        }

        return nil
    }
}
