# app-accessibility-reduce-motion-helper

## Prompt

> "start next slice" (next pick from the accessibility-survey follow-up chain after the swipe-actions slice closed)

Supervisor pick: pri 77 from the 5-slice accessibility-survey follow-up chain. Covers findings M01-M05 from `automation/proofs/app-accessibility-survey/manifest.json`.

## What was done

Honored `accessibilityReduceMotion` at all five animation sites surveyed in the motion category. Introduced a small `OwloryMotion` helper that turns the per-site guard into a single readable line.

### The helper

```swift
enum OwloryMotion {
    static func animation(_ animation: Animation?, reduce: Bool) -> Animation?
    @discardableResult
    static func withAnimation<R>(_ animation: Animation = .default, reduce: Bool, _ body: () throws -> R) rethrows -> R
}
```

- `animation(_:reduce:)` returns `nil` when `reduce` is true. Pair with `.animation(_:value:)`.
- `withAnimation(_:reduce:_:)` executes `body` directly when `reduce` is true, otherwise wraps in `SwiftUI.withAnimation`. `@discardableResult` matches `SwiftUI.withAnimation`.

Inlined into `DesignSystem/AppTheme.swift` instead of a new file because `Owlory.xcodeproj/project.pbxproj` references files by explicit `PBXFileReference` IDs and a standalone file would have been orphaned without a manual project-file edit. Noted as a low-priority cleanup in the handoff.

### Sites gated

| Finding | File | Pattern |
| --- | --- | --- |
| M01 | DesignSystem/AppTheme.swift | `ScrollViewProxy.scrollToContinueHighlight` — signature gained `reduceMotion: Bool = false` so existing callers compile unchanged |
| M02 | Features/Today/TodayView.swift | `.transition(reduceMotion ? .identity : .opacity)` on the reflection-saved confirmation |
| M03 | Features/Today/TodayView.swift | `.animation(OwloryMotion.animation(.easeInOut(duration: 0.15), reduce: reduceMotion), value: value)` on the readiness picker |
| M04 | Features/Train/TrainView.swift | Same readiness-picker pattern in `TrainingReadinessScaleRow` (gained its own `@Environment(\.accessibilityReduceMotion)`) |
| M05a | Features/Today/TodayView.swift | `OwloryMotion.withAnimation(reduce: reduceMotion) { reflectionSaved = true }` |
| M05b | Features/Today/TodayView.swift | Same wrap for `withAnimation { showingReflection = true }` on the evening-reflection nudge |

`TodayView` gained one new `@Environment(\.accessibilityReduceMotion) private var reduceMotion`. `TrainingReadinessScaleRow` (a top-level struct that the picker uses) gained the same env read.

### Approach

- **Inline helper, not new file.** The pbxproj would have rejected a standalone file silently; the inline form ships immediately with no project-file editing.
- **`.transition` is a different shape from `.animation`.** `.transition` takes `AnyTransition`, not `Animation?`, so I used `.identity` as the no-op variant instead of the `OwloryMotion.animation` helper.
- **`scrollToContinueHighlight` signature kept backward-compatible.** Added `reduceMotion: Bool = false` as an optional parameter. The five existing callers compile unchanged; threading the env through them is a future slice.
- **Real swiftc, not SourceKit.** SourceKit's editor diagnostics flagged spurious "Cannot find type X in scope" warnings throughout. Verified each change via `xcodebuild build` — exit 0, no errors.

### Files touched (7 of 8 cap)

1. `owlory_xcode/Owlory/DesignSystem/AppTheme.swift` — added `OwloryMotion`; updated `ScrollViewProxy.scrollToContinueHighlight` signature
2. `owlory_xcode/Owlory/Features/Today/TodayView.swift` — added env read; gated 4 motion sites
3. `owlory_xcode/Owlory/Features/Train/TrainView.swift` — gated 1 motion site (env read on `TrainingReadinessScaleRow`)
4. `automation/queue/slices.json` — slice marked done
5. `automation/handoffs/20260522T082701Z-app-accessibility-reduce-motion-helper.json`
6. `SecondBrain/INDEX.md`
7. `SecondBrain/sessions/2026-05-22/082701-app-accessibility-reduce-motion-helper.md` — this file

## Validation

- `git fetch origin main` — fetched.
- `xcodebuild -project owlory_xcode/Owlory.xcodeproj -scheme Owlory build` — exit 0, no errors.
- `python3 automation/context/build_context.py --slice-id app-accessibility-reduce-motion-helper` — built.
- `make architecture` — passed.
- `make automation-check` — 124 tests OK.
- `make pyright` — 0 errors.
- `git diff --check` — clean.
- Manual smoke: `xcrun simctl install + launch` on iPhone 17 Pro Max with the marketing seed args — app process running (PID 39695), no crash.

## Lane Boundary

`build-tested`. Source changes to 3 Swift files + queue/handoff/INDEX/session. No localization changes. No new project-file entries (helper inlined).

## Not Claimed

- Every animation in the app honors `accessibilityReduceMotion`. Only the 5 sites named in the accessibility-survey motion category are gated. Other implicit SwiftUI animations (NavigationStack push, sheet present, etc.) continue with iOS defaults.
- On-device visual confirmation with Reduce Motion ON has been performed. xcodebuild + launch is clean, but visually confirming the readiness picker is static and the reflection save fades instantly under `reduceMotion=true` requires manual testing.
- The 5 callers of `scrollToContinueHighlight` have been updated to pass `reduceMotion`. They still rely on the default `false` — gating those calls is a follow-up.

## Next

Supervisor's next pick is `app-accessibility-haptic-feedback` (pri 78) — 6 user actions (task completion, focus add, recording start/stop, playback toggle, error alert, protocol step) lack tactile feedback.
