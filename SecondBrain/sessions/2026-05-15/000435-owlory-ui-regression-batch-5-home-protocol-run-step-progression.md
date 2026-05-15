# owlory-ui-regression-batch-5-home-protocol-run-step-progression

## Prompt

Implement Lane 2 Batch 5: active Home protocol run step progression. Reuse the existing single-step seed; add accessibility identifiers on the step row and Complete action; new test class separate from `HomeProtocolRegression`; wire into `make ui-regression DOMAIN=home`.

## Files Edited

- `owlory_xcode/Owlory/Features/Home/HomeView.swift` — added `.accessibilityIdentifier("home.protocolRun.step.action.complete.<uuid>")` on the per-step Complete Button (line ~1133), and `.accessibilityElement(children: .contain)` + `.accessibilityIdentifier("home.protocolRun.step.<uuid>")` on the step HStack row (after its swipeActions modifier). The `children: .contain` is required so the inner Complete button stays individually addressable under the outer row identifier; without it, SwiftUI collapses the row into a single accessibility element.
- `owlory_xcode/OwloryUITests/OwloryUITests.swift` — appended `final class HomeProtocolRunStepRegression: XCTestCase` with `testSeededProtocolRunStepCompleteTransitionsOutOfPending`. The test reuses fixture constants for the single-step protocol run that the seed already provides; the assertion is that the Complete button disappears after tap (XCUITest predicate `exists == false`) and the step title remains visible.
- `Makefile` — added `HomeProtocolRunStepRegression` to the bare `make ui-regression` lane and to `DOMAIN=home` (which now runs both Home classes). `DOMAIN=today/write/train` unchanged.
- `docs/workflows/ui-testing-hygiene.md` — updated the regression-batch list, the `make ui-regression` command listing, and the per-class description block. Added a note about the `.accessibilityElement(children: .contain)` requirement on the step row.
- `docs/workflows/validation.md` — updated the `make ui-regression` description.
- `docs/workflows/roadmap-status.md` — updated the UI regression / snapshot coverage paragraph to list five regression classes.
- `automation/queue/slices.json` — slice flipped to `done`.
- `automation/handoffs/20260515T040435Z-owlory-ui-regression-batch-5-home-protocol-run-step-progression.json`
- `SecondBrain/INDEX.md`
- `SecondBrain/sessions/2026-05-15/000435-owlory-ui-regression-batch-5-home-protocol-run-step-progression.md`

## Why no new seed

The triage left the call to the implementer: reuse `--owlory-ui-seed-home-protocol-run-continue-item` if its single-step protocol suffices. It does — the slice scope is "tap Complete on the first pending step, assert it transitions out of pending." The conditional "if a second step exists, assert it remains the only pending step" is satisfied vacuously because there is no second step. Adding a multi-step seed arg would be infrastructure beyond the slice scope.

## Validation

- `python3 automation/context/build_context.py --slice-id owlory-ui-regression-batch-5-home-protocol-run-step-progression` — exit 0.
- `python3 automation/supervisor/run_next.py --dry-run` — selected this slice before completion.
- `make architecture` — passed.
- `make test-domain DOMAIN=home` — TEST SUCCEEDED.
- `make ui-regression DOMAIN=home` — TEST SUCCEEDED (2 tests, 31.8s — `HomeProtocolRegression` + `HomeProtocolRunStepRegression`).
- `make automation-check` — 57 tests passed.
- `git diff --check` — clean.

`make localization-check` ran clean on the side (314 keys, 13 plural keys; this slice didn't touch resources). The full `make ui-regression` (all five classes) was not re-run as a separate gate — the slice's required validation is `make ui-regression DOMAIN=home`, which exercises both Home classes together. Other domains' regression classes weren't touched and have been green on prior runs.

## Lane Boundary

`running-app-smoke`. The Swift compiles, accessibility identifiers are reachable by XCUITest, the test passes deterministically against the seeded single-step protocol run. Not screenshot proof, not device proof, not TestFlight proof.

## Residual Risk

- The test asserts the Complete button's disappearance as a proxy for "step transitioned out of pending." This is robust because in `ProtocolRunSheet`, the Complete button is only rendered when `step.status == .pending`. If a future refactor renders Complete in other states, the test would falsely pass; if the disappearance assertion is replaced by an explicit status assertion, the seed would need to expose status to the test.
- Only the Complete action is identified. Skip and revert use the same row but have different control flow; their identifiers are not added here per slice scope.
- Only one step is exercised. Multi-step sequential progression (assert the second step remains pending) is documented in the triage memo as an out-of-scope follow-up.
- Accessibility identifiers and labels on the same row coexist: `home.protocolRun.step.<uuid>` (identifier, this slice) on the row, `home.protocol.step.accessibility.complete.<uuid>` (label, prior Home accessibility slice) on the Complete button, plus `home.protocolRun.step.action.complete.<uuid>` (identifier, this slice). All three serve different consumers (XCUITest, VoiceOver, XCUITest) and don't conflict.
- This batch does not exercise the Today → Continue route into the active run sheet that Train and Today already smoke-cover; the test reuses that route as a prerequisite. Failures in the Continue routing would surface here as a different error shape.
