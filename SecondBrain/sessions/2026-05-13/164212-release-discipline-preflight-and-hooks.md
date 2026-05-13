# release-discipline-preflight-and-hooks

## Prompt

Continue with the queued release-preflight work.

## Interpretation

Repeated TestFlight proof attempts showed the same workflow failure: pre-push can pass after the fact, but Xcode Archive can still be dirty if the archive happens before the build-number bump is committed. The missing harness is a single Archive-readiness command that must run after source is clean, committed, pushed, and mirrored.

## What Changed

- Added `Tools/release-preflight.sh`.
- Added `make release-preflight`.
- Made `make release-check` depend on `release-preflight`.
- Added `./Tools/validate.sh release-preflight`.
- Added focused automation tests for:
  - clean mirrored pass
  - dirty tree failure
  - uncommitted build-number bump failure
  - local branch ahead of upstream failure
- Updated release, validation, PR hygiene, and roadmap docs.
- Marked the queue slice done.

## Validation

- `python3 automation/context/build_context.py --slice-id release-discipline-preflight-and-hooks`
- `python3 automation/supervisor/run_next.py --dry-run`
- `python3 -m unittest automation.tests.test_release_preflight automation.tests.test_verify_build_provenance`
- `make architecture`
- `make automation-check`
- `git diff --check`

`make release-preflight` must be run after final push because the command intentionally requires `HEAD...@{u}` to be `0 0`.

## Outcome

Pending final commit, push, and post-push `make release-preflight` validation.
