import Foundation

struct RecurringRolloverTrace: Equatable {
    enum Scope: String {
        case trainingSessions = "training.sessions"
        case homeTasks = "home.tasks"
    }

    let scope: Scope
    let evaluatedCount: Int
    let createdCount: Int
    let resetCount: Int
    let updatedCount: Int
    let notRecurringCount: Int
    let notReadyCount: Int
    let missingScheduleCount: Int
    let notDueCount: Int
    let dedupedCount: Int
    let changedItemIDs: [UUID]

    var changedCount: Int { createdCount + resetCount + updatedCount }
    var skippedCount: Int {
        notRecurringCount +
            notReadyCount +
            missingScheduleCount +
            notDueCount +
            dedupedCount
    }

    var telemetryMessage: String {
        [
            "recurrence.rollover",
            "scope=\(scope.rawValue)",
            "evaluated=\(evaluatedCount)",
            "changed=\(changedCount)",
            "created=\(createdCount)",
            "reset=\(resetCount)",
            "updated=\(updatedCount)",
            "skipped=\(skippedCount)",
            "notRecurring=\(notRecurringCount)",
            "notReady=\(notReadyCount)",
            "missingSchedule=\(missingScheduleCount)",
            "notDue=\(notDueCount)",
            "deduped=\(dedupedCount)",
        ].joined(separator: " ")
    }
}

enum RecurringRolloverPlanner {
    struct TrainingResult: Equatable {
        let sessions: [TrainingSession]
        let trace: RecurringRolloverTrace

        var didChange: Bool { trace.changedCount > 0 }
    }

    struct HomeTaskResult: Equatable {
        let tasks: [HomeTask]
        let trace: RecurringRolloverTrace

        var didChange: Bool { trace.changedCount > 0 }
    }

    static func rolloverTrainingSessions(
        _ sessions: [TrainingSession],
        asOf now: Date,
        calendar: Calendar = .current
    ) -> TrainingResult {
        var output = sessions
        var createdIDs: [UUID] = []
        var updatedIDs: [UUID] = []
        var notRecurringCount = 0
        var notReadyCount = 0
        var missingScheduleCount = 0
        var notDueCount = 0
        var dedupedCount = 0

        for index in output.indices {
            let decision = RecurrenceRules.trainingSessionAutoSkipDecision(
                output[index],
                asOf: now,
                calendar: calendar
            )
            guard let skippedSession = decision.skippedSession else { continue }
            output[index] = skippedSession
            updatedIDs.append(skippedSession.id)
        }

        for session in output {
            let decision = RecurrenceRules.trainingSessionSpawnDecision(
                from: session,
                existingSessions: output,
                asOf: now,
                calendar: calendar
            )

            if let spawned = decision.spawnedSession {
                output.append(spawned)
                createdIDs.append(spawned.id)
                continue
            }

            switch decision.rejection {
            case .notRecurring:
                notRecurringCount += 1
            case .alreadyPlanned:
                notReadyCount += 1
            case .missingSchedule:
                missingScheduleCount += 1
            case .notDue:
                notDueCount += 1
            case .alreadyExistsToday:
                dedupedCount += 1
            case nil:
                break
            }
        }

        return TrainingResult(
            sessions: output,
            trace: RecurringRolloverTrace(
                scope: .trainingSessions,
                evaluatedCount: sessions.count,
                createdCount: createdIDs.count,
                resetCount: 0,
                updatedCount: updatedIDs.count,
                notRecurringCount: notRecurringCount,
                notReadyCount: notReadyCount,
                missingScheduleCount: missingScheduleCount,
                notDueCount: notDueCount,
                dedupedCount: dedupedCount,
                changedItemIDs: updatedIDs + createdIDs
            )
        )
    }

    static func rolloverHomeTasks(
        _ tasks: [HomeTask],
        asOf now: Date,
        calendar: Calendar = .current
    ) -> HomeTaskResult {
        var output = tasks
        var resetIDs: [UUID] = []
        var notRecurringCount = 0
        var notReadyCount = 0
        var missingScheduleCount = 0
        var notDueCount = 0

        for index in output.indices {
            let decision = RecurrenceRules.homeTaskResetDecision(
                output[index],
                asOf: now,
                calendar: calendar
            )

            if let resetTask = decision.resetTask {
                output[index] = resetTask
                resetIDs.append(resetTask.id)
                continue
            }

            switch decision.rejection {
            case .notRecurring:
                notRecurringCount += 1
            case .unresolved:
                notReadyCount += 1
            case .missingSchedule:
                missingScheduleCount += 1
            case .notDue:
                notDueCount += 1
            case nil:
                break
            }
        }

        return HomeTaskResult(
            tasks: output,
            trace: RecurringRolloverTrace(
                scope: .homeTasks,
                evaluatedCount: tasks.count,
                createdCount: 0,
                resetCount: resetIDs.count,
                updatedCount: 0,
                notRecurringCount: notRecurringCount,
                notReadyCount: notReadyCount,
                missingScheduleCount: missingScheduleCount,
                notDueCount: notDueCount,
                dedupedCount: 0,
                changedItemIDs: resetIDs
            )
        )
    }
}
