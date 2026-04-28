# Today Continue Owns Focus Surface

## Prompt

The standalone Focus section reappeared in the Today tab and competed with Continue. Product direction: all Focus behavior should live in Continue, and the codebase should guard against a separate Today Focus dashboard section returning.

## Interpretation

- The previous Focus-completion slice solved the missing Done path by adding a standalone section, but that violated the Today surface contract.
- Continue should be the active Today command surface for current Focus items, carried Focus items, and source-backed Focus work.
- Source-backed Focus work should avoid duplicate Continue rows when the source row is already actionable.

## Supervisor Slice

- Slice: `today-continue-owns-focus-surface`
- Domain: `today`
- Required validations: `make architecture`, `make test-domain DOMAIN=today`, `git diff --check`
- Supervisor dry-run selected this slice and confirmed the allowed path boundary.

## Files Edited

- `automation/queue/slices.json`
- `automation/handoffs/20260428T121301Z-today-continue-owns-focus-surface.json`
- `docs/product/domains/today.md`
- `docs/product/domains/patterns.md`
- `Tools/architecture-lint.sh`
- `owlory_xcode/Owlory/Core/Application/TodayContinuationRules.swift`
- `owlory_xcode/Owlory/Core/Application/TodayContinueSourceComposer.swift`
- `owlory_xcode/Owlory/Core/Domain/ContinueCandidateRules.swift`
- `owlory_xcode/Owlory/Features/Today/TodayView.swift`
- `owlory_xcode/OwloryCoreTests/ContinuePipelineTraceTests.swift`
- `owlory_xcode/OwloryCoreTests/TodayContinueSourceComposerTests.swift`
- `SecondBrain/INDEX.md`
- `SecondBrain/sessions/2026-04-28/121301-today-continue-owns-focus-surface.md`

## Outcome

- Removed the standalone active Today Focus section from `TodayView`.
- Added current Focus candidates to the Continue source composer.
- Added a `focusItem` Continue source for current Focus rows.
- Kept carried Focus rows as stale Continue rows with day badges.
- Suppressed duplicate current or carried Focus candidates when a linked Train, Home task, or Write source row already represents the actionable work.
- Added Focus-backed Continue swipe actions for Done, Defer, and Drop.
- Added a Focus badge to Focus-backed Continue rows.
- Added architecture lint to reject `focusPlanSection`, `focusPlanRow`, or the old standalone Focus footer copy if they return.
- Updated Today and Patterns docs to make Continue the only active Today surface for Focus work.

## Validation

- `python3 automation/supervisor/run_next.py --dry-run`: passed
- `make architecture`: passed
- `make test-domain DOMAIN=today`: passed
- `git diff --check`: passed

## Remaining Risk

- No manual simulator visual pass was performed for the updated Continue affordances.
- Historical Previous Days detail can still render recorded Focus entries; that is review history, not the active Today dashboard surface.
