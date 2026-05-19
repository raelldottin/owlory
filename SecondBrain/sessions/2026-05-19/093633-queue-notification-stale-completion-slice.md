# queue-notification-stale-completion-slice

## Prompt

> "add slice for notifications out of sync with item state. an train item would be completed but a notification will appear stating the window has passed."

User-reported product bug.

## What was done

Queue-only update. Appended one bug-fix slice to `automation/queue/slices.json`. No source/test/doc/proof changes.

### Queued

| Slice ID | Pri | Domain |
|---|---:|---|
| `app-reminders-cancel-pending-on-item-completion` | 90 | reminders |

### Bug shape

- `Core/Application/ReminderScheduler.swift` already suppresses notifications at **schedule-time** via `completedKeys` (`completedSuppressedCount` / `deadlinePassedSuppressedCount` are tracked).
- The infrastructure to cancel pending notifications exists (`center.removePendingNotificationRequests(...)` at lines 81 / 147 / 243 / 251).
- The bug: a notification scheduled BEFORE the item is completed is not always cancelled when the item flips to done — at delivery time the user sees "the window has passed" for an item they already finished.

### Scope recorded in the slice notes

1. Add a domain regression test that schedules a window/deadline-passed notification, completes the item, and asserts no pending notification remains for that item. **Test must FAIL before the fix.**
2. Trace each completion-emitting path (`TrainStore`, `HomeStore`, `TodayStore` focus-item completion, plus indirect paths via `CompletionHistoryStore`).
3. Wire any path that doesn't already call `ReminderScheduler.cancelPending(forItem:)` (or equivalent) through that cancel call.
4. Preserve the existing `completedKeys` schedule-time suppression. Belt and suspenders, both correct.

### Why pri 90

Highest priority of any queued slice — user-reported, visible product defect. The supervisor's selection logic still picked another slice for the next-run dry-run, but `start next slice` invocations can pick this one explicitly when ready.

## Validation

- `python3 -m json.tool automation/queue/slices.json` — passed.
- `make architecture` — passed.
- `make automation-check` — 86 tests passed.
- `make pyright` — 0 errors / 0 warnings.

## Lane Boundary

`doc-only`. Queue record only. The fix is left to whoever implements the slice.

## Not Claimed

- The bug is reproduced (the slice scope includes writing the reproduction test as step 1).
- Every completion path is broken (some likely already cancel correctly; the implementation slice traces all of them and only patches the gaps).

## Residual Risk

- The bug repro might be hard to nail in a deterministic test if the timing of pending-notification cancellation is async. The implementation slice should ensure the assertion is observable via the mockable `OwloryNotificationCenter` (or equivalent) rather than the real `UNUserNotificationCenter`.
- If the bug only manifests for specific reminder kinds (window-passed vs window-opening vs deadline-passed), the test set should cover the affected kinds explicitly.

## Next slice

User's choice. Supervisor would pick this one if invoked next given its priority is highest among queued slices.
