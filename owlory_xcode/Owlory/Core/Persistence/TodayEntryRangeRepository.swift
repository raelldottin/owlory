import Foundation

protocol TodayEntryRangeRepository {
    func loadEntries(from startDate: Date, through endDate: Date) throws -> [DailyEntry]
}

extension FileTodayEntryRepository: TodayEntryRangeRepository {
    func loadEntries(from startDate: Date, through endDate: Date) throws -> [DailyEntry] {
        let calendar = Calendar.current
        var entries: [DailyEntry] = []
        var date = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        while date <= end {
            if let entry = try loadEntry(for: date) {
                entries.append(entry)
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: date) else { break }
            date = next
        }
        return entries
    }
}

extension InMemoryTodayEntryRepository: TodayEntryRangeRepository {
    func loadEntries(from startDate: Date, through endDate: Date) throws -> [DailyEntry] {
        let calendar = Calendar.current
        var entries: [DailyEntry] = []
        var date = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        while date <= end {
            if let entry = try loadEntry(for: date) {
                entries.append(entry)
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: date) else { break }
            date = next
        }
        return entries
    }
}
