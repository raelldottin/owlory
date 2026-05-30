import SwiftUI

/// A thin vertical thread that visualizes how many days a Focus item has
/// carried forward. One segment per day, optionally dashed when that day's
/// status was `.deferred`. Above seven days, a small warning-colored cap
/// dot indicates "more than what fits".
///
/// The ribbon does not present itself as a separate accessibility element —
/// callers should attach a textual summary to the surrounding row instead.
struct LineageRibbon: View {
    let dayStatuses: [FocusItemHistoryRules.DayStatus]

    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let maxVisibleSegments = 7

    private var increasedContrast: Bool { contrast == .increased }
    private var totalDays: Int { dayStatuses.count }
    private var width: CGFloat { increasedContrast ? 3 : 2 }
    private var oneDayOpacity: Double {
        (totalDays == 1 && !increasedContrast) ? 0.6 : 1.0
    }

    private var rampColor: Color {
        switch totalDays {
        case ...1: return OwloryColor.brandAccent
        case 2...3: return OwloryColor.brandSecondary
        default: return OwloryColor.brandPrimary
        }
    }

    var body: some View {
        if totalDays == 0 {
            // Nothing carried — render nothing.
            EmptyView()
        } else {
            ribbon
                .frame(width: width)
                .accessibilityHidden(true)
        }
    }

    private var ribbon: some View {
        let visible = Array(dayStatuses.suffix(LineageRibbon.maxVisibleSegments))
        let showCap = totalDays > LineageRibbon.maxVisibleSegments
        let color = rampColor.opacity(oneDayOpacity)

        return VStack(spacing: 1) {
            if showCap {
                Circle()
                    .fill(OwloryColor.warning)
                    .frame(width: width + 1, height: width + 1)
            }
            ForEach(Array(visible.enumerated()), id: \.offset) { _, segment in
                segmentView(status: segment.status, color: color)
                    .frame(maxHeight: .infinity)
            }
        }
        .animation(
            OwloryMotion.animation(.easeOut(duration: 0.2), reduce: reduceMotion),
            value: totalDays
        )
    }

    @ViewBuilder
    private func segmentView(status: FocusItemStatus, color: Color) -> some View {
        if status == .deferred {
            DashedVerticalSegment(color: color, width: width)
        } else {
            Rectangle().fill(color)
        }
    }
}

private struct DashedVerticalSegment: View {
    let color: Color
    let width: CGFloat

    var body: some View {
        GeometryReader { geo in
            Path { path in
                let x = geo.size.width / 2
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: geo.size.height))
            }
            .stroke(
                color,
                style: StrokeStyle(lineWidth: width, lineCap: .butt, dash: [2, 2])
            )
        }
    }
}
