# Write Lightweight Source Note Conversion

## Prompt

Implement the Owlory mobile expectation that users can open a Write note, choose a simple source-note action, add lightweight source metadata, and save without losing the original note text.

## Interpretation

- The owner is the Write domain.
- Source-note creation should be a lightweight classification step, not a heavy filing ritual.
- The action belongs in note detail because staged Write rows should keep one primary action: open the note.
- The original note title and body must be preserved during conversion.

## Supervisor Slice

- Slice: `write-lightweight-source-note-conversion`
- Domain: `write`
- Required validations: `make architecture`, `make test-domain DOMAIN=write`, `git diff --check`
- Supervisor dry-run selected the slice and confirmed the allowed path boundary.

## Files Edited

- `automation/queue/slices.json`
- `automation/handoffs/20260426T074234Z-write-lightweight-source-note-conversion.json`
- `docs/product/domains/write.md`
- `owlory_xcode/Owlory/Core/Domain/DomainModels.swift`
- `owlory_xcode/Owlory/Core/Application/WriteStore.swift`
- `owlory_xcode/Owlory/Features/Write/WriteView.swift`
- `owlory_xcode/OwloryCoreTests/WriteStoreTests.swift`
- `SecondBrain/INDEX.md`
- `SecondBrain/sessions/2026-04-26/034234-write-lightweight-source-note-conversion.md`

## Outcome

- Added `WritingSourceType` and `WritingSourceMetadata`.
- Added `sourceMetadata` to `WritingNote`.
- Added `WriteStore.turnIntoSourceNote(id:metadata:)`, which preserves title/body and uses existing stage-transition rules.
- Added a note-detail `Turn into Source Note` menu action for eligible notes.
- Added a compact source metadata sheet with source type, title, creator, URL, date, citation, and quote fields.
- The source sheet prefills the source title from the note title and the URL from note text when possible.
- Documented the Write contract that source-note creation is lightweight, optional, and safe.

## Validation

- `python3 automation/context/build_context.py --slice-id write-lightweight-source-note-conversion`: passed
- `python3 automation/supervisor/run_next.py --dry-run`: passed
- `make architecture`: passed
- `make test-domain DOMAIN=write`: passed
- `git diff --check`: passed

## Remaining Risk

- No manual simulator pass was performed for the new note-detail bottom sheet interaction.
