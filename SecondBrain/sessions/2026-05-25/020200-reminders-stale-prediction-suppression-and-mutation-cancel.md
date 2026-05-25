# reminders-stale-prediction-suppression-and-mutation-cancel

## Prompt

User: "remediate rough probabilities" — referring to the three remaining stale-reminder angles flagged after the simulator-proof slice: stale build, activity name drift, and prediction without an active today session.

## Interpretation

(1) Stale build is not a code path — the existing reschedule on launch already wipes `owlory.reminder.*` pending requests, so a clean rebuild self-heals. (2) Activity name drift was a real hole: `TrainStore.updatePlannedActivity`, `HomeStore.updateTask`, `TrainStore.deleteSession`, and `HomeStore.deleteTask` mutated state without firing the per-item cancel hook, leaving the OLD key's pending reminder live until the next foreground reschedule. (3) Predictions without an active today session was a real hole too: the suppression filter only added terminal today sessions to `completedKeys`, so a Train activity or Home recurring task that had historical predictions but no today item still received the missed-window reminder.

## Plan

1. Extract a `ReminderSuppressionRules` domain rule that builds `completedKeys` from "predictions with no active match today." Subsumes the terminal-today-session rule (resolved sessions are not `.planned` so they fall out of the active set) and closes the no-today-item gap.
2. Refactor `RootTabView.refreshRuntimeArtifacts` to call the rule.
3. Add per-item `onItemCompleted` cancels in the four mutation paths.
4. Cover the rule with unit tests (`ReminderSuppressionRulesTests`), cover the new store behavior with unit tests in `TrainStoreTests` / `HomeStoreTests`, and extend the simulator integration class with four new rename/delete cases that prove the cancel reaches real `UNUserNotificationCenter`.
5. Wire the new `ReminderSuppressionRules.swift` into the main and test targets in `project.pbxproj`, wire the new test class into the reminders domain in `Tools/validate.sh`, and refresh the `Reminders` row in `docs/product/domain-index.md` plus the reminders.md "Change Safely" rule list.

## Files Edited

- `automation/queue/slices.json` — added `reminders-stale-prediction-suppression-and-mutation-cancel` slice; flipped to done after validations.
- `owlory_xcode/Owlory/Core/Domain/ReminderSuppressionRules.swift` — new domain rule.
- `owlory_xcode/Owlory/RootTabView.swift` — `refreshRuntimeArtifacts` now delegates to `ReminderSuppressionRules.suppressionKeys(...)`.
- `owlory_xcode/Owlory/Core/Application/TrainStore.swift` — `updatePlannedActivity` fires the cancel hook for the OLD key when the normalized key changes; `deleteSession` fires for the deleted session's key.
- `owlory_xcode/Owlory/Core/Application/HomeStore.swift` — `updateTask` fires the cancel hook for the OLD key when the normalized title changes; `deleteTask` fires for the deleted task's key.
- `owlory_xcode/OwloryCoreTests/ReminderSuppressionRulesTests.swift` — 11 cases covering Train / Home / Protocol suppression rules.
- `owlory_xcode/OwloryCoreTests/TrainStoreTests.swift` — added rename-fires-old-key, rename-to-same-key-doesn't-fire, delete-fires-key.
- `owlory_xcode/OwloryCoreTests/HomeStoreTests.swift` — same three cases for HomeStore.
- `owlory_xcode/OwloryCoreTests/ReminderSchedulerTerminalStatusCancelIntegrationTests.swift` — four new simulator cases proving rename and delete remove the pending request from `UNUserNotificationCenter`.
- `owlory_xcode/Owlory.xcodeproj/project.pbxproj` — registered the new domain file (A701/A702/A705) and the new test file (B703/B704) in main and test target build phases.
- `Tools/validate.sh` — added `ReminderSuppressionRulesTests` to the `reminders` domain run.
- `docs/product/domains/reminders.md` and `docs/product/domain-index.md` — documented the new active-match rule and the mutation-cancel contract.

## Commands

- `python3 automation/supervisor/run_next.py --dry-run` → selected `reminders-stale-prediction-suppression-and-mutation-cancel`.
- `make architecture` → passed.
- `git diff --check` → clean.
- `make test-domain DOMAIN=reminders` → `** TEST SUCCEEDED **`. New tests that passed: 11 `ReminderSuppressionRulesTests` cases and 10 `ReminderSchedulerTerminalStatusCancelIntegrationTests` cases (6 original + 4 new: rename-Train, delete-Train, rename-Home, delete-Home).
- `make test-domain DOMAIN=train` → `** TEST SUCCEEDED **`. New tests: `testRenamingPlannedActivityCallsOnItemCompletedHookForOldKey`, `testRenamingPlannedActivityToSameNormalizedValueDoesNotFireHook`, `testDeletingSessionCallsOnItemCompletedHookWithSessionKey`.
- `make test-domain DOMAIN=home` → `** TEST SUCCEEDED **`. New tests: `testRenamingTaskCallsOnItemCompletedHookForOldKey`, `testRenamingTaskToSameNormalizedTitleDoesNotFireHook`, `testDeletingTaskCallsOnItemCompletedHookWithTaskKey`.

## Outcome

The three remaining stale-reminder angles from the prior slice's end-of-PR notes are now closed in code:

- A Train activity rename or session deletion (and the Home equivalents) synchronously removes the pending reminder via `onItemCompleted`. Same-normalized-key edits do not fire (predictor keys are case-insensitive and trimmed).
- A prediction key with no active match for today (no Train `.planned` session, no active recurring Home task) enters `completedKeys` and is suppressed by `ReminderScheduler.reschedule`. The prior terminal-today-session rule is preserved by the same domain rule because terminal sessions are not `.planned`.
- Stale-build cleanup is unchanged: the existing reschedule clears all `owlory.reminder.*` pending requests at app foreground, so a clean rebuild self-heals.

Simulator coverage now spans the resolution paths (`.completed`, `.modified`, `.skipped`), the negative case (`.planned`), and the mutation paths (rename, delete) for both Train and Home — ten integration tests in total, all passing on iPhone 17 / iOS 26.5.
