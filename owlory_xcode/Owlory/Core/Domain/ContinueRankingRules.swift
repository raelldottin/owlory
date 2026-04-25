import Foundation

enum ContinuePriority: Int, Comparable {
    case dueToday = 0
    case carriedForward = 1
    case active = 2
    case inProgress = 3

    static func < (lhs: ContinuePriority, rhs: ContinuePriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct ContinueCandidate: Equatable {
    let id: String
    let priority: ContinuePriority
    let urgencyScore: Double?
    let originalIndex: Int
}

enum ContinueRankingRules {
    struct SortKey: Comparable, Equatable {
        let urgencyScore: Double
        let priority: ContinuePriority
        let originalIndex: Int
        let id: String

        static func < (lhs: SortKey, rhs: SortKey) -> Bool {
            if lhs.urgencyScore != rhs.urgencyScore {
                return lhs.urgencyScore > rhs.urgencyScore
            }
            if lhs.priority != rhs.priority {
                return lhs.priority < rhs.priority
            }
            if lhs.originalIndex != rhs.originalIndex {
                return lhs.originalIndex < rhs.originalIndex
            }
            return lhs.id < rhs.id
        }
    }

    static func rank(_ candidates: [ContinueCandidate]) -> [ContinueCandidate] {
        candidates.sorted {
            sortKey(for: $0) < sortKey(for: $1)
        }
    }

    static func sortKey(for candidate: ContinueCandidate) -> SortKey {
        SortKey(
            urgencyScore: normalizedUrgency(candidate.urgencyScore),
            priority: candidate.priority,
            originalIndex: candidate.originalIndex,
            id: candidate.id
        )
    }

    private static func normalizedUrgency(_ urgencyScore: Double?) -> Double {
        guard let urgencyScore, urgencyScore.isFinite else { return -Double.infinity }
        return urgencyScore
    }
}
