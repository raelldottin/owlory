# train-completed-sessions-history

## Prompt

Completed items in Train do not automatically go into History.

## Interpretation

- `TrainStore.todaySessions` includes all sessions dated today, which is useful for Today-domain summaries.
- The Train tab also uses `todaySessions` for its Today section, so completed sessions remain visually in Today after saving.
- The fix should add Train-owned projections for active Today versus History without changing Today-domain semantics.

## Plan

1. Register and dry-run the supervisor slice.
2. Add tested TrainStore projections for active planned sessions and history sessions.
3. Update TrainView to use those projections.
4. Update the Train domain contract and handoff.
5. Validate with architecture, Train domain tests, and diff hygiene.

## Files

- To inspect/edit: `TrainStore.swift`, `TrainView.swift`, `TrainStoreTests.swift`, Train domain docs, queue/handoff, and this SecondBrain entry.

## Validation

- `python3 automation/context/build_context.py --slice-id train-completed-sessions-history`: passed.
- `python3 automation/supervisor/run_next.py --dry-run`: passed; selected this slice.
- `make architecture`: passed.
- `make test-domain DOMAIN=train`: passed.
- `git diff --check`: passed.
- `make automation-check`: passed as an extra queue/handoff sanity check.

## Outcome

- Added `activeTodaySessions` for Train's active Today section.
- Added `historySessions` for resolved sessions and prior-day sessions.
- Updated TrainView so completed, modified, and skipped sessions leave the Today section and appear in History immediately.
- Kept `todaySessions` unchanged for Today-domain summaries and counts.
- Added TrainStore tests for active Today filtering, resolved same-day history, past history, and the completed-session move.
