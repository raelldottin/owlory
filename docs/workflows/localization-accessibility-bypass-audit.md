# Localization Accessibility Bypass Audit

Audit-first inventory of `.accessibilityLabel(...)` / `.accessibilityHint(...)` / `.accessibilityValue(...)` call sites that may bypass `Localizable.strings`.

**Source slice:** `app-localization-accessibility-bypass-audit` (doc-only).
**Method:** static scan of `*.swift` files under `owlory_xcode/Owlory/` and `owlory_xcode/OwloryWidgets/` for the three accessibility modifiers, both literal and variable forms. Each variable case was manually traced to its upstream definition.
**Scan date:** 2026-05-16.

This report does NOT fix any strings. It catalogs and queues one narrow follow-up. It does NOT make a translation-quality claim. It does NOT change `provenance.native_reviewed` for any locale.

## Aggregate counts

| Pattern | Sites |
|---|---:|
| `.accessibilityLabel("Lit")` | 9 |
| `.accessibilityLabel(var)` | 7 |
| `.accessibilityHint("Lit")` | 3 |
| `.accessibilityHint(var)` | 2 |
| `.accessibilityValue("Lit")` | 1 |
| **Total** | **22** |

## Classification of the 9 variable sites

| # | Call site | Upstream | Verdict |
|---:|---|---|---|
| 1 | `AudioPlaybackButton.swift:16` `accessibilityLabel(accessibilityText)` | `private var accessibilityText: String` returns hardcoded English: `"Play recording"`, `"Stop playback"`, `"Playback error: \(msg)"`. No `NSLocalizedString` / `String(localized:)` wrapping. | **real-bypass** — fix queued |
| 2 | `VoiceCaptureButton.swift:44` `accessibilityLabel(accessibilityText)` | `private var accessibilityText: String` returns hardcoded English: `"Start voice capture"`, `"Stop recording"`, `"Transcribing"`, `"Voice capture complete"`, `"Error: \(msg)"`. No wrapping. | **real-bypass** — fix queued |
| 3 | `HomeView.swift:496` `accessibilityLabel(leadingButtonAccessibilityLabel)` | Computed property at `HomeView.swift:580` returns `HomeAccessibilityLabels.taskMarkComplete(title:)` / `taskMarkIncomplete(title:)` / `taskRestore(title:)`. | **already-safe** — `HomeAccessibilityLabels` uses `NSLocalizedString` + `String.localizedStringWithFormat`. |
| 4 | `HomeView.swift:532` `accessibilityLabel(HomeAccessibilityLabels.taskEdit(title:))` | Same helper. | **already-safe**. |
| 5 | `HomeView.swift:550` `accessibilityLabel(HomeAccessibilityLabels.taskSkip(title:))` | Same helper. | **already-safe**. |
| 6 | `HomeView.swift:1133` `accessibilityLabel(HomeAccessibilityLabels.protocolStepComplete(title:))` | Same helper. | **already-safe**. |
| 7 | `HomeView.swift:1163` `accessibilityLabel(HomeAccessibilityLabels.protocolStepSkip(title:))` | Same helper. | **already-safe**. |
| 8 | `TodayView.swift:269` `accessibilityHint(continueAccessibilityHint(for:))` | `private func continueAccessibilityHint(for:)` at line 329 uses `NSLocalizedString` + `String.localizedStringWithFormat` with keys `today.continue.accessibility.focusStatusActions` / `addToFocus` / `openDomain` plus `item.domain.localizedDisplayName`. | **already-safe**. |
| 9 | `WriteView.swift:188` `accessibilityHint(writeRowAccessibilityHint(for:))` | `private func writeRowAccessibilityHint(for:)` at line 368 uses `NSLocalizedString` + `String.localizedStringWithFormat` with key `write.row.accessibility.advanceHint` plus `next.localizedDisplayName`, and `String(localized: "write.row.accessibility.defaultHint")` as fallback. | **already-safe**. |

**Summary:** 7 of 9 variable sites are already correctly localized through helper functions that wrap `NSLocalizedString`. **2 of 9** are real bypasses, both in `DesignSystem/` audio/voice button views.

## Classification of the 13 literal sites

| Call site | Visible | Key in `Localizable.strings`? | Verdict |
|---|---|---|---|
| `CareerView.swift:25` `accessibilityLabel("Add career record")` | `"Add career record"` | yes | already-safe |
| `HomeView.swift:50` `accessibilityLabel("Add task or protocol")` | `"Add task or protocol"` | yes | already-safe |
| `HomeView.swift:316` `accessibilityLabel("Archive Protocol")` | `"Archive Protocol"` | yes | already-safe |
| `HomeView.swift:533` `accessibilityHint("Opens task details.")` | `"Opens task details."` | yes | already-safe |
| `BuildInfoView.swift:73` `accessibilityHint("Copies the full build identity to the clipboard…")` | long string | yes | already-safe |
| `BuildInfoView.swift:102` `accessibilityLabel("\(label): \(value)")` | interpolation | n/a | **interpolation-pattern** — content is `Version: 1.0.5` etc.; runtime values are not translatable; `": "` separator is locale-neutral; **acceptable as-is** but could be routed through a formatter for theoretical RTL/CJK correctness |
| `TodayView.swift:47` `accessibilityLabel("Open build info")` | `"Open build info"` | yes | already-safe |
| `TodayView.swift:48` `accessibilityHint("Shows the app version…")` | long string | yes | already-safe |
| `TrainView.swift:39` `accessibilityLabel("Plan training session")` | `"Plan training session"` | yes | already-safe |
| `TrainView.swift:516` `accessibilityLabel("\(label), \(value) of 5")` | interpolation | n/a | **real-bypass via interpolation** — hardcoded English `" of 5"` between two runtime values |
| `TrainView.swift:517` `accessibilityValue("\(value)")` | pure number | n/a | already-safe |
| `WriteView.swift:50` `accessibilityLabel("Capture new note")` | `"Capture new note"` | yes | already-safe |
| `WriteView.swift:553` `accessibilityLabel("Note options")` | `"Note options"` | yes | already-safe |

**Summary:** 11 of 13 literal sites are already-safe (key exists + SwiftUI `LocalizedStringKey` overload). **1** is an interpolation-pattern bypass already covered by the queued `app-localization-string-interpolation-formatters` slice (the `"\(label), \(value) of 5"` line). **1** is acceptable as-is (`"\(label): \(value)"` build-info row).

## Final tally

| Bucket | Count | Action |
|---|---:|---|
| Already-safe variables | 7 | none |
| Already-safe literals | 11 | none |
| Acceptable interpolation (build-info) | 1 | none |
| Real-bypass variables (audio/voice buttons) | 2 | queue narrow follow-up |
| Real-bypass interpolation (Train readiness scale row) | 1 | already covered by `app-localization-string-interpolation-formatters` |

**Net new work surfaced:** **1 narrow follow-up slice** for 2 specific files.

## Queued follow-up

`app-localization-audio-voice-button-accessibility-routing` — route `AudioPlaybackButton.accessibilityText` and `VoiceCaptureButton.accessibilityText` through `NSLocalizedString` / `String(localized:)`. Both files are in `owlory_xcode/Owlory/DesignSystem/`. Each currently has a switch statement returning hardcoded English strings:

- `AudioPlaybackButton`: `"Play recording"`, `"Stop playback"`, `"Playback error: %@"` (interpolated)
- `VoiceCaptureButton`: `"Start voice capture"`, `"Stop recording"`, `"Transcribing"`, `"Voice capture complete"`, `"Error: %@"` (interpolated)

Scope:

- Add 7 new keys to `Localizable.strings` across all 19 locales (LLM-drafted), 2 of which are stringsdict-style format strings with `%@`.
- Wrap returns in `NSLocalizedString(...)` (or `String(localized: ...)` for the non-interpolated cases) plus `String.localizedStringWithFormat(...)` for the two interpolated error/playback-error cases.
- No view code changes outside the two DesignSystem files.

Out of scope of the follow-up:

- Other DesignSystem bypasses (none found by this audit).
- Native review of the new keys.
- Visual layout testing of translated audio button states.

## What this audit does NOT prove

- Runtime behavior: this is a static scan plus upstream-helper trace. We did not exercise each accessibility label on a device under VoiceOver to confirm the spoken output matches the visible state.
- That `HomeAccessibilityLabels.*` / `continueAccessibilityHint` / `writeRowAccessibilityHint` produce correct translations — only that they route through `NSLocalizedString`. Translation quality remains LLM-drafted and unreviewed.
- That `"\(label): \(value)"` in `BuildInfoView` reads well in RTL or CJK — it's currently a developer-facing field rather than user-translation territory.
- That accessibility output matches visible output for the converted Section/Label/Button sites from `app-localization-complete-nls-routing-pass`.
- Native review for any locale. `app-localization-native-review-intake` remains blocked.
