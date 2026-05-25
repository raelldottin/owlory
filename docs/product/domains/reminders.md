# Reminders Domain

## Owns

- Completion history.
- Statistical expected completion times.
- Overdue detection.
- Reminder eligibility, threshold timing, and completed-today suppression.
- Local notification scheduling and cancellation.
- Scheduling app-runtime reminder output for Today-owned prompts such as check-in and evening reflection once Today exposes those prompts.
- Protocol schedule notification delivery. `ProtocolScheduleNotificationRules` (Core/Domain) produces plans; `ReminderScheduler` converts them into `UNNotificationRequest` alongside existing prediction and prompt notifications.

## Does Not Own

- The actual product meaning of a training session, home task, or protocol run.
- Today Continue presentation.
- Apple notification authorization UX beyond scheduler requests.

## Depends On

- `CompletionTimePredictor` for pure prediction logic.
- `ReminderSuppressionRules` for the resolved-today / active-match policy that decides which predictor keys must enter the `completedKeys` set passed to `ReminderSchedulingRules`. A prediction key fires a reminder only when there is something to act on right now: a Train session for today still in `.planned` for that activity, OR a Home recurring task that is active (recurring, not currently completed or skipped) for that title. Any prediction key without an active match is suppressed; this subsumes the prior "terminal today session" rule and closes the stale-prediction gap where an activity with historical completions but no today item still received a reminder.
- `ReminderSchedulingRules` for pure reminder timing and suppression policy.
- `CompletionHistoryStore` for records and predictions.
- `ReminderScheduler` for UserNotifications integration.
- `ReminderScheduleTrace` for scheduler diagnostics (includes `protocolScheduleCount`).
- `ProtocolScheduleNotificationRules` for protocol schedule notification planning.

## Exposes

- Completion keys and predictions.
- Reminder scheduling plans.
- Reminder scheduling entry points.

## Change Safely

- Keep statistical logic pure.
- Keep reminder eligibility and deadline policy in `ReminderSchedulingRules`.
- Keep `UserNotifications` calls inside `ReminderScheduler`.
- Preserve resolved-today suppression so reminders do not nag work the user has already dispositioned today. A Train session marked completed, modified, or skipped, and a recurring Home task marked completed or skipped, are all terminal user dispositions; their predictor keys must enter the `completedKeys` set passed to `ReminderSchedulingRules.plan`, and the per-item `onItemCompleted` cancel hook must fire synchronously at the moment of resolution so a pending notification cannot still fire after the user has decided not to act today. Only Train sessions reverted to planned, and Home tasks restored from skipped, leave a pending reminder in place.
- Treat the per-item `onItemCompleted` cancel hook as a contract for any mutation that invalidates a previously-keyed reminder: renaming a Train session's `plannedActivity` or a Home recurring task's `title` must fire the hook with the OLD predictor key, and deleting either item must fire the hook with its key. The bulk reschedule cleans up at the next foreground entry, but the per-item cancel closes the window between mutation and next reschedule so the user does not see a reminder for a name they have already renamed or deleted.
- Predictions without an active match for today must not fire. The `ReminderSuppressionRules` rule encodes this: if there is no Train `.planned` today session for the prediction's activity (or no active recurring Home task for the prediction's title), the key is included in `completedKeys`. This is intentional — predictions reflect historical activity, not commitment to act today, so a "you missed your usual training window" reminder only makes sense when there is a session to act on.
- Preserve dedupe by clearing existing Owlory reminder and protocol-schedule requests before adding the current plan.
- Scheduling currently happens when app wiring calls `ReminderScheduler.reschedule`, including launch and foreground entry.
- Protocol schedule notifications use identifiers prefixed with `owlory.protocol-schedule.` with a deterministic scheme per protocol/kind, separate from the `owlory.reminder.` prefix used by prediction and prompt notifications.
- Starting a run for a protocol cancels stale notifications for that protocol's window through the next reschedule cycle; satisfied schedules do not produce notifications.
- Delivered notification title/body copy is localized by `ReminderNotificationCopy` in the reminder application path. It may project Today prompt kinds, prediction keys, and protocol schedule plans into notification-specific copy, but must not change prompt timing, schedule eligibility, or product-rule semantics.
- Today owns prompt eligibility and prompt kind; ReminderScheduler owns the delivered notification title/body for those prompt kinds.
- Reminder notification specs should include app-runtime deep-link metadata for the represented prompt or completion key so notification taps and mirrored widget entries can return to the associated Owlory item.

## Verify

- `make test-domain DOMAIN=reminders`
- `xcodebuild test -project Owlory.xcodeproj -scheme Owlory -destination "$OWLORY_XCODE_DESTINATION" -only-testing:OwloryCoreTests/CompletionTimePredictorTests -only-testing:OwloryCoreTests/ReminderSchedulingRulesTests`
