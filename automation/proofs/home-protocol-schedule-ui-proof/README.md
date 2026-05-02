# home-protocol-schedule-ui-proof

Simulator-side screenshot evidence for the run-aware Home protocol schedule labels added in `home-protocol-schedule-stale-treatment` (commit `d443b2a`). Captured on iPhone 16 simulator (UDID `93831D66-8855-467D-8991-81886B30A57F`, iOS 26.3.1) running a Debug build of commit `d443b2ae49a72db6d78d4f54aa2c79dd91489bfb`.

## Files

- `01-home-schedule-states.png` — Home tab showing four seeded protocols, each with a different `ScheduleStatus`. The contrast between the third and fourth rows is the load-bearing proof: same schedule shape (preset `today`, dates `2026-04-30`), different label because run history changes the classification.

## Seed data shape (in-simulator container, NOT checked into the repo)

- `Home/protocols.json` (4 templates):
  - `Active sample (Today preset)` — preset `today`, schedule `2026-05-02T12:00:00Z` (current calendar day in the simulator's local timezone), no run.
  - `Upcoming sample (custom future)` — preset `custom`, schedule `2026-05-04T12:00:00Z`, no run.
  - `Overdue sample (no run)` — preset `today`, schedule `2026-04-30T12:00:00Z` (past), no run.
  - `Satisfied sample (run during window)` — preset `today`, schedule `2026-04-30T12:00:00Z` (same past window as Overdue), one run.
- `Home/runs.json` (1 run):
  - Linked by `protocolID` to `Satisfied sample`. `createdAt = 2026-04-30T16:00:00Z`, `status = completed`, completed step. The day matches the schedule's window start, which is what `runStarted(onOrAfter:)` requires for `.satisfied`.

Schedule dates use noon UTC so that `Calendar.current.startOfDay(for:)` resolves to the intended calendar day in any common host timezone. UTC midnight (`2026-05-02T00:00:00Z`) drifts back one day in PST/PDT, which produced an off-by-one label in the first capture attempt; that was corrected before the final screenshot.

## What the screenshot proves

- The run-aware `ProtocolScheduleRules.scheduleStatus(for:runs:now:calendar:)` plumbs all the way through `HomeStore.scheduleSummary(for:)` to the Home protocol row label in `HomeView.protocolLabel`.
- A passed window with no run shows the "window passed" warning text in orange (`Overdue sample` row).
- A passed window with a run started on or after the window's start day suppresses the warning and reuses the upcoming/active label (`Satisfied sample` row).
- The orange tint applies only to `.overdue` (`HomeView.swift:247` ternary), other statuses use the existing secondary tint.
- App boot with seeded `protocols.json` and `runs.json` does not crash; `HouseholdProtocolSchedule` decoding and `ProtocolRun` decoding both succeed for the schemas used.

## What the screenshot does NOT prove

- This proof is simulator-only. A separate device pass would be needed to claim `device-verified` for the schedule labels.
- The `Satisfied sample` row reads `Scheduled for today` even though its window was actually `2026-04-30`. That is the documented "do not nag" behavior of the run-aware summary, not a calendar bug; future UX work could replace it with a positive completion label.
- Dynamic Type, accessibility content sizes, dark mode, and large text-truncation behavior are not covered by this single screenshot.
