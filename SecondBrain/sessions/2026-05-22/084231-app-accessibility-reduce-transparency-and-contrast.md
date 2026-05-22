# app-accessibility-reduce-transparency-and-contrast

## Prompt

> "start next slice" (4th of 5 accessibility-survey follow-up slices)

Supervisor pick: pri 80. Covers findings M06 (transparency overlays), M08 (color-only severity tint), M09 (Train status pill) from `automation/proofs/app-accessibility-survey/manifest.json`.

## What was done

Added an `OwloryAccessibilityContrast` helper enum and applied it at the two state-conveying tint sites that were color-only. Explicitly documented the other M06 sites as decorative-only (out of scope) and M08 as already-paired with positional shape.

### The helper

In `DesignSystem/AppTheme.swift`, next to `OwloryMotion`:

```swift
enum OwloryAccessibilityContrast {
    static func tintedFill(_ color: Color, alpha: Double, reduceTransparency: Bool, increasedContrast: Bool) -> Color
    static func tintedBorder(_ color: Color, alpha: Double, reduceTransparency: Bool, increasedContrast: Bool) -> Color
    static func borderWidth(_ base: CGFloat, increasedContrast: Bool) -> CGFloat
}
```

- Default settings → returns the requested alpha unchanged (existing visuals preserved).
- `reduceTransparency` → raises the alpha floor (0.35 for fills, 0.55 for borders) so the tint becomes clearly readable.
- `colorSchemeContrast == .increased` → returns the color at full alpha (solid) and doubles the border width.

### Sites gated

| Finding | Surface | What changed |
| --- | --- | --- |
| **M09** | Train status pill (Planned / Completed / Skipped / Modified) | Background fill `.opacity(0.15)` + border `.opacity(0.3)` + border `lineWidth: 1` all now route through the helpers. Selection state remains visible under Reduce Transparency (alpha floors raise to 0.35/0.55) and gains a doubled border under Increased Contrast. |
| **M06 (partial)** | TodayView stale-day badge (the "Xd" Continue indicator showing days carried) | Warning capsule background `.opacity(0.12)` gated; this is state-conveying (carried-forward signal) so it earned the gate. |

### Sites explicitly NOT modified

- **M06 decorative tints** (6 sites in TodayView and AppTheme `ContinueHighlightModifier`): `.foregroundStyle(brandPrimary.opacity(0.8))` and the highlight tint are decorative — visual hierarchy or momentary tap accents, not state indicators. Documented in the handoff.
- **M08 readiness severity tint** (`TodayView.readinessColor(for:)`): the consumer is the 5-dot readiness picker. Each dot's POSITION carries the same severity level as the color. Confirmed already-paired with positional shape; no fix needed.

`TodayView` and `SessionCardView` (TrainView's private struct) each gained two new env reads: `@Environment(\.accessibilityReduceTransparency)` and `@Environment(\.colorSchemeContrast)`, plus a derived `private var increasedContrast: Bool`.

### Approach

- **Two-stage gating: reduceTransparency, then increasedContrast.** Default settings return the original alpha. Reduce Transparency raises the alpha to a stronger floor. Increase Contrast goes to solid + thicker border. Layered so toggling either preference is meaningful, and toggling both is maximal.
- **Selective coverage.** Two state-conveying tint sites get the helper; six decorative `.opacity(0.8)` text/icon tints don't (decorative ≠ accessibility risk for those alphas). Honestly documented.
- **No new file.** Helper lives in `AppTheme.swift` next to `OwloryMotion` — pbxproj would orphan a standalone file. MARK separator keeps the file readable.
- **No localization fan-out.** Helper takes the existing OwloryColor tokens; no new strings.

### Files touched (7 of 12 cap)

1. `owlory_xcode/Owlory/DesignSystem/AppTheme.swift` — added `OwloryAccessibilityContrast` enum
2. `owlory_xcode/Owlory/Features/Train/TrainView.swift` — added env reads on `SessionCardView`; gated pill background + border + width
3. `owlory_xcode/Owlory/Features/Today/TodayView.swift` — added env reads on `TodayView`; gated stale-day badge background
4. `automation/queue/slices.json`
5. `automation/handoffs/20260522T084231Z-app-accessibility-reduce-transparency-and-contrast.json`
6. `SecondBrain/INDEX.md`
7. `SecondBrain/sessions/2026-05-22/084231-app-accessibility-reduce-transparency-and-contrast.md`

## Validation

- `git fetch origin main` — fetched.
- `xcodebuild build` — exit 0, no errors.
- `make architecture` — passed.
- `make automation-check` — 124 tests OK.
- `make pyright` — 0 errors.
- `git diff --check` — clean.
- Manual smoke: app launches on iPhone 17 Pro Max sim (PID 59222) — no init-time crash.

## Lane Boundary

`build-tested`. Source change in 3 Swift files + queue/handoff/INDEX/session. No localization changes. No project-file entries.

## Not Claimed

- Every transparency-sensitive UI surface adapts. Only the two highest-impact state-conveying sites are gated.
- The 0.35/0.55 alpha floors are WCAG-verified. They're reasonable defaults; a polish pass with contrast-ratio measurement could refine.
- On-device behavior with Reduce Transparency ON or Increase Contrast ON has been verified — that's a real-device toggle test, not a simulator run.

## Next

Final slice in the accessibility-survey follow-up chain is `app-accessibility-voice-control-input-labels` (pri 82). Adds short verb-noun aliases via `.accessibilityInputLabels` for high-frequency Voice Control commands. Larger blast radius than the others due to 19-locale fan-out for the new `*.voicecontrol.label.*` namespace.
