# document-local-data-channel-boundaries

## Prompt

Document that Owlory local user data is scoped to the installed app identity, and that source/build mirroring does not imply TestFlight/dev data sharing.

## Interpretation

- This is a documentation/product-contract slice, not a storage implementation slice.
- The docs should distinguish build identity from local data-store identity.
- Intentional transfer between app channels remains future import/export, migration, app-group storage change, or sync work.

## Plan

1. Register and dry-run the supervisor slice.
2. Add an app-runtime local data channel contract.
3. Add observability/release notes that Build Info proves source/build identity, not data identity.
4. Validate with architecture and diff hygiene.

## Files

- To inspect/edit: `docs/product/domains/app-runtime.md`, `docs/runtime/observability.md`, `docs/workflows/release.md`, supervisor queue, handoff, and this SecondBrain entry.

## Validation

- `python3 automation/context/build_context.py --slice-id document-local-data-channel-boundaries`: passed.
- `python3 automation/supervisor/run_next.py --dry-run`: passed; selected this slice.
- `make architecture`: passed.
- `git diff --check`: passed.
- `make automation-check`: passed as an extra queue/handoff sanity check.

## Outcome

- Added a local data channel boundary contract to the app runtime domain.
- Clarified that Build Info proves source/build identity, not shared data-store identity.
- Added TestFlight diagnosis guidance for different-data reports.
- Preserved export/import, migration, app-group storage move, and sync as future explicit features.
