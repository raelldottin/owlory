# owlory-ui-regression-expansion-next-surface

## Prompt

Implement the second Lane 2 UI regression batch chosen by the preceding triage slice: Write capture inbox. proof_level target: `running-app-smoke`.

## Files Edited

- `owlory_xcode/Owlory/Features/Write/WriteView.swift`
- `owlory_xcode/OwloryUITests/OwloryUITests.swift`
- `Makefile`
- `docs/workflows/ui-regression-plan.md`
- `docs/workflows/ui-testing-hygiene.md`
- `docs/workflows/validation.md`
- `automation/queue/slices.json`
- `automation/handoffs/20260513T235054Z-owlory-ui-regression-expansion-next-surface.json`
- `SecondBrain/INDEX.md`
- `SecondBrain/sessions/2026-05-13/235054-owlory-ui-regression-expansion-next-surface.md`

## Outcome

- Added accessibility identifiers on `WriteView`:
  - `write.note.row.<uuid>` on each stage-section note row
  - `write.capture.entry` on the `+` toolbar Button
  - `write.note.action.addToToday.<uuid>` on the Add to Today menu button
- Added `OwloryUITests/WriteCaptureRegression` with two tests:
  - `testSeededWriteCaptureInboxRendersInProgressNoteRowAndCaptureEntry`
  - `testSeededWriteNoteDetailExposesAddToTodayPromotion`
- Reused the existing `--owlory-ui-seed-in-progress-writing-continue-item` seed; a new parallel arg with identical data shape would have been premature abstraction. The triage's "e.g." naming suggestion was prescriptive about deterministic seed availability, not a new arg.
- Wired the `DOMAIN=` matrix into `make ui-regression`:
  - `make ui-regression` runs every regression class
  - `make ui-regression DOMAIN=today` narrows to `TodayContinueRegression`
  - `make ui-regression DOMAIN=write` narrows to `WriteCaptureRegression`
  - Unknown `DOMAIN=` values exit 2 with a usage hint.
- Updated `docs/workflows/ui-regression-plan.md`, `ui-testing-hygiene.md`, and `validation.md` to describe the two regression classes and the new matrix shape.

## Validation

- `make architecture` - passed.
- `make ui-regression` - passed all 15 regression tests across both classes (13 in TodayContinueRegression, 2 in WriteCaptureRegression) in 138.7 seconds.
- `make automation-check` - 50 tests passed.
- `git diff --check` - clean.

Test session results live transiently at `/tmp/owlory-ui-regression-derived-data/Logs/Test/Test-Owlory-2026.05.13_19-47-12--0400.xcresult` per Lane 2's transient-artifact policy.

## Lane Boundary

This slice is `running-app-smoke` (Lane 2 regression). It is not a screenshot proof, not a device proof, and not a TestFlight proof. The captured xcresult is transient and not promoted into `automation/proofs/`.

## Residual Risk

- Voice / live transcription on the Write surface is intentionally not covered; microphone permission is environmental and would require separate device or simulator-permission setup.
- Task promotion and protocol promotion side effects are not exercised; the test stops at affordance visibility for Add to Today and does not tap it.
- This slice does not prove the cross-domain Add-to-Today side effect; that belongs to a follow-up slice with its own Today-side seed and assertion.
- No screenshot, device, or TestFlight proof for the Write surface; only running-app-smoke.
