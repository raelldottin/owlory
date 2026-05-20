# queue-home-today-cancel-followup

## Prompt

> "add honest scope limits to as a slice"

Refers to the scope limit recorded in `app-reminders-cancel-pending-on-item-completion` (commit `c41863a`): the TrainStore fix did NOT extend to HomeStore (tasks + protocol runs) or TodayStore (focus-item Done swipe). Those completion paths still rely on the bulk `reschedule()` rebuild and would show the same stale-notification bug if hit at the wrong time.

## What was done

Queue-only update. Appended one slice to `automation/queue/slices.json`. No source/test/doc/proof changes.

### Queued

| Slice ID | Pri | Depends on |
|---|---:|---|
| `app-reminders-cancel-pending-on-home-and-today-completion` | 30 | `app-reminders-cancel-pending-on-item-completion` |

### Slice scope captured in notes

Pattern-replication slice. Mirror the TrainStore changes from commit `c41863a` across:

1. **HomeStore task completion** — fire `onItemCompleted` with `CompletionTimePredictor.key(forHomeTask: task.title)`.
2. **HomeStore protocol-run completion** — fire `onItemCompleted` with `CompletionTimePredictor.key(forProtocolRun: run.protocolTitle)`.
3. **TodayStore focus-item Done swipe** — fire `onItemCompleted` with the per-source predictor key (forHomeTask / forProtocolRun / forTrainingSession depending on `FocusItem.source`).

Each path needs:
- New `onItemCompleted: ((String) -> Void)?` init param on the store.
- Fire-on-completion hook in the completion method.
- A domain regression test that fails on main before the init signature change.
- `OwloryApp.swift` wires the closure with the same `Task { @MainActor in scheduler.cancelReminder(forKey: key) }` pattern.

Existing keying conventions to reuse:

| Source | Key API | Existing callsite |
|---|---|---|
| Home task | `CompletionTimePredictor.key(forHomeTask: title)` | `CompletionHistoryStore.swift:45` |
| Protocol run | `CompletionTimePredictor.key(forProtocolRun: protocolTitle)` | `CompletionHistoryStore.swift:67` |
| Focus item (home) | `CompletionTimePredictor.key(forHomeTask: item.title)` | `TodayContinueSourceComposer.swift:275, 395` |
| Focus item (protocol run) | `CompletionTimePredictor.key(forProtocolRun: run.protocolTitle)` | `TodayContinueSourceComposer.swift:259` |
| Focus item (training) | `CompletionTimePredictor.key(forTrainingSession: ...)` | `TodayContinueSourceComposer.swift:397` |

### Explicit non-scope reminders for the slice implementor

- Do NOT change `ReminderScheduler` — `cancelReminder(forKey:)` already removes both pending and delivered after commit `c41863a`.
- Do NOT modify the bulk `reschedule()` flow — keep belt-and-suspenders.
- Do NOT bundle this with translation or UI work.

## Validation

- `python3 -m json.tool automation/queue/slices.json` — valid.
- `make automation-check` — 93 tests pass (drift no-drift + 93 unittests OK).
- `python3 automation/supervisor/run_next.py --dry-run` — picks this new slice (pri 30, lowest among queued; Owlory's convention is lower pri = picked first).

## Lane Boundary

`doc-only`. Queue record + this session note. No source/test/doc/proof change.

## Not Claimed

- The HomeStore + TodayStore completion paths are fixed (they aren't; this slice queues the fix).
- The bug surfaces for Home / Today items in production (the TrainStore fix is the only confirmed user-reported case; the Home/Today paths are an inference from "same code shape, same vulnerability").

## Next slice

Supervisor's pick: `app-reminders-cancel-pending-on-home-and-today-completion` is now the lowest-priority queued slice (pri 30). Per Owlory's lower-pri-first convention, the supervisor will offer it on the next `start next slice`.
