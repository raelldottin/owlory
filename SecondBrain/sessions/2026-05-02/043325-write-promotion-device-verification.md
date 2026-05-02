# write-promotion-device-verification (blocked)

## Summary

Built and installed Owlory on the connected physical iPhone (Raell Dottin's iPhone, 26.3.1, device id 00008130-000A090910C1401C) from worktree commit `a849fb9` on branch `claude/frosty-greider-e0a33c`. The build and install both succeeded. Did not exercise the Write -> Turn into Task -> View source note flow on the device because the installed bundle's Build Info was stamped with `GitCommit=no-git` rather than the real commit, which means the install cannot be tied back to source. Marked the slice blocked rather than completing the flow under untraceable provenance.

## Blocker

`Tools/generate-build-info.sh` line 36:

```sh
if [ -n "$GIT_ROOT" ] && [ -d "$GIT_ROOT/.git" ]; then
```

The `[ -d ]` test fails in any git worktree because `.git` is a file pointer (`gitdir: /path/to/main/.git/worktrees/<name>`), not a directory. The script falls through to the `no-git` fallback at lines 47-54. As a result the installed app carries `GitCommit=no-git`, `GitBranch=no-git`, `GitTag=no-git`, and `BuildInfo.isReleaseable` evaluates to false even though the source tree was actually clean.

The fix is small (use `[ -e "$GIT_ROOT/.git" ]` or `git -C "$GIT_ROOT" rev-parse --git-dir > /dev/null 2>&1` for the existence check) but `Tools/` is outside this slice's `allowed_paths`, so it has to land as its own slice first.

## Evidence Captured

- xcodebuild succeeded for `platform=iOS,id=00008130-000A090910C1401C` (Debug, automatic signing, team `DHJQ7QC53Z`).
- `xcrun devicectl device install app` succeeded; bundle installed at `/private/var/containers/Bundle/Application/BDAB3B1C-C95D-4F33-9326-D29AED9700C4/Owlory.app/`.
- Installed `Info.plist` contents:
  - `CFBundleIdentifier=com.raelldottin.owlory`
  - `CFBundleShortVersionString=0.2.0`
  - `CFBundleVersion=20260417081904`
  - `BuildConfiguration=Debug`
  - `BuildDate=2026-05-02T04:31:38Z`
  - `BuildNumberSource=Xcode CURRENT_PROJECT_VERSION`
  - `GitCommit=no-git` (should have been `a849fb95bccb` short)
  - `GitCommitFull=no-git`
  - `GitBranch=no-git` (should have been `claude/frosty-greider-e0a33c`)
  - `GitTag=no-git`

## Why Not Lower the Bar

Two options were considered before blocking:

1. Run the flow on device anyway and claim something below `device-verified`. Rejected: the `screenshot-verified` slice already proved the flow at a lower bar; running it again on device without traceable provenance would not strengthen evidence and would introduce a misleading "we ran it on device" record without a reproducible commit anchor.
2. Rebuild from outside the worktree (the main checkout has a real `.git` directory). Rejected: the slice was scoped to the worktree commit, and switching the build source mid-slice would obscure which checkout the on-device evidence ties back to. The honest call is to fix the stamp script first.

## Validation

- `python3 automation/context/build_context.py --slice-id write-promotion-device-verification`
- `python3 automation/supervisor/run_next.py --dry-run`
- `xcodebuild build -project owlory_xcode/Owlory.xcodeproj -scheme Owlory -configuration Debug -destination 'platform=iOS,id=00008130-000A090910C1401C' -derivedDataPath /tmp/owlory-device-verification/DerivedData -allowProvisioningUpdates`
- `xcrun devicectl device install app --device 00008130-000A090910C1401C /tmp/owlory-device-verification/DerivedData/Build/Products/Debug-iphoneos/Owlory.app`
- `make architecture`
- `make automation-check`
- `git diff --check`

## Next

Land `tools-generate-build-info-worktree-fix` first. Then retry `write-promotion-device-verification` from a clean rebuild that produces a properly stamped install.
