# write-promote-to-task

## Prompt

Implement the next Write promotion slice: a `WritingNote` can become a destination-owned task/action item while preserving the source note, typed origin metadata, duplicate behavior, route-back where supported, focused tests, and updated Write docs. Keep protocol promotion out of scope.

## Interpretation

- This is a narrow implementation slice after `write-promote-to-today`.
- Write remains capture-first; Home owns task lifecycle after promotion.
- Protocol promotion is explicitly deferred.

## Plan

1. Register and dry-run the supervisor slice.
2. Inspect Write and Home task ownership paths.
3. Add source-origin metadata to promoted Home tasks.
4. Expose a lightweight Write detail action for task promotion.
5. Update docs, handoff, and validation notes.

## Files

- Inspected: `docs/product/domains/write.md`, `docs/product/domains/home.md`, `HomeStore.swift`, `WriteView.swift`, `DomainModels.swift`, Home and Write tests.
- Edited: `DomainModels.swift`, `HomeStore.swift`, `WriteView.swift`, `RootTabView.swift`, `HomeStoreTests.swift`, Write/Home docs, roadmap status, queue, handoff, and this SecondBrain entry.

## Outcome

- Added typed origin metadata support for Home tasks by using a generic `OwloryItemOrigin` while preserving the existing `FocusItemOrigin` alias for Today.
- Added HomeStore promotion from `WritingNote` to Home-owned `HomeTask`.
- Promotion trims the task title, copies note body into task notes, preserves the source note, and rejects duplicate task promotion from the same note.
- Added `Turn into Task` to the Write note detail menu.
- Updated Write/Home contract status markers to make task promotion implementation-backed and keep protocol/permanent-note promotion deferred.

## Validation

- `python3 automation/context/build_context.py --slice-id write-promote-to-task` passed.
- `python3 automation/supervisor/run_next.py --dry-run` selected `write-promote-to-task`.
- `make architecture` passed.
- `make test-domain DOMAIN=home` passed.
- `make test-domain DOMAIN=write` passed.
- `make automation-check` passed.
- `git diff --check` passed.
