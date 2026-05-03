# home-protocol-schedule-notifications (implementation)

Added local notification support for Home protocol schedule windows. The implementation follows the declared-first pattern: pure domain planning in Core/Domain, delivery owned by the reminders domain through ReminderScheduler.

## Architecture

- `ProtocolScheduleNotificationRules` (Core/Domain) converts `ProtocolScheduleRules.ScheduleStatus` into notification plans with `windowOpening` and `overdue` kinds. No UserNotifications imports in Core/Domain.
- `ReminderSchedulingRules` gained `filteredProtocolSchedulePlans(_:now:)` for deadline filtering at the domain layer.
- `ReminderScheduler` converts plans into `UNNotificationRequest` alongside existing prediction and prompt notifications. Protocol schedule notifications use `owlory.protocol-schedule.{protocolID}.{kind}` identifiers, separate from the `owlory.reminder.*` prefix.
- `ReminderScheduleTrace` gained `protocolScheduleCount` for observability.
- `RootTabView.refreshRuntimeArtifacts()` produces protocol schedule plans from HomeStore protocols and runs and passes them to both `plannedNotifications()` and `reschedule()`. The `reminderRefreshKey` now includes protocol schedule metadata so schedule edits trigger a reschedule.

## Notification behavior

- **Upcoming window**: schedules both `windowOpening` (8 AM on start day) and `overdue` (8 AM day after end day).
- **Active window, no qualifying run**: schedules `overdue` only (window-opening fire date is past).
- **Active window with qualifying run**: no notifications (run started during window suppresses overdue).
- **Satisfied / overdue**: no notifications.
- Starting a run cancels stale notifications through the next reschedule cycle.

## Files changed

New: `ProtocolScheduleNotificationRules.swift`, `ProtocolScheduleNotificationRulesTests.swift`
Modified: `ReminderSchedulingRules.swift`, `ReminderScheduler.swift`, `ReminderScheduleTrace.swift`, `RootTabView.swift`, `ReminderSchedulingRulesTests.swift`, `project.pbxproj`, `validate.sh`, `home.md`, `reminders.md`, `observability.md`, `slices.json`, `CLAUDE.md` (pre-existing architecture lint fix)

## Proof level

`domain-tested`. 10 new tests in `ProtocolScheduleNotificationRulesTests` cover all schedule status paths, run filtering, identifier format, multi-protocol independence, and cross-protocol isolation. Existing tests updated for new trace field. `make fast`, `make test-domain DOMAIN=reminders`, `make test-domain DOMAIN=home`, `make architecture`, `make automation-check`, and `git diff --check` all pass.

Missing proof levels: `running-app-smoke`, `flow-verified`, `screenshot-verified`, `device-verified`, `testflight-verified`.

## Validation

- `make architecture` — passed
- `make test-domain DOMAIN=reminders` — passed (39 tests)
- `make test-domain DOMAIN=home` — passed
- `make automation-check` — passed (36 tests)
- `make fast` — passed
- `git diff --check` — clean

## Next

Queue plays in priority order: `train-row-status-pill-uniformity` (p=141) is next available slice with no unmet dependencies.
