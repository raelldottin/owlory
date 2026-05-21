# Release Changelog Foundation

Date: 2026-05-21
Type: release documentation
Proof level: doc-only + automation-tested

## Prompt

Start the next supervisor-selected slice.

Selected slice: `release-changelog-foundation`

## Changed

- Added top-level `CHANGELOG.md`.
- Created an `[Unreleased]` section with stable categories:
  - Added
  - Changed
  - Fixed
  - Localization
  - Release And Validation
- Documented that `CHANGELOG.md` is user/support-facing marketing-version release-note state, not operational history.
- Updated `docs/workflows/release.md` with a Changelog Policy and moved Normal Release step 1 to review `[Unreleased]` before running `bump-version.sh`.
- Updated the `test_bump_version.py` fixture to match the real changelog category shape.
- Marked `release-changelog-foundation` done in the queue.

## Boundary

- No current-cycle notes were backfilled.
- No `MARKETING_VERSION` value changed.
- No `CURRENT_PROJECT_VERSION` value changed.
- No script behavior changed.
- No app behavior, archive, TestFlight, App Store Connect, or MDM rollout behavior is claimed.

## Validation

- `git fetch origin main && git pull --rebase origin main` passed.
- `python3 automation/context/build_context.py --slice-id release-changelog-foundation` passed.
- `python3 automation/supervisor/run_next.py --dry-run` passed before edits and selected `release-changelog-foundation`.
- `python3 -m unittest automation.tests.test_bump_version` passed.
- `python3 -m json.tool automation/queue/slices.json` passed.
- `python3 -m json.tool automation/handoffs/20260521T111355Z-release-changelog-foundation.json` passed.
- `make architecture` passed.
- `make automation-check` passed.
- `make pyright` passed.
- `git diff --check` passed.

## Next

Recommended next slice: `release-changelog-current-cycle-backfill`.

Reason: the changelog foundation now exists, satisfying the backfill slice entry condition.
