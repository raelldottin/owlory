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
- Preserve completed-today suppression so reminders do not nag completed work.
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
