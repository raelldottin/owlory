# home-protocol-step-revert (domain-tested)

Added a recovery affordance so completed or skipped protocol steps can be returned to pending without corrupting run lifecycle.

## What changed

### Domain layer (ProtocolLifecycleRules.swift)

- Added `StepUnresolutionResult` type with `run` and `didReopenRun` fields.
- Added `unresolveStep(in:stepID:)` pure rule:
  - Completed → pending: clears status and completedAt.
  - Skipped → pending: clears status and completedAt.
  - Pending → pending: no-op.
  - Abandoned run: no-op (out of scope to undo abandon).
  - Completed run with step reverted: reopens run (status → active, completedAt → nil).
  - Active run with step reverted: stays active.
  - Does not disturb other resolved steps.

### Application layer (HomeStore.swift)

- Added `revertStep(runID:stepID:)` wrapper that calls `unresolveStep`, guards against no-op, and persists.

### UI (HomeView.swift)

- Added trailing swipe action "Mark Pending" (arrow.uturn.backward.circle) on resolved step rows in the protocol run detail sheet. Only appears when step status is not pending.

### Contract (home.md)

- Protocol Run Contract updated: step resolution is reversible; reverting the last resolved step reopens a completed run; reverting a pending or abandoned-run step is a no-op; reverting one step does not disturb other resolved steps.

## Tests added

### ProtocolLifecycleRulesTests (7 new)

- `testUnresolvePendingStepIsNoOp`
- `testUnresolveCompletedStepRevertsToPending`
- `testUnresolveSkippedStepRevertsToPending`
- `testUnresolveLastResolvedStepReopensCompletedRun`
- `testUnresolveMidRunStepLeavesRunActive`
- `testUnresolveStepInAbandonedRunIsNoOp`
- `testUnresolveDoesNotDisturbOtherResolvedSteps`

### HomeStoreTests (3 new)

- `testRevertCompletedStepReturnsToPending`
- `testRevertLastResolvedStepReopensCompletedRun`
- `testRevertPendingStepIsNoOp`

## Proof level

`domain-tested`. All home domain tests pass (44+ tests). No running-app, screenshot, or device proof captured.

## Validation

- `make architecture` — passed
- `make test-domain DOMAIN=home` — passed (TEST SUCCEEDED)
- `make automation-check` — passed (36 tests)
- `git diff --check` — clean

## Out of scope

- Bulk revert across multiple steps
- Undo of explicit run abandon
- Audit/history log of revert events
- UI animation polish

## Next

Queue plays in priority order per supervisor selection.
