# owlory-ui-testflight-proof (gate-failure record)

This directory is **not** a TestFlight proof of Continue UI behavior. It preserves a single Build Info screenshot from a TestFlight install whose stamped provenance did not match committed source. The gate-failure is the finding; no Continue surfaces were captured against this install.

## Build Info gate verdict: FAILED

The TestFlight install of `com.raelldottin.owlory` (Configuration `Release`, captured on Raell Dottin's iPhone, iOS 26.4.2) reported:

```text
Version:        0.2.0
Build:          20260417081911
Commit (short): a2229f97ae25
Commit (full):  a2229f97ae250c2bd48971cf5fa409fd21e37912
Branch:         main
Tag:            a2229f9
Built:          2026-05-05T23:48:12Z
Configuration:  Release
Bundle:         com.raelldottin.owlory
Build source:   Xcode CURRENT_PROJECT_VERSION
```

The source state at commit `a2229f97ae250c2bd48971cf5fa409fd21e37912` was inspected directly:

```bash
git show a2229f97ae250c2bd48971cf5fa409fd21e37912:owlory_xcode/Owlory.xcodeproj/project.pbxproj \
  | grep CURRENT_PROJECT_VERSION
# CURRENT_PROJECT_VERSION = 20260417081904;
```

The commit's pbxproj reports `CURRENT_PROJECT_VERSION = 20260417081904`, but the TestFlight Build Info stamps `Build = 20260417081911`. **The build number and the committed source at the stamped commit do not match.** A walk of every pbxproj-touching commit between `2026-05-01` and `2026-05-08` (the days around the TestFlight build's `Built` timestamp) confirms every such commit's `CURRENT_PROJECT_VERSION` is `20260417081904`; there is no commit on `main` whose source has `20260417081911`.

## What this means

One of the following is true:

1. The TestFlight archive was created from a working tree where `CURRENT_PROJECT_VERSION` had been bumped (`20260417081904` → `20260417081911`) without that bump being committed back. The stamp script's git detection would then have seen a dirty tree at archive time.
2. The TestFlight build number was bumped after the archive was created (e.g., manually in App Store Connect, or by a post-archive automation), without ever flowing back into source. The stamp script captured the pbxproj's pre-bump value, but the binary's `CFBundleVersion` was rewritten downstream.
3. The stamping script ran when the commit was checked out but read a mutated pbxproj that was never committed and never marked dirty.

`01-build-info.png` is cropped at `Build source: Xcode CURRENT_PROJECT_VERSION` and does **not** show the `GitStatus` field that the stamp script writes immediately after `BuildConfiguration`. The visible `Commit`, `Full commit`, and `Tag` fields all show no `-dirty` suffix, which the stamp script's git-describe step would append if the tree were dirty. That circumstantial evidence points at `GitStatus = clean` — meaning the script likely did NOT catch the discrepancy, putting us in case (3) or case (2) above, not case (1). The follow-up audit slice will confirm `GitStatus` directly as its first action.

## Why no Continue capture was attempted

Per the slice contract, `testflight-verified` requires a TestFlight Build Info that matches committed source. The Build Info gate is the mandatory provenance anchor; if it fails, capturing Continue route/visibility artifacts against this install would launder unverifiable provenance into a higher proof lane. Owlory's proof rule is evidence-not-confidence; the right move at gate failure is to record the finding and stop.

## What is preserved here

- `01-build-info.png` — the failing-gate artifact. Treat it as evidence of the gate failure, **not** as evidence of TestFlight behavior.
- `manifest.json` — records the gate failure as a structured finding (`gate_status: "failed"`, expected vs observed build numbers, link to the follow-up audit slice).

## What is NOT preserved here

No Continue route, action, screenshot, or behavior proof from this TestFlight install. The `device-verified` proof lane from [`owlory-ui-device-proof/`](../owlory-ui-device-proof/) remains the highest claim for the Continue surfaces; `testflight-verified` stays in `missing_proof_levels` until the provenance gate can be passed cleanly.

## 2026-05-13 Retry Gate Record

The retry attempt in [`20260513T142117Z-retry/`](20260513T142117Z-retry/) also stopped before Continue capture. The paired iPhone was reachable, but `xcrun devicectl device info apps` still reported installed `com.raelldottin.owlory` as version `0.2.0`, bundle version `20260417081911`.

Local clean `main` at `d0513a41a3e438a76494f43e5f4094a6983ad75e` reports committed build `20260417081904`. Comparing the installed bundle version against local committed source fails:

```text
error: expected build '20260417081911' but Xcode CURRENT_PROJECT_VERSION is '20260417081904'
```

No Build Info screenshot or Continue surface was captured in this retry. The likely next action is to install the fresh clean TestFlight build on the paired iPhone, then rerun the Build Info gate.

## 2026-05-13 Second Retry Gate Record

The second retry attempt in [`20260513T163220Z-retry/`](20260513T163220Z-retry/) also stopped before Continue capture. The paired iPhone had a newer installed Owlory build, bundle version `20260417081912`. Build Info screenshots now preserved in that directory show the TestFlight app was stamped from clean commit `d0513a41a3e438a76494f43e5f4094a6983ad75e`, branch `main`, configuration `Release`, bundle `com.raelldottin.owlory`, and build source `Xcode CURRENT_PROJECT_VERSION`.

The stamped commit's committed `project.pbxproj` still has `CURRENT_PROJECT_VERSION = 20260417081904`, and a Git search found no committed `project.pbxproj` state on `main` containing `20260417081912`.

The provenance comparison failed:

```text
error: expected build '20260417081912' but Xcode CURRENT_PROJECT_VERSION is '20260417081904'
```

No Continue surface was captured in this retry. A future TestFlight proof attempt must start from an uploaded build whose bundle version matches committed source.

## Follow-up

`owlory-release-provenance-stamp-audit` (queued; see slices.json). The audit slice must:

1. Confirm the on-device `GitStatus` field on the same TestFlight install (the field we did not capture this pass).
2. Identify the source of the build-number drift between archive and commit.
3. Decide whether the fix lives in the stamp script, the archive workflow, the release runbook, or in all three.
4. Only after the audit lands and a corrected release produces a TestFlight build whose Build Info matches committed source: re-attempt `owlory-ui-test-testflight-proof`.
