import Foundation

enum TodayContinuationRules {
    enum ContinueSource: Equatable {
        case trainingSession(UUID)
        case focusItem(UUID)
        case carriedFocusItem(UUID)
        case homeProtocolRun(UUID)
        case homeTask(UUID)
        case writingNote(UUID)

        var key: String {
            switch self {
            case .trainingSession(let id):
                return "trainingSession|\(id.uuidString)"
            case .focusItem(let id):
                return "focusItem|\(id.uuidString)"
            case .carriedFocusItem(let id):
                return "carriedFocusItem|\(id.uuidString)"
            case .homeProtocolRun(let id):
                return "homeProtocolRun|\(id.uuidString)"
            case .homeTask(let id):
                return "homeTask|\(id.uuidString)"
            case .writingNote(let id):
                return "writingNote|\(id.uuidString)"
            }
        }
    }

    enum HighlightTarget: Equatable {
        case trainingSession(UUID)
        case homeProtocolRun(UUID)
        case homeTask(UUID)
        case writingNote(UUID)
        case careerRecord(UUID)
    }

    struct ContinueItem: Identifiable, Equatable {
        let id: String
        let title: String
        let domain: LifeDomain
        let subtitleKind: ContinueSubtitleKind
        let source: ContinueSource
        let linkedRecordID: UUID?
        let origin: FocusItemOrigin?
        let staleDayCount: Int?
        /// Urgency score from CompletionTimePredictor (0 = not urgent, 1+ = overdue).
        /// Nil when no statistical prediction exists for this item.
        let urgencyScore: Double?
        let priority: ContinuePriority
        let originalIndex: Int

        init(
            id: String,
            title: String,
            domain: LifeDomain,
            subtitleKind: ContinueSubtitleKind,
            source: ContinueSource,
            linkedRecordID: UUID?,
            origin: FocusItemOrigin? = nil,
            staleDayCount: Int?,
            urgencyScore: Double?,
            priority: ContinuePriority,
            originalIndex: Int
        ) {
            self.id = id
            self.title = title
            self.domain = domain
            self.subtitleKind = subtitleKind
            self.source = source
            self.linkedRecordID = linkedRecordID
            self.origin = origin
            self.staleDayCount = staleDayCount
            self.urgencyScore = urgencyScore
            self.priority = priority
            self.originalIndex = originalIndex
        }

        var supportsAddToFocus: Bool {
            switch source {
            case .trainingSession, .homeTask, .writingNote:
                return true
            case .homeProtocolRun:
                return false
            case .focusItem, .carriedFocusItem:
                return false
            }
        }

        var focusLinkedRecordID: UUID? {
            switch source {
            case .trainingSession(let id):
                return id
            case .homeProtocolRun(let id):
                return id
            case .homeTask(let id):
                return id
            case .writingNote(let id):
                return id
            case .focusItem, .carriedFocusItem:
                return linkedRecordID
            }
        }

        var highlightTarget: HighlightTarget? {
            switch source {
            case .trainingSession(let id):
                return .trainingSession(id)
            case .homeProtocolRun(let id):
                return .homeProtocolRun(id)
            case .homeTask(let id):
                return .homeTask(id)
            case .writingNote(let id):
                return .writingNote(id)
            case .focusItem, .carriedFocusItem:
                if let originTarget = Self.highlightTarget(for: origin) {
                    return originTarget
                }
                guard let linkedRecordID else { return nil }
                switch domain {
                case .training:
                    return .trainingSession(linkedRecordID)
                case .writing:
                    return .writingNote(linkedRecordID)
                case .career:
                    return .careerRecord(linkedRecordID)
                case .home:
                    return .homeTask(linkedRecordID)
                }
            }
        }

        func focusOrigin(createdAt: Date) -> FocusItemOrigin? {
            guard let linkedID = focusLinkedRecordID,
                  let kind = focusOriginKind else {
                return nil
            }

            return FocusItemOrigin(kind: kind, id: linkedID, createdAt: createdAt)
        }

        private var focusOriginKind: FocusItemOrigin.Kind? {
            switch source {
            case .trainingSession:
                return .trainingSession
            case .homeProtocolRun:
                return .homeProtocolRun
            case .homeTask:
                return .homeTask
            case .writingNote:
                return .writingNote
            case .focusItem, .carriedFocusItem:
                return origin?.kind
            }
        }

        private static func highlightTarget(for origin: FocusItemOrigin?) -> HighlightTarget? {
            guard let origin else { return nil }
            switch origin.kind {
            case .trainingSession:
                return .trainingSession(origin.id)
            case .writingNote:
                return .writingNote(origin.id)
            case .careerRecord:
                return .careerRecord(origin.id)
            case .homeTask:
                return .homeTask(origin.id)
            case .homeProtocolRun:
                return .homeProtocolRun(origin.id)
            }
        }
    }

    struct DerivationResult: Equatable {
        let items: [ContinueItem]
        let trace: ContinuePipelineTrace
    }

    /// Derive the Continue list.
    ///
    /// - Parameters:
    ///   - predictions: Statistical completion-time predictions keyed by item key.
    ///     When present, `ContinueRankingRules` uses urgency to surface time-sensitive items.
    ///   - now: Current date/time for urgency scoring. Defaults to `Date()`.
    static func derive(
        todayEntry: DailyEntry,
        calibration: CalibrationRules.Calibration,
        todaySessions: [TrainingSession],
        homeTasks: [HomeTask],
        homeRuns: [ProtocolRun],
        homeProtocols: [HouseholdProtocol] = [],
        writingNotes: [WritingNote],
        predictions: [String: CompletionTimePredictor.Prediction] = [:],
        now: Date = Date()
    ) -> [ContinueItem] {
        deriveWithTrace(
            todayEntry: todayEntry,
            calibration: calibration,
            todaySessions: todaySessions,
            homeTasks: homeTasks,
            homeRuns: homeRuns,
            homeProtocols: homeProtocols,
            writingNotes: writingNotes,
            predictions: predictions,
            now: now
        ).items
    }

    /// Derive the Continue list with runtime trace metadata for diagnostics.
    ///
    /// The returned items match `derive(...)`; the trace exposes step-level counts
    /// and ranking effects without moving telemetry into domain policy.
    static func deriveWithTrace(
        todayEntry: DailyEntry,
        calibration: CalibrationRules.Calibration,
        todaySessions: [TrainingSession],
        homeTasks: [HomeTask],
        homeRuns: [ProtocolRun],
        homeProtocols: [HouseholdProtocol] = [],
        writingNotes: [WritingNote],
        predictions: [String: CompletionTimePredictor.Prediction] = [:],
        now: Date = Date()
    ) -> DerivationResult {
        return PerformanceTelemetry.measure(
            "TodayContinuationRules.derive", category: .continueFlow
        ) {
            let sourceCandidates = PerformanceTelemetry.measure(
                "TodayContinuationRules.compose",
                category: .continueFlow
            ) {
                TodayContinueSourceComposer.compose(
                    todayEntry: todayEntry,
                    calibration: calibration,
                    todaySessions: todaySessions,
                    homeTasks: homeTasks,
                    homeRuns: homeRuns,
                    homeProtocols: homeProtocols,
                    writingNotes: writingNotes
                )
            }
            let assembly = PerformanceTelemetry.measure(
                "TodayContinuationRules.assemble",
                category: .continueFlow
            ) {
                TodayContinueItemAssembler.assembleWithTrace(
                    candidates: sourceCandidates,
                    predictions: predictions,
                    now: now
                )
            }
            let rankedItems = PerformanceTelemetry.measure(
                "TodayContinuationRules.rank",
                category: .continueFlow
            ) {
                rank(assembly.items)
            }
            let trace = ContinuePipelineTrace.make(
                sourceCandidates: sourceCandidates,
                assemblyTrace: assembly.trace,
                preRankingItems: assembly.items,
                rankedItems: rankedItems
            )
            PerformanceTelemetry.notice(trace.telemetryMessage, category: .continueFlow)

            return DerivationResult(items: rankedItems, trace: trace)
        }
    }

    // MARK: - Private Helpers

    private static func rank(_ items: [ContinueItem]) -> [ContinueItem] {
        var itemByID: [String: ContinueItem] = [:]
        for item in items {
            itemByID[item.id] = item
        }

        let candidates = items.map {
            ContinueCandidate(
                id: $0.id,
                priority: $0.priority,
                urgencyScore: $0.urgencyScore,
                originalIndex: $0.originalIndex
            )
        }

        return ContinueRankingRules.rank(candidates).compactMap { itemByID[$0.id] }
    }
}
