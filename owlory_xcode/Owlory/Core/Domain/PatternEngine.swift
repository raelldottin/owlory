import Foundation

enum PatternEngine {

    static func computeCompletionRate(entries: [DailyEntry]) -> CompletionRatePattern {
        var done = 0
        var total = 0
        var deferred = 0
        var dropped = 0

        for entry in entries {
            for item in entry.focusThree {
                total += 1
                switch item.status {
                case .done: done += 1
                case .deferred: deferred += 1
                case .dropped: dropped += 1
                case .planned: break
                }
            }
        }

        return CompletionRatePattern(
            doneCount: done,
            totalCount: total,
            deferredCount: deferred,
            droppedCount: dropped
        )
    }

    // MARK: - Carry-Forward Detection

    static func computeCarryForward(
        entries: [DailyEntry],
        calendar: Calendar = .current
    ) -> CarryForwardPattern {
        guard entries.count >= 3 else {
            return CarryForwardPattern(averageCarriedPerDay: 0, stalledItems: [])
        }

        let entriesByDay = Dictionary(grouping: entries) { entry in
            calendar.startOfDay(for: entry.date)
        }
        let sortedDays = entriesByDay.keys.sorted()

        // Count carried items per day (items with createdFromDate set)
        var totalCarried = 0
        var daysWithItems = 0

        // Track current and max consecutive calendar-day carry streaks by title+domain.
        var activeStreaks: [String: (title: String, domain: LifeDomain, count: Int)] = [:]
        var maxStreaks: [String: (title: String, domain: LifeDomain, count: Int)] = [:]
        var previousDay: Date?

        for day in sortedDays {
            guard let dayEntries = entriesByDay[day] else { continue }
            if let previousDay, !isNextCalendarDay(day, after: previousDay, calendar: calendar) {
                activeStreaks.removeAll()
            }

            let focusItems = dayEntries.flatMap(\.focusThree)
            let carried = focusItems.filter { $0.createdFromDate != nil }
            if !focusItems.isEmpty {
                daysWithItems += 1
            }

            var todayCarriedByKey: [String: (title: String, domain: LifeDomain)] = [:]
            for item in carried {
                let key = itemKey(title: item.title, domain: item.domain)
                todayCarriedByKey[key] = (title: item.title, domain: item.domain)
            }
            totalCarried += todayCarriedByKey.count

            // Track which items are still being carried
            let todayKeys = Set(todayCarriedByKey.keys)
            for key in todayKeys.sorted() {
                guard let item = todayCarriedByKey[key] else { continue }
                let nextCount = (activeStreaks[key]?.count ?? 0) + 1
                let nextStreak = (title: item.title, domain: item.domain, count: nextCount)
                activeStreaks[key] = nextStreak
                if nextCount > (maxStreaks[key]?.count ?? 0) {
                    maxStreaks[key] = nextStreak
                }
            }

            // Reset streaks for items not seen today
            for key in Array(activeStreaks.keys) where !todayKeys.contains(key) {
                activeStreaks.removeValue(forKey: key)
            }
            previousDay = day
        }

        let avg = daysWithItems > 0 ? Double(totalCarried) / Double(daysWithItems) : 0

        // Stalled = carried 3+ consecutive calendar days
        let stalled = maxStreaks.keys.sorted().compactMap { key -> CarryForwardPattern.StalledItem? in
            guard let value = maxStreaks[key] else { return nil }
            guard value.count >= 3 else { return nil }
            return CarryForwardPattern.StalledItem(
                title: value.title,
                domain: value.domain,
                consecutiveDays: value.count
            )
        }

        return CarryForwardPattern(
            averageCarriedPerDay: (avg * 10).rounded() / 10,
            stalledItems: stalled
        )
    }

    private static func itemKey(title: String, domain: LifeDomain) -> String {
        "\(title)|\(domain.rawValue)"
    }

    private static func isNextCalendarDay(
        _ day: Date,
        after previousDay: Date,
        calendar: Calendar
    ) -> Bool {
        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: previousDay) else {
            return false
        }
        return calendar.isDate(day, inSameDayAs: nextDay)
    }

    // MARK: - Domain Attention Balance

    static func computeDomainBalance(entries: [DailyEntry]) -> DomainBalancePattern {
        let actionableDomains: [LifeDomain] = [.training, .writing, .career, .home]
        guard !entries.isEmpty else {
            return DomainBalancePattern(domainShares: [:], neglectedDomains: [])
        }

        var domainCounts: [LifeDomain: Int] = [:]
        var total = 0

        for entry in entries {
            for item in entry.focusThree {
                guard actionableDomains.contains(item.domain) else { continue }
                domainCounts[item.domain, default: 0] += 1
                total += 1
            }
        }

        var shares: [LifeDomain: Double] = [:]
        for domain in actionableDomains {
            let count = domainCounts[domain] ?? 0
            shares[domain] = total > 0 ? Double(count) / Double(total) : 0
        }

        // Neglected = zero focus items across the entire window
        let neglected = actionableDomains.filter { (domainCounts[$0] ?? 0) == 0 }

        return DomainBalancePattern(domainShares: shares, neglectedDomains: neglected)
    }

    // MARK: - Readiness-to-Outcome Correlation

    static func computeReadinessOutcome(entries: [DailyEntry]) -> ReadinessOutcomePattern {
        ReadinessOutcomeRules.pattern(from: entries)
    }

    // MARK: - Writing Pipeline Velocity

    static func computeWritingVelocity(notes: [WritingNote]) -> WritingVelocityPattern {
        var distribution: [WritingStage: Int] = [:]
        for note in notes {
            distribution[note.stage, default: 0] += 1
        }

        // Bottleneck = non-terminal stage with the most notes (excluding archived/published)
        let activeStages: [WritingStage] = [.capture, .source, .permanent, .draftSeed, .draft]
        let bottleneck = activeStages
            .filter { (distribution[$0] ?? 0) > 0 }
            .max { (distribution[$0] ?? 0) < (distribution[$1] ?? 0) }

        // Average days from capture creation to reaching source stage
        // We approximate by looking at source+ notes and computing age from createdDate
        let sourceOrBeyond = notes.filter { $0.stage.rawValue >= WritingStage.source.rawValue }
        let captureOnly = notes.filter { $0.stage == .capture }

        var avgDays: Double? = nil
        if !sourceOrBeyond.isEmpty && !captureOnly.isEmpty {
            // Use median created-date gap between captures and sources as proxy
            let captureAvgDate = captureOnly.map { $0.createdDate.timeIntervalSince1970 }.reduce(0, +) / Double(captureOnly.count)
            let sourceAvgDate = sourceOrBeyond.map { $0.createdDate.timeIntervalSince1970 }.reduce(0, +) / Double(sourceOrBeyond.count)
            let diff = sourceAvgDate - captureAvgDate
            if diff > 0 {
                avgDays = (diff / 86400 * 10).rounded() / 10
            }
        }

        return WritingVelocityPattern(
            stageDistribution: distribution,
            bottleneckStage: bottleneck,
            captureToSourceAvgDays: avgDays
        )
    }

    // MARK: - Training Consistency

    static func computeTrainingConsistency(sessions: [TrainingSession]) -> TrainingConsistencyPattern {
        var planned = 0, completed = 0, modified = 0, skipped = 0
        for session in sessions {
            switch session.status {
            case .planned: planned += 1
            case .completed: completed += 1
            case .modified: modified += 1
            case .skipped: skipped += 1
            }
        }
        return TrainingConsistencyPattern(
            sessionsPlanned: planned,
            sessionsCompleted: completed,
            sessionsModified: modified,
            sessionsSkipped: skipped
        )
    }

    // MARK: - Snapshot

    static func computeSnapshot(
        entries: [DailyEntry],
        windowEnd: Date,
        windowDays: Int,
        generatedAt: Date,
        writingNotes: [WritingNote]? = nil,
        trainingSessions: [TrainingSession]? = nil,
        calendar: Calendar = .current
    ) -> PatternSnapshot {
        let carryForward = entries.count >= 3 ? computeCarryForward(entries: entries, calendar: calendar) : nil
        let domainBalance = entries.count >= 7 ? computeDomainBalance(entries: entries) : nil
        let readinessOutcome = ReadinessOutcomeRules.snapshotPattern(from: entries)

        let writing: WritingVelocityPattern? = {
            guard let notes = writingNotes, notes.count >= 3 else { return nil }
            return computeWritingVelocity(notes: notes)
        }()

        let training: TrainingConsistencyPattern? = {
            guard let sessions = trainingSessions, !sessions.isEmpty else { return nil }
            return computeTrainingConsistency(sessions: sessions)
        }()

        return PatternSnapshot(
            generatedAt: generatedAt,
            windowEnd: windowEnd,
            windowDays: windowDays,
            completionRate: computeCompletionRate(entries: entries),
            carryForward: carryForward,
            domainBalance: domainBalance,
            readinessOutcome: readinessOutcome,
            writingVelocity: writing,
            trainingConsistency: training
        )
    }
}
