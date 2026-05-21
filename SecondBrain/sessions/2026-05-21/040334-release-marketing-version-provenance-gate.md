# Release Marketing Version Provenance Gate

Date: 2026-05-21
Type: release automation
Proof level: automation-tested

## Prompt

Start the next supervisor-selected slice.

Selected slice: `release-marketing-version-provenance-gate`

## Changed

- `Tools/verify-build-provenance.sh` now computes the committed `MARKETING_VERSION` at `HEAD:owlory_xcode/Owlory.xcodeproj/project.pbxproj`.
- Verifier output now includes `Committed marketing version: ...`.
- `--require-clean` now fails when on-disk `MARKETING_VERSION` differs from committed HEAD, with app-version remediation text.
- Informational verifier mode still exits 0 for app-version drift and prints advisory committed-state output.
- Added verifier tests for matching committed marketing version, require-clean failure, and advisory mode.
- Release-preflight tests now assert the committed marketing-version output line.
- Updated `.githooks/pre-push`, `Tools/release-preflight.sh`, `docs/workflows/release.md`, and `docs/workflows/validation.md` to name both `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` provenance.
- Updated `docs/product/domains/app-runtime.md` to remove the previous missing `MARKETING_VERSION` enforcement gap.
- Marked `release-marketing-version-provenance-gate` done in the queue.

## Boundary

- No `MARKETING_VERSION` value changed.
- No `CURRENT_PROJECT_VERSION` value changed.
- No app code changed.
- No archive upload, TestFlight install, App Store Connect, or MDM rollout proof is claimed.
- The slice max file count was expanded from 11 to 12 to keep app-runtime status synced with the implemented gate.

## Validation

- `git fetch origin main && git pull --rebase origin main` passed.
- `python3 automation/context/build_context.py --slice-id release-marketing-version-provenance-gate` passed.
- `python3 automation/supervisor/run_next.py --dry-run` passed before edits and selected `release-marketing-version-provenance-gate`.
- `python3 -m unittest automation.tests.test_verify_build_provenance automation.tests.test_release_preflight` passed, 9 tests.
- `python3 -m json.tool automation/queue/slices.json` passed.
- `make architecture` passed.
- `make automation-check` passed with Pyright 0 errors / 0 warnings and 95 automation tests passing.
- `./Tools/verify-build-provenance.sh` passed and printed `Committed marketing version: matches HEAD`.
- `git diff --check` passed.

## Next

Recommended next slice: `release-bump-version-policy-guard`.

Reason: it is the remaining queued release implementation slice after policy and committed app-version provenance are in place.
