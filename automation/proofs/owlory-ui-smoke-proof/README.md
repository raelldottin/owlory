# owlory-ui-smoke-proof

Durable screenshot pack for the maintained Owlory XCUITest smoke suite. Each PNG is one named attachment from a single passing run of `make ui-smoke`, exported via `automation/smoke/extract_ui_smoke_screenshots.py`. Regenerate with:

```bash
make ui-smoke-proof
```

The PNGs and the [`manifest.json`](manifest.json) are the durable artifact. The originating `.xcresult` bundle under `/tmp/owlory-ui-smoke-derived-data/Logs/Test/` is transient and is not checked in.

## How the capture works

`OwloryUITests` defines a private `captureScreenshot(named:)` helper that calls `XCTAttachment(screenshot: XCUIScreen.main.screenshot())` with `lifetime = .keepAlways`. Each test method invokes it once at the assertion moment the test was designed to prove (row visible, action button revealed, destination view rendered). The extraction script walks the test-results activity tree, filters attachments whose name matches the proof-pack pattern (`NN-kebab-case`), and writes one PNG per attachment.

This is metadata only — the XCUITest target's assertions are unchanged from the maintained smoke surface. Removing `make ui-smoke-proof` would leave the suite functionally identical; it would only stop preserving the screenshots.

## Files

| File | What it proves | Source test |
| --- | --- | --- |
| `01-today-launch.png` | Today dashboard renders after a fresh-day launch with seed `--owlory-ui-seed-fresh-day`. | `testSeededTodayLaunchSurface` |
| `02-focus-continue-item.png` | `.focusItem` Continue row renders with the deterministic accessibility identifier `today.continue.item.focusItem.<UUID>`. | `testSeededTodayContinueItemAppears` |
| `03-home-task-continue-item.png` | `.homeTask` Continue row renders with the deterministic accessibility identifier `today.continue.item.homeTask.<UUID>`. | `testSeededHomeTaskAppearsInTodayContinue` |
| `04-home-protocol-routing.png` | Active protocol run sheet auto-presents after tapping a `.homeProtocolRun` Continue row. | `testSeededHomeProtocolRunContinueRowRoutesToActiveRun` |
| `05-training-continue-item.png` | `.trainingSession` Continue row renders with the deterministic accessibility identifier `today.continue.item.trainingSession.<UUID>`. | `testSeededDueTodayTrainingAppearsInTodayContinue` |
| `06-writing-continue-item.png` | `.writingNote` Continue row renders with the deterministic accessibility identifier `today.continue.item.writingNote.<UUID>`. | `testSeededInProgressWritingAppearsInTodayContinue` |
| `07-carried-forward-continue-item.png` | `.carriedFocusItem` Continue row renders via the live `PatternEngine.computeCarryForward` path with the deterministic accessibility identifier `today.continue.item.carriedFocusItem.<UUID>`. | `testSeededCarriedForwardFocusAppearsInTodayContinue` |
| `08-done-action-revealed.png` | Done swipe action button (`today.continue.action.done.focusItem.<UUID>`) is exposed on the leading edge of a Focus-backed row. | `testSeededTodayContinueItemCanBeMarkedDone` |
| `09-home-task-routing.png` | Tapping a `.homeTask` Continue row routes to Home and exposes the seeded task at `home.task.item.<UUID>`. | `testSeededHomeTaskContinueRowRoutesToHomeTask` |
| `10-writing-routing.png` | Tapping a `.writingNote` Continue row auto-presents the Write note detail sheet identified by `write.note.detail.<UUID>`. | `testSeededInProgressWritingContinueRowRoutesToWriteNoteDetail` |
| `11-training-routing.png` | Tapping a `.trainingSession` Continue row routes to Train and exposes the seeded session at `train.session.item.<UUID>`. | `testSeededDueTodayTrainingContinueRowRoutesToTrain` |
| `12-defer-action-revealed.png` | Defer swipe action button (`today.continue.action.defer.focusItem.<UUID>`) is exposed on the trailing edge of a Focus-backed row. | `testSeededTodayContinueItemCanBeDeferred` |
| `13-drop-action-revealed.png` | Drop swipe action button (`today.continue.action.drop.focusItem.<UUID>`) is exposed on the trailing edge of a Focus-backed row. | `testSeededTodayContinueItemCanBeDropped` |

## What this pack does NOT prove

- It is captured on a simulator (iPhone 16, iOS 26.3.1), not a physical device. Device behavior is a separate slice (`owlory-ui-test-device-proof`).
- It is captured against a Debug build with debug-only seed flags. TestFlight (Release) behavior is a separate slice (`owlory-ui-test-testflight-proof`).
- It captures one frame per test at the assertion moment. It does not prove transition correctness, animation behavior, gesture handling, or accessibility behavior beyond identifier presence.
- Add-to-Focus, Skip-for-today, and any future Continue actions are not captured because no current smoke test exercises them. Per [today.md Continue UI Routing Coverage](../../../docs/product/domains/today.md#continue-ui-routing-coverage) those affordances remain doc-only or N/A by contract.
- It does not encode regression scope. The next regression batch slice is `owlory-ui-regression-batch-1-today-continue`, gated behind `owlory-ui-regression-suite-plan`.

## Manifest integrity

`manifest.json` records:

- `source_commit` — the git HEAD at extraction time.
- `captured_at` — UTC timestamp from the extraction run.
- `xcresult` — the name of the xcresult bundle used (not its path, which is transient).
- `screenshots[]` — `name`, `file`, `sha256`, `size_bytes` for each PNG.

If a PR changes UI without updating the manifest hashes, treat that as a proof drift signal: the screenshots either need to be recaptured against the new behavior or the change is unintentional. Do not hand-edit `manifest.json`; recapture via `make ui-smoke-proof` and re-commit.
