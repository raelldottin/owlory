# owlory-ui-test-screenshot-proof-pack

Turned the maintained 13-test XCUITest smoke into a repo-managed screenshot proof pack under `automation/proofs/owlory-ui-smoke-proof/`. Each PNG is one named `XCTAttachment` from a single passing `make ui-smoke` run; the manifest carries source commit, capture timestamp, xcresult bundle name, and a sha256 hash per file. The XCUITest target's assertions are unchanged — the new helper is metadata only, with attachments lifetime-pinned so they survive passing tests.

## Implementation

`owlory_xcode/OwloryUITests/OwloryUITests.swift`:

- Added `captureScreenshot(named:)` helper that wraps `XCTAttachment(screenshot: XCUIScreen.main.screenshot())`, sets `lifetime = .keepAlways`, and calls `add(attachment)`. Comments explain the proof-pack naming convention (`NN-kebab-case`) and that without `keepAlways` XCTest drops attachments on passing tests.
- Added 13 single-line `captureScreenshot(named: "NN-...")` calls — one per test method, at the assertion moment the test was already designed to prove (row visible, action button revealed, destination view rendered). The tests' XCTAssert logic is unchanged.

`automation/smoke/extract_ui_smoke_screenshots.py` (new):

- Walks `xcrun xcresulttool get test-results tests` for the test list, then `xcrun xcresulttool get test-results activities --test-id <id>` per test for the attachments.
- Filters by the proof-pack regex `^(\d{2}-[a-z0-9-]+)(?:_\d+_[A-F0-9-]+)?(?:\.png)?$` so the runtime-added `_<index>_<UUID>.png` suffix is stripped before mapping to the output filename.
- Exports each matching `payloadId` via `xcrun xcresulttool export object --legacy --type file` into `automation/proofs/owlory-ui-smoke-proof/<stem>.png`.
- Writes `manifest.json` with `slice`, `source_commit`, `captured_at`, `xcresult`, and per-PNG `name` / `file` / `sha256` / `size_bytes`.
- Refuses to write a manifest if two attachments shared the same proof-pack name (would be silent corruption otherwise).

`Makefile`:

- Added `ui-smoke-proof` target that depends on `ui-smoke` then runs the extraction script. `make ui-smoke` still stands alone for the deterministic XCUITest run; `make ui-smoke-proof` is the proof-refresh path.

`docs/workflows/ui-testing-hygiene.md`:

- New "Maintained Smoke Screenshot Pack" section describing `captureScreenshot(named:)`, the `make ui-smoke-proof` workflow, the extraction path, the manifest fields, and the rule that the xcresult bundle is transient (not checked in) while the PNGs are durable.
- New "Simulator Preflight Recovery" section recording the `SBMainWorkspace Busy / Application failed preflight checks` failure mode and the deterministic three-step recovery (`simctl shutdown all` + `simctl erase <UDID>` + `rm -rf /tmp/owlory-ui-smoke-derived-data`). Classified as `test harness or stale DerivedData`, not a product regression.

`automation/proofs/owlory-ui-smoke-proof/`:

- 13 PNG screenshots, one per maintained smoke test, named `01-today-launch.png` through `13-drop-action-revealed.png` per the README table.
- `README.md` mapping each file to its source test and the assertion it proves, plus a "what this does NOT prove" list (simulator-only, Debug build, no animation/gesture/accessibility-beyond-identifier proof, no Add-to-Focus or Skip-for-today, no regression coverage).
- `manifest.json` with sha256 hashes (regenerated on every `make ui-smoke-proof` run).

## Validation

- `python3 automation/context/build_context.py --slice-id owlory-ui-test-screenshot-proof-pack`
- `python3 automation/supervisor/run_next.py --dry-run`
- `make architecture`
- `make ui-smoke-proof` (13 tests passed, 13 attachments extracted, manifest written; recovered once from the documented SBMainWorkspace preflight error via the procedure now in ui-testing-hygiene.md)
- `make automation-check`
- `git diff --check`

## Proof level

`screenshot-verified` for the 13 captured smoke surfaces only. Everything outside those surfaces stays at the level the routing/source slices left it. Device, TestFlight, and regression-suite proof remain in `missing_proof_levels`.

## Bug found during the slice

First extraction-script run reported `no proof-pack-named screenshots found in xcresult`, despite XCUITest correctly logging `Added attachment named '01-today-launch'`. Two mismatches with my initial assumptions about the xcresulttool output:

1. The attachment `name` field carries a runtime-appended `_<index>_<UUID>.png` suffix, not the bare proof-pack stem.
2. The payload reference is `payloadId` (camelCase string), not the legacy `payload.id` nested object.

Both fixes are in the committed script; the regex and the `payloadId` lookup are documented in the extraction script's comments so the next reader does not chase the same dead end.

## Boundary kept

- No new XCUITest behavior (no new test cases, no new assertions). `captureScreenshot(named:)` is metadata.
- No device or TestFlight claim.
- No regression-suite scope creep.
- No Add-to-Focus capture (no seed exposes it; the routing matrix already classifies that as out of scope for the smoke surface).
- xcresult bundles stay under `/tmp/`; only the extracted PNGs and manifest are checked in.

## Next

`owlory-ui-test-device-proof` is the next eligible slice (priority 158, depends_on this slice). It must verify selected Continue smoke paths on a physical iPhone with traceable Build Info; per its slice notes, the device install must come from a clean working tree at a committed SHA.
