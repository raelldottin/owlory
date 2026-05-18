# German Apple HIG Localized UI Gate

## Scope

This starts the Apple Human Interface Guidelines localized UI gate for German (`de`) using the chat-observed evidence Karoline provided on 2026-05-18.

The gate does not pass. The available evidence is incomplete, and the TestFlight Build Info screenshot shows English copy in the German Today surface.

## Evidence Reviewed

- Chat-observed Today screenshot from Karoline showing German UI on the Today tab.
- Chat-observed Build Info screenshot from Karoline showing version `0.2.0`, build `20260517151819`, commit `f6325f3c28e9e9263eebbe76a3bbba777ff6e615`, branch `main`.
- Local source search for the visible English strings `Evening reflection` and `Close the day with one quick reflection.`

No screenshot binaries are committed in this proof directory, so this remains a doc-only gate intake.

## Gate Result

Result: **fail**

Reason: the German Today UI still displays English reflection nudge copy in the supplied TestFlight Build Info screenshot:

- `Evening reflection`
- `Close the day with one quick reflection.`

This fails the HIG localized UI gate under labels/actions, language consistency, and localized UI readiness. A German localized UI cannot be called `hig-ui-reviewed` while visible app-owned English copy remains on the scoped surface.

## Findings

### HIG-DE-001: English reflection nudge copy appears in German Today UI

Severity: blocking

Observed in Karoline's TestFlight Build Info screenshot: the German Today header background contains an evening reflection nudge with English title/body copy.

Local source trace:

- `owlory_xcode/Owlory/Core/Application/TodayStore.swift` returns `EveningReflectionNudge(title:message:)` with English strings from `eveningReflectionNudge(...)`.
- `owlory_xcode/Owlory/Features/Today/TodayView.swift` displays `Text(reflectionNudge.title)` and `Text(reflectionNudge.message)`, so the runtime `String` values render verbatim.
- German localized values already exist for the related notification keys:
  - `notification.prompt.eveningReflection.title`
  - `notification.prompt.eveningReflection.body`
  - `notification.prompt.homeWrappedReflection.title`
  - `notification.prompt.homeWrappedReflection.body`

Recommended fix slice: route `TodayStore.EveningReflectionNudge` through semantic kind data and let `TodayView` format the visible strings with localized keys.

## HIG Areas

| Area | Result | Notes |
| --- | --- | --- |
| Platform consistency | unknown | Existing screenshots look iOS-native, but available evidence is not broad enough for a pass. |
| Adaptive layout | unknown | No committed screenshot set, device-size matrix, orientation check, or larger text pass. |
| Typography and Dynamic Type | not reviewed | No standard/larger accessibility text evidence. |
| Accessibility | not reviewed | No VoiceOver labels, hints, values, reading order, or contrast evidence. |
| Labels and actions | fail | Visible English reflection nudge copy appears in German UI. |
| Locale-aware formatting | partial | The observed Today date is German-formatted, but high-risk counts/plurals/dates are not fully reviewed. |
| Right-to-left behavior | not applicable | German is LTR; RTL gate applies to Arabic and other RTL locales. |

## Missing Evidence For Pass

To claim `hig-ui-reviewed` for German, provide or generate preserved evidence for:

- Build Info screenshot with complete gate fields.
- Today with no visible app-owned English strings.
- All five root tabs.
- Primary empty states and primary actions.
- High-risk date/count/plural surfaces.
- Standard text size and Larger Accessibility Text pass.
- Accessibility labels/hints/values for the reviewed surfaces.

## Status

Do not claim German `hig-ui-reviewed`.

German remains native-reviewed for language entries in the return file, but localized UI readiness is blocked on HIG-DE-001 and missing scoped UI evidence.
