# Reminders Domain

## Owns

- Completion history.
- Statistical expected completion times.
- Overdue detection.
- Reminder eligibility, threshold timing, and completed-today suppression.
- Local notification scheduling and cancellation.
- Scheduling app-runtime reminder output for Today-owned prompts such as check-in and evening reflection once Today exposes those prompts.

## Does Not Own

- The actual product meaning of a training session, home task, or protocol run.
- Today Continue presentation.
- Apple notification authorization UX beyond scheduler requests.

## Depends On

- `CompletionTimePredictor` for pure prediction logic.
- `ReminderSchedulingRules` for pure reminder timing and suppression policy.
- `CompletionHistoryStore` for records and predictions.
- `ReminderScheduler` for UserNotifications integration.
- `ReminderScheduleTrace` for scheduler diagnostics.

## Exposes

- Completion keys and predictions.
- Reminder scheduling plans.
- Reminder scheduling entry points.

## Change Safely

- Keep statistical logic pure.
- Keep reminder eligibility and deadline policy in `ReminderSchedulingRules`.
- Keep `UserNotifications` calls inside `ReminderScheduler`.
- Preserve completed-today suppression so reminders do not nag completed work.
- Preserve dedupe by clearing existing Owlory reminder requests before adding the current plan.
- Scheduling currently happens when app wiring calls `ReminderScheduler.reschedule`, including launch and foreground entry.
- Reminder copy for Today prompts should come from Today-owned prompt rules; reminder code may schedule and mirror those prompts but should not invent alternate product wording or timing.
- Reminder notification specs should include app-runtime deep-link metadata for the represented prompt or completion key so notification taps and mirrored widget entries can return to the associated Owlory item.

## Verify

- `make test-domain DOMAIN=reminders`
- `xcodebuild test -project Owlory.xcodeproj -scheme Owlory -destination "$OWLORY_XCODE_DESTINATION" -only-testing:OwloryCoreTests/CompletionTimePredictorTests -only-testing:OwloryCoreTests/ReminderSchedulingRulesTests`
