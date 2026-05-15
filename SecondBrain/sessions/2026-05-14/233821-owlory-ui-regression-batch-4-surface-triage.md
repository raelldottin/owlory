# owlory-ui-regression-batch-4-surface-triage

## Prompt

Pick the next UI regression surface for Batch 4. Lane 2 Batches 1-3 have shipped (Today Continue, Write capture inbox, Train active/history). Remaining candidates: Home protocols, Patterns, localization layout. Doc-only triage.

## Multi-agent note

A prompt arrived describing the original Batch 2 triage (Write vs Train vs others) as if it had not yet been performed. That triage was already completed on 2026-05-13 by two parallel agents (Agent A picked Write, Agent B picked Train, both shipped). The user confirmed the right interpretation was to triage only the *remaining* surfaces for a new Batch 4 slot, not to re-run the original triage. This slice uses a new slice ID (`owlory-ui-regression-batch-4-surface-triage`) to avoid the same collision pattern.

## Decision

Surface: **Home protocols — active-run step progression.**

Rationale:

- Protocol runs are a primary Home interaction surface.
- The active-run sheet is the natural extension of the existing Today Continue → `home.protocolRun.sheet.<uuid>` route smoke. The route is proven; step-level interactions inside the sheet are not.
- The accessibility-infrastructure cost is bounded to one sheet (step row identifiers + step action identifier). No broad app-wide infrastructure change.
- Recent localization slice wired accessibility *labels* for protocol step Complete/Skip but added no XCUITest *identifiers*; this slice provides the natural follow-up coverage.

Not selected:

- **Patterns** — domain rules heavily unit-tested; UI surfaces are summary/report-oriented with low interaction risk. Defer until a Patterns UI claim needs proof.
- **Localization layout** — reviewed translations are still parked (German review packet exists; intake is blocked). Without translated values, layout regression has nothing locale-distinctive to verify. Defer until translation intake or a layout issue surfaces.

Within Home protocols, Batch 4 narrows further to **active-run step progression** specifically. Step skip, step revert, protocol archive, schedule-window status display, and protocol template editing are explicitly deferred to future scoped slices.

## Files Edited

- `docs/workflows/ui-regression-plan.md` — added "Batch 4 decision" sub-section under "Latest Regression Expansion" with the candidate comparison and the narrowed scope. Updated the lead paragraph to point at the queued implementation slice.
- `automation/queue/slices.json` — triage slice classified, then flipped to `done`. Queued the implementation slice `owlory-ui-regression-batch-4-home-protocol-run-step-progression` with explicit allowed_paths and required_validations.
- `automation/handoffs/20260515T033821Z-owlory-ui-regression-batch-4-surface-triage.json`
- `SecondBrain/INDEX.md`
- `SecondBrain/sessions/2026-05-14/233821-owlory-ui-regression-batch-4-surface-triage.md`

## Coverage goal for the queued implementation slice

- Reuse `--owlory-ui-seed-home-protocol-run-continue-item` if its single-step protocol suffices; only add a new multi-step seed arg if proving sequential progression requires more than one pending step.
- Open the active-run sheet via the Today Continue row (route already smoke-covered).
- Tap the Complete action on the first pending step.
- Assert the step transitions out of pending state.
- If a second step exists, assert it remains the only pending step.

Required new infrastructure (inside the implementation slice scope):

- Accessibility identifiers on protocol step rows and the Complete action button (e.g., `home.protocolRun.step.<uuid>` and `home.protocolRun.step.action.complete.<uuid>`).
- New XCUITest class `OwloryUITests/HomeProtocolRunStepRegression`.
- `make ui-regression DOMAIN=home` matrix branch.

proof_level target for the implementation slice: `running-app-smoke`.

## Validation

- `python3 automation/context/build_context.py --slice-id owlory-ui-regression-batch-4-surface-triage` — exit 0.
- `python3 automation/supervisor/run_next.py --dry-run` — selected this slice before completion; post-completion picks the queued implementation slice next.
- `make architecture` — passed.
- `make automation-check` — 57 tests passed.
- `git diff --check` — clean.

## Lane Boundary

`doc-only`. No XCUITest code, no product behavior changes, no screenshot/device/TestFlight claims. The triage's claim is the surface decision and the scoped implementation slice queued behind it.

## Residual Risk

- The triage assumes the prompt's intent was Batch 4 selection rather than re-running the original Batch 2 triage. The user confirmed this interpretation explicitly; if a parallel agent runs the original triage from a stale view, the two slice IDs (`owlory-ui-regression-next-surface-triage` vs `owlory-ui-regression-batch-4-surface-triage`) prevent direct collision on the queue record.
- "Active-run step progression" is one sub-behavior of many Home protocols possibilities. The deferred sub-behaviors (skip, revert, archive, templates, schedules) each need their own future triage if prioritized.
- The implementation slice will add accessibility identifiers to step rows and Complete actions; the existing `home.protocol.step.accessibility.complete` *label* keys do not conflict with these *identifiers*, but anyone reviewing the diff should note both exist for the same view.
