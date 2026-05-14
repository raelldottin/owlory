# localization-screenshot-proof-idb-harness

## Summary

Added a harness layer for full-locale screenshot proof before retrying the screenshot proof itself. The helper keeps `xcodebuild`/`simctl` as the running-app smoke foundation and uses idb only where it improves screenshot repeatability: target-specific launch, accessibility inspection, known prompt dismissal, settled-surface checks, and guarded screenshot preservation.

## What Changed

- Added `automation/smoke/capture_locale_screenshots.py`.
- Added `make localization-screenshot-idb-check`.
- Added automation tests for idb dependency reporting, known notification prompt detection, dismissal button coordinates, and target-specific idb command construction.
- Updated localization, UI-testing, roadmap, and validation docs so full-locale screenshot proof remains blocked until the idb dependency check reports ready.

## Proof

- Proof level: `tooling-tested`.
- Screenshot proof was not claimed.
- Current machine state during the slice: `idb_companion` is installed, but the `idb` client is missing. The check reports this as a blocked dependency with remediation instead of treating it as a localization failure.

## Validation

- `python3 automation/context/build_context.py --slice-id localization-screenshot-proof-idb-harness`
- `python3 automation/supervisor/run_next.py --dry-run`
- `make localization-screenshot-idb-check`
- `make architecture`
- `make localization-check`
- `./Tools/validate.sh localization`
- `make automation-check`
- `git diff --check`

## Remaining Risk

- Full-locale screenshot proof is still blocked until `idb` is installed and clean settled screenshots are captured for all 19 locales.
- Translation quality remains incomplete; this harness does not replace reviewed translations.
- Physical-device and TestFlight localization proof remain separate lanes.

## Next

Install the idb client outside the repo, rerun `make localization-screenshot-idb-check`, then retry `app-localization-all-locale-screenshot-proof`.
