# owlory-ui-test-testflight-proof-retry

## Prompt

The user reported that a fresh clean TestFlight build was installed on the paired iPhone.

## Interpretation

This is a second TestFlight proof retry. The first gate remains provenance: installed bundle metadata and Build Info must match committed source before any Continue UI proof can be captured.

## What Happened

- Local `main` and `origin/main` are mirrored at `c70ab71f9402ab2b97f0676260c171b868c22ae4`.
- Local committed Xcode build remains `20260417081904`.
- The paired iPhone is reachable through `devicectl`.
- The installed `com.raelldottin.owlory` app now reports bundle version `20260417081912`.
- `git log --all -S20260417081912 -- owlory_xcode/Owlory.xcodeproj/project.pbxproj` found no committed source state containing that build number.
- The provenance comparison fails before Build Info screenshot or Continue capture.

## Files Edited

- `automation/proofs/owlory-ui-testflight-proof/20260513T163220Z-retry/README.md`
- `automation/proofs/owlory-ui-testflight-proof/20260513T163220Z-retry/device-apps.json`
- `automation/proofs/owlory-ui-testflight-proof/20260513T163220Z-retry/manifest.json`
- `automation/proofs/owlory-ui-testflight-proof/README.md`
- `automation/queue/slices.json`
- `automation/handoffs/20260513T163220Z-owlory-ui-test-testflight-proof-retry.json`
- `SecondBrain/INDEX.md`
- `SecondBrain/sessions/2026-05-13/123220-owlory-ui-test-testflight-proof-retry.md`

## Validation

Passed:

- `python3 automation/context/build_context.py --slice-id owlory-ui-test-testflight-proof-retry`
- `make build-provenance`
- `git fetch origin main`
- `git rev-list --left-right --count HEAD...@{u}`
- `git log --all --oneline -S20260417081912 -- owlory_xcode/Owlory.xcodeproj/project.pbxproj`
- `xcrun devicectl device info apps --device 691FB5B7-A8F2-5AE4-BE95-EC1CABC5872F --bundle-id com.raelldottin.owlory --json-output /tmp/owlory-device-apps-fresh.json`

Expected gate failure:

- `./Tools/verify-build-provenance.sh --expected-build 20260417081912 --expected-commit c70ab71f9402ab2b97f0676260c171b868c22ae4`

Required before final handoff:

- `make architecture`
- `make automation-check`
- `git diff --check`
- `make clean-stop` after commit/push

## Outcome

The retry remains blocked. The app installed on the paired iPhone is newer than the previous failed retry, but its build number still is not represented in committed source. No Build Info screenshot, natural-data Continue route, or `testflight-verified` proof was captured.

## Next Step

Create/upload/install a TestFlight build whose bundle version matches committed source. Only then rerun the Build Info provenance gate and Continue proof capture.
