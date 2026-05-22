import SwiftUI

// MARK: - Accessibility Motion

/// Helpers that honor the user's Reduce Motion preference uniformly across the
/// app. SwiftUI does not automatically gate `.animation(_:value:)` or
/// `withAnimation { }` on `accessibilityReduceMotion`; these helpers do, so each
/// animation site stays a single readable line instead of repeating the guard.
enum OwloryMotion {
    /// Returns the supplied animation, or `nil` when the user has Reduce Motion
    /// enabled. Pair with `.animation(_:value:)`.
    static func animation(_ animation: Animation?, reduce: Bool) -> Animation? {
        reduce ? nil : animation
    }

    /// Runs `body` inside `withAnimation(animation)` unless Reduce Motion is
    /// enabled, in which case the state change is applied immediately.
    @discardableResult
    static func withAnimation<Result>(
        _ animation: Animation = .default,
        reduce: Bool,
        _ body: () throws -> Result
    ) rethrows -> Result {
        if reduce {
            return try body()
        }
        return try SwiftUI.withAnimation(animation, body)
    }
}

// MARK: - Layout Tokens

enum AppTheme {
    static let cardCornerRadius: CGFloat = 16
    static let sectionSpacing: CGFloat = 16
    static let compactSpacing: CGFloat = 8
    static let cardPadding: CGFloat = 12
    static let elevationShadowRadius: CGFloat = 4
    static let elevationShadowY: CGFloat = 2
}

// MARK: - Semantic Colors

/// Central color accessor for the Owlory design system.
///
/// All colors are defined as named assets in the asset catalog with
/// Light and Dark appearances. Use these semantic roles instead of
/// hardcoded colors or raw system colors for brand surfaces.
///
/// System semantic colors (e.g. `.primary`, `.secondary`, `.red`) remain
/// appropriate for standard text hierarchy and destructive actions.
enum OwloryColor {

    // MARK: Brand

    static let brandPrimary = Color("brandPrimary")
    static let brandPrimaryPressed = Color("brandPrimaryPressed")
    static let brandSecondary = Color("brandSecondary")
    static let brandAccent = Color("brandAccent")
    static let brandOnPrimary = Color("brandOnPrimary")

    // MARK: Background

    static let backgroundPrimary = Color("backgroundPrimary")
    static let backgroundSecondary = Color("backgroundSecondary")
    static let backgroundTertiary = Color("backgroundTertiary")

    // MARK: Surface

    static let surfacePrimary = Color("surfacePrimary")
    static let surfaceSecondary = Color("surfaceSecondary")
    static let surfaceElevated = Color("surfaceElevated")
    static let surfaceSelected = Color("surfaceSelected")

    // MARK: Text

    static let textPrimary = Color("textPrimary")
    static let textSecondary = Color("textSecondary")
    static let textTertiary = Color("textTertiary")
    static let textOnBrand = Color("textOnBrand")

    // MARK: Border & Separator

    static let borderSubtle = Color("borderSubtle")
    static let borderStrong = Color("borderStrong")
    static let separatorSubtle = Color("separatorSubtle")

    // MARK: State

    static let success = Color("owlorySuccess")
    static let warning = Color("owloryWarning")
    /// Destructive actions use system red for platform consistency.
    static let error = Color.red
    static let info = Color("owloryInfo")
}

private struct ContinueHighlightModifier: ViewModifier {
    let isHighlighted: Bool

    func body(content: Content) -> some View {
        content
            .background {
                if isHighlighted {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(OwloryColor.brandPrimary.opacity(0.10))
                }
            }
    }
}

extension View {
    func continueHighlight(_ isHighlighted: Bool) -> some View {
        modifier(ContinueHighlightModifier(isHighlighted: isHighlighted))
    }
}

extension ScrollViewProxy {
    func scrollToContinueHighlight<ID: Hashable>(_ id: ID?, reduceMotion: Bool = false) {
        guard let id else { return }
        let proxy = self
        DispatchQueue.main.async {
            OwloryMotion.withAnimation(.easeInOut(duration: 0.2), reduce: reduceMotion) {
                proxy.scrollTo(id, anchor: .center)
            }
        }
    }
}
