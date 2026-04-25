import Foundation

struct ContinuePipelineTrace: Equatable {
    struct SourceCount: Equatable {
        let step: TodayContinueSourceComposer.Step
        let count: Int
    }

    struct AdmissionSummary: Equatable {
        let admittedCount: Int
        let emptyTitleRejectedCount: Int
        let totalLimitRejectedCount: Int
        let domainLimitRejectedCount: Int

        var rejectedCount: Int {
            emptyTitleRejectedCount +
                totalLimitRejectedCount +
                domainLimitRejectedCount
        }

        var cappedOutCount: Int {
            totalLimitRejectedCount + domainLimitRejectedCount
        }
    }

    let sourceCounts: [SourceCount]
    let inputCandidateCount: Int
    let admission: AdmissionSummary
    let urgencyScoredItemIDs: [String]
    let preRankingItemIDs: [String]
    let rankedItemIDs: [String]
    let finalItemCount: Int

    var urgencyScoredItemCount: Int { urgencyScoredItemIDs.count }
    var rankingChanged: Bool { preRankingItemIDs != rankedItemIDs }

    var telemetryMessage: String {
        [
            "continue.pipeline",
            "sourceCounts=\(sourceCountsTelemetryValue)",
            "candidates=\(inputCandidateCount)",
            "admitted=\(admission.admittedCount)",
            "rejected=\(admission.rejectedCount)",
            "emptyTitleRejected=\(admission.emptyTitleRejectedCount)",
            "totalCapRejected=\(admission.totalLimitRejectedCount)",
            "domainCapRejected=\(admission.domainLimitRejectedCount)",
            "urgencyScored=\(urgencyScoredItemCount)",
            "rankingChanged=\(rankingChanged)",
            "emitted=\(finalItemCount)",
        ].joined(separator: " ")
    }

    static func make(
        sourceCandidates: [TodayContinueSourceComposer.Candidate],
        assemblyTrace: TodayContinueItemAssembler.Trace,
        preRankingItems: [TodayContinuationRules.ContinueItem],
        rankedItems: [TodayContinuationRules.ContinueItem]
    ) -> ContinuePipelineTrace {
        ContinuePipelineTrace(
            sourceCounts: sourceCounts(for: sourceCandidates),
            inputCandidateCount: sourceCandidates.count,
            admission: assemblyTrace.admission,
            urgencyScoredItemIDs: assemblyTrace.urgencyScoredItemIDs,
            preRankingItemIDs: preRankingItems.map(\.id),
            rankedItemIDs: rankedItems.map(\.id),
            finalItemCount: rankedItems.count
        )
    }

    private static func sourceCounts(
        for candidates: [TodayContinueSourceComposer.Candidate]
    ) -> [SourceCount] {
        TodayContinueSourceComposer.sourceOrder.map { step in
            SourceCount(
                step: step,
                count: candidates.filter { $0.step == step }.count
            )
        }
    }

    private var sourceCountsTelemetryValue: String {
        sourceCounts
            .map { "\($0.step.rawValue):\($0.count)" }
            .joined(separator: ",")
    }
}
