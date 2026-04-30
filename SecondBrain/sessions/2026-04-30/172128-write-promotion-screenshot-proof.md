# write-promotion-screenshot-proof

## Prompt

Preserve screenshot evidence for the already flow-verified Write note -> Home task -> source-note return path. Do not add product behavior or claim screenshot proof for untested destinations.

## Interpretation

- This is a proof-preservation slice only.
- The previous flow proof already exercised the running app.
- This slice upgrades the Write-to-Home-task promotion path only when screenshots are repo-managed and documented.

## Plan

1. Confirm clean mirrored `main`.
2. Build supervisor context and dry-run scope.
3. Preserve the four screenshots captured during the flow proof under `automation/proofs/`.
4. Add a compact proof README with evidence mapping and hashes.
5. Update the Write domain doc without expanding the claim to Today or protocol destinations.
6. Record the automation handoff and validate.

## Files Inspected

- `AGENTS.md`
- `docs/README.md`
- `docs/workflows/validation.md`
- `docs/product/domains/write.md`
- `automation/queue/slices.json`
- `automation/handoffs/20260430T210932Z-write-note-promotion-flow-verification.json`

## Validation

- `git status --short`
- `git rev-list --left-right --count HEAD...@{u}`
- `python3 automation/context/build_context.py --slice-id write-promotion-screenshot-proof`
- `python3 automation/supervisor/run_next.py --dry-run`
- `make architecture`
- `make automation-check`
- `git diff --check`
- `git diff --cached --check`

## Outcome

- Preserved four screenshots under `automation/proofs/write-promotion-screenshot-proof/`.
- Added a proof README that maps each screenshot to the exact claim it supports and records SHA-256 hashes.
- Updated the Write domain doc to say only the Write-to-Home-task promotion/status/source-note return path is screenshot-verified.
- Left Today status-only promotion, protocol status-only promotion, real-device proof, TestFlight proof, and durable screenshot automation as unclaimed.
