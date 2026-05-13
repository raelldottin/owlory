# queue-parked-proof-and-localization-slices

## Prompt

Add explicit queue entries for the near-term Build Info improvement plus parked TestFlight proof, localization review intake, and optional UI regression expansion work. Block or defer work whose entry condition is not yet satisfied.

## Interpretation

The goal is queue hygiene, not implementation. The next agent should see the real next useful slice (`build-info-display-git-status`) while TestFlight, translation, and broad UI-regression work remain blocked until their entry conditions are true.

The queue schema does not support `id`, `summary`, `entry_condition`, or `proof_level_target` fields. These were translated into the repository's supported shape: `slice_id`, `title`, `status`, `priority`, `domain`, `allowed_paths`, `required_validations`, `depends_on`, `max_files_changed`, and a remediation-oriented `notes` string.

## Files Edited

- `SecondBrain/INDEX.md`
- `SecondBrain/sessions/2026-05-13/023215-queue-parked-proof-and-localization-slices.md`
- `automation/queue/slices.json`
- `docs/workflows/roadmap-status.md`

## Outcome

- Added queued slice `build-info-display-git-status`.
- Added blocked slice `owlory-ui-test-testflight-proof-retry`.
- Added blocked slice `owlory-ui-test-testflight-proof-capture`.
- Added blocked slice `app-localization-first-locale-review-intake`.
- Added blocked slice `owlory-ui-regression-expansion-next-surface`.
- Added a `Parked Proof And Localization Work` section to roadmap status so blocked slices are visible and not accidentally started.

## Validation

To run before handoff:

- `make architecture`
- `make automation-check`
- `python3 automation/supervisor/run_next.py --dry-run`
- `git diff --check`

## Proof And Risk

Proof level: `doc-only`. No product code, test code, build settings, or localization resources changed.

The blocked slices rely on their notes for entry conditions because the current queue schema does not have a first-class `entry_condition` field. That is acceptable for now; a future supervisor-schema slice could promote entry conditions to a machine-checked field.
