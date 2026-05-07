# harness-pr-ui-testing-hygiene

## Prompt

Add Gymphant PR and UI testing hygiene behavior to Owlory.

## Interpretation

The user asked to bring over the useful repository behavior, not Gymphant product logic. I treated this as a harness/docs slice: PR claim hygiene, UI proof boundaries, DerivedData/test-state hygiene, screenshot artifact rules, and UI failure classification.

## Files Inspected

- `AGENTS.md`
- `docs/README.md`
- `docs/workflows/review.md`
- `docs/workflows/validation.md`
- `Tools/review-preflight.sh`
- `Tools/architecture-lint.sh`
- Gymphant docs/scripts for PR and UI testing lessons: `README.md`, `AGENTS.md`, `docs/workflows/validation.md`, `docs/workflows/ui-regression-failure-classification.md`, and `scripts/run-ui-regressions.sh`

## Files Changed

- `docs/workflows/pr-hygiene.md`
- `docs/workflows/ui-testing-hygiene.md`
- `docs/README.md`
- `docs/workflows/review.md`
- `docs/workflows/validation.md`
- `Tools/architecture-lint.sh`
- `Tools/review-preflight.sh`
- `automation/queue/slices.json`
- `automation/handoffs/20260507T045629Z-harness-pr-ui-testing-hygiene.json`
- `SecondBrain/INDEX.md`
- `SecondBrain/sessions/2026-05-07/005629-harness-pr-ui-testing-hygiene.md`

## Outcome

- Added a PR hygiene workflow that treats each PR as a reviewable claim with scope, proof level, exact validation, artifacts, and residual risk.
- Added a UI testing hygiene workflow that separates running-app smoke, flow verification, screenshot proof, device proof, TestFlight proof, and future XCUITest coverage.
- Documented that Owlory currently has running-app smoke and proof artifacts but no first-class XCUITest target.
- Updated review preflight to flag PR/review and UI/proof changes with the right docs, validation suggestions, and risks.
- Added architecture lint requirements so the new workflow docs remain part of the maintained docs tree.

## Validation

- `python3 automation/context/build_context.py --slice-id harness-pr-ui-testing-hygiene` - passed.
- `python3 automation/supervisor/run_next.py --dry-run` - passed before implementation; after marking the slice done, it reported no eligible queued slice.
- `make architecture` - passed.
- `make review-preflight` - passed and now recommends PR/UI hygiene docs and proof risks for this change class.
- `make handoff` - passed.
- `make automation-check` - passed.
- `git diff --check` - passed.

## Residual Risk

- This slice does not add a UI test target or make UI proof more automated.
- `python3 automation/smoke/running_app_smoke.py` remains the maintained launched-app proof runner.
- The smoke runner was not run because this slice changes docs/tooling only and does not claim running-app behavior.
- First-class Owlory XCUITest coverage should be a separate implementation slice with a deterministic seed path.

## Next Slice

`owlory-ui-test-seed-and-xcuitest-harness` if/when Owlory needs repeatable XCUITest coverage beyond running-app smoke and preserved screenshots.
