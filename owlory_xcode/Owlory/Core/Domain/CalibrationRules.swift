import Foundation

enum CalibrationRules {

    typealias StaleItemAlert = PatternNudgeRules.StaleItemAlert
    typealias DomainNudge = PatternNudgeRules.DomainNudge

    struct WritingPipelineNudge: Equatable {
        enum Kind: Equatable {
            case captureBacklog
        }

        let kind: Kind
        let captureCount: Int
        let bottleneckStage: WritingStage?
    }

    struct TrainingConsistencySummary: Equatable {
        enum Band: Equatable {
            case strong
            case solid
            case low
        }

        let band: Band
        let completionRate: Double
        let completionPercent: Int
    }

    struct Calibration {
        let enhancedNudge: ReadinessRules.Nudge?
        let completionContext: String?
        let staleItems: [StaleItemAlert]
        let domainNudge: DomainNudge?
        let suggestedFocusLoad: Int
        let writingNudge: WritingPipelineNudge?
        let trainingSummary: TrainingConsistencySummary?
    }

    static func calibrate(
        todayEntry: DailyEntry,
        weeklySnapshot: PatternSnapshot?
    ) -> Calibration {
        let baseNudge = ReadinessRules.nudge(
            energy: todayEntry.energy,
            mood: todayEntry.mood,
            sleepQuality: todayEntry.sleepQuality
        )

        let context = completionContext(from: weeklySnapshot)
        let stale = PatternNudgeRules.staleItemAlerts(from: weeklySnapshot)
        let domain = PatternNudgeRules.domainNudge(from: weeklySnapshot)
        let focusLoad = suggestedFocusLoad(baseNudge: baseNudge, snapshot: weeklySnapshot)
        let writing = writingPipelineNudge(from: weeklySnapshot)
        let training = trainingConsistencySummary(from: weeklySnapshot)

        return Calibration(enhancedNudge: baseNudge, completionContext: context, staleItems: stale, domainNudge: domain, suggestedFocusLoad: focusLoad, writingNudge: writing, trainingSummary: training)
    }

    private static func completionContext(from snapshot: PatternSnapshot?) -> String? {
        guard let snapshot = snapshot else { return nil }
        let rate = snapshot.completionRate
        guard rate.totalCount >= 3 else { return nil }

        let pct = Int(rate.rate * 100)
        return "This week you completed \(rate.doneCount) of \(rate.totalCount) planned items (\(pct)%)."
    }

    private static func suggestedFocusLoad(baseNudge: ReadinessRules.Nudge?, snapshot: PatternSnapshot?) -> Int {
        let baseSuggestion = baseNudge?.suggestedMaxPriorities ?? 3

        guard let ro = snapshot?.readinessOutcome, ro.sampleCount >= 3 else {
            return baseSuggestion
        }

        // If overplanning on low days detected, reduce by 1 on low-readiness days
        if ro.overplanningOnLowDays && baseSuggestion <= 2 {
            return max(1, baseSuggestion - 1)
        }

        // If high readiness days have high completion, allow full load
        if ro.highReadinessAvgCompletion >= 0.7 && baseSuggestion >= 3 {
            return 3
        }

        return baseSuggestion
    }

    private static func writingPipelineNudge(from snapshot: PatternSnapshot?) -> WritingPipelineNudge? {
        guard let velocity = snapshot?.writingVelocity else { return nil }
        let captureCount = velocity.stageDistribution[.capture] ?? 0
        guard captureCount > 10 else { return nil }

        // Check if pipeline is stalled — bottleneck at capture means nothing advancing
        let advancedCount = velocity.stageDistribution.filter { $0.key.rawValue >= WritingStage.source.rawValue }.values.reduce(0, +)
        guard advancedCount == 0 || velocity.bottleneckStage == .capture else { return nil }

        return WritingPipelineNudge(kind: .captureBacklog, captureCount: captureCount, bottleneckStage: velocity.bottleneckStage)
    }

    private static func trainingConsistencySummary(from snapshot: PatternSnapshot?) -> TrainingConsistencySummary? {
        guard let consistency = snapshot?.trainingConsistency else { return nil }
        let total = consistency.sessionsPlanned + consistency.sessionsCompleted + consistency.sessionsModified + consistency.sessionsSkipped
        guard total >= 3 else { return nil }

        let pct = Int(consistency.completionRate * 100)
        let band: TrainingConsistencySummary.Band
        if consistency.completionRate >= 0.8 {
            band = .strong
        } else if consistency.completionRate >= 0.5 {
            band = .solid
        } else {
            band = .low
        }
        return TrainingConsistencySummary(band: band, completionRate: consistency.completionRate, completionPercent: pct)
    }
}
