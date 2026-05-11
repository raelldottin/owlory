# owlory-release-provenance-stamp-audit

Audit of the TestFlight Build Info gate failure recorded by [`owlory-ui-test-testflight-proof`](../owlory-ui-testflight-proof/). The TestFlight install of `com.raelldottin.owlory` shipped with `CFBundleVersion = 20260417081911`, but that build number is not present in any committed pbxproj state on any branch or in the reflog. The audit pins the root cause and queues exactly one fix slice.

This directory is **not** a UI proof artifact. It is a diagnosis record of why the TestFlight install failed the provenance gate and which workflow surface owns the fix.

## Evidence walked

1. **Git history for the stamped commit and surrounding builds.**

   ```bash
   git show a2229f97ae250c2bd48971cf5fa409fd21e37912:owlory_xcode/Owlory.xcodeproj/project.pbxproj \
     | grep CURRENT_PROJECT_VERSION
   # CURRENT_PROJECT_VERSION = 20260417081904;
   ```

   Pickaxe across all branches and reflog:

   ```bash
   git log --all --pickaxe-regex -S "20260417081911"
   # Only match: commit 7eb7fbb (the gate-failure record we just committed).
   git log --reflog --pickaxe-regex -S "20260417081911"
   # Same single match.
   ```

   Every pbxproj-touching commit between `2026-05-01` and `2026-05-08` (around the TestFlight `Built` date) shows `CURRENT_PROJECT_VERSION = 20260417081904`. **No source state ever had `20260417081911` in committed history.**

2. **Build-number timestamp decoding.**

   `Tools/set-build-number.sh --auto` generates `date -u +"%Y%m%d%H%M%S"`. The TestFlight build number `20260417081911` decodes to UTC `2026-04-17 08:19:11`. The TestFlight build's `Built` date is `2026-05-05 23:48:12 UTC` — 19 days later. The bump script ran on April 17; the archive happened on May 5; the bump was never committed in between (or was committed and then rewritten away).

3. **Stamp script behavior at archive time.**

   [`Tools/generate-build-info.sh`](../../../Tools/generate-build-info.sh) reads `CFBundleVersion` from the processed `Info.plist` (line 59) but never writes it back unless the value is empty (lines 72–76). It does not mutate the build number — it only inspects and stamps Git fields plus build date / configuration / build-number-source. The script's git-detection (lines 44–49) appends `-dirty` to `GitCommit`, `GitCommitFull`, and indirectly via `git describe --dirty` to `GitTag` when the tree is dirty.

4. **In-app Build Info display.**

   [`owlory_xcode/Owlory/Features/Today/BuildInfoView.swift`](../../../owlory_xcode/Owlory/Features/Today/BuildInfoView.swift) does **not** render the `GitStatus` field. The user-facing dirty signal is the `Not releaseable — built from a dirty or unknown commit` banner, gated on `BuildInfo.isReleaseable`, which checks `-dirty` suffix on `gitCommit`/`gitCommitFull` (not on `GitStatus` directly).

5. **TestFlight install observation (from [`owlory-ui-testflight-proof/01-build-info.png`](../owlory-ui-testflight-proof/01-build-info.png)).**

   - `Commit`, `Full commit`, `Tag`: all displayed **without** `-dirty` suffix.
   - **No `Not releaseable` warning banner is visible** in the captured Build Info screen.
   - Therefore `isReleaseable == true` at archive time, therefore `gitCommit` had no `-dirty` suffix, therefore the stamp script's `git status --porcelain` returned empty, therefore **`GitStatus = clean` at archive time**.

   Scrolling further on the device would not have surfaced `GitStatus` directly — the field is stamped but never displayed. The audit confirms `GitStatus = clean` from the absence of the warning banner and the absence of `-dirty` suffixes on the visible Git fields. This is a tighter inference than the previous slice's "absence of -dirty suffix" alone.

## Diagnosis

`GitStatus = clean` at archive time. The pbxproj on disk at archive time held `CURRENT_PROJECT_VERSION = 20260417081904` (the committed value). But the binary's `CFBundleVersion` is `20260417081911`. The stamp script and BuildInfo.swift both behaved correctly given the inputs they received; the divergence is upstream of both.

Three concrete mechanisms could produce this state, all reducing to the same fix surface:

- **Mechanism α — xcodebuild command-line override.** The archive was issued with `xcodebuild archive ... CURRENT_PROJECT_VERSION=20260417081911`, overriding the value Xcode pulls from pbxproj at build time without modifying the file on disk. The stamp script's git check still reports clean (file unchanged). The processed Info.plist receives the override value. The binary ships with the override value.
- **Mechanism β — pbxproj commit later rewritten away.** Someone committed the `20260417081911` bump, archived from that committed state (stamp would have reported clean), then `git reset --hard` / force-push / branch reshape removed the commit from reachable history. Reflog garbage collection then erased the last trace. The pickaxe `--reflog` search found no such commit today, which is consistent with this mechanism if GC ran.
- **Mechanism γ — `git update-index --skip-worktree` or similar index manipulation.** Someone marked pbxproj as skip-worktree (or assume-unchanged), bumped the file on disk, archived (git status doesn't list skip-worktree files; the stamp's `git status --porcelain` would return empty), then unset the flag. The bumped pbxproj on disk would have been reverted to the committed value either before or after archive.

All three mechanisms share one property: **the current pbxproj state at HEAD did not contain the build number that ended up in the binary**. The release workflow's existing gate (`make release-check` requires a clean tree at archive time) is therefore necessary but insufficient. A stronger assertion is needed: the current pbxproj's `CURRENT_PROJECT_VERSION` must match the committed pbxproj's value at HEAD.

## Fix surface

`Tools/verify-build-provenance.sh` and `make release-check`. The stamp script and BuildInfo.swift are not in the fix surface — they recorded what they were given. The Xcode build phases are not in the fix surface either — they ordered correctly.

A single follow-up slice was queued: `owlory-release-provenance-stamp-gate-fix` (see [`automation/queue/slices.json`](../../queue/slices.json)). Its acceptance criteria require extending the verifier to assert pbxproj equality between working tree and HEAD, updating `docs/workflows/release.md` to add the gate as a numbered release step, and adding a focused test under `automation/tests/` simulating the failure mode.

## Out of audit scope

- **Surfacing `GitStatus` in `BuildInfoView`.** Recorded as a UI gap during this audit — the field is stamped to Info.plist but never displayed. Closing that gap would make user-facing dirty signals less reliant on suffix inference. Out of this audit because the diagnosis did not require user-facing UI changes; queue as a separate product question if desired.
- **App Store Connect-side audit.** Whether earlier TestFlight builds also drifted is not investigated here. The fix gate would prevent future drifts but not retroactively diagnose the App Store Connect history.
- **Retroactive fix of the failing install.** No attempt to invalidate or replace the TestFlight build currently on the operator's iPhone. That binary remains a known-unverifiable artifact; the device-verified proof from [`owlory-ui-device-proof/`](../owlory-ui-device-proof/) (a different commit, a different build, signed locally not via TestFlight) is the highest current claim for Continue surfaces.

## Files in this directory

- `README.md` — this file; the audit's narrative record.
- `manifest.json` — structured diagnosis: evidence walked, GitStatus determination, mechanisms ranked, fix surface, queued follow-up slice id.

No screenshots are stored here. The TestFlight Build Info screenshot stays under `owlory-ui-testflight-proof/01-build-info.png` because that is where the gate failure was recorded.
