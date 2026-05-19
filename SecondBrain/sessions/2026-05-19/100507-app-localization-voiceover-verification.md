# app-localization-voiceover-verification

## Prompt

> "start next slice" — execute the supervisor-selected slice `app-localization-voiceover-verification`.

## What was done

Test-coverage slice. Picked path (a) from the slice's two options: extend `LocalizationAccessibilityRegression` with non-empty AX-label assertions under representative non-English locales. No app source change, no translation change, no manual VoiceOver protocol added.

### XCUITest changes

`owlory_xcode/OwloryUITests/OwloryUITests.swift`:

- Refactored existing `testRootTabsExposeNonEmptyAccessibilityLabelsUnderEnglish` to delegate to a new private `assertRootTabsExposeNonEmptyAccessibilityLabels(language:, locale:)` helper. No semantic change for English.
- Added 4 new test methods using the same helper:
  - `testRootTabsExposeNonEmptyAccessibilityLabelsUnderGerman`
  - `testRootTabsExposeNonEmptyAccessibilityLabelsUnderArabic`
  - `testRootTabsExposeNonEmptyAccessibilityLabelsUnderJapanese`
  - `testRootTabsExposeNonEmptyAccessibilityLabelsUnderRussian`

Each launches Owlory in the target locale, waits for the root tab bar, asserts exactly 5 hittable buttons, and asserts every button reports a non-empty `XCUIElement.label`. XCUITest reads `.label` which is the value VoiceOver announces, so a non-empty assertion guards the announcement contract without requiring a real VoiceOver-listening human pass.

### Why these 5 locales

| Locale | Rationale |
|---|---|
| `en` | Source baseline (existing) |
| `de` | Native-reviewed cross-cut |
| `ar` | RTL with translated AX labels |
| `ja` | CJK katakana |
| `ru` | Long Cyrillic |

Together they cover the four bucket-gate flavours plus the source baseline. Adding more locales multiplies runtime (~6s per test on iPhone 17 / iOS 26.5); the assertion shape is locale-agnostic so additional value tapers off after one representative per bucket. The 13 uncovered non-English locales (`nl`, `fr`, `it`, `ko`, `nb`, `pt`, `pt-BR`, `es`, `sv`, `zh-Hans`, `zh-Hant`, `tr`, `uk`, `vi`) can be added trivially if the need surfaces.

### Test results

```
LocalizationAccessibilityRegression: 15/15 passed
LocalizationLayoutRegression:         4/4  passed
Total:                                19 tests / 0 failures / 111.9s
TEST SUCCEEDED
```

iPhone 17 / iOS 26.5 simulator. Was 11 tests / 0 failures / ~92s before this slice.

### Proof manifest

`automation/proofs/app-localization-voiceover-verification/manifest.json` documents:

- The 5 verification methods.
- The covered locale set (en/de/ar/ja/ru) plus rationale.
- The 13 uncovered non-English locales.
- Explicit `not_claimed` block: no real VoiceOver-listening pass; non-tab-bar surfaces uncovered; labels not asserted idiomatic, only non-empty.
- Follow-up recommendations if non-tab-bar AX-label coverage or a VoiceOver-listening pass is ever queued.

### Doc update

`docs/workflows/localization-hig-ui-completion.md` — `LocalizationAccessibilityRegression` bullet now lists the VoiceOver-coverage locale set and points at the new proof directory.

## Validation

- `python3 automation/context/build_context.py --slice-id app-localization-voiceover-verification` — ran.
- `python3 automation/supervisor/run_next.py --dry-run` — selected this slice pre-commit.
- `make architecture` — passed.
- `make localization-check` — 19 / 377 / 13.
- `make ui-regression DOMAIN=localization` — **TEST SUCCEEDED** (19 tests / 0 failures / 111.9s).
- `make automation-check` — passed (drift no-drift + 93 unittests OK).
- `git diff --check` — clean.
- `python3 -m json.tool automation/proofs/app-localization-voiceover-verification/manifest.json` — valid.

## Lane Boundary

`regression-tested`. New XCUITest assertions land in the maintained `DOMAIN=localization` regression filter. No app source change, no translation change, no real VoiceOver-listening evidence.

## Residual Risk

- iPad and macOS VoiceOver behavior is not covered (iPhone 17 simulator only).
- 13 non-English locales are not covered at this proof level. Adding them is cheap (one test method each) when the need surfaces.
- `XCUIElement.label` falls back to the visible-text label when no explicit `accessibilityLabel(...)` is set. The non-empty assertion catches the empty case but does not distinguish "natural fallback" from "explicit override that happens to say the same thing."
- A real VoiceOver-listening human pass is a separate proof track. Per the 2026-05-18 policy, neither it nor TestFlight HIG is required for `hig-ui-reviewed`; the regression here records the maintained automated bar.

## Not Claimed

- A real VoiceOver-listening human pass occurred.
- Non-tab-bar accessibility labels are covered (Today rows, Continue items, train sessions, write notes, etc.).
- The labels are idiomatic VoiceOver phrasing (only that they are non-empty).
- AccessibilityXL Dynamic Type + VoiceOver interaction is verified.
- The 13 uncovered non-English locales have non-empty-AX-label regression coverage.

## Next slice

Per Owlory's convention (lower priority number = picked first), the supervisor will pick whichever queued slice has the lowest priority number next. Remaining queued: `app-localization-smaller-width-accessibility-regression` (pri 65) and `app-reminders-cancel-pending-on-item-completion` (pri 90); plus blocked `device-verified` (50) and `testflight-verified` (49).
