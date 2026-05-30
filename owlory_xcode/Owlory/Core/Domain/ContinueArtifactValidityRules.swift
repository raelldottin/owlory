import Foundation

/// Pure rule that decides whether a Continue source emitted from a
/// `FocusItem` still resolves to an existing record. A focus item that
/// links (via `linkedRecordID` or `origin`) to a record that no longer
/// exists is an "invalid artifact" — keeping it in the Continue list
/// would surface a ghost row that routes nowhere.
///
/// User-authored focus items with no record link are always treated as
/// valid; the rule only suppresses record-backed artifacts whose backing
/// record is missing.
///
/// Training and career are intentionally optional: the composer that
/// calls this rule sees only `todaySessions` (a subset of training
/// records), not the full session set, so it cannot distinguish "session
/// belongs to another day" from "session was deleted". Passing `nil` for
/// those sets preserves the current "treat as valid" behavior; a follow-
/// up can expand the composer's input set when training-side ghost
/// detection becomes load-bearing.
enum ContinueArtifactValidityRules {
    struct KnownRecordIDs: Equatable {
        var trainingSessions: Set<UUID>?
        var homeTasks: Set<UUID>
        var homeRuns: Set<UUID>
        var homeProtocols: Set<UUID>
        var writingNotes: Set<UUID>
        var careerRecords: Set<UUID>?

        init(
            trainingSessions: Set<UUID>? = nil,
            homeTasks: Set<UUID> = [],
            homeRuns: Set<UUID> = [],
            homeProtocols: Set<UUID> = [],
            writingNotes: Set<UUID> = [],
            careerRecords: Set<UUID>? = nil
        ) {
            self.trainingSessions = trainingSessions
            self.homeTasks = homeTasks
            self.homeRuns = homeRuns
            self.homeProtocols = homeProtocols
            self.writingNotes = writingNotes
            self.careerRecords = careerRecords
        }
    }

    /// Returns true when the focus item's record link still resolves.
    /// User-authored items (no `linkedRecordID` and no `origin`) are
    /// always considered valid.
    static func isValid(_ item: FocusItem, against ids: KnownRecordIDs) -> Bool {
        if let origin = item.origin {
            return contains(id: origin.id, kind: origin.kind, in: ids)
        }

        guard let linkedID = item.linkedRecordID else {
            return true
        }

        switch item.domain {
        case .training:
            guard let sessions = ids.trainingSessions else { return true }
            return sessions.contains(linkedID)
        case .home:
            return ids.homeTasks.contains(linkedID)
                || ids.homeRuns.contains(linkedID)
                || ids.homeProtocols.contains(linkedID)
        case .writing:
            return ids.writingNotes.contains(linkedID)
        case .career:
            guard let records = ids.careerRecords else { return true }
            return records.contains(linkedID)
        }
    }

    private static func contains(
        id: UUID,
        kind: OwloryItemOrigin.Kind,
        in ids: KnownRecordIDs
    ) -> Bool {
        switch kind {
        case .trainingSession:
            guard let sessions = ids.trainingSessions else { return true }
            return sessions.contains(id)
        case .homeTask:
            return ids.homeTasks.contains(id)
        case .homeProtocolRun:
            return ids.homeRuns.contains(id)
        case .writingNote:
            return ids.writingNotes.contains(id)
        case .careerRecord:
            guard let records = ids.careerRecords else { return true }
            return records.contains(id)
        }
    }
}
