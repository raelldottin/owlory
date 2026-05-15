# owlory-ui-regression-next-surface-triage

## Prompt

Expand Owlory's maintained UI regression coverage by selecting and scoping the next surface beyond Today Continue. Preferred starting candidate was Write unless investigation showed another surface was higher value. Triage only; no XCUITest implementation.

## Assessment

The prompt's baseline was slightly stale. Current repo state already has:

- `TodayContinueRegression` for Today Continue source visibility, source-derived routing, and Focus row actions.
- `WriteCaptureRegression` for Write capture inbox row, capture entry affordance, and Add to Today promotion visibility.
- `TrainRegression` for Train active Today -> History transition.

That means selecting Write again would duplicate Batch 2 rather than broaden Lane 2.

## Decision

Selected surface: Home protocols.

Batch 4 target: protocol template archive/restore management.

Why:

- Home protocols have strong domain coverage and Today Continue route smoke for active runs, but Home's own protocol template management has no Lane 2 regression.
- Recent protocol archive-affordance work made a concrete UI contract worth preserving: whole-protocol archive should be discoverable, but step/item rows must not imply per-step archive.
- The target can stay narrow and deterministic: one template, archive, archived section, restore.

## Candidate Classification

| Surface | Current proof | Decision |
| --- | --- | --- |
| Write | Batch 2 already shipped as `WriteCaptureRegression`; selected promotion paths also have proof artifacts. | Do not repeat for Batch 4. |
| Home protocols | Domain coverage plus active-run Continue smoke; template archive/restore UI lacks Lane 2 regression. | Select. |
| Train | Batch 3 already shipped as `TrainRegression`. | Do not repeat for Batch 4. |
| Patterns | No concrete UI behavior change currently named. | Defer. |
| Localization layout | All-locale screenshots exist; reviewed translations are still blocked. | Defer until translation/layout risk exists. |

## Queued Implementation Slice

`owlory-ui-regression-batch-4-home-protocol-archive-restore`

Coverage goal:

- Seed one active Home protocol template with no active run.
- Open Home and assert the template appears in the active protocol list.
- Assert a direct protocol-level archive affordance exists.
- Archive the template.
- Assert it leaves the active list and appears in Archived Protocols with restore.
- Restore it and assert it returns active.

Needed implementation support:

- New debug-only seed launch argument for one Home protocol template.
- Stable identifiers for active protocol row, archive action, archived row, and restore action.
- New `HomeProtocolRegression` class.
- `make ui-regression DOMAIN=home` support.

Out of scope:

- Per-step archive.
- Active-run lifecycle.
- Schedule-window labels.
- Step revert.
- Screenshot/device/TestFlight proof.
- Broad Home regression coverage.

## Files Edited

- `automation/queue/slices.json`
- `docs/product/domains/home.md`
- `docs/workflows/ui-regression-plan.md`
- `docs/workflows/ui-testing-hygiene.md`
- `docs/workflows/roadmap-status.md`
- `automation/handoffs/20260515T005219Z-owlory-ui-regression-next-surface-triage.json`
- `SecondBrain/INDEX.md`
- `SecondBrain/sessions/2026-05-14/205219-owlory-ui-regression-next-surface-triage.md`

## Validation

- `python3 automation/context/build_context.py --slice-id owlory-ui-regression-next-surface-triage` — passed.
- `python3 automation/supervisor/run_next.py --dry-run` — selected `owlory-ui-regression-batch-4-home-protocol-archive-restore`.
- `python3 -m json.tool automation/queue/slices.json` — passed.
- `make architecture` — passed.
- `make automation-check` — 57 tests passed.
- `git diff --check` — clean.

## Residual Risk

This is doc-only and queue-only. No UI test exists yet for Home protocol archive/restore; the queued implementation slice owns that proof.
