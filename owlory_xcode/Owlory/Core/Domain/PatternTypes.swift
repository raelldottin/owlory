import Foundation

struct CompletionRatePattern: Codable, Equatable {
    let doneCount: Int
    let totalCount: Int
    let deferredCount: Int
    let droppedCount: Int

    var rate: Double {
        guard totalCount > 0 else { return 0 }
        return Double(doneCount) / Double(totalCount)
    }

    var plannedButNotDoneCount: Int {
        totalCount - doneCount
    }
}

struct CarryForwardPattern: Codable, Equatable {
    let averageCarriedPerDay: Double
    let stalledItems: [StalledItem]

    struct StalledItem: Codable, Equatable {
        let title: String
        let domain: LifeDomain
        let consecutiveDays: Int
    }
}

struct DomainBalancePattern: Codable, Equatable {
    let domainShares: [LifeDomain: Double]
    let neglectedDomains: [LifeDomain]
}

struct ReadinessOutcomePattern: Codable, Equatable {
    let lowReadinessAvgCompletion: Double
    let highReadinessAvgCompletion: Double
    let overplanningOnLowDays: Bool
    let sampleCount: Int
}

struct WritingVelocityPattern: Codable, Equatable {
    let stageDistribution: [WritingStage: Int]
    let bottleneckStage: WritingStage?
    let captureToSourceAvgDays: Double?
}

struct TrainingConsistencyPattern: Codable, Equatable {
    let sessionsPlanned: Int
    let sessionsCompleted: Int
    let sessionsModified: Int
    let sessionsSkipped: Int

    var completionRate: Double {
        let total = sessionsPlanned + sessionsCompleted + sessionsModified + sessionsSkipped
        guard total > 0 else { return 0 }
        return Double(sessionsCompleted + sessionsModified) / Double(total)
    }
}

struct PatternSnapshot: Codable, Equatable {
    let generatedAt: Date
    let windowEnd: Date
    let windowDays: Int
    let completionRate: CompletionRatePattern
    let carryForward: CarryForwardPattern?
    let domainBalance: DomainBalancePattern?
    let readinessOutcome: ReadinessOutcomePattern?
    let writingVelocity: WritingVelocityPattern?
    let trainingConsistency: TrainingConsistencyPattern?

    init(
        generatedAt: Date,
        windowEnd: Date,
        windowDays: Int,
        completionRate: CompletionRatePattern,
        carryForward: CarryForwardPattern? = nil,
        domainBalance: DomainBalancePattern? = nil,
        readinessOutcome: ReadinessOutcomePattern? = nil,
        writingVelocity: WritingVelocityPattern? = nil,
        trainingConsistency: TrainingConsistencyPattern? = nil
    ) {
        self.generatedAt = generatedAt
        self.windowEnd = windowEnd
        self.windowDays = windowDays
        self.completionRate = completionRate
        self.carryForward = carryForward
        self.domainBalance = domainBalance
        self.readinessOutcome = readinessOutcome
        self.writingVelocity = writingVelocity
        self.trainingConsistency = trainingConsistency
    }
}
