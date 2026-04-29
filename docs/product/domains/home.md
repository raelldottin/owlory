# Home Domain

## Owns

- Home tasks.
- Recurring home task reset.
- Household protocols.
- Protocol runs and step lifecycle.

## Does Not Own

- Notification delivery.
- Training session rollover.
- Today Continue ranking, except through exposed active tasks and runs.

## Depends On

- `ProtocolLifecycleRules` for protocol start/resume, step resolution, terminal state, and run construction policy.
- `RecurrenceRules` for recurring task reset.
- `RecurringRolloverPlanner` for load-time recurring task orchestration and trace metadata.
- `CompletionHistoryStore` for completed recurring task and protocol run history.
- `ItemListRepository` for tasks, protocols, and runs.

## Exposes

- `HomeStore`.
- `HomeTask`, `HouseholdProtocol`, `ProtocolRun`.

## Task Promotion Contract

Implementation status: `Implemented` for Write-note to Home-task promotion.
Proof level: Home domain tests cover task creation, typed origin metadata, duplicate prevention, and legacy decode compatibility.
Missing/deferred: User-visible route-back UI from Home task detail to the source Write note is not implemented.

- A Write note promoted to a task becomes a Home-owned `HomeTask`.
- The original `WritingNote` remains Write-owned source context; Home must not delete, archive, or mutate it during task creation.
- Promoted tasks store typed source metadata pointing back to the Write note.
- Repeating task promotion for the same Write note is idempotent by rejection; do not silently create duplicate tasks with the same Write-note origin.
- The task keeps its own title and notes so it remains readable even if the source note is later archived or deleted.
- Home owns completion, skipping, recurrence, editing, and deletion after promotion.

## Protocol Run Contract

Implementation status: `Implemented` for the current active-run lifecycle, template preservation, run persistence, duplicate prevention, and Today projection rules.
Proof level: Home protocol lifecycle and Today projection rules have focused domain coverage.
Missing/deferred: Future run windows and Home projects remain `Contract only` until modeled and validated.

- Protocols are reusable templates. A run must not mutate the template that created it.
- Protocol runs are execution snapshots. They remain active until every step is completed or skipped, or until the user explicitly abandons the run.
- Active runs may span reloads and calendar days. Do not auto-complete, auto-abandon, or recreate a run only because the day changed.
- Active protocol runs are first-class Home work. Today and Home summaries should surface them before standalone Home tasks when a run is in progress.
- Today may project an active protocol run in Continue, but that projection must not replace or duplicate the Home-owned run lifecycle by turning the run into persisted Today carry-forward state.
- A Home protocol template without an active run is not active work. Today should not show stale carried Focus rows for that template as if they were protocol work.
- When Today routes into an active protocol run, Home should present the active run directly rather than dropping the user at the reusable protocol template surface.
- Progress counts completed and skipped steps as resolved. The next action should use the next pending step number, not the completed count.
- Weekly digest may count timestamped completed protocol steps as completed Home work, but it must not change protocol run status or treat skipped/pending steps as completed tasks.
- The primary protocol action should continue an existing active run. The explicit secondary action may still start a new run while that UI remains available.

## Future Windows And Projects

- Optional protocol run windows are not currently modeled. If added, start with Today, Weekend, This Week, and Custom.
- Windows should affect labels, stale treatment, or overdue treatment only. A window ending must not auto-abandon or auto-complete a run.
- Any window policy belongs in named rules with deterministic `Date` and `Calendar` inputs and Home validation coverage.
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
