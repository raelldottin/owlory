# owlory-ui-regression-batch-5-surface-triage

## Prompt

Pick the next UI regression surface beyond Today Continue. At the moment this triage ran locally, Lane 2 Batches 1-3 had shipped (Today Continue, Write capture inbox, Train active/history). Doc-only.

## Multi-agent reconciliation

A prompt arrived describing the *original* Batch 2 triage as if it had not yet been performed. The user confirmed the right interpretation was to triage only the *remaining* surfaces for the next Lane 2 batch.

This triage selected Home protocols and narrowed to active-run step progression. While it was running, a parallel agent (Agent B) also triaged Home protocols on `origin/main` and shipped Batch 4 as `HomeProtocolRegression` covering **template archive/restore** — a different Home-protocols sub-behavior. Both choices are defensible.

Non-destructive reconciliation: Agent B's archive/restore is Batch 4 (shipped). This triage's step-progression decision is preserved as **Batch 5**, the next queued slot. The slice IDs (`owlory-ui-regression-batch-4-home-protocol-archive-restore` vs `owlory-ui-regression-batch-5-home-protocol-run-step-progression`) keep both records distinct.

## Decision

Surface: **Home protocols — active-run step progression** (Batch 5).

Rationale:

- Agent B's Batch 4 covers `HomeProtocolRegression` template archive/restore; this sub-behavior is distinct.
- Protocol runs are a primary Home interaction surface. The active-run sheet is the natural extension of the existing Today Continue → `home.protocolRun.sheet.<uuid>` route smoke. The route is proven; step-level interactions inside the sheet are not.
- The accessibility-infrastructure cost is bounded to one sheet (step row identifiers + step action identifier). No broad app-wide infrastructure change.
- The recent localization slice wired accessibility *labels* for protocol step Complete/Skip but added no XCUITest *identifiers*; this slice provides the natural follow-up coverage.

Not selected:

- **Patterns** — domain rules heavily unit-tested; UI surfaces are summary/report-oriented with low interaction risk. Defer until a Patterns UI claim needs proof.
- **Localization layout** — reviewed translations are still parked. Defer until translation intake or a layout issue surfaces.

Within Home protocols, this triage narrows to **active-run step progression** specifically. Step skip, step revert, schedule-window status display, and protocol template editing are deferred to future scoped slices.

## Files Edited

- `docs/workflows/ui-regression-plan.md` — added "### Batch 5 decision" sub-section under "Latest Regression Expansion" with the sub-behavior comparison table and the narrowed scope. Updated the lead paragraph to note both Batch 4 (archive/restore, theirs) and Batch 5 (step progression, mine).
- `automation/queue/slices.json` — triage slice `owlory-ui-regression-batch-5-surface-triage` classified, then flipped to `done`. Queued the implementation slice `owlory-ui-regression-batch-5-home-protocol-run-step-progression` with explicit allowed_paths and required_validations. Reconciled with Agent B's shipped slices (`home-protocol-archive-swipe-affordance` and `owlory-ui-regression-batch-4-home-protocol-archive-restore`) that landed on main during the same window.
- `SecondBrain/INDEX.md` — entries from both agents kept (union resolution).
- `automation/handoffs/20260515T033821Z-owlory-ui-regression-batch-5-surface-triage.json`
- `SecondBrain/sessions/2026-05-14/233821-owlory-ui-regression-batch-5-surface-triage.md`

## Coverage goal for the queued implementation slice

- Reuse `--owlory-ui-seed-home-protocol-run-continue-item` if its single-step protocol suffices; only add a new multi-step seed arg if proving sequential progression requires more than one pending step.
- Open the active-run sheet via the Today Continue row (route already smoke-covered).
- Tap the Complete action on the first pending step.
- Assert the step transitions out of pending state.
- If a second step exists, assert it remains the only pending step.

Required new infrastructure (inside the implementation slice scope):

- Accessibility identifiers on protocol step rows and the Complete action button: `home.protocolRun.step.<uuid>` and `home.protocolRun.step.action.complete.<uuid>`.
- New XCUITest class `OwloryUITests/HomeProtocolRunStepRegression` — separate from the shipped `HomeProtocolRegression` (which already covers Batch 4 archive/restore). Add it to the bare `make ui-regression` lane alongside `HomeProtocolRegression`; the `DOMAIN=home` filter should run both classes.

proof_level target for the implementation slice: `running-app-smoke`.

## Validation

- `python3 automation/context/build_context.py --slice-id owlory-ui-regression-batch-5-surface-triage` — exit 0.
- `python3 automation/supervisor/run_next.py --dry-run` — selected this slice before merge; post-completion picks the queued implementation slice next.
- `make architecture` — passed.
- `make automation-check` — 57 tests passed.
- `git diff --check` — clean.

## Lane Boundary

`doc-only`. No XCUITest code, no product behavior changes, no screenshot/device/TestFlight claims. The triage's claim is the sub-behavior decision and the scoped implementation slice queued behind it.

## Residual Risk

- Slice numbering matters because the queue is now multi-agent. Anyone reviewing this work should note that Batch 4 = archive/restore (HomeProtocolRegression, Agent B), Batch 5 = step progression (queued, this triage).
- Active-run step progression is one of several Home-protocols sub-behaviors. Skip, revert, schedule, and template editing remain deferred; each needs its own future triage if prioritized.
- The implementation slice will add new accessibility *identifiers* on the same view that already carries Group-A *labels* and (from Agent B) `home.protocol.row.*` and `home.protocol.archived.*` identifiers. All four namespaces coexist.
