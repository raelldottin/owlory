import Foundation

struct WeeklyDigest: Identifiable, Codable, Equatable {
    let id: UUID
    let weekStarting: Date
    let weekEnding: Date
    let generatedAt: Date
    let daysWithEntries: Int
    let completionRate: Double
    let totalPlanned: Int
    let totalDone: Int
    let averageReadiness: Double
    let bestDay: DayHighlight?
    let hardestDay: DayHighlight?
    let domainActivity: [LifeDomain: Int]
    let stalledItemCount: Int
    let streakDays: Int
    let keyInsight: String

    struct DayHighlight: Codable, Equatable {
        let date: Date
        let summary: String
    }

    init(
        id: UUID = UUID(),
        weekStarting: Date,
        weekEnding: Date,
        generatedAt: Date,
        daysWithEntries: Int,
        completionRate: Double,
        totalPlanned: Int,
        totalDone: Int,
        averageReadiness: Double,
        bestDay: DayHighlight? = nil,
        hardestDay: DayHighlight? = nil,
        domainActivity: [LifeDomain: Int] = [:],
        stalledItemCount: Int = 0,
        streakDays: Int = 0,
        keyInsight: String = ""
    ) {
        self.id = id
        self.weekStarting = weekStarting
        self.weekEnding = weekEnding
        self.generatedAt = generatedAt
        self.daysWithEntries = daysWithEntries
        self.completionRate = completionRate
        self.totalPlanned = totalPlanned
        self.totalDone = totalDone
        self.averageReadiness = averageReadiness
        self.bestDay = bestDay
        self.hardestDay = hardestDay
        self.domainActivity = domainActivity
        self.stalledItemCount = stalledItemCount
        self.streakDays = streakDays
        self.keyInsight = keyInsight
    }
}
