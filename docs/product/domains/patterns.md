# Patterns Domain

## Owns

- Completion-rate patterns.
- Carry-forward/stale-item pattern detection.
- Domain balance and domain-nudge projection.
- Readiness-to-outcome analysis.
- Writing velocity.
- Training consistency.
- Weekly digest generation and cadence policy.

## Does Not Own

- Direct UI rendering.
- Persistence mechanics beyond `PatternStore` orchestration.
- Reminder notification delivery.

## Depends On

- `PatternEngine`, `PatternNudgeRules`, `ReadinessOutcomeRules`, `CalibrationRules`, `WeeklyDigestRules`, `WeeklyDigestCadenceRules`.
- `PatternStore` for load/refresh/save orchestration.

## Exposes

- `PatternSnapshot`.
- `CalibrationRules.Calibration`.
- `WeeklyDigest`.

## Change Safely

- Keep computations pure and deterministic.
- Add tests for new pattern invariants.
- Keep generated insights factual and based on observed data.
- Keep stale-item detection in `PatternEngine.computeCarryForward`: stalled items require the same title and domain to appear as carried across 3+ consecutive calendar dates.
- Missing calendar dates break a stale-item streak, and same-day duplicate entries do not inflate the streak.
- Keep stale-item alerts and domain-nudge text in `PatternNudgeRules`.
- Generic domain-balance nudges must not surface Write as "quiet." Domain balance is based on Today Focus allocation, not Write note creation cadence.
- Generic domain-balance copy must name Focus explicitly, such as "Career hasn't shown up in Focus lately." Do not use broad activity language like "quiet lately" for a Focus-allocation signal.
- Write-specific nudges should come from `CalibrationRules.writingPipelineNudge`, which is backed by capture pipeline state.
- Keep readiness-to-outcome policy in `ReadinessOutcomeRules`: readiness is the average of energy, mood, and sleep quality; low days are `<= 2.0`, high days are `>= 4.0`, missing and middle-readiness days do not become outcome samples, and only `.done` focus items count as completed outcomes.
- Keep the minimum sample gate for surfacing readiness/outcome snapshots in `ReadinessOutcomeRules.minimumSnapshotSampleCount`.
- Keep `CalibrationRules` as the Today-facing aggregator that combines readiness, stale alerts, domain nudges, writing nudges, and training summaries.
- Keep weekly digest cadence in `WeeklyDigestCadenceRules`: Monday-only generation, previous completed Mon-Sun window selection, and duplicate suppression by normalized week start.
- Keep weekly digest output generation and digest date label helpers in `WeeklyDigestRules`; callers must pass the same explicit calendar used for Pattern snapshots so stale counts, streaks, highlight day names, and week-range labels use the same boundary and time-zone semantics.
- Weekly digest completion totals include Today Focus items and timestamped completed Home protocol steps inside the digest window. Pending protocol steps, skipped protocol steps, and completed steps without a completion timestamp do not change the weekly digest completion totals.
- Keep repository loading, digest persistence, and latest-digest publishing in `PatternStore`.

## Verify

- `make test-domain DOMAIN=patterns`
- `xcodebuild test -project Owlory.xcodeproj -scheme Owlory -destination "$OWLORY_XCODE_DESTINATION" -only-testing:OwloryCoreTests/PatternEngineTests -only-testing:OwloryCoreTests/PatternNudgeRulesTests -only-testing:OwloryCoreTests/ReadinessOutcomeRulesTests -only-testing:OwloryCoreTests/WeeklyDigestRulesTests -only-testing:OwloryCoreTests/WeeklyDigestCadenceRulesTests`
