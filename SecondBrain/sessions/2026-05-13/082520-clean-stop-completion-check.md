# clean-stop-completion-check

## Prompt

Encode the standard that "all slices are complete" only when queue state, Git/repo state, and proof/parking-lot state all agree.

## Interpretation

This is a harness slice, not product work. The repo already had supervisor dry-run, Git checks, and handoff evidence fields, but future agents still needed chat context to know how to combine those signals. The fix is a read-only `make clean-stop` command plus explicit parked-slice entry conditions.

## Files Edited

- `Makefile`
- `Tools/agent-handoff.sh`
- `Tools/clean-stop-check.py`
- `Tools/validate.sh`
- `automation/README.md`
- `automation/queue/slices.json`
- `automation/schemas/slice.schema.json`
- `automation/supervisor/policy.py`
- `automation/tests/test_harness.py`
- `docs/README.md`
- `docs/workflows/agent-handoff.md`
- `docs/workflows/roadmap-status.md`
- `docs/workflows/validation.md`
- `automation/handoffs/20260513T122520Z-clean-stop-completion-check.json`
- `SecondBrain/INDEX.md`
- `SecondBrain/sessions/2026-05-13/082520-clean-stop-completion-check.md`

## Outcome

- Added `python3 Tools/clean-stop-check.py`.
- Added `make clean-stop` and `./Tools/validate.sh clean-stop`.
- The clean-stop check verifies:
  - no open `queued`, `in_progress`, or future `ready` slices
  - clean Git workspace
  - mirrored upstream state
  - supervisor dry-run returns no eligible queued slice
  - blocked/deferred slices have explicit `entry_condition` values
- Added optional queue `entry_condition` schema support.
- Added queue integrity enforcement for blocked/deferred entry conditions.
- Backfilled explicit entry conditions on parked slices.
- Updated handoff and validation docs so this standard lives in the repo instead of chat.

## Validation

Required before final handoff:

- `python3 automation/context/build_context.py --slice-id clean-stop-completion-check`
- `python3 automation/supervisor/run_next.py --dry-run`
- `make clean-stop`
- `make architecture`
- `make automation-check`
- `git diff --check`

## Residual Risk

`make clean-stop` proves there is no currently actionable queued/in-progress work. It does not mean parked external-input work is finished, and it does not prove future TestFlight, translation-review, device, or UI-expansion prerequisites exist.
