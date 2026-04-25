import Foundation

enum TodayContinueSourceComposer {
    enum Step: String, CaseIterable, Equatable {
        case dueTodayTraining
        case carriedForwardFocus
        case activeHomeProtocolRun
        case activeHomeTask
        case inProgressWriting

        var reason: String {
            switch self {
            case .dueTodayTraining:
                return "Due today"
            case .carriedForwardFocus:
                return "Carried forward"
            case .activeHomeProtocolRun:
                return "Protocol run"
            case .activeHomeTask:
                return "Active"
            case .inProgressWriting:
                return "In progress"
            }
        }

        var priority: ContinuePriority {
            switch self {
            case .dueTodayTraining:
                return .dueToday
            case .carriedForwardFocus:
                return .carriedForward
            case .activeHomeProtocolRun:
                return .active
            case .activeHomeTask:
                return .active
            case .inProgressWriting:
                return .inProgress
            }
        }
    }

    struct Candidate: Equatable {
        let step: Step
        let title: String
        let domain: LifeDomain
        let source: TodayContinuationRules.ContinueSource
        let linkedRecordID: UUID?
        let staleDayCount: Int?
        let predictionKey: String?

        var reason: String { step.reason }
        var priority: ContinuePriority { step.priority }
    }

    static let sourceOrder: [Step] = [
        .dueTodayTraining,
        .carriedForwardFocus,
        .activeHomeProtocolRun,
        .activeHomeTask,
        .inProgressWriting,
    ]

    static func compose(
        todayEntry: DailyEntry,
        calibration: CalibrationRules.Calibration,
        todaySessions: [TrainingSession],
        homeTasks: [HomeTask],
        homeRuns: [ProtocolRun],
        homeProtocols: [HouseholdProtocol] = [],
        writingNotes: [WritingNote]
    ) -> [Candidate] {
        let staleByKey = staleIndex(from: calibration)
        let protocolTitles = homeProtocolTitleIndex(
            protocols: homeProtocols,
            runs: homeRuns
        )
        let protocolRunIDs = Set(homeRuns.map(\.id))

        return sourceOrder.flatMap { step -> [Candidate] in
            switch step {
            case .dueTodayTraining:
                return dueTodayTrainingCandidates(from: todaySessions)
            case .carriedForwardFocus:
                return carriedForwardFocusCandidates(
                    from: todayEntry.focusThree,
                    staleByKey: staleByKey,
                    protocolTitles: protocolTitles,
                    protocolRunIDs: protocolRunIDs
                )
            case .activeHomeProtocolRun:
                return activeHomeProtocolRunCandidates(from: homeRuns)
            case .activeHomeTask:
                return activeHomeTaskCandidates(from: homeTasks)
            case .inProgressWriting:
                return inProgressWritingCandidates(from: writingNotes)
            }
        }
    }

    private static func dueTodayTrainingCandidates(
        from sessions: [TrainingSession]
    ) -> [Candidate] {
        sessions.compactMap { session in
            guard ContinueCandidateRules.isDueTodayCandidate(session) else { return nil }
            return Candidate(
                step: .dueTodayTraining,
                title: session.plannedActivity,
                domain: .training,
                source: .trainingSession(session.id),
                linkedRecordID: nil,
                staleDayCount: nil,
                predictionKey: CompletionTimePredictor.key(
                    forTrainingSession: session.plannedActivity
                )
            )
        }
    }

    private static func carriedForwardFocusCandidates(
        from items: [FocusItem],
        staleByKey: [String: CalibrationRules.StaleItemAlert],
        protocolTitles: Set<String>,
        protocolRunIDs: Set<UUID>
    ) -> [Candidate] {
        items.compactMap { item in
            guard !isHomeProtocolFocusArtifact(
                item,
                protocolTitles: protocolTitles,
                protocolRunIDs: protocolRunIDs
            ) else {
                return nil
            }

            let stale = staleByKey[itemKey(title: item.title, domain: item.domain)]
            guard ContinueCandidateRules.isCarriedForwardCandidate(
                item,
                staleDayCount: stale?.consecutiveDays
            ) else {
                return nil
            }

            return Candidate(
                step: .carriedForwardFocus,
                title: item.title,
                domain: item.domain,
                source: .carriedFocusItem(item.id),
                linkedRecordID: item.linkedRecordID,
                staleDayCount: stale?.consecutiveDays,
                predictionKey: predictionKey(for: item)
            )
        }
    }

    private static func activeHomeProtocolRunCandidates(
        from runs: [ProtocolRun]
    ) -> [Candidate] {
        runs.compactMap { run in
            guard ContinueCandidateRules.isActiveHomeProtocolRunCandidate(run) else { return nil }
            return Candidate(
                step: .activeHomeProtocolRun,
                title: run.protocolTitle,
                domain: .home,
                source: .homeProtocolRun(run.id),
                linkedRecordID: nil,
                staleDayCount: nil,
                predictionKey: CompletionTimePredictor.key(forProtocolRun: run.protocolTitle)
            )
        }
    }

    private static func activeHomeTaskCandidates(from tasks: [HomeTask]) -> [Candidate] {
        tasks.compactMap { task in
            guard ContinueCandidateRules.isActiveHomeTaskCandidate(task) else { return nil }
            return Candidate(
                step: .activeHomeTask,
                title: task.title,
                domain: .home,
                source: .homeTask(task.id),
                linkedRecordID: nil,
                staleDayCount: nil,
                predictionKey: CompletionTimePredictor.key(forHomeTask: task.title)
            )
        }
    }

    private static func inProgressWritingCandidates(
        from notes: [WritingNote]
    ) -> [Candidate] {
        notes.compactMap { note in
            guard ContinueCandidateRules.isInProgressWritingCandidate(note) else { return nil }
            return Candidate(
                step: .inProgressWriting,
                title: note.title,
                domain: .writing,
                source: .writingNote(note.id),
                linkedRecordID: nil,
                staleDayCount: nil,
                predictionKey: nil
            )
        }
    }

    private static func staleIndex(
        from calibration: CalibrationRules.Calibration
    ) -> [String: CalibrationRules.StaleItemAlert] {
        var staleByKey: [String: CalibrationRules.StaleItemAlert] = [:]
        for item in calibration.staleItems {
            staleByKey[itemKey(title: item.title, domain: item.domain)] = item
        }
        return staleByKey
    }

    private static func homeProtocolTitleIndex(
        protocols: [HouseholdProtocol],
        runs: [ProtocolRun]
    ) -> Set<String> {
        Set((protocols.map(\.title) + runs.map(\.protocolTitle)).compactMap(normalizedTitle))
    }

    private static func isHomeProtocolFocusArtifact(
        _ item: FocusItem,
        protocolTitles: Set<String>,
        protocolRunIDs: Set<UUID>
    ) -> Bool {
        guard item.domain == .home else { return false }
        if let linkedRecordID = item.linkedRecordID,
           protocolRunIDs.contains(linkedRecordID) {
            return true
        }
        guard let title = normalizedTitle(item.title) else { return false }
        return protocolTitles.contains(title)
    }

    private static func predictionKey(for item: FocusItem) -> String? {
        switch item.domain {
        case .home:
            return CompletionTimePredictor.key(forHomeTask: item.title)
        case .training:
            return CompletionTimePredictor.key(forTrainingSession: item.title)
        default:
            return nil
        }
    }

    private static func itemKey(title: String, domain: LifeDomain) -> String {
        "\(title)|\(domain.rawValue)"
    }

    private static func normalizedTitle(_ title: String) -> String? {
        let normalized = title
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return normalized.isEmpty ? nil : normalized
    }
}
