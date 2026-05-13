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
- `make build-provenance`
- `make automation-check`
- `git diff --check`

Blocked:

- `make test-domain DOMAIN=runtime`
- `OWLORY_XCODE_DESTINATION='id=93831D66-8855-467D-8991-81886B30A57F' make test-domain DOMAIN=runtime`
- `xcodebuild build -quiet -project owlory_xcode/Owlory.xcodeproj -scheme Owlory -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/owlory-build-info-display-build CODE_SIGNING_ALLOWED=NO`
- `xcodebuild build -quiet -project owlory_xcode/Owlory.xcodeproj -scheme Owlory -configuration Debug -destination 'generic/platform=iOS' -derivedDataPath /tmp/owlory-build-info-display-ios-build CODE_SIGNING_ALLOWED=NO`

Blocker: Xcode 26.5 reports no eligible simulator destination because the iOS 26.5 runtime is not installed. `simctl` can boot the iPhone 16 iOS 26.3.1 simulator, but `xcodebuild` still refuses both the named destination and explicit device id.

## Residual Risk

- The slice cannot claim `domain-tested` or `build-tested` proof until `make test-domain DOMAIN=runtime` runs in an Xcode/runtime-compatible environment.
- `BuildInfo.isReleaseable` was intentionally not changed; release provenance policy still follows the existing commit-suffix/missing-ref rule.
- No TestFlight proof is claimed.

## Next

Clean stop. Re-run runtime domain validation after installing the iOS 26.5 simulator runtime or switching Xcode to a matching installed runtime.
