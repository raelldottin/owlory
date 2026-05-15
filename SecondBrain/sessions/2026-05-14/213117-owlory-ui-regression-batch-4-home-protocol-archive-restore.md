# owlory-ui-regression-batch-4-home-protocol-archive-restore

## Summary

Implemented UI regression Batch 4 for Home protocol template archive/restore management.

The maintained Lane 2 regression suite now has `HomeProtocolRegression`, which seeds one Home protocol template without an active run, verifies it appears in the active Protocols list, archives it through the explicit protocol-level affordance, verifies it moves to Archived Protocols, restores it, and verifies it returns active.

## What Changed

- Added `--owlory-ui-seed-home-protocol-template` with stable fixture ID `8B82E9F0-7A18-4B5D-A23E-3CF9C61C7A1D`.
- Added Home accessibility identifiers for the active protocol row, direct archive button, archived protocol row, and restore button.
- Added `OwloryUITests/HomeProtocolRegression`.
- Wired `make ui-regression DOMAIN=home` and added HomeProtocolRegression to bare `make ui-regression`.
- Updated Home, UI regression, UI testing hygiene, validation, and roadmap docs.
- Marked the Batch 4 queue entry done.

## Validation

Passed:

- `python3 -m json.tool automation/queue/slices.json`
- `python3 automation/context/build_context.py --slice-id owlory-ui-regression-batch-4-home-protocol-archive-restore`
- `python3 automation/supervisor/run_next.py --dry-run`
- `make architecture`
- `make test-domain DOMAIN=home`
- `make ui-regression DOMAIN=home`
- `make automation-check`
- `git diff --check`

During implementation, `make ui-regression DOMAIN=home` caught two harness issues that were fixed in-slice:

- The archived row identifier hid the Restore child control; the row now contains children for accessibility so both row and button stay targetable.
- A retry could reuse a prior failed app process; HomeProtocolRegression now terminates before launch so the debug seed hook starts from a deterministic active-template fixture.

## Proof

Proof level: `running-app-smoke, XCUITest-backed`.

The proof is intentionally narrow: one seeded Home protocol template can move active -> archived -> active through Home UI affordances.

## Remaining Risk

- No per-step archive behavior exists or was added.
- Active-run lifecycle, protocol schedule labels, and step revert remain separate surfaces.
- No screenshot, device, or TestFlight proof was captured for this Home protocol archive/restore path.
- No next Lane 2 regression surface is selected.

## Next

Clean stop unless a future prompt selects another concrete UI regression surface. Start with triage before adding another Batch 5 implementation.
