# app-localization-helper-generated-copy-audit

## Prompt

> 4 TestFlight/manual screenshots (2026-05-16, German app language) showing visible English copy on the Schreiben (Write), Training, and Heute (Today) tabs. The prior NLS routing slices had been completed but the actual visible bug remains.

## Why the prior NLS audit missed this

The 2026-05-16 visible-string bypass audit had a category `ok-localized-display-helper` that classified `Text(varName)` as already-safe when `varName` matched a substring list like `.localizedDisplayName`, `.message`, `nudge.`, `readinessSummaryLabel`, `scheduleHelpText`, etc.

The heuristic assumed that if a variable name *looked* like a localized helper, the upstream construction was localized. **That assumption was wrong** for these helpers:

- `nudge.message` — built with `let message = "..."` in CalibrationRules / ReadinessRules / PatternNudgeRules
- `draft.reason` — built with `"You finished this %@ ..."` fragments in FocusSuggestionRules
- `headerGreeting` — branches return raw `"Day in progress"` / `"In progress"`
- `continueRowSubtitle`-equivalent — TodayContinueSourceComposer returns raw `"Due today"` / `"Protocol run"` / `"In progress"`

**Lesson:** `ok-localized-display-helper` should require body inspection, not just name matching.

## Findings (~30+ English strings across 6 files)

### `Core/Domain/CalibrationRules.swift` — 4 strings

- `writingPipelineNudge.message` at line 87: `"You have %d captures waiting. Try developing one into a source note."`
- `trainingConsistencySummary.message` at lines 99/101/103: 3 percent-aware variants.

### `Core/Domain/ReadinessRules.swift` — 9 strings

- 9 readiness-band-aware nudge messages at lines 23/31/39/47/55/63/71/79/86.

### `Core/Domain/PatternNudgeRules.swift` — 5 strings

- `domainNudge.message` at line 31 with `%@` interpolation.
- `focusBalanceTitle(for:)` returning `"Training"` / `"Write"` / `"Career"` / `"Home"` — duplicates existing `LifeDomain.localizedDisplayName`.

### `Core/Domain/FocusSuggestionRules.swift` — multi-fragment

- `reason(for:...)` builds multi-fragment English copy.
- `countPhrase(_:)` returns `"once"` / `"%d times"`.
- `dayDistancePhrase(_:)` returns `"today"` / `"yesterday"` / `"%d days ago"`.

### `Core/Application/TodayContinueSourceComposer.swift` — 3 strings

- `"Due today"` / `"Protocol run"` / `"In progress"`.

### `Features/Today/TodayView.swift` — multiple

- `headerGreeting` line 155: `"Day in progress"` / `"In progress"`.
- Readiness anchors lines 194-200: `("Low", "Okay", "High")`, `("Rough", "Steady", "Good")`, `("Poor", "Fine", "Great")`.
- Additional anchor tuple at line 1579 (PreviousDay).

### `Features/Train/TrainView.swift` — anchor tuple

- `TrainingReadinessScaleRow` anchors `("Low", "Okay", "High")` at the call site.

## Architecture concern

`docs/workflows/localization-dynamic-formatting.md` explicitly forbids `Core/Domain/*` from owning UI copy. Currently `CalibrationRules`, `ReadinessRules`, `PatternNudgeRules`, and `FocusSuggestionRules` all do. Two valid fix approaches per follow-up slice:

1. **In-place wrap** (`NSLocalizedString` at the existing return site). Preserves the layering violation.
2. **Structural refactor** — Domain returns semantic enums, Features formats into localized String. Restores boundary.

The audit doc recommends approach (2) for Domain-located helpers and approach (1) for Features-located ones.

## Files Edited

- `docs/workflows/localization-helper-generated-copy-audit.md` (new) — the catalog
- `automation/queue/slices.json` — audit slice `done`, 7 follow-ups `queued`
- `automation/handoffs/20260517T020723Z-app-localization-helper-generated-copy-audit.json` (new)
- `SecondBrain/INDEX.md`
- `SecondBrain/sessions/2026-05-17/020723-app-localization-helper-generated-copy-audit.md` (this note)

## 7 follow-up slices queued

| Priority | Slice | Source | Approach hint |
|---:|---|---|---|
| 83 | `app-localization-calibration-rules-helper-copy-routing` | CalibrationRules (4) | structural |
| 82 | `app-localization-readiness-rules-helper-copy-routing` | ReadinessRules (9) | structural |
| 81 | `app-localization-pattern-nudge-rules-helper-copy-routing` | PatternNudgeRules (1 + 4) | structural + reuse LifeDomain.localizedDisplayName |
| 80 | `app-localization-focus-suggestion-reason-routing` | FocusSuggestionRules (multi-fragment) | structural |
| 79 | `app-localization-continue-row-subtitle-routing` | TodayContinueSourceComposer (3) | structural |
| 78 | `app-localization-today-header-greeting-routing` | TodayView.headerGreeting | in-place |
| 77 | `app-localization-readiness-anchors-routing` | Today + Train anchor tuples | in-place |

All depend on this audit slice. Each has narrow `allowed_paths` scoped to one source surface.

## Validation

- `make architecture` — passed.
- `make automation-check` — 57/57.
- `git diff --check` — clean.

## Lane Boundary

`doc-only`. No app resources, view code, helper code, or test code touched. No `provenance.native_reviewed` flag flipped.

## Residual Risk

- Audit scope limited to the 4 observed screenshots. Other surfaces (Career, Home, notifications, widgets) may contain additional helper-generated bypasses. A deeper scan is queued conceptually as a follow-up to this audit.
- The recommended approach split (structural for Domain, in-place for Features) is a guideline; slice owners may diverge if it makes sense.
- Native review remains outstanding for every locale and for any new keys the follow-ups add.
- Multiple follow-ups touch `Localizable.strings`; coordination needed if executed in parallel.

## Method-improvement note

Future audits classifying `Text(varName)` should automate upstream-helper body inspection rather than matching variable-name substrings. The substring heuristic is fast but produces false negatives (this case).
