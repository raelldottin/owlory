# release-changelog-required-gate

- Timestamp: 2026-05-21T11:21:42Z
- Slice: `release-changelog-required-gate`
- Proof level: automation-tested

## Summary

Hardened `Tools/bump-version.sh` so release metadata cannot be changed unless `CHANGELOG.md` exists and contains a promotable `## [Unreleased]` section. This closes the previous warning-only behavior where a version/build bump could proceed without updating release notes.

## Files Changed

- `Tools/bump-version.sh`
- `automation/tests/test_bump_version.py`
- `docs/workflows/release.md`
- `automation/queue/slices.json`
- `automation/handoffs/20260521T112142Z-release-changelog-required-gate.json`
- `SecondBrain/INDEX.md`
- `SecondBrain/sessions/2026-05-21/071142-release-changelog-required-gate.md`

## Validation

- `git pull --rebase origin main`
- `python3 automation/context/build_context.py --slice-id release-changelog-required-gate`
- `python3 automation/supervisor/run_next.py --dry-run`
- `python3 -m unittest automation.tests.test_bump_version`
- `make architecture`
- `make automation-check`
- `make pyright`
- `python3 -m json.tool automation/queue/slices.json`
- `python3 -m json.tool automation/handoffs/20260521T112142Z-release-changelog-required-gate.json`
- `git diff --check`

## Notes

- No real `MARKETING_VERSION` or `CURRENT_PROJECT_VERSION` values changed.
- The new regression tests execute copied real scripts inside temporary repositories and prove missing changelog and missing `## [Unreleased]` both fail without mutating project metadata.
- The release workflow now documents the hard changelog precondition for `./Tools/bump-version.sh`.
