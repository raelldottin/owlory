import Foundation

enum RecurrenceRules {
    enum HomeTaskResetRejection: Equatable {
        case notRecurring
        case unresolved
        case missingSchedule
        case notDue
    }

    enum TrainingSessionSpawnRejection: Equatable {
        case notRecurring
        case alreadyPlanned
        case missingSchedule
        case notDue
        case alreadyExistsToday
    }

    enum TrainingSessionAutoSkipRejection: Equatable {
        case notPlanned
        case notPastDay
    }

    struct HomeTaskResetDecision: Equatable {
        let resetTask: HomeTask?
        let rejection: HomeTaskResetRejection?

        var shouldReset: Bool { resetTask != nil }
    }

    struct TrainingSessionSpawnDecision: Equatable {
        let spawnedSession: TrainingSession?
        let rejection: TrainingSessionSpawnRejection?

        var shouldSpawn: Bool { spawnedSession != nil }
    }

    struct TrainingSessionAutoSkipDecision: Equatable {
        let skippedSession: TrainingSession?
        let rejection: TrainingSessionAutoSkipRejection?

        var shouldSkip: Bool { skippedSession != nil }
    }

    static func dueDay(
        after resolvedAt: Date,
        intervalDays: Int,
        calendar: Calendar = .current
    ) -> Date? {
        let resolvedDay = calendar.startOfDay(for: resolvedAt)
        return calendar.date(byAdding: .day, value: intervalDays, to: resolvedDay)
    }

    static func isDue(
        resolvedAt: Date?,
        intervalDays: Int?,
        asOf now: Date,
        calendar: Calendar = .current
    ) -> Bool {
        guard let resolvedAt, let intervalDays else { return false }
        guard let dueDay = dueDay(after: resolvedAt, intervalDays: intervalDays, calendar: calendar) else {
            return false
        }
        return calendar.startOfDay(for: now) >= dueDay
    }

    static func resetHomeTaskIfDue(
        _ task: HomeTask,
        asOf now: Date,
        calendar: Calendar = .current
    ) -> HomeTask? {
        homeTaskResetDecision(task, asOf: now, calendar: calendar).resetTask
    }

    static func homeTaskResetDecision(
        _ task: HomeTask,
        asOf now: Date,
        calendar: Calendar = .current
    ) -> HomeTaskResetDecision {
        guard task.isRecurring else {
            return HomeTaskResetDecision(resetTask: nil, rejection: .notRecurring)
        }
        guard task.isCompleted || task.isSkipped else {
            return HomeTaskResetDecision(resetTask: nil, rejection: .unresolved)
        }

        let resolvedAt = task.isCompleted ? task.lastCompleted : task.lastSkipped
        guard let resolvedAt, let intervalDays = task.recurrenceIntervalDays else {
            return HomeTaskResetDecision(resetTask: nil, rejection: .missingSchedule)
        }
        guard isDue(
            resolvedAt: resolvedAt,
            intervalDays: intervalDays,
            asOf: now,
            calendar: calendar
        ) else {
            return HomeTaskResetDecision(resetTask: nil, rejection: .notDue)
        }

        var reset = task
        reset.isCompleted = false
        reset.isSkipped = false
        return HomeTaskResetDecision(resetTask: reset, rejection: nil)
    }

    static func trainingSessionToSpawnIfDue(
        from session: TrainingSession,
        existingSessions: [TrainingSession],
        asOf now: Date,
        calendar: Calendar = .current
    ) -> TrainingSession? {
        trainingSessionSpawnDecision(
            from: session,
            existingSessions: existingSessions,
            asOf: now,
            calendar: calendar
        ).spawnedSession
    }

    static func trainingSessionSpawnDecision(
        from session: TrainingSession,
        existingSessions: [TrainingSession],
        asOf now: Date,
        calendar: Calendar = .current
    ) -> TrainingSessionSpawnDecision {
        guard session.isRecurring else {
            return TrainingSessionSpawnDecision(spawnedSession: nil, rejection: .notRecurring)
        }
        guard session.status != .planned else {
            return TrainingSessionSpawnDecision(spawnedSession: nil, rejection: .alreadyPlanned)
        }
        guard let intervalDays = session.recurrenceIntervalDays else {
            return TrainingSessionSpawnDecision(spawnedSession: nil, rejection: .missingSchedule)
        }
        guard isDue(
            resolvedAt: session.date,
            intervalDays: intervalDays,
            asOf: now,
            calendar: calendar
        ) else {
            return TrainingSessionSpawnDecision(spawnedSession: nil, rejection: .notDue)
        }

        let todayStart = calendar.startOfDay(for: now)
        let alreadyExists = existingSessions.contains { other in
            other.plannedActivity == session.plannedActivity &&
                calendar.startOfDay(for: other.date) == todayStart
        }
        guard !alreadyExists else {
            return TrainingSessionSpawnDecision(spawnedSession: nil, rejection: .alreadyExistsToday)
        }

        let spawned = TrainingSession(
            date: now,
            plannedActivity: session.plannedActivity,
            isRecurring: true,
            recurrenceIntervalDays: session.recurrenceIntervalDays
        )
        return TrainingSessionSpawnDecision(spawnedSession: spawned, rejection: nil)
    }

    static func autoSkipTrainingSessionIfPastDay(
        _ session: TrainingSession,
        asOf now: Date,
        calendar: Calendar = .current
    ) -> TrainingSession? {
        trainingSessionAutoSkipDecision(
            session,
            asOf: now,
            calendar: calendar
        ).skippedSession
    }

    static func trainingSessionAutoSkipDecision(
        _ session: TrainingSession,
        asOf now: Date,
        calendar: Calendar = .current
    ) -> TrainingSessionAutoSkipDecision {
        guard session.status == .planned else {
            return TrainingSessionAutoSkipDecision(
                skippedSession: nil,
                rejection: .notPlanned
            )
        }

        let sessionDay = calendar.startOfDay(for: session.date)
        let currentDay = calendar.startOfDay(for: now)
        guard sessionDay < currentDay else {
            return TrainingSessionAutoSkipDecision(
                skippedSession: nil,
                rejection: .notPastDay
            )
        }

        var skipped = session
        skipped.status = .skipped
        return TrainingSessionAutoSkipDecision(
            skippedSession: skipped,
            rejection: nil
        )
    }
}
