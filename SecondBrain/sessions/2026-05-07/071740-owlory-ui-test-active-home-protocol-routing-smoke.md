# owlory-ui-test-active-home-protocol-routing-smoke

## Prompt

Resume from the maintained UI harness checkpoint and add the next narrow proof rung: seed one active Home protocol run, show it in Today Continue, tap it, and prove Home presents the active run sheet.

## Interpretation

This was a focused XCUITest smoke slice, not a broad Continue routing matrix or protocol lifecycle refactor. The only app changes were deterministic debug seeding and stable accessibility identifiers needed for UI proof.

## Files Edited

- `automation/queue/slices.json`
- `automation/handoffs/20260507T111740Z-owlory-ui-test-active-home-protocol-routing-smoke.json`
- `docs/workflows/ui-testing-hygiene.md`
- `docs/workflows/validation.md`
- `SecondBrain/INDEX.md`
- `SecondBrain/sessions/2026-05-07/071740-owlory-ui-test-active-home-protocol-routing-smoke.md`
- `owlory_xcode/Owlory/Core/Application/OwloryUITestSupport.swift`
- `owlory_xcode/Owlory/Features/Home/HomeView.swift`
- `owlory_xcode/OwloryUITests/OwloryUITests.swift`

## Outcome

- Added a debug-only seed flag, `--owlory-ui-seed-home-protocol-run-continue-item`, that writes one protocol template and one active protocol run.
- Added stable active-run automation identifiers for Home protocol rows and the active run sheet.
- Added `testSeededHomeProtocolRunContinueRowRoutesToActiveRun`, which launches the seeded app, taps the Home-protocol-run-backed Today Continue row, and asserts Home presents the active run sheet with the seeded step.
- Updated UI testing and validation docs to state that maintained XCUITest smoke now covers one active Home protocol run route from Today Continue.
- Marked the queue slice done and recorded a machine-readable handoff.

## Validation

Passed:

- `python3 automation/context/build_context.py --slice-id owlory-ui-test-active-home-protocol-routing-smoke`
- `python3 automation/supervisor/run_next.py --dry-run`
- `make architecture`
- `make ui-smoke`
- `make test-domain DOMAIN=today`
- `make test-domain DOMAIN=home`
- `make automation-check`
- `git diff --check`

## Proof And Risk

Proof level: `running-app-smoke`, XCUITest-backed.

This proves one seeded active Home-protocol-run-backed Continue row can route from Today into the Home active run sheet. It does not prove every Continue source, a broad routing matrix, screenshots, device behavior, TestFlight behavior, or a full UI regression suite.
