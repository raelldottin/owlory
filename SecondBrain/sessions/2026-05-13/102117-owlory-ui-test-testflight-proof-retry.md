# owlory-ui-test-testflight-proof-retry

## Prompt

The user indicated that a fresh clean TestFlight build exists and asked to retry TestFlight proof.

## Interpretation

This is a proof gate retry, not a product slice. The first required step is to prove the installed TestFlight app identity matches committed source. Continue surfaces must not be captured until that gate passes.

## What Happened

- Local clean `main` is `d0513a41a3e438a76494f43e5f4094a6983ad75e`.
- Local committed build is `20260417081904`.
- The paired iPhone is reachable through `devicectl`.
- The installed `com.raelldottin.owlory` app still reports bundle version `20260417081911`.
- Comparing that installed bundle version to local committed source fails.

## Files Edited

- `automation/proofs/owlory-ui-testflight-proof/20260513T142117Z-retry/README.md`
- `automation/proofs/owlory-ui-testflight-proof/20260513T142117Z-retry/manifest.json`
- `automation/proofs/owlory-ui-testflight-proof/README.md`
- `automation/queue/slices.json`
- `automation/handoffs/20260513T142117Z-owlory-ui-test-testflight-proof-retry.json`
- `SecondBrain/INDEX.md`
- `SecondBrain/sessions/2026-05-13/102117-owlory-ui-test-testflight-proof-retry.md`

## Validation

Passed:

- `python3 automation/context/build_context.py --slice-id owlory-ui-test-testflight-proof-retry`
- `make build-provenance`
- `xcrun devicectl device info apps --device 691FB5B7-A8F2-5AE4-BE95-EC1CABC5872F --bundle-id com.raelldottin.owlory --json-output /tmp/owlory-device-apps.json`

Expected gate failure:

- `./Tools/verify-build-provenance.sh --expected-build 20260417081911 --expected-commit d0513a41a3e438a76494f43e5f4094a6983ad75e`

Required before final handoff:

- `make architecture`
- `make automation-check`
- `git diff --check`
- `make clean-stop` after commit/push

## Outcome

The retry remains blocked. No Build Info screenshot, Continue route, natural-data surface, or `testflight-verified` proof was captured.

## Next Step

Install the fresh clean TestFlight build on the paired iPhone, then rerun the Build Info gate. The installed app's bundle version and Build Info build/commit/GitStatus must match committed source before capturing Continue surfaces.
