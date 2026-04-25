# Train Domain

## Owns

- Training sessions.
- Training-specific readiness signal and optional notes.
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

## Change Safely

- Keep recurrence math and dedupe policy in `RecurrenceRules`.
- Keep stale planned-session auto-skip and recurring spawn policy in rollover/recurrence rules.
- Keep load-time session rollover in `RecurringRolloverPlanner`; `TrainStore` should only load, apply the planner, persist if changed, and emit the trace.
- Training rollover dedupes by same planned activity on the current calendar day.
- A planned session that survives into the next calendar day auto-skips on the next load/foreground rollover pass; recurring sessions may then spawn the next planned instance for the new day.
- Keep persistence behind `ItemListRepository`.
- Keep speech/audio handling in infrastructure and DesignSystem controls.
- Keep voice-to-text field routing in `VoiceTranscriptionRoutingRules`; `TrainStore` only applies the reflection fallback before persistence.

## Verify

- `make test-domain DOMAIN=train`
- `make test-domain DOMAIN=voice`
- `xcodebuild test -project Owlory.xcodeproj -scheme Owlory -destination "$OWLORY_XCODE_DESTINATION" -only-testing:OwloryCoreTests/TrainStoreTests -only-testing:OwloryCoreTests/RecurrenceRulesTests -only-testing:OwloryCoreTests/RecurringRolloverPlannerTests`
