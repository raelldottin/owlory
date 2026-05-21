# repo-automation-auto-update-gate

- Timestamp: 2026-05-21T21:19:39Z
- Slice: `repo-automation-auto-update-gate`
- Proof level: automation-tested + hook-tested

## Summary

Added the safe automatic update gate for Owlory's reusable repo automation. The sync tool now has `--auto-update`, Make has `repo-automation-check` and `repo-automation-update`, and `.githooks/pre-push` runs the update target only when the pending push touches manifest-owned reusable automation sources.

## Behavior

- `--auto-update` refuses a missing target, a non-Git target, or a target with local dirt before syncing.
- `--auto-update` syncs manifest-owned files and immediately verifies check-mode passes.
- The pre-push hook does not commit or push the external repository.
- External Git commit and remote push remain explicit operator actions.

## External Repo State

- Path: `/Users/raelldottin/Documents/Personal/repo-automation`
- Remote: `https://github.com/raelldottin/repo-automation.git`
- Branch: `main`
- HEAD: `7eb3beff41aad923122b8674cf0129ac48c0bf91`
- Mirror: `0 0`
- Sync check: `make repo-automation-check` passes

## Files Changed In Owlory

- `.githooks/pre-push`
- `Makefile`
- `Tools/repo-automation-sync.sh`
- `automation/tests/test_repo_automation_sync.py`
- `docs/workflows/repo-automation.md`
- `docs/workflows/validation.md`
- `automation/queue/slices.json`
- `automation/handoffs/20260521T211939Z-repo-automation-auto-update-gate.json`
- `SecondBrain/INDEX.md`
- `SecondBrain/sessions/2026-05-21/171939-repo-automation-auto-update-gate.md`

## Validation

- `python3 automation/context/build_context.py --slice-id repo-automation-auto-update-gate`
- `python3 automation/supervisor/run_next.py --dry-run`
- `bash -n Tools/repo-automation-sync.sh .githooks/pre-push`
- `python3 -m unittest automation.tests.test_repo_automation_sync`
- `make repo-automation-update`
- `git -C /Users/raelldottin/Documents/Personal/repo-automation commit -m "Add automatic update gate"`
- `git -C /Users/raelldottin/Documents/Personal/repo-automation push origin main`
- `make repo-automation-check`
- `make architecture`
- `make automation-check`
- `make pyright`
- `Tools/repo-automation-sync.sh --check --target /Users/raelldottin/Documents/Personal/repo-automation`
- `python3 -m json.tool automation/queue/slices.json`
- `python3 -m json.tool automation/handoffs/20260521T211939Z-repo-automation-auto-update-gate.json`
- `git diff --check`

## Notes

- Unit tests cover missing target, non-Git target, dirty target refusal, and clean Git target auto-update success.
- The external repo was explicitly committed and pushed by the operator path after local sync; the hook itself remains local-sync only.
- `repo-automation-consumer-adoption-smoke` is the next slice.
