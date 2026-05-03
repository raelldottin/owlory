import Foundation

enum ProtocolScheduleNotificationRules {
    enum Kind: String, Equatable, CaseIterable {
        case windowOpening = "window-opening"
        case overdue = "overdue"
    }

    struct Plan: Equatable {
        let protocolID: UUID
        let title: String
        let kind: Kind
        let fireDate: Date
        let identifier: String
    }

    static let windowOpeningHour = 8
    static let overdueHour = 8

    static func identifier(protocolID: UUID, kind: Kind) -> String {
        "owlory.protocol-schedule.\(protocolID.uuidString).\(kind.rawValue)"
    }

    static func plans(
        for protocols: [HouseholdProtocol],
        runs: [ProtocolRun],
        now: Date,
        calendar: Calendar
    ) -> [Plan] {
        var result: [Plan] = []

        for proto in protocols {
            guard let schedule = proto.schedule else { continue }

            let protocolRuns = runs.filter { $0.protocolID == proto.id }
            let status = ProtocolScheduleRules.scheduleStatus(
                for: schedule,
                runs: protocolRuns,
                now: now,
                calendar: calendar
            )

            let windowStart = calendar.startOfDay(for: schedule.startDate)
            let hasQualifyingRun = protocolRuns.contains { run in
                calendar.startOfDay(for: run.createdAt) >= windowStart
            }

            switch status {
            case .satisfied, .overdue:
                continue
            case .upcoming:
                if let openingDate = fireDate(
                    hour: windowOpeningHour,
                    on: schedule.startDate,
                    calendar: calendar
                ), openingDate > now {
                    result.append(Plan(
                        protocolID: proto.id,
                        title: proto.title,
                        kind: .windowOpening,
                        fireDate: openingDate,
                        identifier: identifier(protocolID: proto.id, kind: .windowOpening)
                    ))
                }
                if let overdueDate = overdueFireDate(
                    after: schedule.endDate,
                    calendar: calendar
                ), overdueDate > now {
                    result.append(Plan(
                        protocolID: proto.id,
                        title: proto.title,
                        kind: .overdue,
                        fireDate: overdueDate,
                        identifier: identifier(protocolID: proto.id, kind: .overdue)
                    ))
                }
            case .active:
                guard !hasQualifyingRun else { continue }
                if let overdueDate = overdueFireDate(
                    after: schedule.endDate,
                    calendar: calendar
                ), overdueDate > now {
                    result.append(Plan(
                        protocolID: proto.id,
                        title: proto.title,
                        kind: .overdue,
                        fireDate: overdueDate,
                        identifier: identifier(protocolID: proto.id, kind: .overdue)
                    ))
                }
            }
        }

        return result
    }

    private static func fireDate(
        hour: Int,
        on date: Date,
        calendar: Calendar
    ) -> Date? {
        let startOfDay = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .hour, value: hour, to: startOfDay)
    }

    private static func overdueFireDate(
        after endDate: Date,
        calendar: Calendar
    ) -> Date? {
        guard let nextDay = calendar.date(
            byAdding: .day,
            value: 1,
            to: calendar.startOfDay(for: endDate)
        ) else {
            return nil
        }
        return calendar.date(byAdding: .hour, value: overdueHour, to: nextDay)
    }
}
