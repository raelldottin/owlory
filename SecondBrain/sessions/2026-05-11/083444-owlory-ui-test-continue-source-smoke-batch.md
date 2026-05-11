# owlory-ui-test-continue-source-smoke-batch

## Summary

Closed the maintained Continue source-visibility coverage from 3/6 to 6/6 by adding deterministic XCUITest smoke for the three composer source kinds that the source-coverage triage flagged as missing:

- `dueTodayTraining` / `.trainingSession`
- `carriedForwardFocus` / `.carriedFocusItem`
- `inProgressWriting` / `.writingNote`

No product behavior changed. No routing, action, screenshot, device, or TestFlight proof was added in this slice.

## Implementation

`OwloryUITestSupport.swift`:

- Added three launch-argument constants and matching fixture UUIDs/titles.
- Added three seed functions:
  - `seedDueTodayTrainingContinueItem` writes one planned `TrainingSession` dated today via `FileItemListRepository<TrainingSession>(directory: "Train", fileName: "sessions")`. `TrainStore.todaySessions` then surfaces it because `calendar.startOfDay(for: session.date) == today`, and `ContinueCandidateRules.isDueTodayCandidate` admits it because `status == .planned` and the title is non-empty.
  - `seedCarriedForwardFocusContinueItem` writes four consecutive `DailyEntry` records (3 prior + today) via `FileTodayEntryRepository`, each carrying a `FocusItem` with the same title/domain and `createdFromDate` set. `PatternStore.refresh()` runs on Today's `.onAppear`, recomputes the weekly snapshot from history, and `PatternEngine.computeCarryForward` registers a stalled-item streak of 4 (>= 3). The resulting `CalibrationRules.Calibration.staleItems` contains the title/domain key, so `TodayContinueSourceComposer.currentFocusCandidates` rejects today's item and `carriedForwardFocusCandidates` admits it as `.carriedFocusItem`. Only today's `FocusItem` carries the fixture ID so the test can assert a deterministic accessibility identifier; prior days' IDs are arbitrary because the streak is keyed by title+domain.
  - `seedInProgressWritingContinueItem` writes one `WritingNote` at `.capture` stage via `FileItemListRepository<WritingNote>(directory: "Write", fileName: "notes")`. `ContinueCandidateRules.isInProgressWritingCandidate` admits it because the stage is not `.published`/`.archived` and the title is non-empty.
- The seeded data passes through the live `FileItemListRepository`/`FileTodayEntryRepository`/`FilePatternSnapshotRepository` paths the app uses in production. No domain rule, no composer, and no admission cap was modified; this is purely a fixture extension.

`OwloryUITests.swift`:

- Added three focused tests:
  - `testSeededDueTodayTrainingAppearsInTodayContinue`
  - `testSeededCarriedForwardFocusAppearsInTodayContinue`
  - `testSeededInProgressWritingAppearsInTodayContinue`
- Each test waits for `today.dashboard.header`, then `today.continue.header`, then asserts the deterministic `today.continue.item.<sourceKind>.<UUID>` accessibility identifier exists and the seeded title is visible. The tests do NOT tap, route, or exercise actions; visibility only.

## Docs

- `docs/workflows/ui-testing-hygiene.md` — added the three new seed-argument entries and updated the "what the suite proves" paragraph to claim source visibility for all six composer source kinds.
- `docs/product/domains/today.md` — updated the Continue UI Source Coverage table; `dueTodayTraining`, `carriedForwardFocus`, and `inProgressWriting` rows now point at their new tests and "Needed proof" is `None for source visibility.` for all six sources.

## Boundary kept

This slice is source-visibility only. Out of scope and explicitly not added:

- Row routing tests for the new sources (waiting on `owlory-ui-test-continue-routing-matrix-triage`).
- Done/Defer/Drop action tests.
- Screenshot proof, device proof, TestFlight proof.
- Any change to the Continue admission policy, ranking, or composer order.
- Any change to product behavior.

## Validation

- `python3 automation/context/build_context.py --slice-id owlory-ui-test-continue-source-smoke-batch`
- `python3 automation/supervisor/run_next.py --dry-run`
- `make architecture`
- `make ui-smoke` (XCUITest target, including the three new tests)
- `make test-domain DOMAIN=today`
- `make automation-check`
- `git diff --check`

## Next

The maintained XCUITest smoke now covers source visibility for all six composer-backed Continue sources. The next queued slice in the UI proof roadmap is `owlory-ui-test-continue-routing-matrix-triage`, which classifies expected routes for each source before adding more route tests. Screenshot, device, and TestFlight lanes remain deliberately downstream.
