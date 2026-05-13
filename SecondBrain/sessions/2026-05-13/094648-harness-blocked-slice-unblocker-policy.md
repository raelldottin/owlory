# harness-blocked-slice-unblocker-policy

## Prompt

Blocked slices should not be executed directly. Add a harness policy that reports blocked slices, their missing entry conditions, and the smallest unblocker slice that can move the work forward honestly.

## Interpretation

This is a harness policy slice, not product work. The correct pattern is:

```text
blocked target -> unblocker slice -> blocked target becomes queued only after its entry condition is true
```

The immediate useful unblocker is TestFlight build preparation, not TestFlight proof capture.

## Files Edited

- `automation/README.md`
- `automation/queue/slices.json`
- `automation/schemas/slice.schema.json`
- `automation/supervisor/policy.py`
- `automation/supervisor/run_next.py`
- `automation/tests/test_harness.py`
- `docs/workflows/roadmap-status.md`
- `docs/workflows/validation.md`
- `automation/handoffs/20260513T134648Z-harness-blocked-slice-unblocker-policy.json`
- `SecondBrain/INDEX.md`
- `SecondBrain/sessions/2026-05-13/094648-harness-blocked-slice-unblocker-policy.md`

## Outcome

- Added optional `recommended_unblocker` support to queue slice records.
- Queue integrity rejects `recommended_unblocker` values that do not point at known slice IDs.
- Added `policy.blocked_slice_reports`.
- Added `python3 automation/supervisor/run_next.py --dry-run --include-blocked`.
- Added docs explaining that blocked slices are not executable work.
- Queued `owlory-release-clean-testflight-build-prep` as the immediate TestFlight-proof unblocker.
- Added deferred unblocker records for first-locale review packet preparation and next UI regression surface triage so `recommended_unblocker` values point at real queue records without making those lanes executable too early.
- Left TestFlight proof retry/capture blocked behind their true external entry conditions.

## Validation

Required before handoff:

- `python3 automation/context/build_context.py --slice-id harness-blocked-slice-unblocker-policy`
- `python3 automation/supervisor/run_next.py --dry-run --include-blocked`
- `make architecture`
- `make automation-check`
- `git diff --check`

## Residual Risk

The harness reports unblocker relationships but does not generate unblocker slices automatically. Localization and UI-regression unblockers are present as deferred records and must stay non-executable until their own entry conditions are true.
