# release-provenance-git-hooks

## Prompt

Add a committed pre-push hook that blocks dirty or unreproducible release provenance before push, while keeping Xcode Archive guarded by the explicit release preflight.

## Interpretation

The worktree already contained an Xcode `CURRENT_PROJECT_VERSION` bump from `20260417081904` to `20260513172951`. Because the requested hook intentionally refuses dirty/uncommitted release metadata, that build-number bump had to be committed first rather than folded into the hook implementation.

## What Changed

- Committed the pre-existing TestFlight build-number bump as release metadata.
- Added `.githooks/pre-push`.
- Documented hook installation with `git config core.hooksPath .githooks`.
- Documented that the hook is push-time enforcement only and cannot replace the pre-Archive release gate.
- Recorded the slice in the queue, handoff, roadmap, and validation docs.

## Validation

- `python3 automation/context/build_context.py --slice-id release-provenance-git-hooks`
- `python3 automation/supervisor/run_next.py --dry-run`
- `.githooks/pre-push`
- Dirty-tree negative check: `touch .owlory-pre-push-dirty-test`, `.githooks/pre-push` refused the push, then the file was removed.
- `make architecture`
- `make build-provenance`
- `make automation-check`
- `git diff --check`

## Outcome

The release build-number bump is committed, the pre-push hook is committed and installed locally with `git config core.hooksPath .githooks`, and the hook passes from a clean committed state.

## Residual Risk

The hook must be installed per local checkout. Xcode Organizer can still archive local state, so TestFlight archive work must continue to run the release preflight immediately before Archive.
