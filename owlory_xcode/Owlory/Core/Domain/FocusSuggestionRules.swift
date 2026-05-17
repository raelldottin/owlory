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

    /// Semantic reason for surfacing a Focus Suggestion. Carries the data
    /// the user needs to evaluate the suggestion ("you completed this N times
    /// on similar-readiness days, usually around midday") without owning the
    /// English presentation copy. Features/Today maps each case to localized
    /// display text via `focusSuggestionReasonText(for:)`. Per
    /// `docs/workflows/localization-dynamic-formatting.md`, Core/Domain must
    /// not own UI strings.
    struct Reason: Equatable, Codable, Sendable {
        enum ReadinessContext: String, Equatable, Codable, Sendable, CaseIterable {
            case low
            case steady
            case high
        }

        enum Completion: Equatable, Codable, Sendable {
            case similarReadinessHistory(count: Int, context: ReadinessContext)
            case recentCompletions(count: Int)
        }

        enum Timing: Equatable, Codable, Sendable {
            /// Median completion time as seconds since midnight.
            case predictedTime(secondsSinceMidnight: TimeInterval)
            /// How many days ago the user last completed this item.
            case lastCompletion(daysAgo: Int)
        }

        let completion: Completion
        let timing: Timing?

        public init(completion: Completion, timing: Timing? = nil) {
            self.completion = completion
            self.timing = timing
        }
    }

    struct Candidate: Equatable {
        let title: String
        let domain: LifeDomain
        let linkedRecordID: UUID?
        let reason: Reason?
        let priority: Int

        init(
            title: String,
            domain: LifeDomain,
            linkedRecordID: UUID? = nil,
            reason: Reason? = nil,
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
        let reason: Reason?
        let key: String

        init(
            id: UUID = UUID(),
            title: String,
            domain: LifeDomain,
            linkedRecordID: UUID?,
            reason: Reason?,
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
    ) -> FocusSuggestionRules.Reason {
        let completion: FocusSuggestionRules.Reason.Completion
        if signal.similarReadinessCount > 0 {
            completion = .similarReadinessHistory(
                count: signal.similarReadinessCount,
                context: todayBand.reasonContext
            )
        } else {
            completion = .recentCompletions(count: signal.completionCount)
        }

        let timing: FocusSuggestionRules.Reason.Timing?
        if let prediction = signal.prediction {
            timing = .predictedTime(secondsSinceMidnight: prediction.medianTimeOfDay)
        } else if let lastCompletedDate = signal.lastCompletedDate {
            let daysAgo = calendar.dateComponents(
                [.day],
                from: calendar.startOfDay(for: lastCompletedDate),
                to: todayStart
            ).day ?? 0
            timing = .lastCompletion(daysAgo: daysAgo)
        } else {
            timing = nil
        }

        return FocusSuggestionRules.Reason(completion: completion, timing: timing)
    }
}

private extension FocusSuggestionRules.ReadinessBand {
    var reasonContext: FocusSuggestionRules.Reason.ReadinessContext {
        switch self {
        case .low: return .low
        case .steady: return .steady
        case .high: return .high
        }
    }
}
