import Foundation

enum PatternNudgeRules {
    struct StaleItemAlert: Equatable {
        let title: String
        let domain: LifeDomain
        let consecutiveDays: Int
    }

    struct DomainNudge: Equatable {
        let domain: LifeDomain
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
        let trainingHasStandaloneActivity = hasTrainingActivity(snapshot?.trainingConsistency)
        let candidate = balance.neglectedDomains.first { domain in
            switch domain {
            case .writing:
                // Writing has its own surface (Write tab capture inbox) that
                // doesn't flow through Focus. The nudge would misfire as
                // "Write hasn't shown up in Focus lately" even when the user
                // is actively capturing. Suppress unconditionally.
                return false
            case .training:
                // Training sessions are tracked outside Focus. If any sessions
                // exist in the snapshot window, the nudge would misfire — the
                // user is engaged with Train, just not through Focus Three.
                return !trainingHasStandaloneActivity
            case .career, .home:
                return true
            }
        }
        guard let first = candidate else { return nil }
        return DomainNudge(domain: first)
    }

    private static func hasTrainingActivity(_ pattern: TrainingConsistencyPattern?) -> Bool {
        guard let pattern else { return false }
        let total = pattern.sessionsPlanned
            + pattern.sessionsCompleted
            + pattern.sessionsModified
            + pattern.sessionsSkipped
        return total > 0
    }
}
