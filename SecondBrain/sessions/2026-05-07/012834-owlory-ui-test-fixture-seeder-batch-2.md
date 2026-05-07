# owlory-ui-test-fixture-seeder-batch-2

## Prompt

Resume from the clean Owlory checkpoint and continue the next UI harness slice. The bookmarked next slice was a deterministic fixture proving Today Continue shows one seeded item.

## Interpretation

Implement one small XCUITest fixture batch, not a broad UI regression suite. The slice should seed exactly one Continue-visible item, exercise the real Today Continue projection in the running simulator app, keep product behavior unchanged, and leave durable handoff evidence.

## Plan

1. Register `owlory-ui-test-fixture-seeder-batch-2` in `automation/queue/slices.json`.
2. Run the supervisor context and dry-run gates before product/harness edits.
3. Add a debug-only `--owlory-ui-seed-today-continue-item` launch argument.
4. Add stable Today Continue accessibility identifiers.
5. Extend the maintained XCUITest smoke class with one seeded Continue assertion.
6. Update UI testing docs and validation docs to describe the expanded smoke lane.
7. Run required validation and write handoff.

## Files Inspected

- `AGENTS.md`
- `docs/README.md`
- `docs/workflows/ui-testing-hygiene.md`
- `docs/workflows/validation.md`
- `docs/product/domain-index.md`
- `docs/architecture/boundaries.md`
- `docs/product/domains/today.md`
- `docs/workflows/second-brain.md`
- `Makefile`
- `owlory_xcode/Owlory/Core/Application/OwloryUITestSupport.swift`
- `owlory_xcode/Owlory/Features/Today/TodayView.swift`
- `owlory_xcode/OwloryUITests/OwloryUITests.swift`
- Today persistence and Continue composition files needed to confirm a planned current Focus item is the safest seed path.

## Files Changed

- `Makefile`
- `automation/queue/slices.json`
- `automation/handoffs/20260507T052349Z-owlory-ui-test-fixture-seeder-batch-2.json`
- `docs/workflows/ui-testing-hygiene.md`
- `docs/workflows/validation.md`
- `owlory_xcode/Owlory/Core/Application/OwloryUITestSupport.swift`
- `owlory_xcode/Owlory/Features/Today/TodayView.swift`
- `owlory_xcode/OwloryUITests/OwloryUITests.swift`
- `SecondBrain/INDEX.md`
- `SecondBrain/sessions/2026-05-07/012834-owlory-ui-test-fixture-seeder-batch-2.md`

## Outcome

Added a second debug-only UI seed path:

- `--owlory-ui-seed-today-continue-item` resets app-local Owlory/Trajectory data.
- The seed writes one current-day `DailyEntry` with one planned Home Focus item titled `Review seeded Continue item`.
- Today Continue renders that item through the existing current-Focus Continue source.

The XCUITest class now has:

- `testSeededTodayLaunchSurface`
- `testSeededTodayContinueItemAppears`

`make ui-smoke` now runs the maintained `OwloryUITests/OwloryUITests` class instead of one method.

## Validation

Passed:

- `python3 automation/context/build_context.py --slice-id owlory-ui-test-fixture-seeder-batch-2`
- `python3 automation/supervisor/run_next.py --dry-run`
- `make architecture`
- `make ui-smoke`
- `make test-domain DOMAIN=today`
- `make automation-check`
- `git diff --check`

Initial failure:

- The first context/dry-run attempt failed because I used invalid queue status `ready`; the queue schema only allows `queued`, `in_progress`, `blocked`, `done`, and `failed`. I changed the new slice status to `queued` and reran successfully.

## Proof

Proof level: `running-app-smoke`.

The running-app proof is now XCUITest-backed for a deterministic Today Continue item. This does not claim screenshot-preserved proof, device proof, TestFlight proof, or coverage for all Continue sources.

## Remaining Risk

- This is still focused smoke coverage, not a broad UI regression suite.
- The seeded item covers current Focus in Continue only; other Continue sources remain unproved by XCUITest.
- No screenshot artifacts were preserved.
- Device and TestFlight behavior remain unverified.

## Next Slice

`owlory-ui-test-fixture-seeder-batch-3` only if another small fixture is valuable, such as a seeded Write note appearing in Write or a seeded Home task appearing in Home.
