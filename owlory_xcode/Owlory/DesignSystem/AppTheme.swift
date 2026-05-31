import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Accessibility Contrast

/// Helpers that adapt tinted fills + borders to the user's Reduce Transparency
/// and Increase Contrast preferences. Under default settings the requested
/// alpha is returned unchanged so existing visuals are preserved.
enum OwloryAccessibilityContrast {
    /// Returns the color at the requested alpha. Under Reduce Transparency the
    /// alpha is raised to a stronger floor; under Increased Contrast the color
    /// is returned at full alpha.
    static func tintedFill(
        _ color: Color,
        alpha: Double,
        reduceTransparency: Bool,
        increasedContrast: Bool
    ) -> Color {
        if increasedContrast {
            return color
        }
        if reduceTransparency {
            return color.opacity(max(alpha, 0.35))
        }
        return color.opacity(alpha)
    }

    /// Returns the border color at the requested alpha. Under Reduce
    /// Transparency the alpha is raised; under Increased Contrast the alpha is
    /// pushed even higher so borders read clearly against any background.
    static func tintedBorder(
        _ color: Color,
        alpha: Double,
        reduceTransparency: Bool,
        increasedContrast: Bool
    ) -> Color {
        if increasedContrast {
            return color
        }
        if reduceTransparency {
            return color.opacity(max(alpha, 0.55))
        }
        return color.opacity(alpha)
    }

    /// Returns the border width to use. Under Increased Contrast the width is
    /// doubled to make selection states unambiguous beyond color.
    static func borderWidth(_ base: CGFloat, increasedContrast: Bool) -> CGFloat {
        increasedContrast ? base * 2 : base
    }
}

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

// MARK: - Appearance

/// One-shot UIKit appearance setup. Promotes nav bar titles, tab bar labels,
/// and toolbar text to SF Rounded so UIKit-rendered chrome matches the
/// SwiftUI `.fontDesign(.rounded)` body of the app.
enum OwloryAppearance {
    static func applyRoundedFontAppearance() {
        #if canImport(UIKit)
        let largeTitleDescriptor = UIFontDescriptor
            .preferredFontDescriptor(withTextStyle: .largeTitle)
            .withDesign(.rounded) ?? UIFontDescriptor.preferredFontDescriptor(withTextStyle: .largeTitle)
        let titleDescriptor = UIFontDescriptor
            .preferredFontDescriptor(withTextStyle: .headline)
            .withDesign(.rounded) ?? UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline)
        let tabFontDescriptor = UIFontDescriptor
            .preferredFontDescriptor(withTextStyle: .caption2)
            .withDesign(.rounded) ?? UIFontDescriptor.preferredFontDescriptor(withTextStyle: .caption2)

        let largeTitleFont = UIFont(descriptor: largeTitleDescriptor, size: 0)
            .withWeight(.bold)
        let titleFont = UIFont(descriptor: titleDescriptor, size: 0)
            .withWeight(.semibold)
        let tabFont = UIFont(descriptor: tabFontDescriptor, size: 0)
            .withWeight(.medium)

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithDefaultBackground()
        navAppearance.largeTitleTextAttributes = [.font: largeTitleFont]
        navAppearance.titleTextAttributes = [.font: titleFont]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance

        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithDefaultBackground()
        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.titleTextAttributes = [.font: tabFont]
        itemAppearance.selected.titleTextAttributes = [.font: tabFont]
        tabAppearance.stackedLayoutAppearance = itemAppearance
        tabAppearance.inlineLayoutAppearance = itemAppearance
        tabAppearance.compactInlineLayoutAppearance = itemAppearance
        UITabBar.appearance().standardAppearance = tabAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        }
        #endif
    }
}

#if canImport(UIKit)
private extension UIFont {
    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        let descriptor = fontDescriptor.addingAttributes([
            .traits: [UIFontDescriptor.TraitKey.weight: weight]
        ])
        return UIFont(descriptor: descriptor, size: 0)
    }
}
#endif

// MARK: - Layout Tokens

enum AppTheme {
    static let cardCornerRadius: CGFloat = 16
    static let sectionSpacing: CGFloat = 16
    static let rowSpacing: CGFloat = 12
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

    // MARK: Signature

    /// Warm overlay used by Dusk Mode. Backed by an asset-catalog colorset
    /// with light and dark variants so the warmth reads correctly under both
    /// system appearances.
    static let duskOverlay = Color("duskOverlay")
}

private struct ContinueHighlightModifier: ViewModifier {
    let isHighlighted: Bool

    func body(content: Content) -> some View {
        content
            .background {
                if isHighlighted {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(OwloryColor.brandAccent.opacity(0.14))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(OwloryColor.brandAccent.opacity(0.35), lineWidth: 1)
                        }
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
