# Today Linked Train Carry-Forward Guard

## Prompt

- User asked: "add a Today projection guard for carried training Focus items with linkedRecordID: only surface them if the linked Train session still represents valid actionable Train work; otherwise suppress or degrade the row to a pure Today Focus item with clearer copy."

## Scope

- Supervisor slice: `today-linked-train-carryforward-guard`
- Domain: Today Continue projection with Train lifecycle as the source contract.
- Goal: Prevent Today from implying that a linked Train session carried forward after Train has resolved or removed its actionable status.

## Findings

- Train already auto-skips stale planned sessions after the calendar day boundary.
- Today's direct Train source already uses only planned sessions from `trainStore.todaySessions`.
- The remaining mismatch was linked Train Focus carry-forward: a stale Focus item with `domain: .training` and `linkedRecordID` could still appear as `Train · Carried forward` even when the linked session was skipped, completed, modified, missing, or no longer today.

## Changes

- `TodayContinueSourceComposer` now builds an index of actionable training session IDs from planned due-today sessions.
- Linked Train carried-focus rows must match that actionable ID set before they can become Continue candidates.
- Unlinked Train focus rows still surface through the generic Today Focus carry-forward path because there is no Train source record to validate.
- Product docs now state that linked Train carried rows must not imply a skipped, resolved, missing, or prior-day session carried forward.
- Added composer tests for valid linked planned sessions and for skipped, completed, modified, and missing linked sessions.

## Validation

- `python3 automation/context/build_context.py --slice-id today-linked-train-carryforward-guard`
- `python3 automation/supervisor/run_next.py --dry-run`
- `make architecture`
- `make test-domain DOMAIN=today`
- `make test-domain DOMAIN=train`
- `git diff --check`

## Result

- Today now fails closed for invalid linked Train carry-forward rows at the projection boundary instead of showing them as actionable Train work.

## Remaining Risk

- Unlinked Train focus carry-forward rows remain visible as generic Today Focus carry-forward. That is intentional for this slice, but future copy could make the distinction clearer if users still read every Train-domain Focus item as a concrete Train session.
