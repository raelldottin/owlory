# Runtime Observability

Owlory currently exposes runtime behavior through several lightweight paths.

## Build Identity

`BuildInfo` reads stamped bundle metadata:

- marketing version
- Xcode build number
- short and full Git commit
- branch and tag/describe output
- build date and configuration
- build-number source

Use the Build Info sheet when reproducing a TestFlight issue. The rollback line gives the exact `git checkout` reference.

Use `make build-provenance` to print the local Xcode version/build and Git rollback identity. To compare a local checkout against a TestFlight build, copy the build number and Git commit from the Build Info sheet and run:

```bash
./Tools/verify-build-provenance.sh --expected-build <testflight-build> --expected-commit <build-info-git-commit>
```

Keep build-provenance checks in workflow tooling. Runtime `BuildInfo` should keep reading stamped bundle metadata and should not shell out or inspect the repository.

## Performance Telemetry

`PerformanceTelemetry` wraps important operations such as pattern refresh, Continue derivation, and build startup logging. Add measurements when a runtime path is important enough that support or performance work will need to explain it later.

Use [Performance Observability](../workflows/performance-observability.md) before adding new MetricKit, OSLog, signpost, Instruments, or performance-gate behavior. That workflow owns tool selection, privacy rules, device profiling, and performance-claim standards.

## MetricKit Subscriber

`MetricKitTelemetrySubscriber` is owned by `OwloryApp` for the app process lifetime. On iOS it registers with MetricKit and logs redacted metric/diagnostic payload counts through `PerformanceTelemetry`; unsupported platforms use a no-op implementation.

Keep MetricKit handling app-owned and low-cardinality. Do not move MetricKit registration into a view or use payload receipt as real-time UI state.

## Continue Pipeline Trace

`TodayContinuationRules` emits step-level Continue signposts for compose, assemble, and rank, then logs one `continue.pipeline` notice through `PerformanceTelemetry`.

`ContinuePipelineTrace` is the testable diagnostic value for that notice. It records per-source candidate counts, admission rejections, cap rejections, urgency-scored item IDs, pre-ranking IDs, ranked IDs, and final emitted count. Keep this trace in `Core/Application`; domain policies should stay deterministic and telemetry-free.

Verify trace behavior with `OwloryCoreTests/ContinuePipelineTraceTests` or `make test-domain DOMAIN=today`.

## Recurring Rollover Trace

`TrainStore` and `HomeStore` apply load-time recurring rollover through `RecurringRolloverPlanner`, then emit one `recurrence.rollover` notice through `PerformanceTelemetry`.

`RecurringRolloverTrace` records the rollover scope, evaluated count, created count, reset count, skipped counts by reason, deduped count, and changed item IDs. Keep the trace and planner in `Core/Application`; `RecurrenceRules` owns the pure policy and duplicate-prevention decisions.

Verify rollover diagnostics with `OwloryCoreTests/RecurringRolloverPlannerTests`, `make test-domain DOMAIN=train`, or `make test-domain DOMAIN=home`.

## Reminder Schedule Trace

`ReminderScheduler` applies `ReminderSchedulingRules` before touching `UserNotifications`, then emits one `reminder.schedule` notice through `PerformanceTelemetry`.

`ReminderScheduleTrace` records prediction candidate count, successfully scheduled count, completed-today suppression count, deadline-passed suppression count, canceled pending request count, and scheduling failure count. Keep this trace in `Core/Application`; `ReminderSchedulingRules` owns deterministic eligibility and deadline policy.

Verify reminder diagnostics with `OwloryCoreTests/ReminderSchedulingRulesTests` or `make test-domain DOMAIN=reminders`.

## Weekly Digest Timing

`PatternStore` wraps weekly digest refresh and loading in `PerformanceTelemetry.measure` under the `patterns` category. `WeeklyDigestCadenceRules` owns the deterministic Monday cadence, previous completed Mon-Sun window selection, and duplicate suppression by normalized week start; `PatternStore` owns repository reads, writes, and latest-digest publication.

Verify digest cadence with `OwloryCoreTests/WeeklyDigestCadenceRulesTests` or `make test-domain DOMAIN=patterns`.

## Local Runtime Coupling

- Audio and speech live in `Core/Infrastructure`; voice-to-text field routing lives in `Core/Domain/VoiceTranscriptionRoutingRules.swift`.
- Local notifications live behind `ReminderScheduler`.
- Widgets live in `owlory_xcode/OwloryWidgets/`. Future Live Activities should stay in runtime/widget code and remain reserved for active user-initiated sessions.

Keep framework-specific failures observable through `lastError`, telemetry, or explicit diagnostics. Do not swallow runtime failures silently when users can observe the broken state.

For ML, speech, or generated-output runtime posture, privacy, and fallback rules, use [ML Model Posture](ml-model-posture.md), [ML Privacy And Drafts](ml-privacy.md), and [ML QA](../workflows/ml-qa.md). Runtime telemetry may observe failures, but generated content must remain draft-only until the user confirms it.
