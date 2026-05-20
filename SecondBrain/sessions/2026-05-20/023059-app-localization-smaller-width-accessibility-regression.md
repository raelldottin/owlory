# app-localization-smaller-width-accessibility-regression

## Prompt

> "start next slice" — execute the supervisor-selected slice `app-localization-smaller-width-accessibility-regression`.

## What was done

Test-coverage slice. Added `DOMAIN=localization-smaller-width` to `make ui-regression`. The new variant runs the same two existing localization regression classes (`LocalizationLayoutRegression` + `LocalizationAccessibilityRegression`) against an iPhone 16 simulator instead of iPhone 17, which exposes tab-bar layout regressions that only manifest on narrower iPhones. No XCUITest source change.

### Why Option B (Makefile DOMAIN variant) and not Option A (XCUITest parameterization)

XCUITest cannot select the destination at test time — that's an xcodebuild-invocation concern. Driving the same tests against multiple devices means re-invoking xcodebuild with different `-destination` flags. Adding a `DOMAIN` case to the existing `ui-regression` target is the natural fit; it keeps the maintained `DOMAIN=localization` filter intact and adds a parallel smaller-width path.

### Makefile change

```make
localization-smaller-width)
  ONLY_TESTING="-only-testing:OwloryUITests/LocalizationLayoutRegression -only-testing:OwloryUITests/LocalizationAccessibilityRegression";
  DESTINATION="platform=iOS Simulator,name=iPhone 16,OS=26.5";
  LABEL="Localization regression on smaller iPhone width (iPhone 16; ...)"
  ;;
```

Same `-only-testing` flags as the baseline `DOMAIN=localization` case; only the `-destination` changes.

### Local simulator rename

The local iPhone 16 simulator was provisioned as "iPhone 16 iOS 26.5" (custom name). `xcodebuild -destination 'platform=iOS Simulator,name=iPhone 16,...'` couldn't match that. Renamed via:

```bash
xcrun simctl rename BE8450CB-77B6-4A56-81EA-9A1F95C22042 'iPhone 16'
```

Recorded as scope deviation in the handoff because future contributors with a custom-named iPhone 16 simulator may need to do the same.

### Doc updates

| File | Change |
|---|---|
| `docs/workflows/validation.md` | `make ui-regression` bullet now lists `DOMAIN=localization` + `DOMAIN=localization-smaller-width` explicitly |
| `docs/workflows/localization-hig-ui-completion.md` | Dynamic Type + Accessibility Regression section points at both DOMAIN values |
| `docs/workflows/ui-testing-hygiene.md` | DOMAIN bullet rewritten with smaller-width variant |

### Test results

```
make ui-regression DOMAIN=localization-smaller-width
Destination: platform=iOS Simulator,name=iPhone 16,OS=26.5
LocalizationAccessibilityRegression: 15/15 passed
LocalizationLayoutRegression:         4/4  passed
Total:                                19 tests / 0 failures / 112s
TEST SUCCEEDED

make ui-regression DOMAIN=localization
Destination: platform=iOS Simulator,name=iPhone 17,OS=26.5
Total:                                19 tests / 0 failures / 112s
TEST SUCCEEDED
```

Both paths preserved; smaller-width adds parallel coverage.

## Validation

- `python3 automation/context/build_context.py --slice-id app-localization-smaller-width-accessibility-regression` — ran.
- `python3 automation/supervisor/run_next.py --dry-run` — selected this slice pre-commit.
- `make architecture` — passed.
- `make localization-check` — 19 / 377 / 13.
- `make ui-regression DOMAIN=localization` — **TEST SUCCEEDED** (19 tests / 0 failures / 112s).
- `make ui-regression DOMAIN=localization-smaller-width` — **TEST SUCCEEDED** (19 tests / 0 failures / 112s).
- `make automation-check` — passed (drift no-drift + 93 unittests OK).
- `git diff --check` — clean.

## Lane Boundary

`regression-tested`. New Makefile case + doc updates. No XCUITest source change, no app source, no translation, no proof artifact.

## Residual Risk

- iPhone 16 is wider than iPhone SE (current and previous generations). A regression that only manifests on iPhone SE would not be caught here. If iPhone SE coverage is needed, provision an iPhone SE simulator on the dev host and add a `localization-smallest-width` DOMAIN case.
- The DOMAIN case hardcodes the simulator name "iPhone 16". Contributors with a custom-named simulator (e.g., "iPhone 16 iOS 26.5") will see xcodebuild error 70. Document the naming convention if friction surfaces.
- Running both `DOMAIN=localization` and `DOMAIN=localization-smaller-width` sequentially takes ~3.5 minutes total. CI cost should be considered before adding both to a default gate.

## Not Claimed

- iPhone SE coverage (smallest widely-deployed iPhone width remains unverified).
- Additional Dynamic Type categories beyond AccessibilityXL.
- iPad or landscape orientation.
- device-verified or testflight-verified for any locale (simulator-only).

## Next slice

Per Owlory's convention (lower priority number = picked first), the remaining queued slice with the lowest priority number is `app-reminders-cancel-pending-on-item-completion` (pri 90, currently the only queued slice after this one closes). Blocked: `app-localization-device-verified-locale-proof` (pri 50) and `app-localization-testflight-verified-locale-proof` (pri 49), both awaiting external inputs.
