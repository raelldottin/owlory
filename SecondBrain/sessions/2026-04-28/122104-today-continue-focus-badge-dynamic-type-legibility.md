# Today Continue Focus Badge Dynamic Type Legibility

## Prompt

Run a simulator visual pass for the Today Focus/Continue contract.

## Interpretation

- The current active Today contract is that Focus work lives in Continue, not in a standalone Focus section.
- A simulator pass with larger Dynamic Type showed the redundant trailing `Focus` pill crowding Continue rows.
- The subtitle already presents the row as `Domain · Focus`, so the trailing pill was not needed for truthfulness.

## Supervisor Slice

- Slice: `today-continue-focus-badge-dynamic-type-legibility`
- Domain: `today`
- Required validations: `make architecture`, `make test-domain DOMAIN=today`, `git diff --check`
- Supervisor dry-run selected this slice and confirmed the allowed path boundary.

## Files Edited

- `automation/queue/slices.json`
- `automation/handoffs/20260428T122104Z-today-continue-focus-badge-dynamic-type-legibility.json`
- `owlory_xcode/Owlory/Features/Today/TodayView.swift`
- `SecondBrain/INDEX.md`
- `SecondBrain/sessions/2026-04-28/122104-today-continue-focus-badge-dynamic-type-legibility.md`

## Outcome

- Removed the redundant trailing `Focus` badge from Continue rows.
- Preserved the `Domain · Focus` subtitle.
- Preserved Focus-backed row accessibility actions for Done, Defer, and Drop.

## Validation

- `python3 automation/supervisor/run_next.py --dry-run`: passed
- `make architecture`: passed
- `make test-domain DOMAIN=today`: passed
- `git diff --check`: passed
- iPhone 16 simulator visual pass with seeded Focus data: confirmed no standalone Focus section, Focus rows appear under Continue, and the Done accessibility action removes the completed Focus row from Continue.

## Remaining Risk

- This was a simulator-local visual pass, not an automated screenshot test.
- Continue still relies on row swipe/accessibility actions for Focus status changes rather than an always-visible Done button.
