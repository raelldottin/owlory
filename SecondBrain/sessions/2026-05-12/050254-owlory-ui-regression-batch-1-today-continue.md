# owlory-ui-regression-batch-1-today-continue

## Prompt

Promote Today Continue from smoke coverage to the first regression batch as defined by the regression suite plan. Build the regression batch as a separate XCUITest target or class so it does not run on every `make ui-smoke` invocation; add `make ui-regression` to invoke it. Cover all six Continue source visibility paths, the routing/action paths covered or classified by the deferred-coverage slice, and selected Continue Actions (Done plus the Defer/Drop paths the deferred-coverage slice classified as covered).

## Interpretation

The deliverable is the regression LANE (separate class + separate `make` target) more than the breadth of the first batch's coverage. The slice's listed scope (six visibility + four source-derived routes + three Focus actions) matches what the smoke already covers, so the first regression batch is structurally parallel rather than broader. Future slices grow the regression class with mixed-source edge cases, Continue cap behavior, and error paths.

The project's `project.pbxproj` is outside this slice's allowed_paths and uses traditional `PBXGroup` references rather than file-system synchronized folders, so a new standalone .swift file would not be picked up by the test target. The regression class is therefore added inside the existing `OwloryUITests.swift` file. The Makefile target uses `-only-testing:OwloryUITests/TodayContinueRegression`, which matches by class name and is independent of file path; a future slice that owns the pbxproj can split the class into its own file without changing the target.

## Files Edited

- `Makefile`
- `SecondBrain/INDEX.md`
- `SecondBrain/sessions/2026-05-12/050254-owlory-ui-regression-batch-1-today-continue.md`
- `automation/handoffs/20260512T050254Z-owlory-ui-regression-batch-1-today-continue.json`
- `automation/queue/slices.json`
- `docs/product/domains/today.md`
- `docs/workflows/roadmap-status.md`
- `docs/workflows/ui-regression-plan.md`
- `docs/workflows/ui-testing-hygiene.md`
- `docs/workflows/validation.md`
- `owlory_xcode/OwloryUITests/OwloryUITests.swift`

## Outcome

- New XCUITest class `TodayContinueRegression` added to `owlory_xcode/OwloryUITests/OwloryUITests.swift`. Covers six source visibility tests, four source-derived routing tests, and three Focus row action tests (Done, Defer, Drop).
- New Makefile target `make ui-regression` runs `xcodebuild test … -only-testing:OwloryUITests/TodayContinueRegression` against `/tmp/owlory-ui-regression-derived-data`. The existing `make ui-smoke` target is unchanged and continues to scope to `OwloryUITests/OwloryUITests`.
- `docs/workflows/ui-regression-plan.md` Lane 2 updated to mark `make ui-regression` as wired (no longer documented intent).
- `docs/workflows/ui-testing-hygiene.md` gains a Regression Batch section pointing at the new command and class.
- `docs/workflows/validation.md` lists `make ui-regression` in Common Commands.
- `docs/product/domains/today.md` records that the regression batch parallels the smoke matrix.
- `docs/workflows/roadmap-status.md` notes the wired regression target and the first batch's scope.

## Validation

Passed:

- `python3 automation/context/build_context.py --slice-id owlory-ui-regression-batch-1-today-continue`
- `python3 automation/supervisor/run_next.py --dry-run`
- `make architecture`
- `make ui-smoke`
- `make ui-regression`
- `make automation-check`
- `git diff --check`

## Proof And Risk

Proof level: `running-app-smoke`. The regression class boots the simulator, launches the seeded Owlory app, and exercises all listed assertions per the smoke's contract.

Initial regression coverage overlaps with the smoke set; the lane is the deliverable. The pbxproj is not in scope for this slice, so the regression class lives in the same file as the smoke class; a future slice can split it into its own file or its own test target without affecting the Makefile target. No screenshot, device, or TestFlight proof is claimed.
