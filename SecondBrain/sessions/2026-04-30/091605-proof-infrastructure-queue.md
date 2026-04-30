# proof-infrastructure-queue

## Prompt

Add supervisor queue slices for the remaining proof-infrastructure roadmap:

- `owlory-running-app-smoke`
- `write-note-promotion-flow-verification`
- `write-promotion-screenshot-proof`
- `legacy-handoff-proof-field-backfill`

## Interpretation

- Legacy-doc cleanup is complete and should not keep absorbing effort.
- The next work should raise proof levels for the running app and Write promotion flows.
- These are proof and automation slices; product behavior changes should be treated as blockers unless a future slice explicitly owns them.

## Outcome

- Preserved the existing `owlory-running-app-smoke` slice and added `make architecture` to its required validation set.
- Added `write-note-promotion-flow-verification` after the running-app smoke slice.
- Added `write-promotion-screenshot-proof` after flow verification.
- Added optional `legacy-handoff-proof-field-backfill` after screenshot proof.
- Kept dependencies ordered so the supervisor advances from the completed smoke proof into Write flow verification once the workspace is clean.

## Validation

- `python3 -m json.tool automation/queue/slices.json`
- `python3 automation/context/build_context.py --slice-id write-note-promotion-flow-verification`
- `python3 automation/supervisor/run_next.py --dry-run`
- `make architecture`
- `make automation-check`
- `git diff --check`

## Remaining Risk

- These slices classify the work; they do not yet prove the running app, flow, or screenshots.
- The supervisor dry-run correctly stops until pre-existing smoke-runner documentation changes are committed or otherwise cleared, because `automation/README.md` is dirty outside the next Write slice scope.
