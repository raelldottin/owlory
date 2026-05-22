# app-accessibility-haptic-feedback

## Prompt

> "start next slice" (3rd of 5 accessibility-survey follow-up slices)

Supervisor pick: pri 78. Covers findings H01–H06 from `automation/proofs/app-accessibility-survey/manifest.json`.

## What was done

Added `.sensoryFeedback` (iOS 17+) at all six user actions named by the haptic survey category. Used the closure form `(oldValue, newValue) -> SensoryFeedback?` so feedback only fires on the desired transition direction.

### Sites

| Finding | Surface | Trigger | Feedback |
| --- | --- | --- | --- |
| H01 | Home — task completion | `completedTaskCount: Int` (computed `store.tasks.count(where: \.isCompleted)`) | `.success` when count goes up |
| H02 | Today — Add to Focus | `focusThreeCount: Int` (new computed on `TodayStore`) | `.selection` when count goes up |
| H03 | VoiceCaptureButton — start/stop | `isRecording: Bool` (computed from `service.state`) | `.impact(weight: .medium)` on every toggle |
| H04 | AudioPlaybackButton — toggle | `isPlaying: Bool` (computed from `player.state`) | `.selection` on every toggle |
| H05 | Error alerts (Train + Write + Career + Home + Today) | `store.lastError != nil` | `.error` only on `false → true` transition (dismiss does not haptic) |
| H06 | Home — protocol step completion | `completedStepCount: Int` (computed: nested loop summing `run.steps where status == .completed`) | `.success` when count goes up |

### Why two ViewModifier wrappers

Chaining 2–3 `.sensoryFeedback` modifiers (each with a trailing closure) directly inside `HomeView` and `TodayView` bodies tripped Swift's body type-checker: `error: the compiler is unable to type-check this expression in reasonable time; try breaking up the expression into distinct sub-expressions`. Extracted `HomeHapticsModifier` (takes 3 trigger values, applies 3 feedbacks) and `TodayHapticsModifier` (takes 2 trigger values, applies 2 feedbacks) as private structs. The other 3 views have only one haptic each and use inline modifiers.

### Why a new `focusThreeCount` on `TodayStore`

`TodayStore.currentEntry` is `private`. Rather than widening its access level, added a focused public computed `var focusThreeCount: Int { currentEntry?.focusThree.count ?? 0 }`. The Today view's haptic modifier reads this single Int.

### Approach

- **Closure-form `.sensoryFeedback`.** `(oldValue, newValue) -> SensoryFeedback?` returns `nil` to suppress feedback. This lets task-completion haptics fire ONLY on increase (not decrease, which happens when a task is uncompleted), and lets the error haptic fire only on `false → true` (not on dismiss).
- **Default Apple haptic types.** `.success` / `.error` / `.selection` / `.impact(weight: .medium)` — no custom intensity tuning in this slice.
- **Nested for-loop for `completedStepCount`.** The equivalent `reduce` expression tripped the type-checker. The explicit loop is O(runs × steps) and is fine for realistic data sizes.

### Files touched (12 of 12 cap)

1. `DesignSystem/VoiceCaptureButton.swift` — `.sensoryFeedback(.impact(.medium), trigger: isRecording)` + computed `isRecording`
2. `DesignSystem/AudioPlaybackButton.swift` — `.sensoryFeedback(.selection, trigger: isPlaying)` + computed `isPlaying`
3. `Core/Application/TodayStore.swift` — added `var focusThreeCount: Int`
4. `Features/Today/TodayView.swift` — applied `TodayHapticsModifier`, added the private struct at file end
5. `Features/Train/TrainView.swift` — inline `.sensoryFeedback(trigger: store.lastError != nil)` on error
6. `Features/Write/WriteView.swift` — same shape
7. `Features/Career/CareerView.swift` — same shape
8. `Features/Home/HomeView.swift` — applied `HomeHapticsModifier` (errors + tasks + steps), added the private struct at file end, plus `completedTaskCount` + `completedStepCount` computeds
9. `automation/queue/slices.json`
10. `automation/handoffs/20260522T083710Z-app-accessibility-haptic-feedback.json`
11. `SecondBrain/INDEX.md`
12. `SecondBrain/sessions/2026-05-22/083710-app-accessibility-haptic-feedback.md` — this file

## Validation

- `git fetch origin main` — fetched.
- `xcodebuild build` — exit 0, no errors.
- `make architecture` — passed.
- `make automation-check` — 124 tests OK.
- `make pyright` — 0 errors.
- `git diff --check` — clean.
- Manual smoke: app launches on iPhone 17 Pro Max sim (PID 52111 in launchctl). Simulator does not vibrate so the user-facing haptic event is not visually confirmable on simulator — code path is exercised without crashing.

## Lane Boundary

`build-tested`. Source change across 6 Swift files + 1 store accessor + queue/handoff/INDEX/session. No localization changes (no new strings). No new project-file entries (the two private modifier structs live at file end inside existing files).

## Not Claimed

- Every user-initiated action in Owlory produces haptic feedback. Only the 6 sites named in the accessibility-survey haptic category are wired.
- Real-device haptic confirmation has been performed — simulator runs do not vibrate. Proof level is `build-tested`, not `device-tested`.
- Haptic intensity is finely tuned. Used SwiftUI defaults; a future polish pass could adjust.

## Next

Supervisor's next pick is `app-accessibility-reduce-transparency-and-contrast` (pri 80). Addresses M06 + M08 + M09 — transparency overlays, color-only severity tint, Train status pill.
