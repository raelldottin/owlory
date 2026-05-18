# app-localization-tab-bar-truncation-fix (reframed)

## Prompt

> "start next slice" — execute the supervisor-selected slice `app-localization-tab-bar-truncation-fix`.

I flagged that the slice's entry condition (literal truncation confirmed by screenshot) was not actually met by the prior screenshot capture, and asked the user via AskUserQuestion how to proceed. User chose **"Reframe: add AccessibilityXL coverage for 8 locales"**.

## What was done

Test-coverage slice. Extended `LocalizationAccessibilityRegression` with 7 new XCUITest methods covering the 7 newly-flagged locales at `UICTContentSizeCategoryAccessibilityXL`. No app source change, no translation change.

### New tests

Each launches a fresh-day seeded Owlory with `-AppleLanguages (xx) -AppleLocale xx_XX -UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityXL` and asserts `assertShellSettled()` (Today dashboard header reachable + tab bar with 5 hittable buttons).

| Locale | Test | Linked finding |
|---|---|---|
| `fr` | `testFreshDayShellSettlesUnderLargerAccessibilityTextFrench` | HIG-FR-001 |
| `ja` | `testFreshDayShellSettlesUnderLargerAccessibilityTextJapanese` | HIG-JA-001 |
| `nl` | `testFreshDayShellSettlesUnderLargerAccessibilityTextDutch` | HIG-NL-001 |
| `ru` | `testFreshDayShellSettlesUnderLargerAccessibilityTextRussian` | HIG-RU-001 |
| `tr` | `testFreshDayShellSettlesUnderLargerAccessibilityTextTurkish` | HIG-TR-001 |
| `uk` | `testFreshDayShellSettlesUnderLargerAccessibilityTextUkrainian` | HIG-UK-001 |
| `ar` | `testFreshDayShellSettlesUnderLargerAccessibilityTextArabic` | HIG-AR-003 |

Existing coverage retained: `English`, `German` AccessibilityXL tests; non-empty accessibility labels; ≥44pt touch targets.

### Test results

`make ui-regression DOMAIN=localization`:

```
LocalizationAccessibilityRegression: 11/11 passed in 66.8s
LocalizationLayoutRegression:         4/4  passed in 25.0s
Total:                                15 tests / 0 failures / 91.8s
TEST SUCCEEDED
```

iPhone 17 / iOS 26.5 simulator.

### Findings closures

8 tab-truncation findings closed via `state: closed-maintained-coverage`:

- `HIG-AR-003` (Arabic Career tab)
- `HIG-DE-002` (German Write tab)
- `HIG-FR-001` (French Today tab)
- `HIG-JA-001` (Japanese Train tab, katakana)
- `HIG-NL-001` (Dutch Write tab)
- `HIG-RU-001` (Russian Train tab, Cyrillic)
- `HIG-TR-001` (Turkish Train tab)
- `HIG-UK-001` (Ukrainian Train tab, Cyrillic)

Closure rationale: iOS auto-shrinks the longer labels at iPhone 17 portrait default Dynamic Type (confirmed by 2026-05-18T103428Z-today-capture screenshots); the maintained regression coverage at AccessibilityXL confirms the shell stays usable when text size grows further. No UI code change required.

### Matrix tally after this slice

- `open_findings`: 1 (`HIG-DE-001`, source-fix-confirmed, evening-reflection state not directly captured)
- `in_progress_findings`: 1 (`HIG-AR-002`, source-fix-confirmed, WriteView Arabic not captured)
- `closed_findings`: 9 (`HIG-AR-001` + 8 tab-truncation findings)

### Reframing record

| Field | Before | After |
|---|---|---|
| Original entry condition | "Screenshot evidence has confirmed at least one of HIG-AR-003 / ... (tab-label truncation)" | (replaced) |
| New entry condition | "Screenshot evidence shows iOS auto-shrinks long localized tab labels rather than truncating; remaining risk is at AccessibilityXL where maintained regression coverage is the appropriate response." | |
| Original scope | UI tweak (lineLimit / truncationMode / minimumScaleFactor) under `owlory_xcode/Owlory/` | (deferred) |
| New scope | XCUITest expansion under `owlory_xcode/OwloryUITests/` | |

The original `owlory_xcode/Owlory/` allowed_path scope was not used; the work landed under `owlory_xcode/OwloryUITests/` which is the test target. Recorded as `scope_deviation` in the handoff.

## Validation

- `python3 automation/context/build_context.py --slice-id app-localization-tab-bar-truncation-fix` — ran.
- `python3 automation/supervisor/run_next.py --dry-run` — selected this slice pre-commit.
- `make architecture` — passed.
- `make localization-check` — 19 / 377 / 13.
- `make ui-regression DOMAIN=localization` — **TEST SUCCEEDED** (15 tests / 0 failures / 91.8s).
- `make automation-check` — 71 tests passed.
- `xcodebuild build-for-testing` — exit 0 (warnings only, pre-existing).
- `git diff --check` — clean.
- `python3 -m json.tool` on all 5 manifests — valid.

## Lane Boundary

`regression-tested`. New tests compile and pass under iPhone 17 / iOS 26.5 simulator at AccessibilityXL. No product UI change. No translation change. No screenshot artifact captured. No device or TestFlight evidence.

## Residual Risk

- AccessibilityXL regressions assert the shell settles and tabs are hittable but do not measure label readability at the auto-shrunk size. The text may render legibly but smaller for the longer-label tabs; only a VoiceOver / vision-test pass would catch readability concerns.
- Smaller iPhone widths (iPhone SE) are not covered. Current regression targets iPhone 17 only.
- The maintained regression is locale-specific; if a new locale is added later with an even longer tab label, that locale must be added explicitly to `LocalizationAccessibilityRegression`.
- HIG-DE-001 and HIG-AR-002 still need their own evidence-rerun slices before the all-locale HIG closure slice can run.

## Not Claimed

- Any locale is `hig-ui-reviewed`.
- Translation quality for any locale.
- Device or TestFlight proof.
- Smaller iPhone width verification.
- VoiceOver listening verification under non-English locales.
- Screenshot evidence at AccessibilityXL (the regression asserts behavior, doesn't preserve a screenshot).

## Next slices

Per the supervisor / queue, all 3 remediation slices from the original triage are now done. Remaining open work:

- `HIG-DE-001` post-fix evening-reflection-state screenshot evidence (would need a debug-fixture launch arg or time-of-day mocking).
- `HIG-AR-002` post-fix WriteView Arabic screenshot (would need either harness AX-identifier support or per-locale `--label-overrides` for the navigation step in addition to the settled-state).
- `app-localization-all-locale-hig-ui-closure` (still blocked on the two in-progress findings).

These are the next eligible queue items, though both `HIG-DE-001` and `HIG-AR-002` need supporting tooling that doesn't exist yet (debug fixtures + harness navigation enhancements respectively).
