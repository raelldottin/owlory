# home-protocol-schedule-stale-treatment

## Summary

Made Home protocol schedule windows produce Home-owned stale/overdue meaning by layering run-history awareness on top of the existing date-only window evaluation. A passed schedule window is now classified as `satisfied` when a run for the same protocol was started during or after the window, and only as `overdue` when no such run exists. Today Continue admission and run lifecycle are unchanged.

## What Changed

`ProtocolScheduleRules` (Core/Domain):

- Added `ScheduleStatus` enum: `upcoming`, `active`, `satisfied`, `overdue`.
- Added `ScheduleSummary { text, status }` to carry the new classification alongside a label.
- Added `scheduleStatus(for: schedule, runs: [ProtocolRun], now: Date, calendar: Calendar) -> ScheduleStatus`. A passed window is `.satisfied` if any provided run's `createdAt` day is on or after the window's start day; otherwise `.overdue`.
- Added a run-aware `summary(for:runs:now:calendar:) -> ScheduleSummary?` that reuses the upcoming/active label when a schedule is `.satisfied` (no nag) and only emits the existing "window passed" warning text when `.overdue`.
- The original date-only `windowState(...)` and `summary(for:now:calendar:) -> Summary?` API is unchanged; existing tests and the schedule-edit preview still use it.

`HomeStore` (Core/Application):

- Added `scheduleStatus(for: HouseholdProtocol, calendar: Calendar = .current) -> ProtocolScheduleRules.ScheduleStatus?`. Filters `runs` by `protocolID` and reads the store's injected clock, so callers do not have to.
- Added `scheduleSummary(for: HouseholdProtocol, calendar: Calendar = .current) -> ProtocolScheduleRules.ScheduleSummary?` for HomeView labels.

`HomeView` (Features/Home):

- `protocolLabel(for:)` now reads `store.scheduleSummary(for: proto)` instead of the date-only rule, and tints the caption orange only when `summary.status == .overdue`. All other statuses keep the existing secondary tint.

`docs/product/domains/home.md`:

- Updated the Protocol Schedule Windows section to record the new classification, the satisfied-vs-overdue rule, and the explicit boundary that this is Home schedule state only and must not change Today Continue admission, run lifecycle, or auto-start a run.

## Why this is the right shape

The slice contract was: "Scheduled Home protocol templates should show stale/overdue state when their selected window passes without an active or completed run, while preserving the rule that schedules do not auto-start, auto-complete, auto-abandon, or auto-admit templates into Today Continue."

The minimum-correct implementation was therefore additive. Existing date-only callers (the schedule edit preview) keep working unchanged. New callers (HomeView's protocol row) get a richer status that distinguishes "we already did it" from "we missed it." `today.md` was deliberately not touched and `automation/proofs/` was not extended; this slice produced no new device or screenshot proof beyond the proof level the existing route-back work already established.

## Validation

- `python3 automation/context/build_context.py --slice-id home-protocol-schedule-stale-treatment`
- `python3 automation/supervisor/run_next.py --dry-run`
- `make architecture`
- `make test-domain DOMAIN=home` (8 new ProtocolScheduleRulesTests, 5 new HomeStoreTests, all passing alongside the existing suite)
- `make test-domain DOMAIN=today` (regression guard, all passing)
- `make automation-check`
- `git diff --check`

## Next

No follow-up slice queued. The deferred items remain explicitly out of scope and should be classified deliberately if pursued:

- Today projection for scheduled templates (would change Today Continue admission for protocol templates, reopens the protocol-template-vs-active-run boundary).
- every-N-days / weekly cadence as new schedule presets.
- scheduled-by-default for Write to Protocol promotion.
- richer Home schedule editing UX (e.g., snooze, skip-this-window, overdue counter).
