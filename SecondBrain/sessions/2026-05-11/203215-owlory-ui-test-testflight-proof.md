# owlory-ui-test-testflight-proof (blocked at Build Info gate)

The slice halted at the mandatory Build Info gate. The installed TestFlight build of `com.raelldottin.owlory` reported `Configuration: Release` and a real commit/branch/tag stamp, but its build number `20260417081911` does not match committed source: the stamped commit's `project.pbxproj` has `CURRENT_PROJECT_VERSION = 20260417081904`. No Continue route, action, screenshot, or behavior proof was claimed against this install. A follow-up audit slice was queued; the lane stays at `device-verified` until the gate passes cleanly.

## Approach chosen at slice start

Per the slice's pre-capture decision rule, the operator selected the conservative approach:

```text
1. Build Info / launch proof from TestFlight
2. Real-data Continue route proof only if the TestFlight install naturally has suitable data
3. Do NOT add a TestFlight fixture/demo mode in this slice
```

Debug-only `--owlory-ui-seed-*` flags do not run in Release builds, so the slice did not assume any seeded state on TestFlight. Real-data capture was contingent on Build Info gate passing first.

## Build Info gate (FAILED)

Captured screenshot saved as [`automation/proofs/owlory-ui-testflight-proof/01-build-info.png`](../../../automation/proofs/owlory-ui-testflight-proof/01-build-info.png). Fields read directly from the on-device Build Info sheet:

```text
Version:        0.2.0
Build:          20260417081911    ← stamped at archive
Commit (short): a2229f97ae25
Commit (full):  a2229f97ae250c2bd48971cf5fa409fd21e37912
Branch:         main
Tag:            a2229f9
Built:          2026-05-05T23:48:12Z
Configuration:  Release
Bundle:         com.raelldottin.owlory
Build source:   Xcode CURRENT_PROJECT_VERSION
```

Verifier output against committed source at the stamped commit:

```bash
git show a2229f97ae250c2bd48971cf5fa409fd21e37912:owlory_xcode/Owlory.xcodeproj/project.pbxproj \
  | grep CURRENT_PROJECT_VERSION
# CURRENT_PROJECT_VERSION = 20260417081904;
```

Walk across every commit touching `pbxproj` between `2026-05-01` and `2026-05-08`:

```text
d0d9291  CURRENT_PROJECT_VERSION = 20260417081904
a440ff8  CURRENT_PROJECT_VERSION = 20260417081904
8b6461a  CURRENT_PROJECT_VERSION = 20260417081904
60576b3  CURRENT_PROJECT_VERSION = 20260417081904
```

No commit on `main` has `20260417081911`. The TestFlight build's stamped commit + build pair therefore is not reproducible from committed source.

## Inference about GitStatus

The on-device Build Info screenshot is cropped at `Build source: Xcode CURRENT_PROJECT_VERSION` and does not show the `GitStatus` row that the stamp script writes immediately after `BuildConfiguration`. However, the visible `Commit`, `Full commit`, and `Tag` fields all show **no `-dirty` suffix**. The stamp script's git-describe step appends `-dirty` to those values when the tree is dirty, so the absence of the suffix is circumstantial evidence that `GitStatus = clean`.

That is the **worse** branch: the stamp reported clean while the build did not match committed source. The follow-up audit slice's first action is to confirm `GitStatus` directly so the diagnosis is grounded in observation rather than inference.

## Why no Continue surfaces were captured

`testflight-verified` requires a TestFlight Build Info that matches committed source. Capturing Continue artifacts against an install that fails the gate would launder unverifiable provenance into a higher proof lane. Per Owlory's evidence-not-confidence rule, the right move at gate failure is to record the finding and stop.

## What this slice produced

- A documented finding that the TestFlight provenance gate caught real source/build drift — exactly the class of release problem the gate exists to surface.
- One preserved artifact ([`01-build-info.png`](../../../automation/proofs/owlory-ui-testflight-proof/01-build-info.png)) labeled as gate-failure evidence, not TestFlight behavior evidence.
- A structured [`manifest.json`](../../../automation/proofs/owlory-ui-testflight-proof/manifest.json) recording `gate_status: "failed"`, the observed Build Info, the committed source at the stamped commit, the drift, the inferred diagnosis, and the alternatives the audit must rule out.
- A queued follow-up slice (`owlory-release-provenance-stamp-audit`) with explicit first actions and allowed paths covering the stamp script, BuildInfo, the verify-build-provenance script, and `release.md`.

## Validation

- `python3 automation/context/build_context.py --slice-id owlory-ui-test-testflight-proof`
- `python3 automation/supervisor/run_next.py --dry-run`
- `make architecture`
- `make automation-check`
- `git diff --check`
- Build Info gate evidence: visual capture + git-source verification.

## Proof level

`doc-only`. The slice's deliverable is a documented gate-failure finding plus a queued audit. `testflight-verified` stays in `missing_proof_levels`; `device-verified` from the prior slice remains the highest claim for Continue surfaces. The slice's `status` is `blocked` because the gate did not pass — not because the work was incomplete.

## Next

`owlory-release-provenance-stamp-audit` is queued at priority 156 with `depends_on: [owlory-ui-test-testflight-proof]`. It must land before any re-attempt of `owlory-ui-test-testflight-proof`. The audit's first action is direct confirmation of the on-device `GitStatus` field for the same install; only after that observation can the diagnosis branch (script bug vs archive-workflow bug vs both) be picked deliberately.
