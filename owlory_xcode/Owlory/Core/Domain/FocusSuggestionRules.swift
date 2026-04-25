import Foundation

enum FocusSuggestionRules {
    struct ActiveItem: Equatable {
        let title: String
        let domain: LifeDomain

        init(title: String, domain: LifeDomain) {
            self.title = title
            self.domain = domain
        }
    }

    struct Candidate: Equatable {
        let title: String
        let domain: LifeDomain
        let linkedRecordID: UUID?
        let reason: String
        let priority: Int

        init(
            title: String,
            domain: LifeDomain,
            linkedRecordID: UUID? = nil,
            reason: String = "",
            priority: Int
        ) {
            self.title = title
            self.domain = domain
            self.linkedRecordID = linkedRecordID
            self.reason = reason
            self.priority = priority
        }
    }

    struct Draft: Identifiable, Equatable {
        let id: UUID
        let title: String
        let domain: LifeDomain
        let linkedRecordID: UUID?
        let reason: String
        let key: String

        init(
            id: UUID = UUID(),
            title: String,
            domain: LifeDomain,
            linkedRecordID: UUID?,
            reason: String,
            key: String
        ) {
            self.id = id
            self.title = title
            self.domain = domain
            self.linkedRecordID = linkedRecordID
            self.reason = reason
            self.key = key
        }
    }

    static func candidates(
        todayEntry: DailyEntry,
        recentEntries: [DailyEntry],
        predictions: [String: CompletionTimePredictor.Prediction],
        now: Date,
        calendar: Calendar = .current,
        activeItems: [ActiveItem] = []
    ) -> [Candidate] {
        let todayStart = calendar.startOfDay(for: todayEntry.date)
        let todayBand = readinessBand(for: todayEntry)
        let blockedKeys = Set(
            todayEntry.focusThree.map {
                key(title: $0.title, domain: $0.domain, linkedRecordID: nil)
            }
        ).union(
            activeItems.map {
                key(title: $0.title, domain: $0.domain, linkedRecordID: nil)
            }
        )

        var signals: [String: Signal] = [:]

        for entry in recentEntries.sorted(by: { $0.date > $1.date }) {
            guard calendar.startOfDay(for: entry.date) < todayStart else { continue }
            let entryBand = readinessBand(for: entry)

            for item in entry.focusThree where item.status == .done {
                let key = key(title: item.title, domain: item.domain, linkedRecordID: nil)
                guard !key.isEmpty, !blockedKeys.contains(key) else { continue }

                var signal = signals[key] ?? Signal(
                    title: item.title.trimmingCharacters(in: .whitespacesAndNewlines),
                    domain: item.domain,
                    completionCount: 0,
                    similarReadinessCount: 0,
                    lastCompletedDate: nil,
                    prediction: nil,
                    sourceOrder: signals.count
                )
                signal.completionCount += 1
                if entryBand == todayBand {
                    signal.similarReadinessCount += 1
                }
                if signal.lastCompletedDate.map({ entry.date > $0 }) ?? true {
                    signal.lastCompletedDate = entry.date
                }
                signals[key] = signal
            }
        }

        for predictionKey in predictions.keys.sorted() {
            guard let prediction = predictions[predictionKey],
                  let descriptor = descriptor(forPredictionKey: predictionKey) else {
                continue
            }

            let key = key(title: descriptor.title, domain: descriptor.domain, linkedRecordID: nil)
            guard !key.isEmpty, !blockedKeys.contains(key) else { continue }

            var signal = signals[key] ?? Signal(
                title: descriptor.title,
                domain: descriptor.domain,
                completionCount: 0,
                similarReadinessCount: 0,
                lastCompletedDate: nil,
                prediction: nil,
                sourceOrder: signals.count
            )
            signal.completionCount = max(signal.completionCount, prediction.sampleCount)
            signal.prediction = prediction
            signals[key] = signal
        }

        let ranked = signals.values
            .filter { isStrongEnough($0) }
            .sorted { lhs, rhs in
                let lhsScore = score(
                    lhs,
                    todayBand: todayBand,
                    todayStart: todayStart,
                    now: now,
                    calendar: calendar
                )
                let rhsScore = score(
                    rhs,
                    todayBand: todayBand,
                    todayStart: todayStart,
                    now: now,
                    calendar: calendar
                )
                if lhsScore != rhsScore {
                    return lhsScore > rhsScore
                }
                switch (lhs.lastCompletedDate, rhs.lastCompletedDate) {
                case let (lhsDate?, rhsDate?) where lhsDate != rhsDate:
                    return lhsDate > rhsDate
                case (nil, _?):
                    return false
                case (_?, nil):
                    return true
                default:
                    return lhs.sourceOrder < rhs.sourceOrder
                }
            }

        // Keep the candidate fact set compact: enough signal for future model
        // re-ranking, while deterministic statistics remain the fallback.
        return ranked.prefix(12).enumerated().map { index, signal in
            Candidate(
                title: signal.title,
                domain: signal.domain,
                reason: reason(
                    for: signal,
                    todayBand: todayBand,
                    todayStart: todayStart,
                    calendar: calendar
                ),
                priority: index
            )
        }
    }

    static func drafts(
        todayEntry: DailyEntry,
        suggestedFocusLoad: Int,
        candidates: [Candidate],
        dismissedKeys: Set<String>,
        makeID: () -> UUID = UUID.init
    ) -> [Draft] {
        let targetCount = max(0, min(DailyPlanningRules.focusItemLimit, suggestedFocusLoad))
        let remainingSlots = max(0, targetCount - todayEntry.focusThree.count)
        guard remainingSlots > 0 else { return [] }

        let existingKeys = Set(
            todayEntry.focusThree.map {
                key(title: $0.title, domain: $0.domain, linkedRecordID: $0.linkedRecordID)
            }
        )

        var seenKeys: Set<String> = []
        var drafts: [Draft] = []
        let sortedCandidates = candidates.enumerated().sorted { lhs, rhs in
            if lhs.element.priority != rhs.element.priority {
                return lhs.element.priority < rhs.element.priority
            }
            return lhs.offset < rhs.offset
        }

        for (_, candidate) in sortedCandidates {
            let key = key(
                title: candidate.title,
                domain: candidate.domain,
                linkedRecordID: candidate.linkedRecordID
            )
            guard !key.isEmpty,
                  !existingKeys.contains(key),
                  !dismissedKeys.contains(key),
                  !seenKeys.contains(key) else {
                continue
            }

            seenKeys.insert(key)
            drafts.append(
                Draft(
                    id: makeID(),
                    title: candidate.title,
                    domain: candidate.domain,
                    linkedRecordID: candidate.linkedRecordID,
                    reason: candidate.reason,
                    key: key
                )
            )

            if drafts.count >= remainingSlots {
                break
            }
        }
        return drafts
    }

    static func key(title: String, domain: LifeDomain, linkedRecordID: UUID?) -> String {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return "" }
        return [trimmedTitle.lowercased(), domain.rawValue.lowercased(), linkedRecordID?.uuidString ?? ""]
            .joined(separator: "|")
    }
}

private extension FocusSuggestionRules {
    enum ReadinessBand: Equatable {
        case low
        case steady
        case high

        var phrase: String {
            switch self {
            case .low:
                return "low-readiness"
            case .steady:
                return "steady"
            case .high:
                return "high-readiness"
            }
        }
    }

    struct Signal {
        let title: String
        let domain: LifeDomain
        var completionCount: Int
        var similarReadinessCount: Int
        var lastCompletedDate: Date?
        var prediction: CompletionTimePredictor.Prediction?
        let sourceOrder: Int
    }

    static func readinessBand(for entry: DailyEntry) -> ReadinessBand {
        let average = Double(entry.energy + entry.mood + entry.sleepQuality) / 3.0
        if average <= 2.33 {
            return .low
        }
        if average >= 3.67 {
            return .high
        }
        return .steady
    }

    static func descriptor(
        forPredictionKey key: String
    ) -> (title: String, domain: LifeDomain)? {
        let parts = key.split(separator: "|", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2 else { return nil }
        let rawTitle = String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !rawTitle.isEmpty else { return nil }

        let domain: LifeDomain
        switch parts[0] {
        case "home", "protocol":
            domain = .home
        case "train":
            domain = .training
        default:
            return nil
        }

        return (displayTitle(fromNormalizedTitle: rawTitle), domain)
    }

    static func displayTitle(fromNormalizedTitle title: String) -> String {
        title
            .split(separator: " ")
            .map { word in
                guard let first = word.first else { return "" }
                return String(first).uppercased() + String(word.dropFirst())
            }
            .joined(separator: " ")
    }

    static func isStrongEnough(_ signal: Signal) -> Bool {
        signal.completionCount >= 2 || signal.similarReadinessCount > 0 || signal.prediction != nil
    }

    static func score(
        _ signal: Signal,
        todayBand: ReadinessBand,
        todayStart: Date,
        now: Date,
        calendar: Calendar
    ) -> Double {
        let completionScore = min(Double(signal.completionCount), 6)
        let readinessScore = Double(signal.similarReadinessCount) * 2
        let recencyScore: Double = {
            guard let lastCompletedDate = signal.lastCompletedDate else { return 0 }
            let daysAgo = calendar.dateComponents(
                [.day],
                from: calendar.startOfDay(for: lastCompletedDate),
                to: todayStart
            ).day ?? 30
            return max(0, Double(30 - daysAgo)) / 10
        }()
        let timingScore = signal.prediction?.urgencyScore(now: now, on: todayStart, calendar: calendar) ?? 0
        let predictionConfidence = min(Double(signal.prediction?.sampleCount ?? 0), 8) * 0.25
        let lowReadinessPenalty = todayBand == .low && signal.similarReadinessCount == 0 ? -1.5 : 0

        return completionScore + readinessScore + recencyScore + (timingScore * 2) + predictionConfidence + lowReadinessPenalty
    }

    static func reason(
        for signal: Signal,
        todayBand: ReadinessBand,
        todayStart: Date,
        calendar: Calendar
    ) -> String {
        var parts: [String] = []
        if signal.similarReadinessCount > 0 {
            parts.append(
                "You finished this \(countPhrase(signal.similarReadinessCount)) on \(todayBand.phrase) check-in days."
            )
        } else {
            parts.append("You completed this \(countPhrase(signal.completionCount)) recently.")
        }

        if let prediction = signal.prediction {
            parts.append("Usually completed around \(timeOfDayString(prediction.medianTimeOfDay)).")
        } else if let lastCompletedDate = signal.lastCompletedDate {
            let daysAgo = calendar.dateComponents(
                [.day],
                from: calendar.startOfDay(for: lastCompletedDate),
                to: todayStart
            ).day ?? 0
            parts.append("Last done \(dayDistancePhrase(daysAgo)).")
        }

        return parts.joined(separator: " ")
    }

    static func countPhrase(_ count: Int) -> String {
        if count <= 1 {
            return "once"
        }
        return "\(count) times"
    }

    static func dayDistancePhrase(_ daysAgo: Int) -> String {
        switch daysAgo {
        case 0:
            return "today"
        case 1:
            return "yesterday"
        default:
            return "\(daysAgo) days ago"
        }
    }

    static func timeOfDayString(_ secondsSinceMidnight: TimeInterval) -> String {
        let totalMinutes = Int((secondsSinceMidnight / 60).rounded())
        let hour24 = (totalMinutes / 60) % 24
        let minute = totalMinutes % 60
        let hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12
        let suffix = hour24 < 12 ? "AM" : "PM"
        if minute == 0 {
            return "\(hour12) \(suffix)"
        }
        return String(format: "%d:%02d %@", hour12, minute, suffix)
    }
}
