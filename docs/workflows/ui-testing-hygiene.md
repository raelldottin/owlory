# UI Testing Hygiene

Use this before adding UI tests, preserving screenshot proof, or claiming running-app behavior. It adapts the durable Gymphant UI-testing lessons to Owlory without pretending Owlory already has a full XCUITest suite.

See [UI Regression Plan](ui-regression-plan.md) for the canonical definition of the five UI coverage lanes (smoke, regression, screenshot, device, TestFlight), what each lane proves and does not prove, and which gating command claims which proof level. This page covers the durable rules that apply within those lanes.

## Current State

- Owlory has a running-app smoke runner: `python3 automation/smoke/running_app_smoke.py`.
- Owlory has repo-managed screenshot proof directories under `automation/proofs/`.
- Owlory has a minimal first-class XCUITest target, `OwloryUITests`, with focused deterministic Today smoke coverage.
- Owlory has five Lane 2 regression batches run by `make ui-regression`: `TodayContinueRegression`, `WriteCaptureRegression`, `TrainRegression`, `HomeProtocolRegression`, and `HomeProtocolRunStepRegression`. `DOMAIN=today`, `DOMAIN=write`, and `DOMAIN=train` filter to a single class each; `DOMAIN=home` filters to both Home regression classes.
- `DOMAIN=localization` filters to two classes: `LocalizationLayoutRegression` (en/de/ar/zh-Hans launch-shell + 5 hittable tab buttons) and `LocalizationAccessibilityRegression` (9-locale AccessibilityXL shell-settle + 5-locale non-empty AX-label coverage on root tabs + ≥44pt tab touch targets). Both run on iPhone 17 by default. `DOMAIN=localization-smaller-width` runs the same two classes on iPhone 16 to surface smaller-width tab layout regressions. These prove shell stability under locale, accessibility, and width launch arguments, not translation quality.
- Smallest-width localization regression work depends on a provisioned simulator named `iPhone SE`. Use `make provision-localization-smallest-width-simulator` once per host and `make provision-localization-smallest-width-simulator-check` in validation before enabling the iPhone SE regression destination.
- Owlory has a narrow TestFlight proof packet for the natural-data Today Continue launch surface plus one Home protocol run route at `automation/proofs/owlory-ui-testflight-proof/20260513T205620Z-provenance-intake/`.
- Owlory has an idb-first dependency check and capture helper for full-locale screenshot proof: `make localization-screenshot-idb-check` and `python3 automation/smoke/capture_locale_screenshots.py`.
- Owlory has an idb-first multisurface screenshot harness for scoped HIG surfaces (Build Info, Today, each root tab, primary empty states, date/count/plural): `make localization-multisurface-screenshot-idb-check` and `python3 automation/smoke/capture_localized_surfaces.py`. Output lands under `automation/proofs/app-localization-hig-multisurface-screenshot-harness/` with a per-capture manifest.

Do not treat the current Today, Write, Train, Home protocol, or queued localization-layout regression batches as broad app-wide UI regression coverage.

## Proof Lanes

Keep these separate:

- `running-app-smoke`: the app built, installed, launched, and produced a non-empty screenshot or log artifact.
- `flow-verified`: a specific running-app user flow was exercised end to end.
- `screenshot-verified`: screenshots are preserved in the repo with a README or manifest that explains the claim.
- `device-verified`: the flow was repeated on a physical device with build provenance.
- `testflight-verified`: the flow was repeated from the TestFlight build identity being claimed.

One lane does not imply another. A smoke screenshot is not a reviewed screenshot-proof artifact by itself. Simulator automation cannot claim `device-verified` or `testflight-verified`; those proof levels require human-provided physical-device or TestFlight evidence with build provenance.

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

## Manual Localization UI Checks

Manual device and TestFlight localization checks may use iOS per-app language selection:

```text
Settings > Apps > Owlory > Language
```

If the option is missing, add the target language through:

```text
Settings > General > Language & Region > Add Language
```

This is a manual review path for language and layout inspection. Do not use Settings automation as the maintained smoke lane; automated locale checks should use the running-app smoke runner's launch arguments instead.

If the desired language does not appear, classify the result as `manual language setting diagnostic needed`, not as a UI regression. Follow the diagnostic steps in [Validation Workflows](validation.md#manual-per-app-language-testing) and preserve the failure shape: no Language row, or Language row present but target language missing.

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
make ui-regression                 # every regression class
make ui-regression DOMAIN=today    # only OwloryUITests/TodayContinueRegression
make ui-regression DOMAIN=write    # only OwloryUITests/WriteCaptureRegression
make ui-regression DOMAIN=train    # only OwloryUITests/TrainRegression
make ui-regression DOMAIN=home     # OwloryUITests/HomeProtocolRegression + HomeProtocolRunStepRegression
```

That command uses `/tmp/owlory-ui-regression-derived-data` and targets these regression classes:

```text
OwloryUITests/TodayContinueRegression
OwloryUITests/WriteCaptureRegression
OwloryUITests/TrainRegression
OwloryUITests/HomeProtocolRegression
OwloryUITests/HomeProtocolRunStepRegression
```

The regression classes live in `owlory_xcode/OwloryUITests/OwloryUITests.swift` alongside the smoke class but are intentionally excluded from `make ui-smoke` by the smoke command's `-only-testing` filter. Trigger the regression batch pre-release, after a domain refactor, or on demand — not on every PR.

`TodayContinueRegression` covers source visibility for all six composer-backed Continue sources, source-derived routing for the four route smokes (Home task, active Home protocol run, in-progress Writing, due-today Training), and Focus row actions (Done, Defer, Drop) via `--owlory-ui-seed-today-continue-item` and the other Today seed launch args.

`WriteCaptureRegression` covers the Write capture inbox surface via the existing `--owlory-ui-seed-in-progress-writing-continue-item` seed: it opens the Write tab, asserts the seeded in-progress note row and the capture entry affordance, and asserts the Add to Today promotion is reachable from the note detail sheet without exercising the cross-domain side effect. Voice / live transcription, task promotion side effects, protocol promotion side effects, and screenshot / device / TestFlight claims are intentionally out of scope; follow-up slices own those.

`TrainRegression` covers the Train active/history transition via the existing `--owlory-ui-seed-due-today-training-continue-item` seed: it opens Train, asserts the seeded planned session appears in active Today, completes it through the existing status/save controls, and asserts it appears in History with completed status. Modified/skipped statuses, recurrence rollover UI, voice/reflection fallback, screenshot, device, and TestFlight claims are intentionally out of scope.

`HomeProtocolRegression` covers Home protocol template archive/restore management via `--owlory-ui-seed-home-protocol-template`: it opens Home, asserts the seeded protocol template appears in the active protocol list, archives it through the direct protocol-level archive affordance, asserts it moves to Archived Protocols, restores it, and asserts it returns active. Active-run lifecycle, schedule labels, step revert, per-step archive, screenshot, device, and TestFlight claims are intentionally out of scope.

`HomeProtocolRunStepRegression` covers active-run step progression via the existing `--owlory-ui-seed-home-protocol-run-continue-item` seed: it opens the active run sheet through the Today Continue row, taps the per-step Complete action, and asserts the step transitions out of pending state while the step title remains visible. Step skip, step revert, schedule-window status display, protocol template editing, additional pending steps, screenshot, device, and TestFlight claims are intentionally out of scope. The row uses `.accessibilityElement(children: .contain)` so the inner per-step Complete button remains individually addressable under the outer `home.protocolRun.step.<uuid>` identifier; do not remove that modifier without rewriting the test.

The app-side seed path is intentionally narrow:

- `--owlory-ui-testing` marks the launch as harness-owned and suppresses notification authorization prompts.
- `--owlory-ui-seed-fresh-day` resets app-local `Owlory` and legacy `Trajectory` application-support directories in Debug builds, letting `TodayStore` create a deterministic fresh-day dashboard.
- `--owlory-ui-seed-today-continue-item` resets the same app-local state, writes one current-day planned Focus item, and verifies that Today Continue renders it through the normal Continue projection.
- `--owlory-ui-seed-home-task-continue-item` resets the same app-local state, writes one active Home task, and verifies that Today Continue renders source-derived Home work without changing Home or Today product rules.
- `--owlory-ui-seed-home-protocol-run-continue-item` resets the same app-local state, writes one active Home protocol run, and verifies that Today Continue renders and routes to the active run sheet without changing protocol lifecycle rules.
- `--owlory-ui-seed-home-protocol-template` resets the same app-local state, writes one active Home protocol template without an active run, and verifies Home protocol template archive/restore management without changing protocol lifecycle rules.
- `--owlory-ui-seed-due-today-training-continue-item` resets the same app-local state, writes one planned `TrainingSession` dated today, and verifies that Today Continue renders the due-today Training row via the `trainingSession` source.
- `--owlory-ui-seed-carried-forward-focus-continue-item` resets the same app-local state, writes four consecutive daily entries (three prior + today) carrying the same focus title/domain so `PatternEngine.computeCarryForward` produces a stalled-item streak >= 3, and verifies that Today Continue renders today's row via the `carriedFocusItem` source rather than the current Focus source.
- `--owlory-ui-seed-in-progress-writing-continue-item` resets the same app-local state, writes one in-progress `WritingNote` (capture stage), and verifies that Today Continue renders the in-progress Writing row via the `writingNote` source.
- The tests verify the Today dashboard, seeded Continue rows for all six composer source kinds (currentFocus, dueTodayTraining, carriedForwardFocus, activeHomeProtocolRun, activeHomeTask, inProgressWriting), one Focus-backed Continue Done action, one Home-task-backed Continue route into Home, one Home-protocol-run-backed Continue route into the active run sheet, one Train tab active Today -> History transition, and one Home protocol template archive/restore flow through stable accessibility identifiers.

This proves that deterministic UI seed paths and the XCUITest harness are operational for the Today launch surface, source visibility across all six composer-backed Continue sources (currentFocus, dueTodayTraining, carriedForwardFocus, activeHomeProtocolRun, activeHomeTask, inProgressWriting), one Focus-backed Continue row action, four route smokes (Home task -> Home highlight, Home protocol run -> active run sheet, in-progress Writing -> Write note detail sheet, due-today Training -> Train session highlight), the Train active Today -> History transition for a completed session, and Home protocol template archive/restore management. It does not prove focus or carried-forward Focus routing, every Train status, recurrence rollover UI, Home protocol schedule labels, per-step archive, screenshot-reviewed proof, device behavior, TestFlight behavior, or a full regression suite.

The maintained XCUITest smoke suite proves selected high-value Today Continue paths, not exhaustive UI behavior.

## UI Proof Roadmap

Treat the remaining UI proof gaps as a roadmap, not one giant slice. Broaden source coverage first, then routing, then preserved screenshots, then physical-device and TestFlight proof, then design a full regression suite. The five-lane shape that this roadmap converges on is defined in [UI Regression Plan](ui-regression-plan.md).

Completed foundation slices:

| Slice | Purpose | Proof target |
| --- | --- | --- |
| `owlory-ui-test-continue-source-coverage-triage` | Inventory every Today Continue source and classify current vs needed XCUITest source coverage. | `doc-only`; complete in [Today Domain](../product/domains/today.md#continue-ui-source-coverage). |
| `owlory-ui-test-continue-source-smoke-batch` | Add deterministic source-visibility smoke for due-today Training, carried-forward Focus, and in-progress Writing. | `running-app-smoke`, XCUITest-backed |
| `owlory-ui-test-continue-routing-matrix-triage` | Define expected routes for each Continue source before adding more route tests. | `doc-only` |
| `owlory-ui-test-continue-routing-smoke-batch` | Add deterministic route smoke for the highest-value missing sources selected by the matrix. | `running-app-smoke`, XCUITest-backed |
| `owlory-ui-regression-batch-1-today-continue` | Establish Lane 2 regression wiring around Today Continue source visibility, source-derived routing, and Focus row actions. | `running-app-smoke`, XCUITest-backed |
| `owlory-ui-regression-expansion-next-surface` | Lane 2 Batch 2 covering the Write capture inbox row, capture entry affordance, and Add to Today promotion visibility. | `running-app-smoke`, XCUITest-backed |
| `owlory-ui-regression-batch-3-train-active-history` | Lane 2 Batch 3 covering the Train tab active/history transition: seed one planned session, complete it through visible Train UI, and assert it leaves active Today and appears in History. | `running-app-smoke`, XCUITest-backed |
| `owlory-ui-regression-batch-4-home-protocol-archive-restore` | Lane 2 Batch 4 for Home protocol template archive/restore management: seed one template, archive it through a protocol-level affordance, verify it moves to Archived Protocols, restore it, and verify it returns active. | `running-app-smoke`, XCUITest-backed |

The next selected regression surface is localization layout, scoped to representative locale launch-shell stability. The queued implementation slice is `owlory-ui-regression-batch-7-localization-layout-shell`; do not broaden it into translation quality, all-locale layout proof, screenshots, device proof, or TestFlight proof.

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

## Localization Screenshot Capture

Use the idb capture helper for full-locale localization screenshot proof:

```bash
make localization-screenshot-idb-check
python3 automation/smoke/capture_locale_screenshots.py --udid <simulator-udid>
```

The check is intentionally separate from `make localization-check` and the running-app smoke runner. Missing `idb` or `idb_companion` blocks the screenshot proof lane on that machine, but it does not invalidate localization parity or all-locale resource-loading smoke.

The helper uses idb for the pieces where `simctl` is too blunt:

- launch Owlory with locale arguments against a specific target
- inspect accessibility state through `idb ui describe-all`
- dismiss known system prompts such as notification permission
- wait for the settled Today launch surface
- reject captures while a prompt remains or the expected surface is missing
- require an empty proof directory so stale and fresh screenshots are never mixed

`xcodebuild` and `simctl` remain the build/install/running-app smoke foundation. idb is the UI interaction/capture helper for screenshot proof, not a replacement for the existing smoke lane.

For scoped HIG surfaces beyond the Today launch screenshot, use the multisurface harness:

```bash
make localization-multisurface-screenshot-idb-check
python3 automation/smoke/capture_localized_surfaces.py --list-surfaces
python3 automation/smoke/capture_localized_surfaces.py --capture --udid <udid> \
    --locales en de --surfaces today build-info
```

The multisurface harness shares the idb dependency check, system-prompt dismissal, and empty-output-directory guard with the launch-surface helper. It adds a configurable surface catalog (`today`, `root-tab-train`, `root-tab-write`, `root-tab-career`, `root-tab-home`, `build-info`, `empty-state-today`, `date-count-plural-today`) and writes a per-capture `manifest.json` with `locale`, `surface_id`, `file`, `bytes`, `sha256`, `navigation_steps_executed`, `git_commit_short`, and explicit non-claims.

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
