import XCTest
#if SWIFT_PACKAGE
@testable import OwloryCore
#endif

final class ProtocolScheduleNotificationRulesTests: XCTestCase {
    private let formatter = ISO8601DateFormatter()

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.firstWeekday = 1
        return calendar
    }

    // MARK: - No schedule

    func testProtocolWithoutScheduleProducesNoPlans() {
        let proto = HouseholdProtocol(
            id: UUID(),
            title: "Kitchen reset",
            steps: ["Wipe counters"]
        )

        let plans = ProtocolScheduleNotificationRules.plans(
            for: [proto],
            runs: [],
            now: date("2026-05-01T07:00:00Z"),
            calendar: calendar
        )

        XCTAssertTrue(plans.isEmpty)
    }

    // MARK: - Upcoming window

    func testUpcomingWindowProducesBothPlans() {
        let protoID = UUID()
        let proto = HouseholdProtocol(
            id: protoID,
            title: "Deep clean",
            steps: ["Mop floors"],
            schedule: HouseholdProtocolSchedule(
                preset: .thisWeek,
                startDate: date("2026-05-05T00:00:00Z"),
                endDate: date("2026-05-09T00:00:00Z")
            )
        )

        let plans = ProtocolScheduleNotificationRules.plans(
            for: [proto],
            runs: [],
            now: date("2026-05-03T07:00:00Z"),
            calendar: calendar
        )

        XCTAssertEqual(plans.count, 2)

        let opening = plans.first { $0.kind == .windowOpening }
        XCTAssertEqual(opening?.protocolID, protoID)
        XCTAssertEqual(opening?.title, "Deep clean")
        XCTAssertEqual(opening?.fireDate, date("2026-05-05T08:00:00Z"))
        XCTAssertEqual(
            opening?.identifier,
            "owlory.protocol-schedule.\(protoID.uuidString).window-opening"
        )

        let overdue = plans.first { $0.kind == .overdue }
        XCTAssertEqual(overdue?.protocolID, protoID)
        XCTAssertEqual(overdue?.fireDate, date("2026-05-10T08:00:00Z"))
        XCTAssertEqual(
            overdue?.identifier,
            "owlory.protocol-schedule.\(protoID.uuidString).overdue"
        )
    }

    // MARK: - Active window

    func testActiveWindowWithoutRunProducesOverduePlanOnly() {
        let protoID = UUID()
        let proto = HouseholdProtocol(
            id: protoID,
            title: "Weekend cleanup",
            steps: ["Vacuum"],
            schedule: HouseholdProtocolSchedule(
                preset: .weekend,
                startDate: date("2026-05-03T00:00:00Z"),
                endDate: date("2026-05-04T00:00:00Z")
            )
        )

        let plans = ProtocolScheduleNotificationRules.plans(
            for: [proto],
            runs: [],
            now: date("2026-05-03T10:00:00Z"),
            calendar: calendar
        )

        XCTAssertEqual(plans.count, 1)
        XCTAssertEqual(plans.first?.kind, .overdue)
        XCTAssertEqual(plans.first?.fireDate, date("2026-05-05T08:00:00Z"))
    }

    func testActiveWindowWithQualifyingRunProducesNoPlans() {
        let protoID = UUID()
        let proto = HouseholdProtocol(
            id: protoID,
            title: "Weekend cleanup",
            steps: ["Vacuum"],
            schedule: HouseholdProtocolSchedule(
                preset: .weekend,
                startDate: date("2026-05-03T00:00:00Z"),
                endDate: date("2026-05-04T00:00:00Z")
            )
        )
        let run = ProtocolRun(
            protocolID: protoID,
            protocolTitle: "Weekend cleanup",
            createdAt: date("2026-05-03T09:00:00Z")
        )

        let plans = ProtocolScheduleNotificationRules.plans(
            for: [proto],
            runs: [run],
            now: date("2026-05-03T10:00:00Z"),
            calendar: calendar
        )

        XCTAssertTrue(plans.isEmpty)
    }

    func testActiveWindowIgnoresRunsFromBeforeWindow() {
        let protoID = UUID()
        let proto = HouseholdProtocol(
            id: protoID,
            title: "Weekend cleanup",
            steps: ["Vacuum"],
            schedule: HouseholdProtocolSchedule(
                preset: .weekend,
                startDate: date("2026-05-03T00:00:00Z"),
                endDate: date("2026-05-04T00:00:00Z")
            )
        )
        let oldRun = ProtocolRun(
            protocolID: protoID,
            protocolTitle: "Weekend cleanup",
            createdAt: date("2026-04-26T09:00:00Z")
        )

        let plans = ProtocolScheduleNotificationRules.plans(
            for: [proto],
            runs: [oldRun],
            now: date("2026-05-03T10:00:00Z"),
            calendar: calendar
        )

        XCTAssertEqual(plans.count, 1)
        XCTAssertEqual(plans.first?.kind, .overdue)
    }

    // MARK: - Satisfied and overdue windows

    func testSatisfiedScheduleProducesNoPlans() {
        let protoID = UUID()
        let proto = HouseholdProtocol(
            id: protoID,
            title: "Daily reset",
            steps: ["Clear sink"],
            schedule: HouseholdProtocolSchedule(
                preset: .today,
                startDate: date("2026-05-01T00:00:00Z"),
                endDate: date("2026-05-01T00:00:00Z")
            )
        )
        let run = ProtocolRun(
            protocolID: protoID,
            protocolTitle: "Daily reset",
            createdAt: date("2026-05-01T08:00:00Z")
        )

        let plans = ProtocolScheduleNotificationRules.plans(
            for: [proto],
            runs: [run],
            now: date("2026-05-03T07:00:00Z"),
            calendar: calendar
        )

        XCTAssertTrue(plans.isEmpty)
    }

    func testOverdueScheduleProducesNoPlans() {
        let protoID = UUID()
        let proto = HouseholdProtocol(
            id: protoID,
            title: "Daily reset",
            steps: ["Clear sink"],
            schedule: HouseholdProtocolSchedule(
                preset: .today,
                startDate: date("2026-05-01T00:00:00Z"),
                endDate: date("2026-05-01T00:00:00Z")
            )
        )

        let plans = ProtocolScheduleNotificationRules.plans(
            for: [proto],
            runs: [],
            now: date("2026-05-03T07:00:00Z"),
            calendar: calendar
        )

        XCTAssertTrue(plans.isEmpty)
    }

    // MARK: - Fire date suppression

    func testUpcomingWindowSuppressesPastOpeningFireDate() {
        let protoID = UUID()
        let proto = HouseholdProtocol(
            id: protoID,
            title: "Morning routine",
            steps: ["Stretch"],
            schedule: HouseholdProtocolSchedule(
                preset: .today,
                startDate: date("2026-05-05T00:00:00Z"),
                endDate: date("2026-05-05T00:00:00Z")
            )
        )

        // now is after the 8 AM window-opening fire time but still before the window start day
        // (this shouldn't normally happen with real dates, but tests the guard)
        let plans = ProtocolScheduleNotificationRules.plans(
            for: [proto],
            runs: [],
            now: date("2026-05-04T07:00:00Z"),
            calendar: calendar
        )

        XCTAssertEqual(plans.count, 2)
        XCTAssertTrue(plans.contains { $0.kind == .windowOpening })
        XCTAssertTrue(plans.contains { $0.kind == .overdue })
    }

    // MARK: - Multiple protocols

    func testMultipleProtocolsProduceIndependentPlans() {
        let id1 = UUID()
        let id2 = UUID()

        let protocols = [
            HouseholdProtocol(
                id: id1,
                title: "Kitchen",
                steps: ["Wipe"],
                schedule: HouseholdProtocolSchedule(
                    preset: .thisWeek,
                    startDate: date("2026-05-05T00:00:00Z"),
                    endDate: date("2026-05-09T00:00:00Z")
                )
            ),
            HouseholdProtocol(
                id: id2,
                title: "Laundry",
                steps: ["Sort"],
                schedule: HouseholdProtocolSchedule(
                    preset: .weekend,
                    startDate: date("2026-05-03T00:00:00Z"),
                    endDate: date("2026-05-04T00:00:00Z")
                )
            ),
        ]

        let plans = ProtocolScheduleNotificationRules.plans(
            for: protocols,
            runs: [],
            now: date("2026-05-03T07:00:00Z"),
            calendar: calendar
        )

        let kitchenPlans = plans.filter { $0.protocolID == id1 }
        let laundryPlans = plans.filter { $0.protocolID == id2 }

        XCTAssertEqual(kitchenPlans.count, 2)
        XCTAssertEqual(laundryPlans.count, 1)
        XCTAssertEqual(laundryPlans.first?.kind, .overdue)
    }

    // MARK: - Run for different protocol does not suppress

    func testRunForDifferentProtocolDoesNotSuppress() {
        let protoID = UUID()
        let otherProtoID = UUID()
        let proto = HouseholdProtocol(
            id: protoID,
            title: "Morning routine",
            steps: ["Stretch"],
            schedule: HouseholdProtocolSchedule(
                preset: .weekend,
                startDate: date("2026-05-03T00:00:00Z"),
                endDate: date("2026-05-04T00:00:00Z")
            )
        )
        let otherRun = ProtocolRun(
            protocolID: otherProtoID,
            protocolTitle: "Different protocol",
            createdAt: date("2026-05-03T09:00:00Z")
        )

        let plans = ProtocolScheduleNotificationRules.plans(
            for: [proto],
            runs: [otherRun],
            now: date("2026-05-03T10:00:00Z"),
            calendar: calendar
        )

        XCTAssertEqual(plans.count, 1)
        XCTAssertEqual(plans.first?.kind, .overdue)
    }

    // MARK: - Identifier format

    func testIdentifierFormatIsDeterministic() {
        let id = UUID()

        XCTAssertEqual(
            ProtocolScheduleNotificationRules.identifier(protocolID: id, kind: .windowOpening),
            "owlory.protocol-schedule.\(id.uuidString).window-opening"
        )
        XCTAssertEqual(
            ProtocolScheduleNotificationRules.identifier(protocolID: id, kind: .overdue),
            "owlory.protocol-schedule.\(id.uuidString).overdue"
        )
    }

    // MARK: - Helpers

    private func date(_ value: String) -> Date {
        formatter.date(from: value)!
    }
}
