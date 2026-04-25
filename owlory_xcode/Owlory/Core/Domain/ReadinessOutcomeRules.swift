import Foundation

enum ReadinessOutcomeRules {
    enum ReadinessBand: Equatable {
        case missing
        case low
        case middle
        case high
    }

    struct DaySample: Equatable {
        let readinessBand: ReadinessBand
        let completionRate: Double
        let plannedCount: Int
        let completedCount: Int
        let isOverplannedLowReadinessDay: Bool
    }

    static let minimumSnapshotSampleCount = 3

    private static let lowReadinessMaximum = 2.0
    private static let highReadinessMinimum = 4.0
    private static let overplannedLowDayMinimumItems = 3
    private static let overplannedLowDayCompletionThreshold = 0.5

    static func pattern(from entries: [DailyEntry]) -> ReadinessOutcomePattern {
        pattern(from: samples(from: entries))
    }

    static func snapshotPattern(from entries: [DailyEntry]) -> ReadinessOutcomePattern? {
        let result = pattern(from: entries)
        return result.sampleCount >= minimumSnapshotSampleCount ? result : nil
    }

    static func samples(from entries: [DailyEntry]) -> [DaySample] {
        entries.compactMap(sample(from:))
    }

    static func sample(from entry: DailyEntry) -> DaySample? {
        let band = readinessBand(
            energy: entry.energy,
            mood: entry.mood,
            sleepQuality: entry.sleepQuality
        )

        guard band == .low || band == .high else {
            return nil
        }

        let items = entry.focusThree
        guard !items.isEmpty else {
            return nil
        }

        let completedCount = items.filter { $0.status == .done }.count
        let completionRate = Double(completedCount) / Double(items.count)
        let isOverplannedLowReadinessDay = band == .low &&
            items.count >= overplannedLowDayMinimumItems &&
            completionRate < overplannedLowDayCompletionThreshold

        return DaySample(
            readinessBand: band,
            completionRate: completionRate,
            plannedCount: items.count,
            completedCount: completedCount,
            isOverplannedLowReadinessDay: isOverplannedLowReadinessDay
        )
    }

    static func readinessBand(
        energy: Int,
        mood: Int,
        sleepQuality: Int
    ) -> ReadinessBand {
        let average = Double(energy + mood + sleepQuality) / 3.0
        guard average > 0 else {
            return .missing
        }

        if average <= lowReadinessMaximum {
            return .low
        }

        if average >= highReadinessMinimum {
            return .high
        }

        return .middle
    }

    private static func pattern(from samples: [DaySample]) -> ReadinessOutcomePattern {
        let lowSamples = samples.filter { $0.readinessBand == .low }
        let highSamples = samples.filter { $0.readinessBand == .high }
        let overplannedLowDayCount = lowSamples.filter { $0.isOverplannedLowReadinessDay }.count

        return ReadinessOutcomePattern(
            lowReadinessAvgCompletion: roundedCompletionAverage(lowSamples),
            highReadinessAvgCompletion: roundedCompletionAverage(highSamples),
            overplanningOnLowDays: lowSamples.count >= 2 &&
                overplannedLowDayCount > lowSamples.count / 2,
            sampleCount: lowSamples.count + highSamples.count
        )
    }

    private static func roundedCompletionAverage(_ samples: [DaySample]) -> Double {
        guard !samples.isEmpty else { return 0 }
        let average = samples.map(\.completionRate).reduce(0, +) / Double(samples.count)
        return (average * 100).rounded() / 100
    }
}
