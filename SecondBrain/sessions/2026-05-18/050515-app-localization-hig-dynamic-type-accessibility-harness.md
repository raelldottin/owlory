# app-localization-hig-dynamic-type-accessibility-harness

## Prompt

> "start next slice" — execute the supervisor-selected slice `app-localization-hig-dynamic-type-accessibility-harness`, which adds maintained representative checks for localized accessibility text presence, root tab reachability, Dynamic Type/accessibility text-size launch stability, and touch target regressions.

## What was done

Automation/test slice. Extended the existing `OwloryUITests` target with a new XCUITest class alongside `LocalizationLayoutRegression`. No product UI rewritten, no translations touched, no new accessibility identifiers added (the slice notes explicitly allowed adding identifiers only where needed; the existing `today.dashboard.header` plus tab-bar reachability cover the cases).

### New XCUITest class

`final class LocalizationAccessibilityRegression: XCTestCase` with 4 maintained representative tests:

| Test | Locale | Launch arguments | Assertion |
|---|---|---|---|
| `testFreshDayShellSettlesUnderLargerAccessibilityTextEnglish` | `en_US` | `--owlory-ui-seed-fresh-day` + `-UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityXL` | Today shell settles, tab bar present with 5 hittable buttons |
| `testFreshDayShellSettlesUnderLargerAccessibilityTextGerman` | `de_DE` | same + `-AppleLanguages (de)` | Same — German long compounds must not break the shell at AccessibilityXL |
| `testRootTabsExposeNonEmptyAccessibilityLabelsUnderEnglish` | `en_US` | standard fresh-day | Each of 5 tab buttons has a non-empty `.label` |
| `testRootTabsRemainAt44ptTouchTargetsUnderEnglish` | `en_US` | standard fresh-day | Each of 5 tab buttons has `.frame.width` ≥ 44pt and `.frame.height` ≥ 44pt per Apple HIG |

The Dynamic Type stability tests share an `assertShellSettled()` helper that re-asserts the dashboard header + 5 hittable tab buttons under any locale + content-size combination.

### Makefile wiring

| Target | Change |
|---|---|
| `ui-regression` default case | Append `-only-testing:OwloryUITests/LocalizationAccessibilityRegression` to the all-classes selection |
| `ui-regression DOMAIN=localization` | Append the new class; relabel to "Localization layout + accessibility regression (en, de, ar, zh-Hans launch-shell + Dynamic Type accessibility XL + tab label/touch-target checks)" |

### Docs

- `docs/workflows/localization-hig-ui-completion.md` — new "Dynamic Type + Accessibility Regression" section between Evidence Matrix and Multisurface Screenshot Harness, listing the two regression classes and explicit non-claims.
- `docs/workflows/ui-testing-hygiene.md` — replaced the "queued but not implemented" Batch 7 bullet with a current-state bullet describing the two-class `DOMAIN=localization` filter.

## Validation

- `python3 automation/context/build_context.py --slice-id app-localization-hig-dynamic-type-accessibility-harness` — ran.
- `python3 automation/supervisor/run_next.py --dry-run` — selected this slice pre-commit.
- `make architecture` — passed.
- `make localization-check` — 19 / 377 / 13.
- `make ui-regression DOMAIN=localization` — **TEST SUCCEEDED** (8 tests / 0 failures / 48s on iPhone 17 / iOS 26.5 simulator). 4 layout cases + 4 accessibility cases.
- `make automation-check` — 71 tests passed.
- `git diff --check` — clean.

## Lane Boundary

`regression-tested`. New XCUITest class compiles and passes under the standard iPhone 17 / iOS 26.5 simulator destination. No product or translation changes; pure test harness expansion.

## Residual Risk

- Dynamic Type stability is checked for `en` and `de` only. Long-script and CJK locales rely on `LocalizationLayoutRegression` for shell settle but not yet for accessibility XL text-size stability. Adding more locale × content-size combinations is queued under per-bucket HIG gate slices.
- Accessibility-label presence is asserted only for the 5 root tab bar buttons. Surfaces such as Today rows, Continue items, Train sessions, and Write notes are not yet covered.
- Touch target inspection uses `XCUIElement.frame.size`, which matches what Apple HIG documents but does not account for hidden hit regions that SwiftUI may expand beyond the visible frame.
- These regressions run on the iOS Simulator only. Physical device Dynamic Type and accessibility behavior is not proven by this slice.

## Not Claimed

- Any locale is `hig-ui-reviewed`.
- Translation quality at any text size.
- Full HIG layout correctness for the 17 LLM-drafted locales.
- Device or TestFlight Dynamic Type behavior.
- Every accessibility label is idiomatic in every locale (only presence and non-emptiness are asserted).
- Touch target compliance for non-tab-bar controls.

## Next slice in the HIG ladder

Per the queue, downstream work is the per-bucket HIG gate slices (`app-localization-hig-gate-source-english`, `app-localization-hig-gate-bucket-rtl`, `app-localization-hig-gate-bucket-cjk`, `app-localization-hig-gate-bucket-long-script`, `app-localization-hig-gate-bucket-remaining-ltr`). Each gate consumes both the multisurface screenshot harness and this accessibility regression, then appends findings into the all-locale HIG evidence matrix.
