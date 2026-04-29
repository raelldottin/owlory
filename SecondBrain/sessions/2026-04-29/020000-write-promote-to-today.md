# Write Promote To Today

- Date: 2026-04-29
- Slice: `write-promote-to-today`
- Prompt summary: implement only Write note promotion into Today-owned work while preserving the original note and origin route-back metadata.

## Interpretation

- Keep this slice limited to Write to Today.
- Do not add task, permanent-note, or protocol promotion.
- Today-owned work should be a writing-domain Focus item because Today has no standalone Focus section and Continue owns Focus-backed work.

## Files Touched

- `owlory_xcode/Owlory/Core/Domain/DomainModels.swift`
- `owlory_xcode/Owlory/Core/Domain/DailyPlanningRules.swift`
- `owlory_xcode/Owlory/Core/Domain/CarryForwardRules.swift`
- `owlory_xcode/Owlory/Core/Application/TodayStore.swift`
- `owlory_xcode/Owlory/Core/Application/TodayContinuationRules.swift`
- `owlory_xcode/Owlory/Core/Application/TodayContinueSourceComposer.swift`
- `owlory_xcode/Owlory/Core/Application/TodayContinueItemAssembler.swift`
- `owlory_xcode/Owlory/RootTabView.swift`
- `owlory_xcode/Owlory/Features/Write/WriteView.swift`
- `owlory_xcode/OwloryCoreTests/DailyPlanningRulesTests.swift`
- `owlory_xcode/OwloryCoreTests/CarryForwardRulesTests.swift`
- `owlory_xcode/OwloryCoreTests/TodayStoreTests.swift`
- `owlory_xcode/OwloryCoreTests/TodayContinueSourceComposerTests.swift`
- `owlory_xcode/OwloryCoreTests/TodayContinueItemAssemblerTests.swift`
- `docs/product/domains/write.md`
- `docs/product/domains/today.md`
- `docs/workflows/roadmap-status.md`
- `automation/queue/slices.json`

## Outcome

- Added typed `FocusItemOrigin` metadata for source-backed Today Focus items.
- `TodayStore.promoteWritingNoteToToday` creates a writing Focus item linked to the `WritingNote`, with `.writingNote` origin metadata and a promotion timestamp.
- Duplicate Write-to-Today promotion is blocked by source identity.
- Carry-forward preserves origin metadata so routed promoted work does not lose its source.
- Write note detail now exposes `Add to Today` in the note options menu when the note can be promoted.
- The original `WritingNote` is not deleted, archived, or consumed by promotion.

## Validation

- `python3 automation/context/build_context.py --slice-id write-promote-to-today` passed.
- `python3 automation/supervisor/run_next.py --dry-run` selected `write-promote-to-today`.
- `make architecture` passed.
- `make test-domain DOMAIN=write` passed after fixing test fixture setup.
- `make test-domain DOMAIN=today` passed.
- `make automation-check` passed.
- `git diff --check` passed.
