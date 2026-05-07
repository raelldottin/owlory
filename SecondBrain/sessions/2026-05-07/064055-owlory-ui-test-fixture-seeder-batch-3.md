# owlory-ui-test-fixture-seeder-batch-3

## Prompt

Resume the next narrow UI harness slice after Batch 2. Preferred proof target: seed one active Home task and prove it appears in Today Continue without widening into a UI regression suite.

## Assessment

- The repo was clean and mirrored before implementation except for the newly queued `owlory-ui-test-fixture-seeder-batch-3` entry.
- Batch 2 already proved the fresh Today launch surface and one Focus-backed Continue row.
- Today can derive Continue rows from active Home tasks through existing `TodayContinueSourceComposer` and `ContinueCandidateRules`; no product policy change was needed.

## Changes

- Added `--owlory-ui-seed-home-task-continue-item` in `OwloryUITestSupport`.
- The new debug-only seed resets app-local Owlory/Trajectory support data and writes one active `HomeTask` through the existing Home task repository.
- Added `testSeededHomeTaskAppearsInTodayContinue` to `OwloryUITests`.
- Updated UI testing and validation docs to describe the Home-task-backed Continue smoke claim.
- Marked the queue slice done and wrote the JSON handoff.

## Validation

- `python3 automation/context/build_context.py --slice-id owlory-ui-test-fixture-seeder-batch-3` passed.
- `python3 automation/supervisor/run_next.py --dry-run` passed.
- `make architecture` passed.
- `make ui-smoke` passed with 3 XCUITests.
- `make test-domain DOMAIN=today` passed.
- `make test-domain DOMAIN=home` passed.
- `make automation-check` passed.
- `git diff --check` passed.

## Proof Level

`running-app-smoke`, XCUITest-backed.

Missing: `flow-verified`, `screenshot-verified`, `device-verified`, `testflight-verified`.

## Residual Risk

- This is still focused UI smoke, not broad UI regression coverage.
- It proves one active Home task source appears in Today Continue. It does not prove every Continue source, routing, screenshots, device behavior, or TestFlight behavior.

## Next

Clean stop is valid. If UI harness depth is needed later, queue one fixture at a time, such as a seeded Write note in the Write tab or active Home protocol run in Today Continue.
