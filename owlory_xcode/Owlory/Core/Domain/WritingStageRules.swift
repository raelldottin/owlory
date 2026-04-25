import Foundation

enum WritingStageTransitionError: Error, Equatable, LocalizedError {
    case invalidTransition(from: WritingStage, to: WritingStage)

    var errorDescription: String? {
        switch self {
        case .invalidTransition(let from, let to):
            return "Cannot move writing note from \(from.title) to \(to.title)."
        }
    }
}

enum WritingStageRules {
    static func canTransition(from current: WritingStage, to next: WritingStage) -> Bool {
        allowedTransitions[current, default: []].contains(next)
    }

    static func transition(_ note: WritingNote, to next: WritingStage) throws -> WritingNote {
        guard canTransition(from: note.stage, to: next) else {
            throw WritingStageTransitionError.invalidTransition(from: note.stage, to: next)
        }

        var updated = note
        updated.stage = next
        return updated
    }

    static func advance(_ note: WritingNote) throws -> WritingNote {
        guard let next = nextStage(after: note.stage) else {
            throw WritingStageTransitionError.invalidTransition(from: note.stage, to: note.stage)
        }
        return try transition(note, to: next)
    }

    static func nextStage(after stage: WritingStage) -> WritingStage? {
        switch stage {
        case .capture:
            return .source
        case .source:
            return .permanent
        case .permanent:
            return .draftSeed
        case .draftSeed:
            return .draft
        case .draft:
            return .published
        case .published, .archived:
            return nil
        }
    }

    private static let allowedTransitions: [WritingStage: Set<WritingStage>] = [
        .capture: [.source, .archived],
        .source: [.capture, .permanent, .archived],
        .permanent: [.source, .draftSeed, .archived],
        .draftSeed: [.permanent, .draft, .archived],
        .draft: [.draftSeed, .published, .archived],
        .published: [.draft, .archived],
        .archived: [.capture, .source, .permanent, .draftSeed, .draft, .published]
    ]
}
