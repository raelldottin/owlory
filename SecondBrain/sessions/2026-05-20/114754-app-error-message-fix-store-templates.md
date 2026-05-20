# app-error-message-fix-store-templates

## Prompt

> "start next slice" - execute the supervisor-selected slice after the error-message audit.

## What changed

Closed the eight audited store-template `lastError` findings F01 and F03-F09. These surfaces no longer interpolate `error.localizedDescription` into user-visible alert bodies.

Store routing:

- `TrainStore.persist` -> `train.error.session.save`
- `WriteStore.persist` -> `write.error.note.save`
- `HomeStore.persistRuns` -> `home.error.run.save`
- `HomeStore.persistTasks` -> `home.error.task.save`
- `HomeStore.persistProtocols` -> `home.error.protocol.save`
- `CareerStore.persist` -> `career.error.record.save`
- `TodayStore.loadRecentEntries` -> `today.error.history.load`
- `TodayStore.persistCurrentEntry` -> `today.error.entry.save`

Added the eight keys to all 19 `Localizable.strings` files. Non-English values are localized automated drafts, not English placeholders.

Updated all 18 non-English review return files with matching rows:

- `review_status`: `needs-layout-check`
- `reviewer`: `Codex automated draft (not native/fluent reviewer)`
- `native_review.accepted`: `false`
- `pending_native_review`: `true`

The prior project-owner-reported native/fluent review remains scoped to the 419 entries present before 2026-05-20; the 8 new rows per locale are explicit post-packet additions.

## Docs and Queue

`docs/workflows/content-standards.md` now says the five store-template surfaces are fixed and leaves only:

- `WriteStore` source-note-stage conversion message.
- `PatternStore` failure visibility/copy decision.

`automation/queue/slices.json` marks this slice done and expands `max_files_changed` from 30 to 50. The expansion is documented because the slice required 19 resource files plus 18 review files for parity and provenance.

## Validation

- `python3 automation/context/build_context.py --slice-id app-error-message-fix-store-templates` - passed.
- `python3 automation/supervisor/run_next.py --dry-run` - passed pre-implementation; selected this slice.
- `make architecture` - passed.
- `make localization-check` - passed (19 locales, 385 keys, 13 plural keys).
- `make automation-check` - passed (pyright 0 errors / 0 warnings; localization drift 0; 93 tests).
- `git diff --check` - passed.

## Not Claimed

- Native/fluent review for the eight new non-English strings.
- PatternStore failure visibility resolution.
- WriteStore stage-conversion message resolution.
- DesignSystem audio/voice accessibility error-label resolution.

## Next

Supervisor next eligible slice should be `app-error-message-fix-writestore-domain-message`.
