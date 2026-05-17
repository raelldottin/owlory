# app-localization-focus-suggestion-reason-routing

## Prompt

> "Start the supervisor-selected slice: app-localization-focus-suggestion-reason-routing ... Do: move FocusSuggestionRules reason copy out of Core/Domain ... introduce semantic enum/value type if needed ... update tests to assert semantic values, not English strings ... add keys across all 19 locales ... Do not: wrap NSLocalizedString inside Core/Domain ... rewrite suggestion logic ... change scoring/selection behavior ... bundle other rules ... claim native review."

## What was done

Structural refactor following the pattern established by `app-localization-continue-row-subtitle-routing`:

```
Core/Domain emits semantic Reason struct (Completion + Timing + ReadinessContext).
Features/Today formats it into localized display copy.
```

### New type in FocusSuggestionRules

```swift
struct Reason: Equatable, Codable, Sendable {
    enum ReadinessContext: String, Equatable, Codable, Sendable, CaseIterable {
        case low, steady, high
    }
    enum Completion: Equatable, Codable, Sendable {
        case similarReadinessHistory(count: Int, context: ReadinessContext)
        case recentCompletions(count: Int)
    }
    enum Timing: Equatable, Codable, Sendable {
        case predictedTime(secondsSinceMidnight: TimeInterval)
        case lastCompletion(daysAgo: Int)
    }
    let completion: Completion
    let timing: Timing?
}
```

### Cascading replacements

| File | Change |
|---|---|
| `Core/Domain/FocusSuggestionRules.swift` | `Candidate.reason: String = ""` → `Reason? = nil`; `Draft.reason: String` → `Reason?`; `static func reason(...)` returns `Reason`; removed `countPhrase`, `dayDistancePhrase`, `timeOfDayString`, and `ReadinessBand.phrase` (all English presentation); added private `ReadinessBand.reasonContext` mapping |
| `Features/Today/TodayView.swift` | `Text(draft.reason)` → `if let reason = draft.reason { Text(focusSuggestionReasonText(for: reason)) }`; added `focusSuggestionReasonText(for:)` + helpers `focusSuggestionCountPhrase`, `focusSuggestionDayPhrase`, `focusSuggestionBandPhrase`; cache-key signature uses `String(describing: $0.reason)` for stability |
| `OwloryCoreTests/FocusSuggestionRulesTests.swift` | 2 string assertions → semantic enum pattern matches |
| `OwloryCoreTests/TodayStoreTests.swift` | 2 in-test string assertions → semantic enum; 6 fixture sites `reason: "..."` → `reason: nil` |

### Boundary restored

Before: `Core/Domain/FocusSuggestionRules.swift` owned English copy — "low-readiness", "Usually completed around 7 PM", "%d days ago", "once" — embedded directly in the suggestion data structure that Application/Features both consumed.

After: Domain emits semantic enum cases with raw signal data (counts, seconds-since-midnight, days-ago). Features/Today formats with locale-aware `Date.FormatStyle` and 12 localized keys. Boundary respected — Domain layer has zero presentation copy left in the reason pipeline.

### 12 new keys × 19 locales

| Key | English |
|---|---|
| `today.focus.suggestion.completion.similarReadinessHistory` | You finished this %1$@ on %2$@ check-in days. |
| `today.focus.suggestion.completion.recentCompletions` | You completed this %@ recently. |
| `today.focus.suggestion.timing.predictedTime` | Usually completed around %@. |
| `today.focus.suggestion.timing.lastCompletion` | Last done %@. |
| `today.focus.suggestion.countPhrase.once` | once |
| `today.focus.suggestion.countPhrase.times` | %d times |
| `today.focus.suggestion.dayPhrase.today` | today |
| `today.focus.suggestion.dayPhrase.yesterday` | yesterday |
| `today.focus.suggestion.dayPhrase.daysAgo` | %d days ago |
| `today.focus.suggestion.band.low` | low-readiness |
| `today.focus.suggestion.band.steady` | steady |
| `today.focus.suggestion.band.high` | high-readiness |

## Files Edited (23)

- 1 modified Core/Domain Swift (FocusSuggestionRules.swift)
- 1 modified Features Swift (TodayView.swift) — added 4 private helpers
- 2 modified test files
- 19 × Localizable.strings (12 keys each)

No project.pbxproj change needed — the new `Reason` type is nested inside existing `FocusSuggestionRules.swift`.

## Validation

- `make architecture` — passed.
- `make localization-check` — 19 / **363** / 13 (up from 351, +12 today.focus.suggestion.* keys).
- `./Tools/validate.sh localization` — passed.
- `make test-domain DOMAIN=today` — TEST SUCCEEDED.
- `make automation-check` — 57/57.
- `xcodebuild build` — exit 0 (warnings only, pre-existing).
- `git diff --check` — clean.

## Lane Boundary

`build-tested + domain-tested`. Build is clean, parity holds, today domain tests pass with enum assertions. Architecture boundary restored — presentation copy removed from Core/Domain reason pipeline.

## Residual Risk

- Translations remain LLM-drafted by claude-opus-4-7 (status: `needs-layout-check`). Native review still queued under `app-localization-native-review-intake`.
- Per-locale review return files are now 33 entries stale per locale (21 prior + 12 new). Run `python3 Tools/localization-return-files-refresh.py --apply` when next syncing.
- Adding a new `Completion` or `Timing` enum case without matching localized keys would not fail build — lookup would silently fall back to raw key string.
- Predicted-time format uses `Date.FormatStyle` (`time: .shortened`), which produces locale-default time formatting (e.g., "7:00 PM" vs "19:00"). Layout review needed for very long locale strings (ar/de/ru) once native review begins.
- `String(describing: Reason?)` is used as part of focus-suggestion-cache stability key. Stable but verbose; if Swift reflection output ever changes, cache invalidation pattern may shift. Acceptable for now since `Reason` is `Equatable`.

## What remains queued (helper-copy followups)

3 of 7 helper-generated-copy follow-ups still queued:

| Priority | Slice | Approach |
|---:|---|---|
| 83 | `app-localization-calibration-rules-helper-copy-routing` | structural |
| 82 | `app-localization-readiness-rules-helper-copy-routing` | structural |
| 81 | `app-localization-pattern-nudge-rules-helper-copy-routing` | structural |
