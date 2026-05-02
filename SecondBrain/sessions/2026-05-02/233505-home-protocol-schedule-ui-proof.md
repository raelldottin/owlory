# home-protocol-schedule-ui-proof

## Summary

Captured simulator-side screenshot proof for the run-aware Home protocol schedule labels that shipped in `home-protocol-schedule-stale-treatment` (commit `d443b2a`). Built that commit for the iPhone 16 simulator (`93831D66-8855-467D-8991-81886B30A57F`, iOS 26.3.1), seeded four `HouseholdProtocol` records and one `ProtocolRun` directly into the simulator's app data container, launched the app, navigated to the Home tab, and captured a screenshot showing all four `ScheduleStatus` values rendering correctly. The Overdue vs Satisfied contrast (same schedule shape, different label because of run history) is the load-bearing piece of evidence and is preserved as a durable artifact under `automation/proofs/home-protocol-schedule-ui-proof/`.

## What the screenshot shows

| Row | Schedule | Run history | Rendered label | Tint |
| --- | --- | --- | --- | --- |
| Active sample (Today preset) | preset=today, dates=2026-05-02 | none | "Scheduled for today" | secondary |
| Upcoming sample (custom future) | preset=custom, dates=2026-05-04 | none | "Scheduled for May 4, 2026" | secondary |
| Overdue sample (no run) | preset=today, dates=2026-04-30 | none | "Today window passed" | **orange** |
| Satisfied sample (run during window) | preset=today, dates=2026-04-30 | one run, createdAt=2026-04-30 | "Scheduled for today" | secondary |

Rows 3 and 4 share an identical schedule shape and differ only in run history. The fact that they render different labels proves the run-aware classification (`scheduleStatus(for:runs:now:calendar:)` and `summary(for:runs:now:calendar:)`) is live in the running app, not only in `ProtocolScheduleRulesTests` / `HomeStoreTests`.

## How the proof was driven

- Built once for simulator from a clean working tree at `d443b2a` so the install carried real git provenance (the worktree-aware stamp fix landed earlier in this session).
- Seeded `Library/Application Support/Owlory/Home/protocols.json` and `runs.json` directly in the simulator's data container with the JSON schema produced by `FileItemListRepository<Item>`. Schedule dates use noon UTC so `Calendar.current.startOfDay(for:)` resolves to the intended calendar day across common host timezones; the first seed pass used UTC midnight and drifted back one day in PST/PDT, which produced an off-by-one label until corrected.
- Set `xcrun simctl ui … content_size large` because the host simulator was inheriting an accessibility-extra-extra-extra-large content size that hid most rows below the fold.
- Captured with `xcrun simctl io … screenshot` after the operator tapped the Home tab. `simctl` does not support taps, and neither `osascript` (no accessibility grant) nor `idb`/`cliclick` (not installed) could drive the tap from the harness.

## Validation

- `python3 automation/context/build_context.py --slice-id home-protocol-schedule-ui-proof`
- `python3 automation/supervisor/run_next.py --dry-run`
- `make architecture`
- `make automation-check`
- `git diff --check`
- Build: `xcodebuild build` for `platform=iOS Simulator,id=93831D66-8855-467D-8991-81886B30A57F` (Debug) at `d443b2a`.
- Install + launch: `xcrun simctl install` and `xcrun simctl launch com.raelldottin.owlory`.
- Capture: `xcrun simctl io … screenshot` (Home tab), persisted under `automation/proofs/home-protocol-schedule-ui-proof/`.

## Findings worth preserving

- **Satisfied label is intentionally non-nagging but technically misleading.** Row 4 reads "Scheduled for today" although the window was 2026-04-30. That matches the rule documented in `home-protocol-schedule-stale-treatment` ("don't nag once a run satisfied the window") but a future UX pass could replace it with something like "Today window completed" once a copy pattern is chosen. Recorded as a residual risk; not queued.
- **Tap automation gap.** The slice required two manual taps from the operator. A more ambitious schedule-UI proof slice (multi-state captures, device coverage, accessibility variants) should plan for `idb`, an accessibility-grant osascript, or a small XCUITest harness rather than ad-hoc manual driving.
- **Seed data is not in the repo.** Reproducing this proof on a fresh simulator requires re-running the seed against a freshly installed app. The README documents the JSON shape so it is reproducible. A small seed script under `automation/` would be cleaner; that lives outside this slice's scope.

## Next

Queue order remains:

1. `today-last-week-insights-actionability-triage` (queued, priority 145)
2. `home-protocol-schedule-notifications` (queued, priority 140)

`device-verified` for the schedule labels is not pursued here; it can be a separate slice if it becomes a release gate. The seed-script and accessibility/dark-mode coverage are also separate slices on demand.
