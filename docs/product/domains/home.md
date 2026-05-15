# Home Domain

## Owns

- Home tasks.
- Recurring home task reset.
- Household protocols.
- Protocol runs and step lifecycle.
- Protocol template archive/restore state.

## Does Not Own

- Notification delivery. Home provides protocol schedule signals to `ProtocolScheduleNotificationRules`; the reminders domain owns converting those signals into local notifications through `ReminderScheduler`.
- Training session rollover.
- Today Continue ranking, except through exposed active tasks and runs.

## Depends On

- `ProtocolLifecycleRules` for protocol start/resume, step resolution, terminal state, and run construction policy.
- `ProtocolScheduleRules` for protocol template schedule-window anchoring, normalization, and semantic schedule status.
- `RecurrenceRules` for recurring task reset.
- `RecurringRolloverPlanner` for load-time recurring task orchestration and trace metadata.
- `CompletionHistoryStore` for completed recurring task and protocol run history.
- `ItemListRepository` for tasks, protocols, and runs.

## Exposes

- `HomeStore`.
- `HomeTask`, `HouseholdProtocol`, `HouseholdProtocolSchedule`, `ProtocolRun`.

## Task Promotion Contract

Implementation status: `Implemented` for Write-note to Home-task promotion and source-note route-back.
Proof level: Home domain tests cover task creation, typed origin metadata, duplicate prevention, legacy decode compatibility, and source-note routing state. App wiring routes available source notes through the existing Write note highlight/detail path.
Missing/deferred: Screenshot/UI regression proof is not present.

- A Write note promoted to a task becomes a Home-owned `HomeTask`.
- The original `WritingNote` remains Write-owned source context; Home must not delete, archive, or mutate it during task creation.
- Promoted tasks store typed source metadata pointing back to the Write note.
- Repeating task promotion for the same Write note is idempotent by rejection; do not silently create duplicate tasks with the same Write-note origin.
- The task keeps its own title and notes so it remains readable even if the source note is later archived or deleted.
- Home owns completion, skipping, recurrence, editing, and deletion after promotion.
- Home task detail shows `View source note` for promoted tasks whose source `WritingNote` still exists.
- Write note detail may show that a Home task already exists for the note and may route to the task through the existing Home task highlight path.
- If the source note is missing or deleted, Home task detail should degrade gracefully by showing that the source note is unavailable rather than offering a broken route.
- Tasks without Write-note origin metadata must not show a source-note route.

## Protocol Promotion Contract

Implementation status: `Implemented` for Write-note to Home-protocol draft/template promotion and source-note route-back.
Proof level: Home domain tests cover protocol creation, typed origin metadata, duplicate prevention, blank-title rejection, no active-run creation, and source-note routing state. Today domain tests cover that promoted protocol templates do not surface in Continue without an active run.
Missing/deferred: Screenshot/UI regression proof is not present.

- A Write note promoted to a protocol becomes a Home-owned `HouseholdProtocol` draft/template.
- The original `WritingNote` remains Write-owned source context; Home must not delete, archive, or mutate it during protocol creation.
- Promoted protocols store typed source metadata pointing back to the Write note.
- Repeating protocol promotion for the same Write note is idempotent by rejection; do not silently create duplicate protocols with the same Write-note origin.
- The protocol keeps its own title and steps so it remains readable even if the source note is later archived or deleted.
- Home owns protocol editing, deletion, and any future run lifecycle after promotion.
- Promoting a Write note to a protocol must not create an active `ProtocolRun`.
- A promoted protocol template without an active run must not appear in Today Continue.
- Home protocol detail shows `View source note` for promoted protocols whose source `WritingNote` still exists.
- Write note detail may show that a Home protocol draft/template already exists for the note, but protocol-template route-to-destination remains status-only until Home has explicit template highlighting.
- If the source note is missing or deleted, Home protocol detail should degrade gracefully by showing that the source note is unavailable rather than offering a broken route.
- Protocols without Write-note origin metadata must not show a source-note route.

## Protocol Run Contract

Implementation status: `Implemented` for the current active-run lifecycle, template preservation, run persistence, duplicate prevention, and Today projection rules.
Proof level: Home protocol lifecycle and Today projection rules have focused domain coverage. Lane 2 UI regression proof is queued for template archive/restore management only.
Missing/deferred: Home projects remain `Contract only`; protocol schedule windows currently affect Home template labels only.

- Protocols are reusable templates. A run must not mutate the template that created it.
- Archived protocol templates remain stored with their steps, origin, and schedule metadata. Archiving hides the template from the active protocol list; it does not delete the template or mutate run history.
- Archived protocol templates may not start new runs. If a run was already active before the template was archived, the primary resume path may continue that run until it reaches the normal completed or abandoned terminal state.
- Archived protocol templates do not produce protocol schedule notification candidates. App runtime wiring should use `HomeStore.activeProtocols` when handing templates to `ProtocolScheduleNotificationRules`.
- Protocol template archive/delete actions should be explicit template actions, not trailing swipes on the expanded protocol row. The active protocol row may expose a direct protocol-level archive button, and the edit sheet owns archive/restore/delete management. Template steps are currently plain strings with no per-step archive state; do not expose a step-looking swipe action that archives the whole template. A future per-step archive feature needs its own model slice.
- Protocol runs are execution snapshots. They remain active until every step is completed or skipped, or until the user explicitly abandons the run.
- Active runs may span reloads and calendar days. Do not auto-complete, auto-abandon, or recreate a run only because the day changed.
- Active protocol runs are first-class Home work. Today and Home summaries should surface them before standalone Home tasks when a run is in progress.
- Today may project an active protocol run in Continue, but that projection must not replace or duplicate the Home-owned run lifecycle by turning the run into persisted Today carry-forward state.
- A Home protocol template without an active run is not active work. Today should not show stale carried Focus rows for that template as if they were protocol work.
- When Today routes into an active protocol run, Home should present the active run directly rather than dropping the user at the reusable protocol template surface.
- Step resolution is reversible. A completed or skipped step can be returned to pending, clearing its completedAt metadata. Reverting a step that is already pending is a no-op. Reverting a resolved step in an abandoned run is a no-op.
- Reverting the last resolved step in a completed run reopens the run by clearing completedAt and returning status to active. Reverting a step in an active run leaves the run active. Reverting one step must not disturb other resolved steps.
- Progress counts completed and skipped steps as resolved. The next action should use the next pending step number, not the completed count.
- Weekly digest may count timestamped completed protocol steps as completed Home work, but it must not change protocol run status or treat skipped/pending steps as completed tasks.
- The primary protocol action should continue an existing active run. The explicit secondary action may still start a new run while that UI remains available.

## Protocol Schedule Windows

Implementation status: `Partially implemented` for template-owned schedule windows with Today, Weekend, This Week, and Custom ranges, plus run-aware stale/overdue treatment in Home.
Proof level: Home domain tests cover deterministic window anchoring, summary state, add/update persistence, legacy protocol decode compatibility, and run-aware schedule classification (`upcoming`, `active`, `satisfied`, `overdue`).
Missing/deferred: schedule windows still do not drive Today projection or admission. Today Continue admission for protocol templates remains unchanged: a template without an active run is not admitted regardless of schedule status.

- Protocol schedule windows are template metadata stored on `HouseholdProtocol`.
- Windows persist explicit start/end days plus the preset that created them.
- Window policy belongs in `ProtocolScheduleRules` with deterministic `Date` and `Calendar` inputs.
- Windows may affect labels, stale treatment, or overdue treatment only. A window ending must not auto-abandon or auto-complete a run.
- Starting, resuming, completing, or abandoning a run must not silently clear or rewrite the protocol template's schedule window.
- Editing a protocol may change the template window without mutating existing runs created from that template.
- Schedule classification is run-aware. `ProtocolScheduleRules.scheduleStatus(for:runs:now:calendar:)` returns one of `upcoming`, `active`, `satisfied`, or `overdue`. A passed window classifies as `satisfied` when at least one run for the same protocol was started on or after the window's start day, and as `overdue` only when no such run exists. Old runs from before the window do not satisfy a later schedule.
- HomeView protocol rows surface this classification through `HomeStore.scheduleSummary(for:)`; the returned summary is semantic schedule state only. Localized row/help text belongs to Home presentation formatting, so an `overdue` window shows the existing "window passed" copy in a warning treatment, while a `satisfied` schedule reuses the upcoming/active label without nagging the user.
- Schedule classification is Home schedule state only. It must not change Today Continue admission, must not auto-start, auto-complete, auto-abandon, or auto-admit a run, and must not be used as input to `TodayContinueSourceComposer`. A `satisfied` or `overdue` classification is informational about the template; the user may still start a fresh run, edit the schedule, or remove the schedule entirely.
- `ProtocolScheduleNotificationRules` converts schedule classification into notification plans (`windowOpening`, `overdue`). Home exposes protocols and runs so app wiring can produce those plans; Home does not import `UserNotifications` or own notification delivery. Starting a run during an active window suppresses pending overdue notifications through the next reschedule cycle.

## Future Projects

- Work intended to last weeks or months should become a Home project or recurring task instead of stretching one protocol run indefinitely.
- Future Home projects may contain tasks and protocol runs, but should be introduced as their own product model rather than hidden inside protocol lifecycle rules.

## Change Safely

- Keep recurrence reset policy in `RecurrenceRules`.
- Keep load-time task reset orchestration in `RecurringRolloverPlanner`; `HomeStore` should only load, apply the planner, persist if changed, and emit the trace.
- Home recurring tasks reset in place when completed or skipped and due; they do not create a second task instance.
- Task-row and protocol-step inline controls should preserve comfortable iPhone touch targets even when the visible affordance is icon-only.
- Task rows should keep edit/open separate from complete, skip, and audio controls; do not nest those controls inside a row-level edit button.
- Preserve day-boundary behavior by passing deterministic `Date` and `Calendar` in tests.
- Keep protocol lifecycle policy in `ProtocolLifecycleRules`; `HomeStore` should orchestrate repositories, clocks, generated IDs, and completion-history logging.
- Do not duplicate active protocol runs through the primary `continueOrStartRun` path; it must resume the existing active run.
- Preserve the explicit secondary "Start New Run" path while it remains visible in Home UI.
- Preserve archive semantics: archive/unarchive must toggle template visibility only, and archived templates must not start new runs or feed schedule notification planning.
- Terminal protocol runs must not be re-completed, re-abandoned, or logged to completion history more than once.
- Preserve protocol templates when runs mutate step state.

## Verify

- `make test-domain DOMAIN=home`
- `xcodebuild test -project Owlory.xcodeproj -scheme Owlory -destination "$OWLORY_XCODE_DESTINATION" -only-testing:OwloryCoreTests/HomeStoreTests -only-testing:OwloryCoreTests/ProtocolLifecycleRulesTests -only-testing:OwloryCoreTests/RecurrenceRulesTests -only-testing:OwloryCoreTests/RecurringRolloverPlannerTests`

Protocol lifecycle acceptance checks:

- A protocol template can be reused without being mutated by a run.
- A run started yesterday remains active today when steps are pending.
- Completing part of a weekend protocol today leaves remaining steps pending for tomorrow.
- A run completes only when every step is completed or skipped.
- Abandoning a run remains an explicit user action.
- Active Runs communicates the run age and next pending step.
- Protocol templates may show a persisted schedule window label without that label creating or mutating an active run.
