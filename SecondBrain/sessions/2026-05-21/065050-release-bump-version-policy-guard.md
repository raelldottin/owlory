# Release Bump Version Policy Guard

Date: 2026-05-21
Type: release automation tests
Proof level: automation-tested

## Prompt

Start the next supervisor-selected slice.

Selected slice: `release-bump-version-policy-guard`

## Changed

- Added `automation/tests/test_bump_version.py`.
- The tests copy and execute the real `Tools/bump-version.sh` and `Tools/set-build-number.sh` in temporary project fixtures.
- Covered `major`, `minor`, and `patch` bump behavior from `0.2.3`.
- Covered synchronized `MARKETING_VERSION` replacement across multiple project configurations.
- Covered `CURRENT_PROJECT_VERSION` timestamp generation as 14 numeric digits within the App Store Connect 18-character limit.
- Covered `CHANGELOG.md` promotion to a dated release heading in the fixture.
- Covered invalid bump type rejection without mutating the project or changelog fixture.
- Covered explicit build-number updates without changing `MARKETING_VERSION`.
- Covered invalid and too-long build-number rejection without mutating the project fixture.
- Marked `release-bump-version-policy-guard` done in the queue.

## Boundary

- No real `MARKETING_VERSION` value changed.
- No real `CURRENT_PROJECT_VERSION` value changed.
- No real changelog file changed.
- No script changes were required.
- No app code, archive, TestFlight, App Store Connect, or MDM behavior is claimed.

## Validation

- `git fetch origin main && git pull --rebase origin main` passed.
- `python3 automation/context/build_context.py --slice-id release-bump-version-policy-guard` passed.
- `python3 automation/supervisor/run_next.py --dry-run` passed before edits and selected `release-bump-version-policy-guard`.
- `python3 -m unittest automation.tests.test_bump_version` passed, 4 tests.
- `python3 -m json.tool automation/queue/slices.json` passed.
- `python3 -m json.tool automation/handoffs/20260521T105050Z-release-bump-version-policy-guard.json` passed.
- `make architecture` passed.
- `make automation-check` passed.
- `make pyright` passed.
- `git diff --check` passed.

## Next

No adjacent release-versioning implementation slice remains. Run the supervisor/clean-stop gate to choose broader next work.
