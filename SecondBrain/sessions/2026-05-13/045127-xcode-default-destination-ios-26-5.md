# xcode-default-destination-ios-26-5

## Prompt

Continue after the BuildInfo runtime validation recovery.

## Assessment

- The supervisor queue was empty.
- The previous handoff still named a real residual risk: repo defaults used `platform=iOS Simulator,name=iPhone 16,OS=26.3.1`.
- After installing the Xcode 26.5 runtime, only iOS 26.5 runtimes/devices are available through `xcodebuild`.
- `xcodebuild -showdestinations` reports a standard `iPhone 17 / OS=26.5` destination.
- Leaving the old default would make future agents fail `make test-domain DOMAIN=runtime` unless they remembered an out-of-band `OWLORY_XCODE_DESTINATION` override.

## Changes

- Added and completed queue slice `xcode-default-destination-ios-26-5`.
- Updated default Xcode destination in:
  - `Tools/validate.sh`
  - `Makefile` (`ui-smoke`, `ui-regression`)
  - `automation/smoke/running_app_smoke.py`
  - `docs/workflows/validation.md`
- Updated running-app smoke tests to expect the iOS 26.5 destination.
- Updated UI preflight recovery guidance to avoid a stale hardcoded simulator UDID.

## Validation

Passed:

- `python3 automation/context/build_context.py --slice-id xcode-default-destination-ios-26-5`
- `python3 automation/supervisor/run_next.py --dry-run`
- `make architecture`
- `make test-domain DOMAIN=runtime`
- `make build-provenance`
- `make automation-check`
- `git diff --check`

## Residual Risk

- UI smoke/regression lanes were not rerun in this slice; their defaults now point at iPhone 17 / iOS 26.5, but the proof run focused on runtime domain validation and automation tests.
- Historical proof artifacts that name iPhone 16 / iOS 26.3.1 are still accurate historical evidence and were not rewritten.
- CoreSimulator still has an unusable duplicate iOS 26.5 disk image from the first runtime install attempt. It is not blocking validation.

## Next

Clean stop. Blocked TestFlight/localization/UI expansion slices remain parked behind their entry conditions.
