import Foundation

enum WeeklyDigestCadenceRules {
    struct WeekWindow: Equatable {
        let weekStarting: Date
        let weekEnding: Date
    }

    private static let mondayWeekday = 2

    static func targetWindow(for now: Date, calendar: Calendar) -> WeekWindow? {
        guard calendar.component(.weekday, from: now) == mondayWeekday else {
            return nil
        }

        let todayStart = calendar.startOfDay(for: now)
        guard let previousMonday = calendar.date(byAdding: .day, value: -7, to: todayStart),
            let previousSunday = calendar.date(byAdding: .day, value: -1, to: todayStart)
        else {
            return nil
        }

        return WeekWindow(weekStarting: previousMonday, weekEnding: previousSunday)
    }

    static func hasGeneratedDigest(
        for window: WeekWindow,
        existingDigests: [WeeklyDigest],
        calendar: Calendar
    ) -> Bool {
        let targetStart = calendar.startOfDay(for: window.weekStarting)
        return existingDigests.contains {
            calendar.startOfDay(for: $0.weekStarting) == targetStart
        }
    }
}
