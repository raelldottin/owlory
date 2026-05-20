# app-reminders-cancel-pending-on-item-completion

## Prompt

> "start next slice" — execute the supervisor-selected slice for the user-reported bug "an train item would be completed but a notification will appear stating the window has passed."

## What was done

Bug-fix slice for the user-reported notification bug. Build-tested + domain-tested. No translation changes, no other product surface touched.

### Root cause

`ReminderScheduler.cancelReminder(forKey:)` existed but was **never called from any store**. Completion-aware suppression only ran via the bulk `reschedule()` rebuild path. That path:

1. Depends on `RootTabView.refreshRuntimeArtifacts()` firing.
2. Which depends on SwiftUI's `.onChange(of: reminderRefreshKey)` firing.
3. Which depends on a View being on-screen and the published keys actually changing.

Failure modes:

- App is backgrounded between scheduling and completion. The next `reschedule()` doesn't run until foreground. Meanwhile, the OS delivers the now-stale notification.
- Notification has already been delivered. `removePendingNotificationRequests` only removes pending, not delivered.

### Fix

1. **`TrainStore`** gains an `onItemCompleted: ((String) -> Void)?` init param. `updateSession(...)` fires the closure with `CompletionTimePredictor.key(forTrainingSession:)` whenever status flips to `.completed` or `.modified`. Synchronous, same MainActor turn as the status flip.

2. **`ReminderScheduler.cancelReminder(forKey:)`** now removes both pending AND delivered notifications for the same identifier, so a notification that arrived just before the completion tap is cleared from Notification Center.

3. **`OwloryApp.swift`** wires the closure: `{ key in Task { @MainActor in scheduler.cancelReminder(forKey: key) } }`. The `@MainActor` hop is required because the closure is `Sendable` from a non-isolated escape, while `ReminderScheduler` is `@MainActor`.

4. The existing bulk `reschedule()` suppression via `completedKeys` is **preserved** as belt-and-suspenders.

### Regression tests

`owlory_xcode/OwloryCoreTests/TrainStoreTests.swift` — 3 new methods:

| Test | Assertion |
|---|---|
| `testCompletingSessionCallsOnItemCompletedHookWithPredictorKey` | `.completed` fires the hook with the predictor key |
| `testModifyingSessionAlsoCallsOnItemCompletedHook` | `.modified` is treated the same (matches existing `completionHistory.logTrainingCompletion` behavior) |
| `testNonCompletionStatusDoesNotCallOnItemCompletedHook` | `.skipped` does NOT fire the hook |

**Confirmed-failing-on-main**: Before the TrainStore init signature change landed, all three tests failed to compile with `error: extra argument 'onItemCompleted' in call`. After the fix, all pass.

### Why TrainStore only, not Home/Today

The user-reported bug names train items specifically. The same closure-injection pattern generalizes trivially to `HomeStore.completedTasks` / completed protocol runs and `TodayStore` focus-item completion, but a single-store fix keeps the slice tight and the regression demonstrable. Recommended follow-up slice: `app-reminders-cancel-pending-on-home-and-today-completion`.

## Validation

- `python3 automation/context/build_context.py --slice-id app-reminders-cancel-pending-on-item-completion` — ran.
- `python3 automation/supervisor/run_next.py --dry-run` — selected this slice pre-commit.
- `make architecture` — passed.
- `make localization-check` — 19 / 377 / 13.
- `make test-domain DOMAIN=train` — **TEST SUCCEEDED** (includes the 3 new regression tests).
- `make test-domain DOMAIN=runtime` — **TEST SUCCEEDED**.
- `make automation-check` — passed (drift no-drift + 93 unittests OK).
- `make pyright` — 0 errors / 0 warnings.
- `xcodebuild build ... -destination 'generic/platform=iOS Simulator' ...` — exit 0 (warnings only, pre-existing).
- `git diff --check` — clean.

## Lane Boundary

`build-tested + domain-tested`. xcodebuild compiles the wired closure; domain tests cover the TrainStore contract; the run-time `cancelReminder` call is observable in the Notification Center via the OS (not unit-tested directly since `UNUserNotificationCenter.current()` is a singleton without an injection seam — that's a separate refactor).

## Residual Risk

- If a future code path mutates `session.status` to `.completed` or `.modified` without going through `TrainStore.updateSession`, the hook won't fire. Today, all status mutations go through `updateSession`; a future direct-repository write would bypass it. Add a regression test if a new path is introduced.
- The closure runs on MainActor via `Task { @MainActor in ... }`. The captured `scheduler` is the long-lived `OwloryApp` singleton, so lifetime is not currently a hazard. Future refactors that move scheduler ownership should preserve the capture safely.
- `cancelReminder` now removes delivered notifications too. If a user has multiple devices with the same iCloud account, the delivered-removal happens on the device where the completion was tapped; iCloud-mirrored devices may still show the banner until they sync.
- The HomeStore and TodayStore completion paths still rely on the bulk `reschedule()` flow. Recommended follow-up slice noted in handoff.

## Not Claimed

- HomeStore or TodayStore completion paths now cancel reminders (queued follow-up).
- Background-fetch-time completion paths are covered (closure fires only on MainActor).
- Lock-screen / Siri / widget completion is covered (those paths bypass the View; if they call `TrainStore` directly, the hook fires too, but indirect paths via shared persistence haven't been audited).

## Downstream recommended slice

`app-reminders-cancel-pending-on-home-and-today-completion`: apply the same `onItemCompleted` callback pattern to:

- `HomeStore` task completion
- `HomeStore` protocol run completion
- `TodayStore` focus-item completion (Focus Three Done swipe)

The pattern is identical; the work is mechanical replication across 3 more code paths.
