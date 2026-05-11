# owlory-ui-test-continue-routing-smoke-batch

Added the two highest-value routing smoke tests selected by the routing matrix triage: in-progress Writing Continue row to the auto-presented note detail sheet, and due-today Training Continue row to the Train session row in the Today section. Two new tests, two new destination accessibility identifiers. No focus / carried-forward routing tests, no screenshot/device/TestFlight proof, no product behavior change.

## Implementation

`owlory_xcode/Owlory/Features/Write/WriteView.swift`:

- Added `.accessibilityIdentifier("write.note.detail.\(note.id.uuidString)")` to the `NoteDetailView` Form after its `.confirmationDialog` modifier. This is the same convention used for Home (`home.protocolRun.sheet.<UUID>`, `home.task.item.<UUID>`). XCUITest can find the auto-presented note detail sheet by the deterministic identifier.

`owlory_xcode/Owlory/Features/Train/TrainView.swift`:

- Added `.accessibilityIdentifier("train.session.item.\(session.id.uuidString)")` to the `SessionCardView` rendered inside the Today section's `ForEach(todaySessions)`. A planned `TrainingSession` dated today renders here as a `SessionCardView`, so this identifier matches what a `dueTodayTraining` Continue row would route to. The history section (completed/modified/skipped sessions) is intentionally not given a row identifier because it is not the destination of a `dueTodayTraining` route.

`owlory_xcode/OwloryUITests/OwloryUITests.swift`:

- `testSeededInProgressWritingContinueRowRoutesToWriteNoteDetail`: launches with `--owlory-ui-seed-in-progress-writing-continue-item`, waits for the Continue row, taps it, and asserts the `write.note.detail.<UUID>` identifier appears (proving the auto-present path through `WriteView.presentHighlightedNoteIfNeeded`).
- `testSeededDueTodayTrainingContinueRowRoutesToTrain`: launches with `--owlory-ui-seed-due-today-training-continue-item`, waits for the Continue row, taps it, and asserts the `train.session.item.<UUID>` identifier appears (proving the tab switch plus scroll-to-highlight path through `TrainView.highlightedSessionID`).

## Reuse, not new fixtures

Both tests reuse the existing seed paths added by the source smoke batch (`seedInProgressWritingContinueItem`, `seedDueTodayTrainingContinueItem`). No new launch arguments, no new fixture UUIDs. The slice's scope is purely adding two assertions plus two accessibility identifiers.

## What this does NOT prove

- Focus and carried-forward Focus routing remain deferred per the routing matrix. They depend on typed `FocusItemOrigin` or `linkedRecordID` and are action-routed first.
- The destination state correctness (note body, stage controls, train session readiness inputs) is not asserted; only that the destination view renders with the seeded identifier visible.
- No screenshot, device, or TestFlight evidence. The maintained smoke suite still runs only on the iPhone 16 simulator with Debug seed paths.
- No add-to-Focus, Skip-for-today, or other action affordances are exercised; Continue Actions remain documented in today.md but only the Focus Done action has UI proof.

## Validation

- `python3 automation/context/build_context.py --slice-id owlory-ui-test-continue-routing-smoke-batch`
- `python3 automation/supervisor/run_next.py --dry-run`
- `make architecture`
- `make ui-smoke` (now 11 tests; both new tests included)
- `make test-domain DOMAIN=today`
- `make automation-check`
- `git diff --check`

## Next

The maintained smoke suite now covers source visibility for all six composer-backed Continue sources plus routing for four of them (homeTask, homeProtocolRun, writingNote, trainingSession). Focus and carriedFocus routing remain deferred. The next lanes in the UI proof roadmap (`owlory-ui-test-screenshot-proof-pack`, `owlory-ui-test-device-proof`, `owlory-ui-test-testflight-proof`, `owlory-ui-regression-suite-plan`) are still not queued; classify them deliberately when the source/routing coverage is the right shape for a screenshot or device pass.
