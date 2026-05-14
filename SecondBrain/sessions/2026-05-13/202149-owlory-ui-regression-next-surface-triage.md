# owlory-ui-regression-next-surface-triage

## Summary

Selected **Train active/history transition** as the next UI regression expansion surface.

The triage compared:

- Write promotion
- Home protocols
- Train
- Patterns
- Localization layout

Train was selected because it is small, deterministic, and distinct from the existing Today Continue regression batch. The current Train docs already identify the active Today to History transition as missing UI regression proof.

## Selected Batch 2 Scope

- Seed one planned Train session for the current day.
- Open the Train tab and assert the session appears in the active Today surface.
- Resolve the session through one visible action, preferably `Complete`.
- Assert the session leaves the active Today surface and appears in History.

## Boundary

No product code or XCUITest code changed in this slice.

Out of scope for the queued implementation:

- recurrence rollover edge cases
- voice/reflection fallback
- multiple Train statuses in one slice
- Continue routing
- screenshot proof
- device proof
- TestFlight proof

## Validation

```bash
python3 automation/context/build_context.py --slice-id owlory-ui-regression-next-surface-triage
python3 automation/supervisor/run_next.py --dry-run
python3 automation/supervisor/run_next.py --dry-run
make architecture
make automation-check
git diff --check
```

The second supervisor dry-run verifies that the newly queued implementation slice is selectable and scoped to Train regression work.

## Next

Run `owlory-ui-regression-expansion-next-surface`.
