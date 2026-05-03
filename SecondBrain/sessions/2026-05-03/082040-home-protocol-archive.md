# home-protocol-archive

## Summary

Added archive/restore state for Home protocol templates. Archived templates remain persisted with their steps, schedule metadata, origin, active runs, and run history, but are hidden from the active protocol list and blocked from starting new runs.

## Assessment

- `HouseholdProtocol` had no archive flag; deleting was the only built-in way to remove a template from the visible list.
- `HomeStore` already owned protocol template persistence and run orchestration, so archive toggling and new-run rejection fit there.
- `HomeView` owned the visible active protocol list, so the UI change stayed narrow: active templates stay in the Protocols section, archived templates appear in an Archived Protocols restore section.
- Schedule notification planning had already landed and consumed all protocols, so runtime wiring now passes `activeProtocols` to avoid archived-template notification candidates.

## Changed Files

- `owlory_xcode/Owlory/Core/Domain/DomainModels.swift`
- `owlory_xcode/Owlory/Core/Application/HomeStore.swift`
- `owlory_xcode/Owlory/Features/Home/HomeView.swift`
- `owlory_xcode/Owlory/RootTabView.swift`
- `owlory_xcode/OwloryCoreTests/HomeStoreTests.swift`
- `docs/product/domains/home.md`
- `automation/queue/slices.json`
- `automation/handoffs/20260503T122040Z-home-protocol-archive.json`

## Validation

- `python3 automation/context/build_context.py --slice-id home-protocol-archive`
- `python3 automation/supervisor/run_next.py --dry-run`
- `make architecture`
- `make test-domain DOMAIN=home`
- `make automation-check`
- `git diff --check`

## Residual Risk

No running-app, flow, screenshot, device, or TestFlight proof was captured. Notification exclusion is wired through `RootTabView` and active protocol filtering, but this slice does not add a notification-specific archived-template test.

## Next

`home-protocol-step-revert` is the adjacent queued Home lifecycle slice.
