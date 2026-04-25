import Foundation

protocol TodayEntryRepository {
    func loadEntry(for date: Date) throws -> DailyEntry?
    func saveEntry(_ entry: DailyEntry) throws
}
