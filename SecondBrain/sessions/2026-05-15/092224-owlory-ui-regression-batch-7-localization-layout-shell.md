# owlory-ui-regression-batch-7-localization-layout-shell

## Prompt

Execute the supervisor-selected slice for Batch 7 localization layout shell. The triage on the parent slice picked representative-locale launch-shell stability for en, de, ar, and zh-Hans through stable accessibility identifiers, not translated labels. Out of scope: translation quality, all-locale layout correctness, screenshot proof, device proof, TestFlight proof.

## Files Edited

- `owlory_xcode/OwloryUITests/OwloryUITests.swift` — added new `LocalizationLayoutRegression` XCUITest class with four tests (`testFreshDayShellSettlesUnderEnglishLocale`, `testFreshDayShellSettlesUnderGermanLocale`, `testFreshDayShellSettlesUnderArabicLocale`, `testFreshDayShellSettlesUnderSimplifiedChineseLocale`). Each launches with `--owlory-ui-testing`, `--owlory-ui-seed-fresh-day`, `-AppleLanguages "(<lang>)"`, `-AppleLocale <locale>` and asserts (a) `today.dashboard.header` settles via `waitForExistence(timeout: 15)` and (b) `app.tabBars.firstMatch` has exactly 5 buttons that each `exists` and `isHittable`.
- `Makefile` — extended `ui-regression`: bare invocation now runs all six regression classes (added `LocalizationLayoutRegression`); new `DOMAIN=localization` case scopes to `LocalizationLayoutRegression` only.
- `automation/queue/slices.json` — flipped `owlory-ui-regression-batch-7-localization-layout-shell` from `queued` to `done`. Notes field rewritten to document the implementation, the SwiftUI identifier-attachment quirk, and what is and is not proved.
- `automation/handoffs/20260515T092224Z-owlory-ui-regression-batch-7-localization-layout-shell.json` — new handoff JSON.
- `SecondBrain/INDEX.md` — index entry for this slice.
- `SecondBrain/sessions/2026-05-15/092224-owlory-ui-regression-batch-7-localization-layout-shell.md` — this note.

## Implementation Detail: SwiftUI Tab Identifier Quirk

Initial implementation added `.accessibilityIdentifier("root.tab.today")` / `.accessibilityIdentifier("root.tabView")` etc. to each `.tabItem`-modified NavigationStack in `RootTabView`. The XCUITest run revealed the SwiftUI behavior: `.accessibilityIdentifier()` on a TabView child attaches to the *active tab's content subtree*, not to the tab-bar button. The first run on Simplified Chinese found `root.tabView` and `root.tab.today` but timed out on `root.tab.train` because the inactive tab's content does not exist in the accessibility tree.

The fix was to revert the identifier additions on `RootTabView.swift` (the file is back to its `origin/main` state) and switch the test to a locale-agnostic shell signal: `app.tabBars.firstMatch` returns the tab-bar element regardless of locale, and `.buttons.count == 5` plus per-index `exists` + `isHittable` checks prove the shell did not blank or hide tabs.

This means no production code changes are retained for this slice — only the test class and the Makefile case. That is consistent with the slice's "Add stable tab/shell identifiers only if the existing shell is label-only and therefore brittle under real translations" instruction: the tab bar's structural exposure to XCUITest is already locale-agnostic without additional identifiers; only `tabBars.buttons["Today"]`-style lookups by label are brittle.

## Validation

- `python3 automation/context/build_context.py --slice-id owlory-ui-regression-batch-7-localization-layout-shell` — exit 0.
- `python3 automation/supervisor/run_next.py --dry-run` — selected this slice before completion.
- `make architecture` — passed.
- `make localization-check` — 19 locales, 314 keys, 13 plural keys.
- `./Tools/validate.sh localization` — passed.
- `make ui-regression DOMAIN=localization` — TEST SUCCEEDED. 4 tests passed in 61.7s of test time on `iPhone 17 / iOS 26.5`.
- `make automation-check` — 57 tests passed.
- `git diff --check` — clean.

## What This Proves vs. What It Does Not

Proves:

- The Today dashboard shell settles under `-AppleLanguages` / `-AppleLocale` launch arguments for `en`, `de`, `ar`, and `zh-Hans`.
- The root tab bar remains reachable and exposes exactly five hittable tab buttons under each of those four locales (`make ui-regression DOMAIN=localization` exit 0).
- The Lane 2 regression suite now includes a locale-launch-shell guard scoped through `DOMAIN=localization`.

Does not prove:

- Translation quality. Non-English values in `Localizable.strings` / `.stringsdict` remain English placeholders for `de`, `ar`, and `zh-Hans`; no reviewed translations were ingested.
- Translated-text layout correctness. Tests assert shell hittability, not that translated copy lays out on a surface.
- All 19 supported locales. Only the four representative locales chosen by the parent triage are exercised.
- Pseudo or long-text layout stress, Dynamic Type matrix coverage, RTL or CJK rendering correctness beyond shell hittability.
- Screenshot proof, device proof, TestFlight proof.

## Lane Boundary

`running-app-smoke` per Lane 2 (`docs/workflows/ui-regression-plan.md`). The proof is that the app builds, installs, launches under each of four locale launch-argument configurations, and the Today dashboard shell plus root tab bar remain reachable through stable accessibility signals. Screenshot, device, and TestFlight proofs are not claimed.

## Residual Risk

- Non-English values fall back to English. The shell-hittability proof does not regress under translation; once reviewed translations are ingested, this batch will still pass but will not validate that the translations *fit* on the same surfaces. Pseudo/long-text or reviewed-translation layout would be a separate slice.
- Tab presence is asserted by count (5) rather than per-tab identifier. A reorder or replacement of tabs would be caught only as a count mismatch; a swap of two tabs would not be caught at all. Adding per-tab identifiers via a different SwiftUI pattern (e.g., a UITabBarItem.accessibilityIdentifier customization through UIKit appearance) is a deferred refinement.
- The `--owlory-ui-seed-fresh-day` seed is reused; no app-data fixtures were added per slice scope. Surfaces beyond Today's dashboard shell (Train, Write, Career, Home content) are reachable through their tab buttons but the test only asserts hittability of the tab bar, not contents of those tabs under each locale.
- The XCUITest run reaches the simulator on `iPhone 17 / iOS 26.5` (the default `OWLORY_XCODE_DESTINATION`). Other simulator destinations or device classes are unproved by this batch.

## Notes

- The user's instructions explicitly forbade claiming translation quality, all-locale layout correctness, screenshot proof, device proof, or TestFlight proof. Those claims are not made in this slice's notes, handoff, or session record. Only `running-app-smoke` for four representative locales is claimed.
- Multi-agent collisions to expect: another agent could parallel-implement the same slice or pick up a different localization slice. The handoff JSON is timestamp-stamped (`20260515T092224Z`) so reconciliation can be non-destructive.
