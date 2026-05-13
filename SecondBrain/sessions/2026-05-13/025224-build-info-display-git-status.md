# build-info-display-git-status

## Prompt

Execute the next queued diagnostics slice after parking TestFlight/localization/UI-regression work: display the stamped `GitStatus` field directly in Build Info.

## Assessment

- `Tools/generate-build-info.sh` already stamps `GitStatus` as `clean`, `dirty`, or `unknown`.
- `BuildInfo` did not read that field, so support diagnosis had to infer clean/dirty state from `GitCommit` suffixes or the `Not releaseable` banner.
- `BuildInfoView` showed commit, branch, tag, checkout, and releaseability banner, but no direct Git status row.
- Release docs mentioned dirty status generically instead of naming the explicit stamped field.

## Changes

- Added `BuildInfo.gitStatus` with bundle parsing, whitespace normalization, and an `unavailable` fallback.
- Added `Git status: ...` to the diagnostic report.
- Added a `Git status` row to the Build Info sheet while preserving the existing Not releaseable banner.
- Added focused `BuildInfoTests` coverage for stamped bundle reading and missing-key fallback.
- Updated `docs/workflows/release.md` to name `GitStatus` / Git status directly.
- Marked `build-info-display-git-status` done in `automation/queue/slices.json`.

## Validation

Passed:

- `python3 automation/context/build_context.py --slice-id build-info-display-git-status`
- `python3 automation/supervisor/run_next.py --dry-run`
- `make architecture`
- `xcodebuild -downloadPlatform iOS`
- `xcrun simctl runtime match set iphoneos26.5 23F77 --sdkBuild 23F73`
- `xcrun simctl runtime scan-and-mount`
- `xcrun simctl create 'iPhone 16 iOS 26.5' com.apple.CoreSimulator.SimDeviceType.iPhone-16 com.apple.CoreSimulator.SimRuntime.iOS-26-5`
- `OWLORY_XCODE_DESTINATION='id=BE8450CB-77B6-4A56-81EA-9A1F95C22042' make test-domain DOMAIN=runtime`
- `make build-provenance`
- `make automation-check`
- `git diff --check`

Recovered:

- Initial `make test-domain DOMAIN=runtime` failed because Xcode 26.5 could not find an eligible simulator destination for the repo default `iPhone 16 / iOS 26.3.1`.
- `xcodebuild -downloadPlatform iOS` installed the matching iOS 26.5 runtime, but CoreSimulator initially reported a duplicate disk image.
- `xcrun simctl runtime match set iphoneos26.5 23F77 --sdkBuild 23F73` mapped Xcode's iOS 26.5 SDK build to the installed runtime build.
- `xcrun simctl runtime scan-and-mount` registered the runtime.
- A new compatible simulator, `iPhone 16 iOS 26.5` (`BE8450CB-77B6-4A56-81EA-9A1F95C22042`), was created and selected with `OWLORY_XCODE_DESTINATION`.

## Residual Risk

- The slice now claims `domain-tested` proof. It does not claim standalone `build-tested`, running-app, screenshot, device, or TestFlight proof.
- The repo default validation destination still names `iPhone 16 / iOS 26.3.1`; this machine now has a compatible iOS 26.5 simulator selected via `OWLORY_XCODE_DESTINATION`.
- CoreSimulator still has an unusable duplicate iOS 26.5 disk-image record from the first install attempt. It did not block the rerun.
- `BuildInfo.isReleaseable` was intentionally not changed; release provenance policy still follows the existing commit-suffix/missing-ref rule.
- No TestFlight proof is claimed.

## Next

Clean stop. If future agents need the runtime domain lane on this machine, use:

```bash
OWLORY_XCODE_DESTINATION='id=BE8450CB-77B6-4A56-81EA-9A1F95C22042' make test-domain DOMAIN=runtime
```
