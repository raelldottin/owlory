# queue-automate-blocked-slice-unblockers

Prompt received 2026-05-20T07:30:16Z.

User asked to add slices to automate blocked-slice unblocking.

Context:
- Repo was clean and mirrored before work.
- Supervisor had no eligible queued slice.
- Parked blocked slices were:
  - `app-localization-device-verified-locale-proof`
  - `app-localization-testflight-verified-locale-proof`
  - `app-localization-smallest-width-accessibility-regression`
- `app-localization-nextstep-plist-parser` was deferred, not blocked, and remains superseded by XML stringdict conversion.

Queue changes:
- Added queued slice `app-localization-external-proof-blocker-reclassification` at priority 20.
  - Purpose: reclassify optional physical-device/TestFlight proof blockers as deferred manual-extension proof tracks, preserving proof-level honesty and the existing automated simulator HIG claim.
  - Linked it as `recommended_unblocker` for both device/TestFlight proof slices.
- Added queued slice `automation-localization-iphone-se-simulator-provisioning` at priority 21.
  - Purpose: add an idempotent simulator-provisioning/check helper for the iPhone SE smallest-width localization regression.
  - Linked it as `recommended_unblocker` for `app-localization-smallest-width-accessibility-regression`.

Validation:
- `python3 -m json.tool automation/queue/slices.json` passed.
- Queue schema + integrity validation passed.
- `python3 automation/supervisor/run_next.py --dry-run --include-blocked` now selects `app-localization-external-proof-blocker-reclassification`.
- `python3 automation/context/build_context.py --slice-id app-localization-external-proof-blocker-reclassification` passed.
- `make architecture` passed.
- `make localization-check` passed.
- `make automation-check` passed.
- `make pyright` passed.
- `git diff --check` passed.

State:
- This was a queue-only planning change; no app code changed.
