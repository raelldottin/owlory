# queue-release-discipline-preflight-and-hooks

## Prompt

Queue a stricter release-discipline slice after repeated TestFlight provenance failures.

## Interpretation

The repo already has the committed-build-number verifier and `.githooks/pre-push`. The missing implementation lane is a canonical `make release-preflight` command that proves Archive readiness in one place and fails on dirty tree, unmirrored branch, and uncommitted `CURRENT_PROJECT_VERSION` drift.

## What Changed

- Added queued slice `release-discipline-preflight-and-hooks` to `automation/queue/slices.json`.
- Scoped the slice to `make release-preflight`, hook alignment, docs, and focused automation tests.
- Explicitly excluded app behavior changes and TestFlight proof claims.

## Validation

- `python3 -m json.tool automation/queue/slices.json`
- `python3 -m json.tool automation/handoffs/20260513T203413Z-queue-release-discipline-preflight-and-hooks.json`
- `python3 automation/context/build_context.py --slice-id release-discipline-preflight-and-hooks`
- `python3 automation/supervisor/run_next.py --dry-run`
- `git diff --check`

## Outcome

The new queued slice is the next supervisor-selected implementation slice.
