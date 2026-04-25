import Foundation

final class InMemoryTodayEntryRepository: TodayEntryRepository {
    private var storage: [Date: DailyEntry] = [:]
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func loadEntry(for date: Date) throws -> DailyEntry? {
        storage[calendar.startOfDay(for: date)]
    }

    func saveEntry(_ entry: DailyEntry) throws {
        storage[calendar.startOfDay(for: entry.date)] = entry
    }
}
