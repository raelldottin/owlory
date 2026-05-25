# reminders-terminal-status-cancel-simulator-proof

## Prompt

User re-reported "Train items still receive notifications for missed windows when Train item status is not pending. No notifications should occur for items with skipped and completed status." Asked to test completion using simulators.

## Interpretation

Previous slice landed the fix but coverage was only at the store-level (asserting the `onItemCompleted` callback fires). The user wanted simulator-level proof that the cancel chain actually removes the pending request from `UNUserNotificationCenter`, not just that the closure is invoked.

## Plan

1. Add a follow-up slice for the simulator-level proof, separate from the previous fix slice.
2. Write an XCTest that drives the real `UNUserNotificationCenter` on the simulator: requests provisional notification authorization, schedules a pending reminder with the exact `owlory.reminder.<key>` identifier scheme, then exercises each terminal status and the negative case.
3. Wire the test file into the Xcode project (PBXBuildFile, PBXFileReference, group, sources build phase) and into `Tools/validate.sh`'s `reminders` domain so `make test-domain DOMAIN=reminders` runs it.
4. Run via iPhone 17 simulator on iOS 26.5 and capture per-test results.

## Files Edited

- `automation/queue/slices.json` — added `reminders-terminal-status-cancel-simulator-proof` slice; flipped to done after validations.
- `owlory_xcode/OwloryCoreTests/ReminderSchedulerTerminalStatusCancelIntegrationTests.swift` — new file; six tests covering Train `.skipped`, `.completed`, `.modified`, `.planned` (negative), and Home recurring task completed/skipped.
- `owlory_xcode/Owlory.xcodeproj/project.pbxproj` — added B701/B702 IDs to register the new test file in the OwloryCoreTests target.
- `Tools/validate.sh` — appended the new test class to the `reminders` domain run.

## Commands

- `python3 automation/supervisor/run_next.py --dry-run` → selected `reminders-terminal-status-cancel-simulator-proof`.
- `make architecture` → passed.
- `make test-domain DOMAIN=reminders` → `** TEST SUCCEEDED **`. All six new integration tests passed on iPhone 17 (iOS 26.5):
  - `testCompletingRecurringHomeTaskRemovesPendingReminder` (0.572s)
  - `testCompletingTrainSessionRemovesPendingReminder` (0.535s)
  - `testModifyingTrainSessionRemovesPendingReminder` (0.526s)
  - `testRevertingTrainSessionToPlannedLeavesPendingReminder` (0.525s, negative case — `.planned` leaves the pending reminder intact)
  - `testSkippingRecurringHomeTaskRemovesPendingReminder` (0.523s)
  - `testSkippingTrainSessionRemovesPendingReminder` (0.528s)
- `make test-domain DOMAIN=train` → `** TEST SUCCEEDED **`.
- `make test-domain DOMAIN=home` → `** TEST SUCCEEDED **` (after a `xcrun simctl shutdown all` to clear a busy-launch from the prior run).
- `git diff --check` → clean.

## Outcome

Simulator-level proof confirms the cancel chain works end-to-end. For Train `.completed`, `.modified`, `.skipped` and Home recurring `.completed`, `.skipped`, the pending `UNUserNotificationCenter` request with identifier `owlory.reminder.<predictor-key>` is removed within ~500ms of the status change. The negative case (`.planned`) leaves the pending request intact, confirming only terminal statuses cancel.

If the user still observes a missed-window notification firing for a Train or Home item that is currently completed/skipped, the cause is not in the cancel wiring proven by this slice — the binary on the device may pre-date commit `3eb808a`, the prediction belongs to an activity whose name no longer matches the active session's `plannedActivity` (key mismatch), or the activity has historical predictions but no resolved-today session (the suppression filter only enters the key when a today session exists in a terminal state).
