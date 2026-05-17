import Foundation

enum TodayContinueItemAssembler {
    struct Result: Equatable {
        let items: [TodayContinuationRules.ContinueItem]
        let trace: Trace
    }

    struct Trace: Equatable {
        let inputCandidateCount: Int
        let admission: ContinuePipelineTrace.AdmissionSummary
        let urgencyScoredItemIDs: [String]
    }

    static func assemble(
        candidates: [TodayContinueSourceComposer.Candidate],
        predictions: [String: CompletionTimePredictor.Prediction] = [:],
        now: Date,
        limitPolicy: ContinueCandidateLimitPolicy = .todayDefault
    ) -> [TodayContinuationRules.ContinueItem] {
        assembleWithTrace(
            candidates: candidates,
            predictions: predictions,
            now: now,
            limitPolicy: limitPolicy
        ).items
    }

    static func assembleWithTrace(
        candidates: [TodayContinueSourceComposer.Candidate],
        predictions: [String: CompletionTimePredictor.Prediction] = [:],
        now: Date,
        limitPolicy: ContinueCandidateLimitPolicy = .todayDefault
    ) -> Result {
        var items: [TodayContinuationRules.ContinueItem] = []
        var urgencyScoredItemIDs: [String] = []
        var emptyTitleRejectedCount = 0
        var totalLimitRejectedCount = 0
        var domainLimitRejectedCount = 0
        var sourceIndex = 0

        for candidate in candidates {
            if let rejection = ContinueCandidateRules.admissionRejection(
                title: candidate.title,
                domain: candidate.domain,
                selectedDomains: items.map(\.domain),
                policy: limitPolicy
            ) {
                switch rejection {
                case .emptyTitle:
                    emptyTitleRejectedCount += 1
                case .totalLimitReached:
                    totalLimitRejectedCount += 1
                case .domainLimitReached:
                    domainLimitRejectedCount += 1
                }
                continue
            }

            sourceIndex += 1
            let urgencyScore = urgencyScore(
                for: candidate,
                predictions: predictions,
                now: now
            )
            let item = assembleItem(
                candidate: candidate,
                sourceIndex: sourceIndex,
                urgencyScore: urgencyScore
            )
            if urgencyScore != nil {
                urgencyScoredItemIDs.append(item.id)
            }
            items.append(item)
        }

        return Result(
            items: items,
            trace: Trace(
                inputCandidateCount: candidates.count,
                admission: ContinuePipelineTrace.AdmissionSummary(
                    admittedCount: items.count,
                    emptyTitleRejectedCount: emptyTitleRejectedCount,
                    totalLimitRejectedCount: totalLimitRejectedCount,
                    domainLimitRejectedCount: domainLimitRejectedCount
                ),
                urgencyScoredItemIDs: urgencyScoredItemIDs
            )
        )
    }

    private static func assembleItem(
        candidate: TodayContinueSourceComposer.Candidate,
        sourceIndex: Int,
        urgencyScore: Double?
    ) -> TodayContinuationRules.ContinueItem {
        TodayContinuationRules.ContinueItem(
            id: [
                "\(sourceIndex)",
                candidate.source.key,
                candidate.domain.rawValue,
                candidate.title,
            ].joined(separator: "|"),
            title: candidate.title,
            domain: candidate.domain,
            subtitleKind: candidate.subtitleKind,
            source: candidate.source,
            linkedRecordID: candidate.linkedRecordID,
            origin: candidate.origin,
            staleDayCount: candidate.staleDayCount,
            urgencyScore: urgencyScore,
            priority: candidate.priority,
            originalIndex: sourceIndex
        )
    }

    private static func urgencyScore(
        for candidate: TodayContinueSourceComposer.Candidate,
        predictions: [String: CompletionTimePredictor.Prediction],
        now: Date
    ) -> Double? {
        candidate.predictionKey.flatMap { key in
            predictions[key]?.urgencyScore(now: now, on: now)
        }
    }
}
