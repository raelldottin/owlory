# repo-automation-sync-tooling

- Timestamp: 2026-05-21T20:29:35Z
- Slice: `repo-automation-sync-tooling`
- Proof level: automation-tested

## Summary

Added the manifest-driven reusable automation sync tool. `Tools/repo-automation-sync.sh` now supports `--check`, `--sync`, `--target`, `--source`, and `--manifest`, reads `automation/reusable-manifest.json`, preserves executable mode where requested, removes stale files only under manifest-owned `delete_stale` paths, and rejects Owlory-specific state unless a manifest entry explicitly opts in.

## Files Changed

- `Tools/repo-automation-sync.sh`
- `automation/reusable-manifest.json`
- `automation/tests/test_repo_automation_sync.py`
- `docs/workflows/repo-automation.md`
- `docs/workflows/validation.md`
- `automation/queue/slices.json`
- `automation/handoffs/20260521T202935Z-repo-automation-sync-tooling.json`
- `SecondBrain/INDEX.md`
- `SecondBrain/sessions/2026-05-21/162935-repo-automation-sync-tooling.md`

## Validation

- `git pull --rebase origin main`
- `python3 automation/context/build_context.py --slice-id repo-automation-sync-tooling`
- `python3 automation/supervisor/run_next.py --dry-run`
- `python3 -m unittest automation.tests.test_repo_automation_sync`
- `tmpdir=$(mktemp -d /tmp/repo-automation-manifest.XXXXXX); Tools/repo-automation-sync.sh --sync --target "$tmpdir"; Tools/repo-automation-sync.sh --check --target "$tmpdir"; rm -rf "$tmpdir"`
- `make architecture`
- `make automation-check`
- `make pyright`
- `python3 -m json.tool automation/reusable-manifest.json`
- `python3 -m json.tool automation/queue/slices.json`
- `python3 -m json.tool automation/handoffs/20260521T202935Z-repo-automation-sync-tooling.json`
- `git diff --check`

## Notes

- The real `/Users/raelldottin/Documents/Personal/repo-automation` folder was not modified in this slice.
- The next slice, `repo-automation-external-repo-bootstrap`, owns initializing and populating that external folder with the tested sync tool.
- Automatic hooks are still not wired; `repo-automation-auto-update-gate` owns that later.
