import Foundation

enum ProtocolScheduleRules {
    struct Draft: Equatable {
        var preset: ProtocolSchedulePreset?
        var startDate: Date
        var endDate: Date

        init(
            preset: ProtocolSchedulePreset? = nil,
            startDate: Date,
            endDate: Date
        ) {
            self.preset = preset
            self.startDate = startDate
            self.endDate = endDate
        }

        init(referenceDate: Date) {
            self.init(startDate: referenceDate, endDate: referenceDate)
        }

        init(schedule: HouseholdProtocolSchedule?, referenceDate: Date) {
            guard let schedule else {
                self.init(referenceDate: referenceDate)
                return
            }

            self.init(
                preset: schedule.preset,
                startDate: schedule.startDate,
                endDate: schedule.endDate
            )
        }
    }

    enum WindowState: Equatable {
        case upcoming
        case active
        case overdue
    }

    struct Summary: Equatable {
        let preset: ProtocolSchedulePreset
        let startDate: Date
        let endDate: Date
        let state: WindowState
    }

    /// Run-aware classification of a schedule. `.overdue` requires that the
    /// window has passed and no run was started on or after the window's start
    /// day; if a run was started during or after the window, the schedule is
    /// `.satisfied` instead. This is Home schedule state only — it does not
    /// drive Today Continue admission or any run lifecycle.
    enum ScheduleStatus: Equatable {
        case upcoming
        case active
        case satisfied
        case overdue
    }

    struct ScheduleSummary: Equatable {
        let preset: ProtocolSchedulePreset
        let startDate: Date
        let endDate: Date
        let status: ScheduleStatus
    }

    static func draft(
        byApplying preset: ProtocolSchedulePreset?,
        to draft: Draft,
        referenceDate: Date,
        calendar: Calendar
    ) -> Draft {
        guard let preset else {
            return Draft(referenceDate: referenceDate)
        }

        switch preset {
        case .today, .weekend, .thisWeek:
            let range = presetDateRange(for: preset, referenceDate: referenceDate, calendar: calendar)
            return Draft(
                preset: preset,
                startDate: range.start,
                endDate: range.end
            )
        case .custom:
            let range = normalizedDateRange(
                start: draft.startDate,
                end: draft.endDate,
                calendar: calendar
            )
            return Draft(
                preset: .custom,
                startDate: range.start,
                endDate: range.end
            )
        }
    }

    static func schedule(
        from draft: Draft,
        calendar: Calendar
    ) -> HouseholdProtocolSchedule? {
        guard let preset = draft.preset else {
            return nil
        }

        let range = normalizedDateRange(
            start: draft.startDate,
            end: draft.endDate,
            calendar: calendar
        )

        return HouseholdProtocolSchedule(
            preset: preset,
            startDate: range.start,
            endDate: range.end
        )
    }

    static func windowState(
        for schedule: HouseholdProtocolSchedule,
        now: Date,
        calendar: Calendar
    ) -> WindowState {
        let today = calendar.startOfDay(for: now)
        let range = normalizedDateRange(
            start: schedule.startDate,
            end: schedule.endDate,
            calendar: calendar
        )

        if today < range.start {
            return .upcoming
        }
        if today > range.end {
            return .overdue
        }
        return .active
    }

    static func summary(
        for schedule: HouseholdProtocolSchedule?,
        now: Date,
        calendar: Calendar
    ) -> Summary? {
        guard let schedule else {
            return nil
        }

        let state = windowState(for: schedule, now: now, calendar: calendar)
        let range = normalizedDateRange(
            start: schedule.startDate,
            end: schedule.endDate,
            calendar: calendar
        )

        return Summary(
            preset: schedule.preset,
            startDate: range.start,
            endDate: range.end,
            state: state
        )
    }

    /// Run-aware schedule classification. `runs` should already be filtered to
    /// runs of the protocol that owns this schedule; the rule does not look at
    /// `protocolID` here. A run satisfies a passed window if its `createdAt`
    /// day is on or after the window's start day (windows are day-resolution).
    /// Schedules never auto-start, auto-complete, or auto-abandon a run; this
    /// function only classifies.
    static func scheduleStatus(
        for schedule: HouseholdProtocolSchedule,
        runs: [ProtocolRun],
        now: Date,
        calendar: Calendar
    ) -> ScheduleStatus {
        let state = windowState(for: schedule, now: now, calendar: calendar)
        switch state {
        case .upcoming:
            return .upcoming
        case .active:
            return .active
        case .overdue:
            return runStarted(
                onOrAfter: schedule.startDate,
                in: runs,
                calendar: calendar
            ) ? .satisfied : .overdue
        }
    }

    /// Run-aware semantic schedule summary for Home presentation. `.satisfied`
    /// lets the presentation layer reuse the active-window label so the surface
    /// does not nag about a passed window when the user already engaged; only
    /// `.overdue` should render "window passed" copy.
    static func summary(
        for schedule: HouseholdProtocolSchedule?,
        runs: [ProtocolRun],
        now: Date,
        calendar: Calendar
    ) -> ScheduleSummary? {
        guard let schedule else {
            return nil
        }

        let status = scheduleStatus(for: schedule, runs: runs, now: now, calendar: calendar)
        let range = normalizedDateRange(
            start: schedule.startDate,
            end: schedule.endDate,
            calendar: calendar
        )

        return ScheduleSummary(
            preset: schedule.preset,
            startDate: range.start,
            endDate: range.end,
            status: status
        )
    }

    private static func runStarted(
        onOrAfter date: Date,
        in runs: [ProtocolRun],
        calendar: Calendar
    ) -> Bool {
        let threshold = calendar.startOfDay(for: date)
        return runs.contains { run in
            calendar.startOfDay(for: run.createdAt) >= threshold
        }
    }

    private static func presetDateRange(
        for preset: ProtocolSchedulePreset,
        referenceDate: Date,
        calendar: Calendar
    ) -> (start: Date, end: Date) {
        let referenceDay = calendar.startOfDay(for: referenceDate)

        switch preset {
        case .today:
            return (referenceDay, referenceDay)
        case .weekend:
            return weekendDateRange(containingOrFollowing: referenceDay, calendar: calendar)
        case .thisWeek:
            let interval = calendar.dateInterval(of: .weekOfYear, for: referenceDay)
            let intervalEnd = interval?.end ?? referenceDay
            let endDay = calendar.startOfDay(
                for: calendar.date(byAdding: .day, value: -1, to: intervalEnd) ?? referenceDay
            )
            return (referenceDay, max(referenceDay, endDay))
        case .custom:
            return (referenceDay, referenceDay)
        }
    }

    private static func weekendDateRange(
        containingOrFollowing referenceDay: Date,
        calendar: Calendar
    ) -> (start: Date, end: Date) {
        let weekday = calendar.component(.weekday, from: referenceDay)
        let saturday = 7
        let sunday = 1

        let start: Date
        switch weekday {
        case saturday:
            start = referenceDay
        case sunday:
            start = calendar.date(byAdding: .day, value: -1, to: referenceDay) ?? referenceDay
        default:
            start = calendar.date(byAdding: .day, value: saturday - weekday, to: referenceDay) ?? referenceDay
        }

        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        return (calendar.startOfDay(for: start), calendar.startOfDay(for: end))
    }

    private static func normalizedDateRange(
        start: Date,
        end: Date,
        calendar: Calendar
    ) -> (start: Date, end: Date) {
        let startDay = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)
        if startDay <= endDay {
            return (startDay, endDay)
        }
        return (endDay, startDay)
    }

}
