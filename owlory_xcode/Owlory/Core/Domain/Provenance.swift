import Foundation

/// Tracks how a persisted item entered Owlory's state. `nil` (the default
/// on existing records) means user-authored — the system has no claim
/// otherwise. New cases are added as the codebase wires more generated-item
/// paths through this enum; the default `nil` keeps existing data
/// forward-compatible without migration.
enum Provenance: String, Codable, Equatable {
    /// Created from a `FocusSuggestionRules` draft that the user accepted.
    case focusSuggestion
}
