import SwiftUI

/// Applies a warm dusk-mode overlay tint when active. Honors Reduce Motion
/// (instant transition) and Increase Contrast (no overlay, readability wins).
///
/// The overlay is non-hit-testing — it never blocks underlying controls.
struct DuskTintModifier: ViewModifier {
    let isActive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast

    private var increasedContrast: Bool { contrast == .increased }

    func body(content: Content) -> some View {
        content
            .overlay {
                if isActive && !increasedContrast {
                    OwloryColor.duskOverlay
                        .opacity(0.05)
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
            }
            .animation(
                OwloryMotion.animation(.easeInOut(duration: 0.6), reduce: reduceMotion),
                value: isActive
            )
    }
}

extension View {
    /// Layers a warm dusk-mode wash over the view when `isActive` is true.
    /// No-op under Increase Contrast.
    func duskTint(_ isActive: Bool) -> some View {
        modifier(DuskTintModifier(isActive: isActive))
    }
}
