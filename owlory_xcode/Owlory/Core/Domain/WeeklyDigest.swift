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
        /// Legacy English-only fallback. New digests store an empty summary
        /// and rely on the structured fields below; old digests on disk
        /// still carry a composed English sentence here so presentation can
        /// fall through when the structured fields are absent.
        let summary: String
        /// Best-day signals. Non-nil on best-day highlights from new digests.
        let doneCount: Int?
        let plannedCount: Int?
        /// Hardest-day signal. Non-nil on hardest-day highlights from new
        /// digests. Encoded as the raw value of `ReadinessBand` so the
        /// model stays Codable-stable.
        let readinessBand: String?

        init(
            date: Date,
            summary: String = "",
            doneCount: Int? = nil,
            plannedCount: Int? = nil,
            readinessBand: String? = nil
        ) {
            self.date = date
            self.summary = summary
            self.doneCount = doneCount
            self.plannedCount = plannedCount
            self.readinessBand = readinessBand
        }

        enum CodingKeys: String, CodingKey {
            case date
            case summary
            case doneCount
            case plannedCount
            case readinessBand
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            date = try container.decode(Date.self, forKey: .date)
            summary = try container.decodeIfPresent(String.self, forKey: .summary) ?? ""
            doneCount = try container.decodeIfPresent(Int.self, forKey: .doneCount)
            plannedCount = try container.decodeIfPresent(Int.self, forKey: .plannedCount)
            readinessBand = try container.decodeIfPresent(String.self, forKey: .readinessBand)
        }
    }

    /// Raw values for keyInsight on new digests. WeeklyDigest.keyInsight stays
    /// a plain `String` so legacy stored digests (which hold a full English
    /// sentence) keep decoding; new digests store the rawValue and the
    /// presentation helper resolves it back to a localized sentence.
    enum InsightKind: String, Codable {
        case lightWeek
        case strongWeek
        case finishedMost
        case toughWeek
        case stalledCarryOver
        case severalDeferred
        case lowCompletion
        case steady
    }

    /// Raw values for the hardest-day `readinessBand` field.
    enum ReadinessBand: String, Codable {
        case low
        case moderate
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
