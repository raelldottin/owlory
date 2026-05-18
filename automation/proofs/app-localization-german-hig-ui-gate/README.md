# German Apple HIG Localized UI Gate

## Scope

This is the Apple Human Interface Guidelines localized UI gate for German (`de`). It was opened on 2026-05-18 using chat-observed evidence from Karoline and a local source trace, and re-gated on 2026-05-18 after the HIG-DE-001 source fix landed.

The gate still does not pass. The HIG-DE-001 source fix is confirmed in the committed source, but no post-fix screenshot artifact is preserved here, and the scoped UI evidence set remains incomplete.

## Evidence Reviewed

- Chat-observed Today screenshot from Karoline showing pre-fix German UI on the Today tab.
- Chat-observed Build Info screenshot from Karoline showing version `0.2.0`, build `20260517151819`, commit `f6325f3c28e9e9263eebbe76a3bbba777ff6e615`, branch `main`.
- Local source search for the visible English strings `Evening reflection` and `Close the day with one quick reflection.` (now absent from source).
- Post-fix source state on 2026-05-18, verified by reading
  `owlory_xcode/Owlory/Core/Application/TodayStore.swift`,
  `owlory_xcode/Owlory/Features/Today/TodayView.swift`, and the German
  `Localizable.strings` resources after commit `1cd9f5e` "Localize evening reflection nudge".

No screenshot binaries are committed in this proof directory, so this remains a doc-only gate.

## Gate Result

Result: **fail**

Reason: scoped UI evidence is still incomplete and HIG-DE-001 has not yet been closed because no post-fix screenshot has been preserved. The source fix is confirmed in the committed source.

## Findings

### HIG-DE-001: English reflection nudge copy appears in German Today UI

Severity: blocking
State: **in-progress** (source-fix-confirmed; awaiting post-fix screenshot evidence)
Remediation slice: `app-localization-evening-reflection-nudge-routing`

Pre-fix observation (from Karoline's TestFlight Build Info screenshot): the German Today header contained an evening reflection nudge with English title/body copy:

- `Evening reflection`
- `Close the day with one quick reflection.`

Post-fix source trace (commit `1cd9f5e`):

- `owlory_xcode/Owlory/Core/Application/TodayStore.swift:551` — `EveningReflectionNudge` is now `struct EveningReflectionNudge: Equatable` with semantic `Kind` enum (`.eveningReflection`, `.homeWrappedReflection`). No English `title`/`message` strings are emitted from Application.
- `owlory_xcode/Owlory/Features/Today/TodayView.swift:1400` — `reflectionNudgeTitle(for:)` uses `String(localized: "notification.prompt.eveningReflection.title")` / `"notification.prompt.homeWrappedReflection.title"`.
- `owlory_xcode/Owlory/Features/Today/TodayView.swift:1409` — `reflectionNudgeMessage(for:)` uses the matching `.body` keys.
- `owlory_xcode/Owlory/Resources/de.lproj/Localizable.strings:231-234` — German values exist for all four keys: `Abendreflexion`, `Schließen Sie den Tag mit einer kurzen Reflexion.`, `Haushalt abgeschlossen`, and the home-wrapped body.

Closure blocker: no rerun screenshot of the German Today surface has been preserved under `automation/proofs/`. The chat-observed pre-fix screenshot is not committed and is no longer representative. The finding remains open in state `in-progress` until a post-fix capture lands.

## HIG Areas

| Area | Result | Notes |
| --- | --- | --- |
| Platform consistency | unknown | Pre-fix screenshot looked iOS-native, but the post-fix surface has not been captured. |
| Adaptive layout | unknown | No committed screenshot set, device-size matrix, orientation check, or larger text pass. |
| Typography and Dynamic Type | not reviewed | No standard/larger accessibility text evidence preserved for German. |
| Accessibility | not reviewed | No VoiceOver labels, hints, values, reading order, or contrast evidence preserved for German. |
| Labels and actions | source-fix-confirmed-pending-rerun | Source fix landed; visible-copy regression is gone in the committed source; no rerun screenshot proves the runtime surface. |
| Locale-aware formatting | partial | The pre-fix observed Today date was German-formatted, but high-risk counts/plurals/dates are not fully reviewed. |
| Right-to-left behavior | not applicable | German is LTR; RTL gate applies to Arabic and other RTL locales. |

## Missing Evidence For Pass

To claim German `hig-ui-reviewed`, provide or generate preserved evidence for:

- Post-fix Today screenshot for German showing the reflection nudge in localized copy.
- Build Info screenshot with complete gate fields, committed under `automation/proofs/`.
- All five root tabs.
- Primary empty states and primary actions.
- High-risk date/count/plural surfaces.
- Standard text size and Larger Accessibility Text pass.
- Accessibility labels/hints/values for the reviewed surfaces.

The all-locale multisurface screenshot harness (`automation/smoke/capture_localized_surfaces.py`) can capture most of these surfaces in one run with `--locales de --label-overrides de_labels.json`. Dynamic Type evidence is covered for the source `en` + native-reviewed `de` shell by `LocalizationAccessibilityRegression`, but Dynamic Type screenshots are not preserved by that regression.

## Status

Do not claim German `hig-ui-reviewed`.

German remains native-reviewed for the language entries in the return file (419 entries on 2026-05-18). Localized UI readiness for German is now blocked on:

1. Closing HIG-DE-001 by capturing a post-fix Today screenshot.
2. Capturing the remaining scoped HIG surface evidence and recording it in this gate plus the all-locale HIG evidence matrix (`automation/proofs/app-localization-hig-ui-matrix/manifest.json`).

## Re-gate History

- **2026-05-18T02:29:24Z** — Initial gate intake on chat-observed Karoline screenshots. Gate failed on HIG-DE-001 (visible English reflection nudge in German Today UI).
- **2026-05-18T05:12:32Z** — Re-gate after `app-localization-evening-reflection-nudge-routing` landed source fix. HIG-DE-001 moved from `blocking_findings` to `in_progress_findings` with `source_fix_confirmed=true`. Gate result remains `fail` because scoped UI evidence has not been captured after the fix.
