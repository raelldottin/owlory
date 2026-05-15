# home-protocol-archive-swipe-affordance

## Prompt

In Home, Protocol, swiping left on an item within a protocol exposed Archive, but the action archived the entire protocol. The expected behavior was not to make a protocol-step-looking swipe archive the whole protocol.

## Assessment

- Protocol template archive state exists on `HouseholdProtocol.isArchived`.
- Protocol template steps are stored as plain strings, not stable step records with identity/archive state.
- The expanded protocol `DisclosureGroup` owned trailing Archive/Delete swipe actions, so a swipe in the expanded protocol area could appear item-scoped while mutating the whole template.
- True per-step archive is a product/model change and was intentionally not implemented in this slice.

## What Changed

- Removed trailing Archive/Delete swipe actions from expanded active protocol rows in `HomeView`.
- Kept the leading Edit swipe action for opening the template editor.
- Kept template archive/restore in the Edit Protocol sheet.
- Added explicit template Delete to the Edit Protocol sheet so deleting the whole template is still available, but no longer hidden behind a step-looking row swipe.
- Documented the rule in the Home domain doc and roadmap status: template archive/delete actions are explicit template-level actions; per-step archive needs its own model slice.
- Added and completed the supervisor queue entry for `home-protocol-archive-swipe-affordance`.

## Validation

- `python3 automation/context/build_context.py --slice-id home-protocol-archive-swipe-affordance` — passed.
- `python3 automation/supervisor/run_next.py --dry-run` — initially blocked by unrelated untracked `browser-harness/`; after marking the slice done, returned `stop: no eligible queued slice found.`
- `python3 -m json.tool automation/queue/slices.json` — passed.
- `make architecture` — passed.
- `make test-domain DOMAIN=home` — TEST SUCCEEDED.
- `make automation-check` — 57 tests passed.
- `xcodebuild build -quiet -project owlory_xcode/Owlory.xcodeproj -scheme Owlory -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/owlory-home-protocol-archive-swipe-build CODE_SIGNING_ALLOWED=NO` — BUILD SUCCEEDED. Existing TodayView `onChange(of:perform:)` deprecation warning remains unrelated.
- `git diff --check` — clean.
- `git push origin main` — blocked by the repo pre-push provenance hook because pre-existing untracked `browser-harness/` keeps the worktree dirty. The directory was outside this slice and was not touched.

## Lane Boundary

`build-tested`. This preserves protocol lifecycle/schedule/run behavior and only changes the Home presentation affordance. It is not running-app, screenshot, device, or TestFlight proof.

## Residual Risk

- Per-step archive remains unimplemented because template steps do not have a model identity/archive field.
- If per-step archive is desired, queue `home-protocol-step-archive-model-triage` or equivalent before changing persistence/UI behavior.
- Pre-existing untracked `browser-harness/` remains outside this slice and was not touched.
- Local commit exists; push is pending until `browser-harness/` is resolved or explicitly ignored by its owner.

## Notes For Next Slice

Clean stop is valid for actionable queue work. The only direct follow-up is a product decision: whether protocol template steps should become first-class archived/restorable records rather than plain strings.
