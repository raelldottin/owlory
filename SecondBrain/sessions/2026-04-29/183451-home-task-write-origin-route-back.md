# home-task-write-origin-route-back

## Prompt

Implement a narrow route-back slice so a Home task created from a Write note exposes a visible way to return to the source Write note. Keep protocol promotion out of scope.

## Interpretation

- The task promotion data contract exists: promoted Home tasks carry typed Write-note origin metadata.
- This slice should make that source context user-visible from Home task detail.
- Missing or deleted source notes should not crash or present a broken route.

## Plan

1. Register and dry-run the supervisor slice.
2. Add a small routing helper for Home task source-note state.
3. Add a visible Home task detail affordance for available source notes.
4. Route selection through `RootTabView` to the Write note highlight/detail path.
5. Update docs, handoff, and validation notes.

## Files

- To inspect: `HomeStore.swift`, `HomeView.swift`, `RootTabView.swift`, `WriteView.swift`, Home/Write tests, Home/Write docs.
- To edit: bounded by the `home-task-write-origin-route-back` supervisor slice.

## Validation

- `python3 automation/context/build_context.py --slice-id home-task-write-origin-route-back`: passed.
- `python3 automation/supervisor/run_next.py --dry-run`: passed; selected this slice.
- `make architecture`: passed.
- `make test-domain DOMAIN=home`: passed.
- `make test-domain DOMAIN=write`: passed.
- `make automation-check`: passed.
- `git diff --check`: passed.

## Outcome

- Home task source routing now classifies Write-note origins as absent, available, or missing.
- Home task detail shows `View source note` only for tasks with available Write-note origins.
- Missing source notes degrade to a non-routable unavailable source message.
- Selecting the source route switches to Write and reuses the existing note highlight/detail path.
- Protocol promotion stayed out of scope.
