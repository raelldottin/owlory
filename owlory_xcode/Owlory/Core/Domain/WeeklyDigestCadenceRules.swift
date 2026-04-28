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

        return previousCompletedWeekWindow(for: now, calendar: calendar)
    }

    static func previousCompletedWeekWindow(for now: Date, calendar: Calendar) -> WeekWindow? {
        let todayStart = calendar.startOfDay(for: now)
        let weekday = calendar.component(.weekday, from: todayStart)
        let daysSinceMonday = (weekday - mondayWeekday + 7) % 7

        guard let currentMonday = calendar.date(byAdding: .day, value: -daysSinceMonday, to: todayStart),
            let previousMonday = calendar.date(byAdding: .day, value: -7, to: currentMonday),
            let previousSunday = calendar.date(byAdding: .day, value: -1, to: currentMonday)
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
