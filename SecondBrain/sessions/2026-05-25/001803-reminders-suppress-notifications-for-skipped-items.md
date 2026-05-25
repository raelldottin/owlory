# reminders-suppress-notifications-for-skipped-items

## Prompt

User reported that Train items still receive notifications for missed windows when the Train item status is `skipped`, and stated the rule: no notifications should occur for skipped items.

## Interpretation

The user's stated rule is general ("no notifications for skipped items"), and a parallel bug pattern exists in Home (skipped recurring tasks). User confirmed scope as Train + Home.

## Plan

1. Classify slice `reminders-suppress-notifications-for-skipped-items` in `automation/queue/slices.json` and dry-run the supervisor.
2. Treat `.skipped` as a terminal user disposition for reminder suppression only — do not log skipped items to `CompletionHistoryStore`.
3. Fire the `onItemCompleted` cancel hook synchronously in `TrainStore.updateSession` for `.skipped` and in `HomeStore.skipTask`.
4. Include skipped items in the `completedKeys` set built by `RootTabView.refreshRuntimeArtifacts` so bulk re-schedule does not re-add the reminder.
5. Flip the stale `TrainStoreTests.testNonCompletionStatusDoesNotCallOnItemCompletedHook` (which codified the bug as intended behavior) and add positive coverage in both `TrainStoreTests` and `HomeStoreTests`.
6. Update `docs/product/domains/reminders.md` from "completed-today suppression" to a resolved-today rule that names skipped explicitly.

## Files Edited

- `automation/queue/slices.json` — added queued slice; status moved to done after validations.
- `owlory_xcode/Owlory/Core/Application/TrainStore.swift` — split the resolution branch so `.skipped` fires `onItemCompleted` without logging to history.
- `owlory_xcode/Owlory/Core/Application/HomeStore.swift` — `skipTask` now fires `onItemCompleted` with the predictor key.
- `owlory_xcode/Owlory/RootTabView.swift` — `refreshRuntimeArtifacts` now adds skipped recurring Home tasks and skipped Train sessions to `completedKeys`; comments renamed from "completed/modified" to "resolved".
- `owlory_xcode/OwloryCoreTests/TrainStoreTests.swift` — replaced the negative `.skipped` assertion with `testSkippingSessionAlsoCallsOnItemCompletedHook`; added `testRevertingSessionToPlannedDoesNotCallOnItemCompletedHook` to keep negative coverage on the only remaining non-terminal status.
- `owlory_xcode/OwloryCoreTests/HomeStoreTests.swift` — added `testSkippingTaskCallsOnItemCompletedHookWithPredictorKey`.
- `docs/product/domains/reminders.md` — rewrote the suppression note to spell out the Train and Home terminal-disposition rule.

## Commands

- `python3 automation/supervisor/run_next.py --dry-run` — selected `reminders-suppress-notifications-for-skipped-items` with the exact allowed_paths.
- `make architecture` — passed.
- `git diff --check` — clean.
- `make test-domain DOMAIN=train` — `** TEST SUCCEEDED **`, including the two new test cases.
- `make test-domain DOMAIN=home` — first attempt failed with a simulator-busy launch error (`FBSOpenApplicationServiceErrorDomain Code=1 ... Busy`); after `xcrun simctl shutdown all`, re-run produced `** TEST SUCCEEDED **`, including `testSkippingTaskCallsOnItemCompletedHookWithPredictorKey`.

## Outcome

Skipped Train sessions and skipped recurring Home tasks no longer trigger missed-window notifications. Per-item cancel fires synchronously at the moment of skip, and the bulk reschedule loop treats both completed and skipped recurring items as resolved-today.
