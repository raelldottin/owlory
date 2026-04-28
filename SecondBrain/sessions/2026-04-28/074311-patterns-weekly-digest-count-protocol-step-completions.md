# Patterns Weekly Digest Protocol Step Completion Counts

## Prompt

Active protocol item completions are not being considered as completed tasks in weekly digest.

## Interpretation

- Weekly digest completion was only derived from `DailyEntry.focusThree`.
- Home protocol steps live on `ProtocolRun.steps` in `Home/runs.json`.
- Completed protocol steps are real Home work and should count in weekly digest totals when they have a completion timestamp inside the digest week.
- Pending and skipped protocol steps should not be treated as completed tasks.

## Supervisor Slice

- Slice: `patterns-weekly-digest-count-protocol-step-completions`
- Domain: `patterns`
- Required validations: `make architecture`, `make test-domain DOMAIN=patterns`, `git diff --check`
- Supervisor dry-run selected this slice and confirmed the allowed path boundary.

## Files Edited

- `automation/queue/slices.json`
- `automation/handoffs/20260428T074311Z-patterns-weekly-digest-count-protocol-step-completions.json`
- `docs/product/domains/home.md`
- `docs/product/domains/patterns.md`
- `docs/product/domains/today.md`
- `owlory_xcode/Owlory/OwloryApp.swift`
- `owlory_xcode/Owlory/Core/Application/PatternStore.swift`
- `owlory_xcode/Owlory/Core/Domain/WeeklyDigestRules.swift`
- `owlory_xcode/OwloryCoreTests/WeeklyDigestRulesTests.swift`
- `SecondBrain/INDEX.md`
- `SecondBrain/sessions/2026-04-28/074311-patterns-weekly-digest-count-protocol-step-completions.md`

## Outcome

- Added `protocolRuns` input to `WeeklyDigestRules.generate`.
- Counted only `.completed` protocol steps whose `completedAt` lands inside the digest week.
- Added completed protocol steps to weekly digest `totalDone`, `totalPlanned`, and Home domain activity.
- Allowed a digest to be produced when protocol steps were completed even if there were no Today entries that week.
- Wired `PatternStore` to the Home run repository.
- Refreshed the latest persisted digest from source data when it is loaded, preserving the original `generatedAt` timestamp to avoid repeated churn.
- Documented the Patterns, Home, and Today contracts for protocol step completion counting.

## Validation

- `python3 automation/context/build_context.py --slice-id patterns-weekly-digest-count-protocol-step-completions`: passed
- `python3 automation/supervisor/run_next.py --dry-run`: passed
- `make architecture`: passed
- `make test-domain DOMAIN=patterns`: passed
- `git diff --check`: passed

## Remaining Risk

- Older non-latest persisted weekly digest rows are not bulk-backfilled by this slice.
- No manual simulator visual pass was performed for the Today weekly digest row after the count change.
