import Foundation

enum PatternNudgeRules {
    struct StaleItemAlert: Equatable {
        let title: String
        let domain: LifeDomain
        let consecutiveDays: Int
    }

    struct DomainNudge: Equatable {
        let domain: LifeDomain
        let message: String
    }

    static func staleItemAlerts(from snapshot: PatternSnapshot?) -> [StaleItemAlert] {
        guard let carryForward = snapshot?.carryForward else { return [] }
        return carryForward.stalledItems.map { item in
            StaleItemAlert(
                title: item.title,
                domain: item.domain,
                consecutiveDays: item.consecutiveDays
            )
        }
    }

    static func domainNudge(from snapshot: PatternSnapshot?) -> DomainNudge? {
        guard let balance = snapshot?.domainBalance else { return nil }
        guard let first = balance.neglectedDomains.first(where: { $0 != .writing }) else { return nil }
        return DomainNudge(
            domain: first,
            message: "\(first.title) has been quiet lately."
        )
    }
}
