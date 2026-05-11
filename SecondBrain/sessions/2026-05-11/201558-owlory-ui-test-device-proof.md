# owlory-ui-test-device-proof

Verified selected Continue smoke paths on a physical iPhone from a clean working-tree build at commit `c49e5adb01c48ca3eae5ab96aedd09ae06a29c30` on branch `claude/trusting-jepsen-0acf20`. Captured five device screenshots: the mandatory Build Info gate plus Today launch plus three Continue tap-routing paths (Writing → note detail sheet, Training → session card, Home protocol → active run sheet). Three source kinds and three routing paths reach `device-verified`. Three other source kinds and three actions remain `not-attempted-yet` because the device's natural data state did not expose them; this is recorded honestly, not synthesized.

## Build Info gate (mandatory; passed)

Captured first; no other artifact is meaningful without this matching the installed bundle:

```text
Commit:        c49e5adb01c4
Full commit:   c49e5adb01c48ca3eae5ab96aedd09ae06a29c30
Branch:        claude/trusting-jepsen-0acf20
Tag:           c49e5ad
Built:         2026-05-11T16:31:58Z
Configuration: Debug
Bundle:        com.raelldottin.owlory
GitStatus:     clean
```

The clean-tree stamp confirms the worktree-aware `Tools/generate-build-info.sh` fix from `tools-generate-build-info-worktree-fix` is still doing its job. If a future device run shows a `-dirty` suffix or `no-git`, treat the artifact as untraceable per `docs/workflows/ui-testing-hygiene.md`.

## Device-verified surfaces (5 captures)

| File | Surface | Notes |
| --- | --- | --- |
| `01-build-info.png` | Build Info screen | Provenance gate. |
| `02-today-launch.png` | Today dashboard, populated | Implicitly proves source visibility for `.homeProtocolRun` (×2), `.trainingSession` (×1), `.writingNote` (×2) — those are the five Continue rows visible. |
| `03-writing-routing.png` | `.writingNote` → Write note detail sheet | `WriteView.presentHighlightedNoteIfNeeded` auto-presents on real device. |
| `04-training-routing.png` | `.trainingSession` → Train tab session card | `TrainView.highlightedSessionID` + scroll-to-highlight works on real device. |
| `05-home-protocol-routing.png` | `.homeProtocolRun` → active run sheet | `HomeView.presentHighlightedRunSheetIfNeeded` auto-presents on real device. |

## Not-attempted-yet (honestly deferred)

Recorded in `automation/proofs/owlory-ui-device-proof/manifest.json` and the proof pack's README:

- `.focusItem` source visibility — device's current Focus Three is empty; no `.focusItem` Continue row appears.
- `.homeTask` source visibility and routing — `.home` domain Continue cap of 2 is filled by the two active protocol runs; `.homeTask` is admission-rejected.
- `.carriedFocusItem` source visibility — requires a stale Focus streak of 3+ consecutive carried calendar days; not naturally present in the device's history today.
- Done / Defer / Drop swipe actions — all require a Focus-backed Continue row; none present on device this pass.
- Add-to-Focus action — out of scope; routing-coverage triage already classified this as no-current-seed-exposes-it.

These are not failures. They are the honest outcome of running the device pass against live data without synthesizing seed state on the device (which is intentional — the Debug-only seed flags do not exist in Release builds and we did not extend them to device).

## What this pack does NOT prove

- No claim about TestFlight (Release-build) behavior. The Build Info on this install shows `Configuration: Debug`; the build came from a developer-signed local Xcode build, not from a TestFlight distribution. TestFlight proof remains in `missing_proof_levels` (separately tracked by `owlory-ui-test-testflight-proof`).
- No claim about other device models, iOS versions, Dynamic Type sizes, dark mode, accessibility content sizes, or RTL. Only the captured configuration on iPhone (`00008130-000A090910C1401C`, iOS 26.4.2) at this commit.
- No claim about transitions, animations, or persistence behavior. Routing tests captured the destination's first frame; they did not exercise further interactions inside each destination.

## Workflow followed

1. Reverted my own `status=in_progress` slice edit to keep the working tree clean for stamping (else the build would suffix `-dirty`).
2. Clean rebuild at `c49e5ad`: `xcodebuild build ... -destination 'platform=iOS,id=<UDID>' -allowProvisioningUpdates`. Stamp confirmed `GitStatus=clean`.
3. Installed: `xcrun devicectl device install app --device <UDID> .../Owlory.app`. Installation URL recorded in the install log.
4. Build Info gate verified on device. Refused to capture further surfaces until the gate matched the install. (It did; this run passed first try.)
5. Capture loop, surface by surface. For each surface where the device's live data could exercise it honestly, the operator screenshotted and AirDropped/saved to `/tmp/owlory-device-proof/artifacts/screenshots/<NN>-<kebab>.png`.
6. After capture, screenshots copied to `automation/proofs/owlory-ui-device-proof/`; manifest generated with sha256 hashes; README authored mapping each file to its source kind and noting what the pack does and does not prove.

## Validation

- `python3 automation/context/build_context.py --slice-id owlory-ui-test-device-proof`
- `python3 automation/supervisor/run_next.py --dry-run`
- `make architecture`
- `make automation-check`
- `git diff --check`
- Device build: `xcodebuild build -destination 'platform=iOS,id=00008130-000A090910C1401C'` produced a clean-tree `Owlory.app` (GitStatus=clean, GitCommit matched HEAD).
- Device install: `xcrun devicectl device install app` succeeded; install path recorded in handoff.
- Device Build Info: visually verified to match the installed bundle's stamp.

## Next

`owlory-ui-test-testflight-proof` is the next eligible slice (priority 157, depends_on this slice). It must pick one of three documented approaches (real data, TestFlight-safe fixture mode, or launch+Build-Info-only) before capturing artifacts — debug-only seed flags do not run in Release builds. Today launch + Build Info gate are the minimum honest TestFlight claim; any Continue interaction proof would require new fixture decisions.
