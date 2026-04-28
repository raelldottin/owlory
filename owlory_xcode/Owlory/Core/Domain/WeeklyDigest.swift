import Foundation

enum WeeklyDigestRuleVersion {
    /// Current calculation contract for weekly digest completion totals.
    ///
    /// Version 2 records the contract that counts completed Today Focus items plus
    /// timestamped completed Home protocol steps inside the digest week.
    static let current = 2
}

struct WeeklyDigest: Identifiable, Codable, Equatable {
    let id: UUID
    let digestRuleVersion: Int?
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

    var usesCurrentDigestRuleVersion: Bool {
        digestRuleVersion == WeeklyDigestRuleVersion.current
    }

    var isLegacyDigestRuleVersion: Bool {
        !usesCurrentDigestRuleVersion
    }

    struct DayHighlight: Codable, Equatable {
        let date: Date
        let summary: String
    }

    func withStableID(_ stableID: UUID) -> WeeklyDigest {
        WeeklyDigest(
            id: stableID,
            digestRuleVersion: digestRuleVersion,
            weekStarting: weekStarting,
            weekEnding: weekEnding,
            generatedAt: generatedAt,
            daysWithEntries: daysWithEntries,
            completionRate: completionRate,
            totalPlanned: totalPlanned,
            totalDone: totalDone,
            averageReadiness: averageReadiness,
            bestDay: bestDay,
            hardestDay: hardestDay,
            domainActivity: domainActivity,
            stalledItemCount: stalledItemCount,
            streakDays: streakDays,
            keyInsight: keyInsight
        )
    }

    init(
        id: UUID = UUID(),
        digestRuleVersion: Int? = WeeklyDigestRuleVersion.current,
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
        self.digestRuleVersion = digestRuleVersion
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
