import SwiftUI

/// Applies a warm dusk-mode overlay tint when active. Honors Reduce Motion
/// (instant transition) and Increase Contrast (no overlay, readability wins).
///
/// The overlay is non-hit-testing — it never blocks underlying controls.
/// Renders a top-anchored gradient so the wash reads as a horizon glow rather
/// than a flat veil, doubling down on the dusk identity now that gold anchors
/// the palette.
struct DuskTintModifier: ViewModifier {
    let isActive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast

    private var increasedContrast: Bool { contrast == .increased }

    func body(content: Content) -> some View {
        content
            .background {
                if isActive && !increasedContrast {
                    LinearGradient(
                        stops: [
                            .init(color: OwloryColor.duskOverlay.opacity(0.35), location: 0.0),
                            .init(color: OwloryColor.brandAccent.opacity(0.18), location: 0.5),
                            .init(color: OwloryColor.duskOverlay.opacity(0.22), location: 1.0),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .transition(.opacity)
                }
            }
            .overlay {
                if isActive && !increasedContrast {
                    LinearGradient(
                        stops: [
                            .init(color: OwloryColor.duskOverlay.opacity(0.12), location: 0.0),
                            .init(color: Color.clear, location: 0.30),
                            .init(color: Color.clear, location: 0.75),
                            .init(color: OwloryColor.duskOverlay.opacity(0.10), location: 1.0),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
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
