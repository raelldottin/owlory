# Today Focus Completion Contract Actions

## Prompt

Weekly digest showed `0 of 21 (0%)`, exposing that Today Focus planned items could accumulate without a reliable user-facing path to become done.

## Interpretation

- `21` likely represents 7 days times 3 Focus items.
- Weekly digest was truthful about stored Focus status, but not necessarily truthful about real completed work.
- Today already had a persisted `.done` mutation path, but the dashboard did not render current Focus Three as an actionable surface.
- Source-backed Focus items should become done when the linked source has unambiguous completion semantics.

## Supervisor Slice

- Slice: `today-focus-completion-contract-actions`
- Domain: `today`
- Required validations: `make architecture`, `make test-domain DOMAIN=today`, `git diff --check`
- Supervisor dry-run selected this slice and confirmed the allowed path boundary.

## Files Edited

- `automation/queue/slices.json`
- `automation/handoffs/20260428T075238Z-today-focus-completion-contract-actions.json`
- `docs/product/domains/today.md`
- `docs/product/domains/patterns.md`
- `owlory_xcode/Owlory/Core/Application/TodayStore.swift`
- `owlory_xcode/Owlory/Features/Today/TodayView.swift`
- `owlory_xcode/Owlory/RootTabView.swift`
- `owlory_xcode/OwloryCoreTests/TodayStoreTests.swift`
- `SecondBrain/INDEX.md`
- `SecondBrain/sessions/2026-04-28/075238-today-focus-completion-contract-actions.md`

## Outcome

- Added a current Today `Focus` section to the dashboard.
- Added visible per-item Done controls.
- Added swipe actions for Done, Defer, and Drop on Focus rows.
- Added linked source completion reconciliation in `TodayStore`.
- Root tab synchronization now marks planned linked Focus items done for completed or modified Train sessions, completed Home tasks, and published Write notes.
- Deferred and dropped Focus items are not overridden by automatic source completion.
- Documented the Focus completion contract in Today and Patterns docs.

## Validation

- `python3 automation/supervisor/run_next.py --dry-run`: passed
- `make architecture`: passed
- `make test-domain DOMAIN=today`: passed
- `git diff --check`: passed

## Remaining Risk

- No manual simulator visual pass was performed for the new Today Focus section.
- Existing persisted weekly digest artifacts older than the latest digest are still not bulk-regenerated.
