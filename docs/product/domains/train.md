# Train Domain

## Owns

- Training sessions.
- Session status updates: planned, completed, modified, skipped.
- Recurring training session rollover.
- Training reflections and voice transcription fallback.

## Does Not Own

- Daily focus suggestion ranking.
- Global reminder scheduling.
- Weekly digest generation.

## Depends On

- `RecurrenceRules` for rollover decisions.
- `RecurringRolloverPlanner` for load-time rollover orchestration and trace metadata.
- `CompletionHistoryStore` for completion-time telemetry.
- `ItemListRepository<TrainingSession>` for persistence.

## Exposes

- `TrainStore`.
- `TrainingSession` and `TrainingStatus`.

## Training Rollover Contract

Implementation status: `Implemented` for stale planned-session auto-skip and recurring planned-session rollover.
Proof level: Train domain tests and the common `make fast` slice cover recurrence rules and rollover orchestration.
Missing/deferred: Future affect/check-in relationship design remains `Contract only` until a Train-owned rule and validation path are defined.

- A planned session that survives into the next calendar day auto-skips on the next load/foreground rollover pass.
- Recurring sessions may spawn the next planned instance for the new day after stale sessions are resolved.
- Today may present Train work as actionable only from planned sessions for the current day.

## Train History Projection Contract

Implementation status: `Implemented`.
Proof level: Train domain tests cover the active Today and History projections; `make ui-regression` includes `TrainRegression`, which seeds one planned session, completes it through the Train tab, and verifies it moves from active Today into History.
Missing/deferred: No screenshot, device, or TestFlight proof exists for the Train section transition.

- `todaySessions` keeps all sessions dated today for cross-domain summaries and Today counts.
- `activeTodaySessions` is the Train tab's active Today surface and includes only planned sessions dated today.
- `historySessions` includes resolved sessions (`completed`, `modified`, or `skipped`) immediately, including sessions resolved today, plus prior-day sessions.
- Saving a Train session as completed, modified, or skipped should move it out of the Train tab's Today section and into History without requiring reload, rollover, or a separate archive action.

## Change Safely

- Keep recurrence math and dedupe policy in `RecurrenceRules`.
- Keep stale planned-session auto-skip and recurring spawn policy in rollover/recurrence rules.
- Keep Train tab display projections in `TrainStore` so Today summary semantics and Train UI semantics do not fight over one collection.
- Keep load-time session rollover in `RecurringRolloverPlanner`; `TrainStore` should only load, apply the planner, persist if changed, and emit the trace.
- Training rollover dedupes by same planned activity on the current calendar day.
- A planned session that survives into the next calendar day auto-skips on the next load/foreground rollover pass; recurring sessions may then spawn the next planned instance for the new day.
- Today may present Train work as actionable only from planned sessions for the current day. Linked carried Focus rows that point at skipped, completed, modified, missing, or prior-day sessions should not imply the session itself carried forward.
- Keep persistence behind `ItemListRepository`.
- Keep speech/audio handling in infrastructure and DesignSystem controls.
- Keep voice-to-text field routing in `VoiceTranscriptionRoutingRules`; `TrainStore` only applies the reflection fallback before persistence.

## Verify

- `make test-domain DOMAIN=train`
- `make test-domain DOMAIN=voice`
- `xcodebuild test -project Owlory.xcodeproj -scheme Owlory -destination "$OWLORY_XCODE_DESTINATION" -only-testing:OwloryCoreTests/TrainStoreTests -only-testing:OwloryCoreTests/RecurrenceRulesTests -only-testing:OwloryCoreTests/RecurringRolloverPlannerTests`
