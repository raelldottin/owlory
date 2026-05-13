# owlory-ui-test-testflight-proof-retry

## Prompt

The user uploaded new TestFlight provenance screenshots into the proof directory.

## Interpretation

This is another TestFlight proof retry, but the mandatory Build Info gate still comes first. The screenshots must be preserved without claiming TestFlight behavior proof unless Build Info proves a clean, reproducible source/build identity.

## What Happened

- New screenshots were found under `automation/proofs/owlory-ui-testflight-proof/20260513T173000Z-retry/`.
- TestFlight lists Owlory `0.2.0 (20260513172951)`.
- Build Info shows Commit `de320a7dd2c3-dirty`, Full commit `de320a7dd2c38878df3343ae3f945df9ffb8f815-dirty`, Branch `main`, Git status `dirty`, Built `2026-05-13T17:30:34Z`, Configuration `Release`, Bundle `com.raelldottin.owlory`, and Build source `Xcode CURRENT_PROJECT_VERSION`.
- `git show de320a7dd2c38878df3343ae3f945df9ffb8f815:owlory_xcode/Owlory.xcodeproj/project.pbxproj` shows `CURRENT_PROJECT_VERSION = 20260417081904`.
- The installed build number `20260513172951` was therefore produced from uncommitted local state at archive time.
- A Today Continue screenshot was preserved, but it is context only because the Build Info gate failed first.

## Files Edited

- `automation/proofs/owlory-ui-testflight-proof/20260513T173000Z-retry/README.md`
- `automation/proofs/owlory-ui-testflight-proof/20260513T173000Z-retry/manifest.json`
- `automation/proofs/owlory-ui-testflight-proof/20260513T173000Z-retry/01-build-info-top.png`
- `automation/proofs/owlory-ui-testflight-proof/20260513T173000Z-retry/02-build-info-source.png`
- `automation/proofs/owlory-ui-testflight-proof/20260513T173000Z-retry/03-testflight-launch.png`
- `automation/proofs/owlory-ui-testflight-proof/20260513T173000Z-retry/04-continue-surface.png`
- `automation/proofs/owlory-ui-testflight-proof/README.md`
- `automation/queue/slices.json`
- `automation/handoffs/20260513T202123Z-owlory-ui-test-testflight-proof-retry.json`
- `SecondBrain/INDEX.md`
- `SecondBrain/sessions/2026-05-13/162123-owlory-ui-test-testflight-proof-retry.md`

## Validation

Initial checks:

- `git rev-parse HEAD`
- `git rev-list --left-right --count HEAD...@{u}`
- `git show de320a7dd2c38878df3343ae3f945df9ffb8f815:owlory_xcode/Owlory.xcodeproj/project.pbxproj | rg "CURRENT_PROJECT_VERSION" | sort -u`
- `shasum -a 256 automation/proofs/owlory-ui-testflight-proof/20260513T173000Z-retry/*.png`
- `sips -g pixelWidth -g pixelHeight automation/proofs/owlory-ui-testflight-proof/20260513T173000Z-retry/*.png`

Repo validation:

- JSON validation
- `python3 automation/supervisor/run_next.py --dry-run`
- `make architecture`
- `make automation-check`
- `git diff --check`
- `make clean-stop` after commit/push remains the final step

## Outcome

The proof lane remains blocked because Build Info reports a dirty archive. The uploaded Continue screenshot is preserved as context only, not as `testflight-verified` proof.

## Next Step

Create/upload/install a TestFlight build from clean committed source after the build-number bump is committed. Only then rerun the Build Info provenance gate and capture Continue proof.
