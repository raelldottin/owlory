# app-localization-continue-row-subtitle-routing

## Prompt

> "start continue-row-subtitle-routing. Yes — confirm the structural approach before editing. For `app-localization-continue-row-subtitle-routing`, do **not** solve it by putting `String(localized:)` or `NSLocalizedString` inside `TodayContinueSourceComposer` ... Use the structural path: Domain/Application emits semantic subtitle intent. Features/Today formats that intent into localized display copy."

## What was done

Structural refactor following the user's prescribed pattern:

```
Application emits semantic subtitle intent (enum).
Features/Today formats it into localized display copy.
```

### New type

`Core/Application/ContinueSubtitleKind.swift`:

```swift
public enum ContinueSubtitleKind: String, Equatable, Codable, CaseIterable, Sendable {
    case focus
    case dueToday
    case carriedForward
    case protocolRun
    case active
    case inProgress
}
```

### Cascading replacements

| File | Change |
|---|---|
| `Core/Application/TodayContinueSourceComposer.swift` | `Step.reason: String` → `Step.subtitleKind: ContinueSubtitleKind`; `Candidate.reason` → `Candidate.subtitleKind` |
| `Core/Application/TodayContinueItemAssembler.swift` | passes `subtitleKind: candidate.subtitleKind` to ContinueItem |
| `Core/Application/TodayContinuationRules.swift` | `ContinueItem.reason: String` → `ContinueItem.subtitleKind: ContinueSubtitleKind` (constructor signature updated) |
| `Features/Today/TodayView.swift` | new `continueSubtitleLabel(for:) -> String` helper; `Text(item.reason)` → `Text(continueSubtitleLabel(for: item.subtitleKind))`; removed the now-unreachable `if !item.reason.isEmpty` check (enum is non-optional) |

### Boundary restored

Before: `Core/Application/TodayContinueSourceComposer.swift` line 12-27 owned English presentation copy ("Focus", "Due today", "Carried forward", "Protocol run", "Active", "In progress"). This violated `docs/workflows/localization-dynamic-formatting.md` ("Application coordinates runtime-owned messages" — but only when it also owns the scheduling side effect, which it doesn't here).

After: Application emits semantic enum cases. Features/Today owns the localized String. Boundary respected.

### Test updates

9 assertions across 4 test files now assert on the semantic enum instead of English strings:

| File | Change |
|---|---|
| `TodayContinueSourceComposerTests.swift:78-84` | `\.reason` → `\.subtitleKind`; list of strings → list of enum cases |
| `TodayContinueSourceComposerTests.swift:164` | `reason == "Focus"` → `subtitleKind == .focus` |
| `TodayContinueItemAssemblerTests.swift:30` | `reason == "Carried forward"` → `subtitleKind == .carriedForward` |
| `TodayContinuationRulesTests.swift:41` | same fix |
| `TodayStoreTests.swift:511, 551, 586, 626, 720` | constructor-style fixtures: `reason: "X"` → `subtitleKind: .x` |

Note: TodayStoreTests lines 763-768 use `TodayStore.FocusSuggestionCandidate` (different type, different bypass class — out of scope, separate slice `app-localization-focus-suggestion-reason-routing`).

### 6 new keys × 19 locales

| Key | English | German |
|---|---|---|
| `today.continue.subtitle.focus` | Focus | Fokus |
| `today.continue.subtitle.dueToday` | Due today | Heute fällig |
| `today.continue.subtitle.carriedForward` | Carried forward | Übertragen |
| `today.continue.subtitle.protocolRun` | Protocol run | Protokollausführung |
| `today.continue.subtitle.active` | Active | Aktiv |
| `today.continue.subtitle.inProgress` | In progress | Im Gange |

### Xcode project wiring

- `A092` build file ref (main target) + `B097` build file ref (test target) both reference `A192` (file reference)
- `A192` added to the Application group children list

## Files Edited (33)

- 1 new Swift file (ContinueSubtitleKind.swift)
- 5 modified Swift files (composer, assembler, rules, view, project.pbxproj)
- 4 modified test files
- 19 × Localizable.strings (6 keys each)
- queue/handoff/session/INDEX entries

## Validation

- `make architecture` — passed.
- `make localization-check` — 19 / **351** / 13 (up from 345).
- `./Tools/validate.sh localization` — passed.
- `make test-domain DOMAIN=today` — TEST SUCCEEDED.
- `make automation-check` — 57/57.
- `xcodebuild build -quiet -destination 'generic/platform=iOS Simulator'` — exit 0.
- `git diff --check` — clean.

## Lane Boundary

`build-tested + domain-tested`. Build is clean, parity holds, today domain tests pass with enum assertions. Architecture boundary is restored (presentation copy removed from Application).

## Residual Risk

- Other Core/Domain and Core/Application helpers still own English copy (FocusSuggestionRules, CalibrationRules, ReadinessRules, PatternNudgeRules). Five queued slices cover those.
- Tests now assert on enum cases. Adding a new ContinueSubtitleKind case without a matching localized key would not fail the build — the localization lookup would silently fall back to the raw key string.
- 6 new keys are LLM-drafted by claude-opus-4-7. "Im Gange" for German "In progress" is correct but conversational.
- Per-locale review return files are now 21 entries stale per locale since 2026-05-16 (9 anchors + 6 header greeting + 6 subtitle). Run `python3 Tools/localization-return-files-refresh.py --apply` to refresh.
- Native review still outstanding for every locale.

## What remains queued

4 of 7 helper-generated-copy follow-ups still queued:

| Priority | Slice | Approach |
|---:|---|---|
| 83 | `app-localization-calibration-rules-helper-copy-routing` | structural |
| 82 | `app-localization-readiness-rules-helper-copy-routing` | structural |
| 81 | `app-localization-pattern-nudge-rules-helper-copy-routing` | structural |
| 80 | `app-localization-focus-suggestion-reason-routing` | structural |
