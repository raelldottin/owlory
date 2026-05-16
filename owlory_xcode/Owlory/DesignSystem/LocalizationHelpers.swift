import SwiftUI

/// Wrap a `String` (literal or runtime variable) as a `LocalizedStringKey` so
/// SwiftUI initializers that accept both `LocalizedStringKey` and
/// `StringProtocol` overloads unambiguously pick the localizing path.
///
/// Use this for `Section`, `Label`, `Button`, and any other SwiftUI view whose
/// initializer has both overloads. The two-parameter `Label(_:systemImage:)`
/// in particular has been observed to bind to the `<S: StringProtocol>`
/// overload for string literals in some build configurations, bypassing
/// `Localizable.strings` even when a matching key exists. Routing the title
/// through `L(...)` forces the `LocalizedStringKey` overload.
///
/// Example:
///
///     Section(L("Today")) { ... }
///     Label(L("Training"), systemImage: "heart.text.square")
///     Label(L(label), systemImage: systemImage) // label: String at runtime
///
/// The helper is intentionally a single line. It does NOT make a translation-
/// quality claim — it only ensures the runtime call site routes through the
/// localization lookup. Non-English values remain LLM-drafted; native review
/// is a separate gate.
@inlinable
public func L(_ key: String) -> LocalizedStringKey {
    LocalizedStringKey(key)
}
