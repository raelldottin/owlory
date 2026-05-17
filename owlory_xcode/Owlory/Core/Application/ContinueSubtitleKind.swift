import Foundation

/// Semantic subtitle intent for a Today Continue row.
///
/// The composer in `Core/Application/` emits this enum; the Today feature
/// layer maps it to localized display copy. Domain/Application code MUST NOT
/// own English presentation copy — that responsibility lives in
/// `Features/Today/` per `docs/workflows/localization-dynamic-formatting.md`.
public enum ContinueSubtitleKind: String, Equatable, Codable, CaseIterable, Sendable {
    case focus
    case dueToday
    case carriedForward
    case protocolRun
    case active
    case inProgress
}
