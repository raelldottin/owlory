# home-protocol-schedule-windows

## Prompt

Protocols - ability to schedule protocols

## Interpretation

- The existing Home protocol lifecycle is stable and should not be repurposed into a planning engine.
- The maintained Home contract already scoped future windows to labels, stale treatment, or overdue treatment only.
- The smallest safe slice is template-owned schedule metadata plus visible schedule labels, without auto-starting or auto-ending runs.

## Plan

1. Register the slice in `automation/queue/slices.json`.
2. Build bounded context and confirm scope with the supervisor dry-run.
3. Add a pure schedule-window rule for Today, Weekend, This Week, and Custom windows.
4. Persist schedule metadata on `HouseholdProtocol` and expose it in Home add/edit UI.
5. Add focused Home and schedule-rule tests.
6. Update maintained Home docs and roadmap status.

## Files Inspected

- `AGENTS.md`
- `docs/README.md`
- `docs/architecture/boundaries.md`
- `docs/product/domain-index.md`
- `docs/product/domains/home.md`
- `docs/product/domain-index.md`
- `docs/workflows/validation.md`
- `docs/workflows/second-brain.md`
- `docs/workflows/roadmap-status.md`
- `automation/README.md`
- `automation/queue/slices.json`
- `owlory_xcode/Owlory/Core/Domain/DomainModels.swift`
- `owlory_xcode/Owlory/Core/Domain/ProtocolLifecycleRules.swift`
- `owlory_xcode/Owlory/Core/Application/HomeStore.swift`
- `owlory_xcode/Owlory/Features/Home/HomeView.swift`
- `owlory_xcode/OwloryCoreTests/HomeStoreTests.swift`
- `owlory_xcode/OwloryCoreTests/ProtocolLifecycleRulesTests.swift`

## Validation

- `python3 automation/context/build_context.py --slice-id home-protocol-schedule-windows`
- `python3 automation/supervisor/run_next.py --dry-run`
- `make architecture`
- `make test-domain DOMAIN=home`
- `make test-domain DOMAIN=today`
- `make automation-check`
- `xcodebuild test -project owlory_xcode/Owlory.xcodeproj -scheme Owlory -destination "platform=iOS Simulator,name=iPhone 16,OS=26.3.1" -derivedDataPath /tmp/owlory-protocol-schedule-tests -only-testing:OwloryCoreTests/ProtocolScheduleRulesTests`
- `git diff --check`

## Outcome

- Added `HouseholdProtocolSchedule` and `ProtocolSchedulePreset` to the Home protocol template model.
- Added `ProtocolScheduleRules` as the pure Home rule for anchoring Today, Weekend, This Week, and Custom windows into explicit persisted day ranges and readable summary text.
- Home add/edit protocol sheets now let the user choose a window and store it without changing protocol run behavior.
- Home protocol rows now surface the persisted schedule summary.
- The standard Home validation path now includes `ProtocolScheduleRulesTests`, and the domain index now points agents at the new Home rule/test ownership.
- Home docs now say explicitly that schedule windows are template labels only and must not auto-complete or auto-abandon runs.
- The automation slice was completed and recorded with a JSON handoff.

## Notes

- The first supervisor dry-run was blocked by unrelated automation files outside the slice scope; a rerun after the repo state narrowed succeeded and selected `home-protocol-schedule-windows`.
- `make test-domain DOMAIN=today` remains the boundary guardrail proving scheduled protocol templates do not leak into Today Continue membership without an active run path change.
