# owlory-ui-test-continue-home-task-routing-smoke

## Prompt

Resume from the clean UI harness checkpoint and add the next narrow proof rung: seed one Home-task-backed Continue row, tap it from Today Continue, and prove it routes into Home with the seeded task visible.

## Interpretation

This was a focused XCUITest smoke slice, not a broad routing matrix. Product behavior was expected to remain unchanged; the slice only needed stable UI-test identification for the Home task row and one deterministic route assertion.

## Files Edited

- `automation/queue/slices.json`
- `automation/handoffs/20260507T110643Z-owlory-ui-test-continue-home-task-routing-smoke.json`
- `docs/workflows/ui-testing-hygiene.md`
- `docs/workflows/validation.md`
- `SecondBrain/INDEX.md`
- `SecondBrain/sessions/2026-05-07/070643-owlory-ui-test-continue-home-task-routing-smoke.md`
- `owlory_xcode/Owlory/Features/Home/HomeView.swift`
- `owlory_xcode/OwloryUITests/OwloryUITests.swift`

## Outcome

- Added a stable `home.task.item.<uuid>` accessibility identifier to the existing Home task edit/open button.
- Added `testSeededHomeTaskContinueRowRoutesToHomeTask`, which launches with `--owlory-ui-seed-home-task-continue-item`, taps the Home-task-backed Today Continue row, and asserts the seeded Home task is visible in Home.
- Updated UI testing and validation docs to state the maintained XCUITest smoke now covers one Home-task-backed Continue route.
- Marked the queue slice done and recorded a machine-readable handoff.

## Validation

Passed:

- `python3 automation/context/build_context.py --slice-id owlory-ui-test-continue-home-task-routing-smoke`
- `python3 automation/supervisor/run_next.py --dry-run`
- `make architecture`
- `make ui-smoke`
- `make test-domain DOMAIN=today`
- `make test-domain DOMAIN=home`
- `make automation-check`
- `git diff --check`

## Proof And Risk

Proof level: `running-app-smoke`, XCUITest-backed.

This proves one seeded Home-task-backed Continue row can route from Today into Home with the seeded task visible. It does not prove every Continue source, a broad routing matrix, screenshots, device behavior, TestFlight behavior, or a full UI regression suite.
