# owlory-ui-regression-batch-3-train-active-history

## Summary

Implemented the selected Lane 2 UI regression expansion for the Train active/history transition.

The maintained regression lane now includes `TrainRegression`, which:

- launches with the deterministic due-today Training seed
- opens the Train tab
- verifies the seeded planned session appears in the active Today surface
- completes it through the existing Train status/save controls
- verifies the session leaves active Today and appears in History with completed status

## Changes

- Added stable Train accessibility identifiers for:
  - active session rows
  - readiness disclosure containment
  - status buttons
  - save button
  - History rows
  - History status badge
- Added `TrainRegression` to `OwloryUITests.swift`.
- Updated `make ui-regression` to run both `TodayContinueRegression` and `TrainRegression`.
- Marked `owlory-ui-regression-expansion-next-surface` done in the queue.
- Updated Train, validation, UI regression, UI testing hygiene, and roadmap docs.

## Boundary

This slice did not broaden into:

- recurrence rollover
- voice/reflection fallback
- modified/skipped Train status paths
- Continue routing
- screenshot proof
- device proof
- TestFlight proof
- broad app-wide UI regression coverage

## Validation

```bash
python3 automation/context/build_context.py --slice-id owlory-ui-regression-batch-3-train-active-history
python3 automation/supervisor/run_next.py --dry-run
make architecture
make test-domain DOMAIN=train
xcodebuild test -quiet -project owlory_xcode/Owlory.xcodeproj -scheme Owlory -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -derivedDataPath /tmp/owlory-train-regression-derived-data-7 -only-testing:OwloryUITests/TrainRegression
make ui-regression
make automation-check
git diff --check
```

## Residual Risk

- Train `completed` is covered; `modified` and `skipped` are not.
- No visual screenshot proof was preserved for this Train transition.
- No device or TestFlight proof was captured.
- The broader UI regression suite is still intentionally narrow.

## Next

Clean stop unless a new UI regression surface is selected through triage.
