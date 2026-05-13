# UI Testing Hygiene

Use this before adding UI tests, preserving screenshot proof, or claiming running-app behavior. It adapts the durable Gymphant UI-testing lessons to Owlory without pretending Owlory already has a full XCUITest suite.

See [UI Regression Plan](ui-regression-plan.md) for the canonical definition of the five UI coverage lanes (smoke, regression, screenshot, device, TestFlight), what each lane proves and does not prove, and which gating command claims which proof level. This page covers the durable rules that apply within those lanes.

## Current State

- Owlory has a running-app smoke runner: `python3 automation/smoke/running_app_smoke.py`.
- Owlory has repo-managed screenshot proof directories under `automation/proofs/`.
- Owlory has a minimal first-class XCUITest target, `OwloryUITests`, with focused deterministic Today smoke coverage.
- Owlory has a narrow TestFlight proof packet for the natural-data Today Continue launch surface plus one Home protocol run route at `automation/proofs/owlory-ui-testflight-proof/20260513T205620Z-provenance-intake/`.
- Owlory does not currently have a batched UI regression suite.

Do not treat the single smoke test as broad UI regression coverage.

## Proof Lanes

Keep these separate:

- `running-app-smoke`: the app built, installed, launched, and produced a non-empty screenshot or log artifact.
- `flow-verified`: a specific running-app user flow was exercised end to end.
- `screenshot-verified`: screenshots are preserved in the repo with a README or manifest that explains the claim.
- `device-verified`: the flow was repeated on a physical device with build provenance.
- `testflight-verified`: the flow was repeated from the TestFlight build identity being claimed.

One lane does not imply another. A smoke screenshot is not a reviewed screenshot-proof artifact by itself.

## Deterministic UI Test Rules

Future UI tests should:

- Use a fresh, slice-specific DerivedData path under `/tmp`, never a developer's default DerivedData.
- Use deterministic launch arguments or seeded fixtures instead of relying on local user data.
- Reset or isolate simulator state when a test depends on first-run behavior, persistence, or locale.
- Add accessibility identifiers for stable controls before writing brittle coordinate or label-only tests.
- Keep screenshots as attachments or write them to an explicit artifact directory only when the test owns screenshot evidence.
- Terminate or relaunch the app between tests when persisted state can leak.
- Prefer focused batches over one giant UI suite when simulator memory, timing, or state leakage is a known risk.

If a UI test requires manual taps because the environment lacks a driver, record that as residual risk and queue automation follow-up instead of calling the proof repeatable.

## Maintained XCUITest Smoke

Run the maintained smoke path with:

```bash
make ui-smoke
```

The command uses `/tmp/owlory-ui-smoke-derived-data` and runs only the maintained `OwloryUITests/OwloryUITests` smoke class:

```text
OwloryUITests/OwloryUITests
```

## Regression Batch

The regression lane (Lane 2 in [UI Regression Plan](ui-regression-plan.md)) runs separately so the smoke loop stays fast:

```bash
make ui-regression
```

That command uses `/tmp/owlory-ui-regression-derived-data` and targets the regression class only:

```text
OwloryUITests/TodayContinueRegression
```

The first batch lives in `owlory_xcode/OwloryUITests/OwloryUITests.swift` alongside the smoke class but is intentionally excluded from `make ui-smoke` by the smoke command's `-only-testing` filter. Trigger the regression batch pre-release, after a Today/Continue refactor, or on demand — not on every PR.

The next regression batch is queued as `owlory-ui-regression-expansion-next-surface`, targeting the Write capture inbox. The implementation slice should add a new XCUITest class (`OwloryUITests/WriteCaptureRegression`) and wire either `make ui-regression DOMAIN=<domain>` or an additional `-only-testing` filter rather than collapsing Write into `TodayContinueRegression`.

The app-side seed path is intentionally narrow:

- `--owlory-ui-testing` marks the launch as harness-owned and suppresses notification authorization prompts.
- `--owlory-ui-seed-fresh-day` resets app-local `Owlory` and legacy `Trajectory` application-support directories in Debug builds, letting `TodayStore` create a deterministic fresh-day dashboard.
- `--owlory-ui-seed-today-continue-item` resets the same app-local state, writes one current-day planned Focus item, and verifies that Today Continue renders it through the normal Continue projection.
- `--owlory-ui-seed-home-task-continue-item` resets the same app-local state, writes one active Home task, and verifies that Today Continue renders source-derived Home work without changing Home or Today product rules.
- `--owlory-ui-seed-home-protocol-run-continue-item` resets the same app-local state, writes one active Home protocol run, and verifies that Today Continue renders and routes to the active run sheet without changing protocol lifecycle rules.
- `--owlory-ui-seed-due-today-training-continue-item` resets the same app-local state, writes one planned `TrainingSession` dated today, and verifies that Today Continue renders the due-today Training row via the `trainingSession` source.
- `--owlory-ui-seed-carried-forward-focus-continue-item` resets the same app-local state, writes four consecutive daily entries (three prior + today) carrying the same focus title/domain so `PatternEngine.computeCarryForward` produces a stalled-item streak >= 3, and verifies that Today Continue renders today's row via the `carriedFocusItem` source rather than the current Focus source.
- `--owlory-ui-seed-in-progress-writing-continue-item` resets the same app-local state, writes one in-progress `WritingNote` (capture stage), and verifies that Today Continue renders the in-progress Writing row via the `writingNote` source.
- The tests verify the Today dashboard, seeded Continue rows for all six composer source kinds (currentFocus, dueTodayTraining, carriedForwardFocus, activeHomeProtocolRun, activeHomeTask, inProgressWriting), one Focus-backed Continue Done action, one Home-task-backed Continue route into Home, and one Home-protocol-run-backed Continue route into the active run sheet through stable accessibility identifiers.

This proves that deterministic UI seed paths and the XCUITest harness are operational for the Today launch surface, source visibility across all six composer-backed Continue sources (currentFocus, dueTodayTraining, carriedForwardFocus, activeHomeProtocolRun, activeHomeTask, inProgressWriting), one Focus-backed Continue row action, four route smokes (Home task -> Home highlight, Home protocol run -> active run sheet, in-progress Writing -> Write note detail sheet, due-today Training -> Train session highlight). It does not prove focus or carried-forward Focus routing, screenshot-reviewed proof, device behavior, TestFlight behavior, or a full regression suite.

The maintained XCUITest smoke suite proves selected high-value Today Continue paths, not exhaustive UI behavior.

## UI Proof Roadmap

Treat the remaining UI proof gaps as a roadmap, not one giant slice. Broaden source coverage first, then routing, then preserved screenshots, then physical-device and TestFlight proof, then design a full regression suite. The five-lane shape that this roadmap converges on is defined in [UI Regression Plan](ui-regression-plan.md).

Immediate queued slices:

| Slice | Purpose | Proof target |
| --- | --- | --- |
| `owlory-ui-test-continue-source-coverage-triage` | Inventory every Today Continue source and classify current vs needed XCUITest source coverage. | `doc-only`; complete in [Today Domain](../product/domains/today.md#continue-ui-source-coverage). |
| `owlory-ui-test-continue-source-smoke-batch` | Add deterministic source-visibility smoke for due-today Training, carried-forward Focus, and in-progress Writing. | `running-app-smoke`, XCUITest-backed |
| `owlory-ui-test-continue-routing-matrix-triage` | Define expected routes for each Continue source before adding more route tests. | `doc-only` |
| `owlory-ui-test-continue-routing-smoke-batch` | Add deterministic route smoke for the highest-value missing sources selected by the matrix. | `running-app-smoke`, XCUITest-backed |

Deferred proof lanes:

| Lane | Gate before starting | Proof target |
| --- | --- | --- |
| `owlory-ui-test-screenshot-proof-pack` | Source and routing smoke should be clear enough that screenshots preserve useful evidence rather than random surfaces. | `screenshot-verified` |
| `owlory-ui-test-device-proof` | Running simulator paths should be stable, and the chosen device flows should have explicit provenance expectations. | `device-verified` |
| `owlory-ui-test-testflight-proof` | Completed for the captured natural-data Today Continue launch surface plus one Home protocol run route; debug-only seed flags were not used. | `testflight-verified` for the captured path only |
| `owlory-ui-regression-suite-plan` | Smoke/source/routing proof should be mature enough to define what broader regression coverage means. | `doc-only` |

Do not claim broad UI regression coverage until that suite is intentionally designed and maintained.

## Screenshot Proof Artifacts

Repo-managed screenshot proof must live under:

```text
automation/proofs/<slice-id>/
```

Each proof directory needs:

- screenshots with stable names
- a README explaining what each screenshot proves
- hashes or a manifest when the proof claim depends on image integrity
- a clear list of what the screenshots do not prove

Do not preserve white launch-transition screenshots or stale screenshots just because a file exists. Recapture after the surface settles, or keep the proof level lower.

## Maintained Smoke Screenshot Pack

The maintained XCUITest smoke captures one named screenshot per test via `captureScreenshot(named:)` in `OwloryUITests` (`XCTAttachment(screenshot:)` with `lifetime = .keepAlways`). Naming follows the proof-pack convention `NN-kebab-case` so the extraction script can map attachments to files deterministically.

Refresh the screenshot pack after every change that affects a maintained smoke flow:

```bash
make ui-smoke-proof
```

That target runs `make ui-smoke` and then `python3 automation/smoke/extract_ui_smoke_screenshots.py`, which walks the newest `.xcresult` bundle under `/tmp/owlory-ui-smoke-derived-data/Logs/Test/`, exports each proof-pack-named attachment via `xcrun xcresulttool export object --legacy`, and writes the PNGs plus a `manifest.json` (with sha256 hashes, source commit, capture timestamp) to:

```text
automation/proofs/owlory-ui-smoke-proof/
```

The screenshots in that directory are the durable artifact; the xcresult bundle is transient. Do not check the xcresult bundle in. Do not edit the PNGs by hand — recapture if a change is needed and let the manifest hashes shift.

## Simulator Preflight Recovery

`make ui-smoke` and `make ui-smoke-proof` occasionally fail with:

```text
Simulator device failed to launch com.raelldottin.owlory.uitests.xctrunner.
... Application failed preflight checks
... Busy ("SBMainWorkspace")
```

This is environmental, not a product or test-logic regression. It happens when a prior test run left a stale xctrunner or app process in the simulator's launch services. The deterministic recovery is:

```bash
xcrun simctl shutdown all
xcrun simctl erase <available-simulator-udid>   # choose the default destination UDID from `xcrun simctl list devices available`
rm -rf /tmp/owlory-ui-smoke-derived-data
make ui-smoke
```

After the recovery passes once, the suite tends to stay green on subsequent runs without re-erasing. Classify this as `test harness or stale DerivedData` per the Failure Classification list above; do not chase it as a product regression unless the failure persists after a clean simulator + clean DerivedData.

## Failure Classification

When a UI test or proof run fails, classify the failure before broad fixes:

- app crash or launch failure
- test harness or stale DerivedData
- missing fixture or seed data
- missing accessibility identifier
- timing or scroll/hittability issue
- actual product regression
- pre-existing expected failure

Failure reports should include:

- command run
- destination and OS
- DerivedData path
- artifact/log path
- expected state
- observed state
- smallest next fix slice

Do not bury known failures inside broad PR prose. Put durable classifications in `docs/workflows/` or the slice handoff when they affect future work.

## Minimum Validation Shape

For UI-affecting source changes:

```bash
make architecture
<affected domain validation>
make ui-smoke
python3 automation/smoke/running_app_smoke.py
git diff --check
```

For proof-only screenshot slices:

```bash
make architecture
make automation-check
git diff --check
```
