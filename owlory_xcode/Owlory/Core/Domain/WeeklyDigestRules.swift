import Foundation

enum WeeklyDigestRules {
    static let currentDigestRuleVersion = WeeklyDigestRuleVersion.current

    static func collapsedCompletionSummary(for digest: WeeklyDigest) -> String {
        guard digest.totalPlanned > 0 else {
            return "No planned Focus items"
        }

        return "\(digest.totalDone) of \(digest.totalPlanned) done"
    }

    static func usesCurrentDigestRuleVersion(_ digest: WeeklyDigest) -> Bool {
        digest.digestRuleVersion == currentDigestRuleVersion
    }

    static func relativeWeekLabel(
        for digest: WeeklyDigest,
        now: Date,
        calendar: Calendar = .current
    ) -> String {
        guard let previousWeek = WeeklyDigestCadenceRules.previousCompletedWeekWindow(
            for: now,
            calendar: calendar
        ) else {
            return "Most Recent Week"
        }

        let digestStart = calendar.startOfDay(for: digest.weekStarting)
        let digestEnd = calendar.startOfDay(for: digest.weekEnding)
        let previousStart = calendar.startOfDay(for: previousWeek.weekStarting)
        let previousEnd = calendar.startOfDay(for: previousWeek.weekEnding)

        if digestStart == previousStart && digestEnd == previousEnd {
            return "Last Week"
        }

        return "Most Recent Week"
    }

    static func generate(
        entries: [DailyEntry],
        weekStarting: Date,
        weekEnding: Date,
        generatedAt: Date,
        protocolRuns: [ProtocolRun] = [],
        calendar: Calendar = .current
    ) -> WeeklyDigest? {
        let completedProtocolStepCount = completedProtocolStepsInWindow(
            protocolRuns: protocolRuns,
            weekStarting: weekStarting,
            weekEnding: weekEnding,
            calendar: calendar
        )

        guard !entries.isEmpty || completedProtocolStepCount > 0 else { return nil }

        let daysWithEntries = entries.count

        // Completion rate
        var totalPlanned = 0
        var totalDone = 0
        var totalDeferred = 0

        for entry in entries {
            for item in entry.focusThree {
                totalPlanned += 1
                switch item.status {
                case .done: totalDone += 1
                case .deferred: totalDeferred += 1
                case .dropped, .planned: break
                }
            }
        }

        totalPlanned += completedProtocolStepCount
        totalDone += completedProtocolStepCount

        let completionRate = totalPlanned > 0 ? Double(totalDone) / Double(totalPlanned) : 0

        // Average readiness
        let readinessEntries = entries.filter { $0.energy > 0 || $0.mood > 0 || $0.sleepQuality > 0 }
        let averageReadiness: Double = {
            guard !readinessEntries.isEmpty else { return 0 }
            let sum = readinessEntries.reduce(0.0) { acc, e in
                acc + Double(e.energy + e.mood + e.sleepQuality) / 3.0
            }
            return (sum / Double(readinessEntries.count) * 10).rounded() / 10
        }()

        // Best day = highest completion rate; hardest = lowest readiness avg
        let bestDay = bestDayHighlight(entries: entries, calendar: calendar)
        let hardestDay = hardestDayHighlight(entries: readinessEntries, calendar: calendar)

        // Domain activity
        var domainActivity: [LifeDomain: Int] = [:]
        for entry in entries {
            for item in entry.focusThree {
                domainActivity[item.domain, default: 0] += 1
            }
        }
        if completedProtocolStepCount > 0 {
            domainActivity[.home, default: 0] += completedProtocolStepCount
        }

        // Stalled items (carried items across last 3+ days of window)
        let stalledItemCount: Int = {
            guard entries.count >= 3 else { return 0 }
            let cf = PatternEngine.computeCarryForward(entries: entries, calendar: calendar)
            return cf.stalledItems.count
        }()

        // Streak = consecutive days with entries from end of week backward
        let streakDays = computeStreak(
            entries: entries,
            weekEnding: weekEnding,
            calendar: calendar
        )

        // Key insight
        let keyInsight = generateInsight(
            completionRate: completionRate,
            averageReadiness: averageReadiness,
            daysWithEntries: daysWithEntries,
            totalDeferred: totalDeferred,
            stalledItemCount: stalledItemCount
        )

        return WeeklyDigest(
            weekStarting: weekStarting,
            weekEnding: weekEnding,
            generatedAt: generatedAt,
            daysWithEntries: daysWithEntries,
            completionRate: (completionRate * 100).rounded() / 100,
            totalPlanned: totalPlanned,
            totalDone: totalDone,
            averageReadiness: averageReadiness,
            bestDay: bestDay,
            hardestDay: hardestDay,
            domainActivity: domainActivity,
            stalledItemCount: stalledItemCount,
            streakDays: streakDays,
            keyInsight: keyInsight
        )
    }

    // MARK: - Helpers

    private static func completedProtocolStepsInWindow(
        protocolRuns: [ProtocolRun],
        weekStarting: Date,
        weekEnding: Date,
        calendar: Calendar
    ) -> Int {
        protocolRuns.reduce(0) { count, run in
            count + run.steps.filter { step in
                guard step.status == .completed,
                    let completedAt = step.completedAt
                else {
                    return false
                }

                return isInDigestWindow(
                    completedAt,
                    weekStarting: weekStarting,
                    weekEnding: weekEnding,
                    calendar: calendar
                )
            }.count
        }
    }

    private static func isInDigestWindow(
        _ date: Date,
        weekStarting: Date,
        weekEnding: Date,
        calendar: Calendar
    ) -> Bool {
        let start = calendar.startOfDay(for: weekStarting)
        let endDay = calendar.startOfDay(for: weekEnding)
        guard let exclusiveEnd = calendar.date(byAdding: .day, value: 1, to: endDay) else {
            return false
        }

        return date >= start && date < exclusiveEnd
    }

    static func weekRangeLabel(
        for digest: WeeklyDigest,
        calendar: Calendar = .current,
        separator: String = "–"
    ) -> String {
        let start = monthDayLabel(for: digest.weekStarting, calendar: calendar)
        let end = monthDayLabel(for: digest.weekEnding, calendar: calendar)
        return "\(start) \(separator) \(end)"
    }

    private static func bestDayHighlight(
        entries: [DailyEntry],
        calendar: Calendar
    ) -> WeeklyDigest.DayHighlight? {
        let withItems = entries.filter { !$0.focusThree.isEmpty }
        guard !withItems.isEmpty else { return nil }

        let best = withItems.max { a, b in
            let aRate = Double(a.focusThree.filter { $0.status == .done }.count) / Double(a.focusThree.count)
            let bRate = Double(b.focusThree.filter { $0.status == .done }.count) / Double(b.focusThree.count)
            return aRate < bRate
        }!

        let doneCount = best.focusThree.filter { $0.status == .done }.count
        let plannedCount = best.focusThree.count

        return WeeklyDigest.DayHighlight(
            date: best.date,
            summary: "",
            doneCount: doneCount,
            plannedCount: plannedCount
        )
    }

    private static func hardestDayHighlight(
        entries: [DailyEntry],
        calendar: Calendar
    ) -> WeeklyDigest.DayHighlight? {
        guard !entries.isEmpty else { return nil }

        let hardest = entries.min { a, b in
            let aAvg = Double(a.energy + a.mood + a.sleepQuality) / 3.0
            let bAvg = Double(b.energy + b.mood + b.sleepQuality) / 3.0
            return aAvg < bAvg
        }!

        let avg = Double(hardest.energy + hardest.mood + hardest.sleepQuality) / 3.0
        let band: WeeklyDigest.ReadinessBand = avg <= 2.0 ? .low : .moderate

        return WeeklyDigest.DayHighlight(
            date: hardest.date,
            summary: "",
            readinessBand: band.rawValue
        )
    }

    private static func monthDayLabel(for date: Date, calendar: Calendar) -> String {
        label(for: date, calendar: calendar, dateFormat: "MMM d")
    }

    private static func label(for date: Date, calendar: Calendar, dateFormat: String) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = dateFormat
        return formatter.string(from: date)
    }

    private static func computeStreak(
        entries: [DailyEntry],
        weekEnding: Date,
        calendar: Calendar
    ) -> Int {
        let entryDays = Set(entries.map { calendar.startOfDay(for: $0.date) })
        var streak = 0
        var day = calendar.startOfDay(for: weekEnding)

        while entryDays.contains(day) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }

        return streak
    }

    private static func generateInsight(
        completionRate: Double,
        averageReadiness: Double,
        daysWithEntries: Int,
        totalDeferred: Int,
        stalledItemCount: Int
    ) -> String {
        if daysWithEntries <= 2 {
            return WeeklyDigest.InsightKind.lightWeek.rawValue
        }
        if completionRate >= 0.8 && averageReadiness >= 3.5 {
            return WeeklyDigest.InsightKind.strongWeek.rawValue
        }
        if completionRate >= 0.8 {
            return WeeklyDigest.InsightKind.finishedMost.rawValue
        }
        if completionRate < 0.4 && averageReadiness <= 2.5 {
            return WeeklyDigest.InsightKind.toughWeek.rawValue
        }
        if stalledItemCount >= 2 {
            return WeeklyDigest.InsightKind.stalledCarryOver.rawValue
        }
        if totalDeferred >= 3 {
            return WeeklyDigest.InsightKind.severalDeferred.rawValue
        }
        if completionRate < 0.5 {
            return WeeklyDigest.InsightKind.lowCompletion.rawValue
        }
        return WeeklyDigest.InsightKind.steady.rawValue
    }
}
