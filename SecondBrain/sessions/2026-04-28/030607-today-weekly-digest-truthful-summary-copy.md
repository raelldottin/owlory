# Today Weekly Digest Truthful Summary Copy

## Prompt

Fix the Today tab's Last Week collapsed digest copy so `0% done` does not represent both `0/3` and `0/0`, and so stale stored digests are not labeled `Last Week`.

## Interpretation

- The issue is not the completion-rate math; it is the presentation contract.
- `0% done` is only honest when there were planned Focus items.
- A digest with zero planned Focus items should not imply failure.
- `Last Week` should only describe the immediately previous Monday-Sunday digest window.

## Supervisor Slice

- Slice: `today-weekly-digest-truthful-summary-copy`
- Domain: `today`
- Required validations: `make architecture`, `make test-domain DOMAIN=patterns`, `git diff --check`
- Supervisor dry-run selected the slice and confirmed the allowed path boundary.

## Files Edited

- `automation/queue/slices.json`
- `automation/handoffs/20260428T070607Z-today-weekly-digest-truthful-summary-copy.json`
- `docs/product/domains/today.md`
- `owlory_xcode/Owlory/Core/Domain/WeeklyDigestCadenceRules.swift`
- `owlory_xcode/Owlory/Core/Domain/WeeklyDigestRules.swift`
- `owlory_xcode/Owlory/Features/Today/TodayView.swift`
- `owlory_xcode/OwloryCoreTests/WeeklyDigestCadenceRulesTests.swift`
- `owlory_xcode/OwloryCoreTests/WeeklyDigestRulesTests.swift`
- `SecondBrain/INDEX.md`
- `SecondBrain/sessions/2026-04-28/030607-today-weekly-digest-truthful-summary-copy.md`

## Outcome

- Added `WeeklyDigestRules.collapsedCompletionSummary(for:)`.
- Added `WeeklyDigestRules.relativeWeekLabel(for:now:calendar:)`.
- Added `WeeklyDigestCadenceRules.previousCompletedWeekWindow(for:calendar:)`.
- Updated Today's collapsed weekly digest row to show `0 of 3 done`, `No planned Focus items`, or `Most Recent Week` when appropriate.
- Documented the Today product contract for count-first digest summaries and truthful week labels.

## Validation

- `python3 automation/context/build_context.py --slice-id today-weekly-digest-truthful-summary-copy`: passed
- `python3 automation/supervisor/run_next.py --dry-run`: passed
- `make architecture`: passed
- `make test-domain DOMAIN=patterns`: passed
- `git diff --check`: passed

## Remaining Risk

- No manual simulator visual pass was performed for the collapsed weekly digest row.
