# Localization Helper-Generated Copy Audit

Audit-first inventory of `Core/Domain/*` and `Core/Application/*` helpers that return English text directly to view layers, bypassing `Localizable.strings`.

**Source observation:** TestFlight/manual testing on 2026-05-16 (German app language) showed the Today / Train / Write tabs still rendering English copy in the pipeline nudge, training consistency banner, readiness nudge, domain nudge, Focus suggestion reason, and Continue row subtitles.

**Scan date:** 2026-05-16.

**Doc-only.** Catalogs the bypass surface and queues narrow follow-up slices. Does not fix strings.

## Why the prior audit missed these

The 2026-05-16 visible-string bypass audit classified `Text(nudge.message)`, `Text(headerGreeting)`, `Text(draft.reason)` as `ok-localized-display-helper` based on a substring heuristic — the variable names looked like already-localized helpers. They are not: the upstream helpers in `Core/Domain/*` and `Core/Application/*` build English copy with `let message = "..."` directly.

Action item for future audits: an `ok-localized-display-helper` classification should be confirmed by inspecting the helper's body, not just by name. A name like `nudge.message` is suggestive but not load-bearing.

## Findings

### `Core/Domain/CalibrationRules.swift`

| Line | Helper | English source |
|---:|---|---|
| 87 | `writingPipelineNudge.message` | `"You have \(captureCount) captures waiting. Try developing one into a source note."` |
| 99 | `trainingConsistencySummary.message` (≥ 80%) | `"Strong consistency — \(pct)% of sessions completed or adapted."` |
| 101 | `trainingConsistencySummary.message` (≥ 60%) | `"Solid rhythm — \(pct)% follow-through this period."` |
| 103 | `trainingConsistencySummary.message` (< 60%) | `"Training follow-through at \(pct)%. Consider fewer, more committed sessions."` |

### `Core/Domain/ReadinessRules.swift`

| Line | Helper | English source |
|---:|---|---|
| 23 | readinessNudge.message | `"Tough signals today. Focus on one thing that matters and let the rest go."` |
| 31 | readinessNudge.message | `"Low reserves today. Keep the plan light — minimum viable wins."` |
| 39 | readinessNudge.message | `"Low energy today. Favor easy wins over deep work."` |
| 47 | readinessNudge.message | `"Sleep was rough. You may have less focus than you think."` |
| 55 | readinessNudge.message | `"Rough mood today. Be honest about what you can carry."` |
| 63 | readinessNudge.message | `"Strong signals today. Good day for deep work or hard problems."` |
| 71 | readinessNudge.message | `"Solid day. You have capacity — use it on what matters most."` |
| 79 | readinessNudge.message | `"Steady day. Trust the plan."` |
| 86 | readinessNudge.message | `"Decent day ahead. Stay focused on your priorities."` |

### `Core/Domain/PatternNudgeRules.swift`

| Line | Helper | English source |
|---:|---|---|
| 31 | domainNudge.message | `"\(focusBalanceTitle(for: first)) hasn't shown up in Focus lately."` |
| 37–40 | `focusBalanceTitle(for:)` | `"Training" / "Write" / "Career" / "Home"` (raw LifeDomain → English) |

### `Core/Domain/FocusSuggestionRules.swift`

| Line | Helper | English source |
|---:|---|---|
| 348–375 | `reason(for:todayBand:todayStart:calendar:)` | Multiple fragments concatenated: `"You finished this %@ on %@ check-in days."`, `"You completed this %@ recently."`, `"Usually completed around %@."`, `"Last done %@."` |
| 377–382 | `countPhrase(_:)` | `"once"` / `"\(count) times"` |
| 384+ | `dayDistancePhrase(_:)` | `"today"` / `"yesterday"` / `"\(daysAgo) days ago"` etc. |
| (related) | `ReadinessBand.phrase` | `"low-readiness"` / `"high-readiness"` / `"moderate-readiness"` (need to verify exact strings) |

### `Core/Application/TodayContinueSourceComposer.swift`

| Line | Helper | English source |
|---:|---|---|
| 17 | continue row subtitle | `"Due today"` |
| 21 | continue row subtitle | `"Protocol run"` |
| 25 | continue row subtitle | `"In progress"` |

### `Features/Today/TodayView.swift`

| Line | Helper | English source |
|---:|---|---|
| 155 | `headerGreeting` (compact-header branch) | `"Day in progress"` / `"In progress"` |
| 194 | readinessRow anchors | `("Low", "Okay", "High")` |
| 197 | readinessRow anchors | `("Rough", "Steady", "Good")` |
| 200 | readinessRow anchors | `("Poor", "Fine", "Great")` |
| 1579 | readinessRow anchors (PreviousDay) | `("Low", "Okay", "High")` |

(`headerGreeting` has other branches with `enhancedNudge.title` and `entryState`-derived strings; those need to be traced individually.)

### `Features/Train/TrainView.swift`

| Line | Helper | English source |
|---:|---|---|
| ~180 | `TrainingReadinessScaleRow` `anchors:` tuple | `("Low", "Okay", "High")` (passed at call site) |

## Total surface

Roughly **30+ English copy fragments** across **6 source files**, all rendered to non-English users as English.

## Architecture note

`docs/workflows/localization-dynamic-formatting.md` states:

> `Core/Domain`: enums, IDs, counts, dates, windows, statuses, and other semantic values. No SwiftUI, UserNotifications, presentation copy ownership, or localized string construction.

`CalibrationRules`, `ReadinessRules`, `PatternNudgeRules`, and `FocusSuggestionRules` are currently in `Core/Domain/` and own user-facing English copy. This is both:

- A localization bypass (the immediate visible bug).
- A boundary violation (presentation copy in Domain).

Two valid fix approaches:

1. **In-place fix (smaller diff, preserves layering violation):** wrap each return value in `NSLocalizedString` / `String.localizedStringWithFormat` and add the keys to `Localizable.strings`. The Domain layer continues to own the copy, but it routes through localization. The architecture violation remains.

2. **Refactor (larger diff, restores architecture):** move presentation copy out of `Core/Domain/*` into UI-adjacent helpers (`Core/Application/*` or `Features/*`), and have the domain helpers return semantic enums (e.g., `ReadinessNudgeKind` instead of `String message`). The Feature layer maps enum → localized String.

Approach 2 is what the dynamic-formatting workflow prescribes. Approach 1 is faster but stacks tech debt.

## Recommended follow-up slices (queued)

Each scoped to one source file. Each picks approach (1) or (2) per its own architecture sensitivity.

| Slice | Scope | Approach hint |
|---|---|---|
| `app-localization-calibration-rules-helper-copy-routing` | CalibrationRules (4 strings) | (2) — move writingPipelineNudge + trainingConsistencySummary copy to Features/ |
| `app-localization-readiness-rules-helper-copy-routing` | ReadinessRules (9 strings) | (2) — move 9 readiness nudge messages to Features/ via semantic enum |
| `app-localization-pattern-nudge-rules-helper-copy-routing` | PatternNudgeRules (1 message + 4 focusBalanceTitle) | (2) — use existing `LifeDomain.localizedDisplayName` |
| `app-localization-focus-suggestion-reason-routing` | FocusSuggestionRules.reason() (multi-fragment) | (2) — return structured reason data, format in Features/ |
| `app-localization-continue-row-subtitle-routing` | TodayContinueSourceComposer (3 strings) | (2) — return enum, map in Features/ |
| `app-localization-today-header-greeting-routing` | TodayView.headerGreeting (multiple branches) | (1) — wrap returns in NSLocalizedString in-file |
| `app-localization-readiness-anchors-routing` | Today + Train anchor tuples (3 sets) | (1) — replace hardcoded tuples with NSLocalizedString-backed values |

## Out of scope

- Translating the new keys (LLM-drafted, follows existing pattern).
- Native review of any locale. `app-localization-native-review-intake` remains blocked.
- Restoring `Core/Domain` boundary purity globally — only the surfaces touched by each follow-up.
- Other helpers not yet observed in TestFlight/manual testing. A deeper scan of `Core/Application/*` for `return "..."` user-facing English may be warranted as a separate audit follow-up.

## What this audit does NOT prove

- That every helper-generated visible string was found. Only the surfaces reachable by the 4 observed screenshots (Schreiben, Training, Today) are confirmed. Other screens may have additional bypasses.
- That the recommended approach (1 vs 2) is the right call per slice — the follow-up slice owners should weigh architecture impact.
- Translation quality for any of the future keys. Native review remains the only path to a quality claim.
