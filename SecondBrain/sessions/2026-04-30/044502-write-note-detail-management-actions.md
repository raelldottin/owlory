# write-note-detail-management-actions

## Prompt

When editing a note, provide an option to delete or archive the note. If delete is not safe, archive-only is sufficient.

## Interpretation

- Write rows already expose swipe actions for Delete and Archive.
- The edit/detail sheet does not expose note-management actions, so users can miss them after opening a note.
- Hard delete already exists in `WriteStore` and is tested, but the detail UI should require explicit confirmation before deleting.

## Plan

1. Register and dry-run the supervisor slice.
2. Add Archive/Delete actions to the note detail options menu.
3. Confirm destructive deletion before removing the note.
4. Update Write docs and validation notes.
5. Validate with architecture, Write domain tests, and diff hygiene.

## Files

- To inspect/edit: `WriteView.swift`, `WriteStoreTests.swift`, Write domain docs, queue/handoff, and this SecondBrain entry.

## Validation

- `python3 automation/context/build_context.py --slice-id write-note-detail-management-actions`: passed.
- `python3 automation/supervisor/run_next.py --dry-run`: passed; selected this slice.
- `make architecture`: passed.
- `make test-domain DOMAIN=write`: passed.
- `make automation-check`: passed.
- `git diff --check`: passed.

## Outcome

- Added Archive Note and Delete Note to the Write note detail options menu.
- Archive saves current edits before transitioning the note to `archived`.
- Delete opens a destructive confirmation before removing the note.
- Updated the Write contract to require explicit cleanup actions from note detail.
