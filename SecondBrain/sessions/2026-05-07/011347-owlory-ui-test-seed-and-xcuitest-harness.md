# owlory-ui-test-seed-and-xcuitest-harness

## Summary

Added Owlory's first maintained XCUITest smoke lane. The slice wires a small `OwloryUITests` target into the Xcode project and shared scheme, adds a debug-only deterministic fresh-day launch seed, and exposes `make ui-smoke` as the repeatable validation path.

## What Changed

- Added `OwloryUITestSupport` for `--owlory-ui-testing` and `--owlory-ui-seed-fresh-day`.
- Skipped notification authorization prompts during UI test launches.
- Added stable accessibility identifiers for the Today fresh-day dashboard header and existing welcome copy.
- Added `OwloryUITests/OwloryUITests.swift` with one launch-surface smoke test.
- Added `make ui-smoke` with isolated DerivedData at `/tmp/owlory-ui-smoke-derived-data`.
- Updated UI testing and validation docs to reflect the new smoke lane without claiming broad regression coverage.
- Added architecture/review guardrails so UI tests stay project-wired and review preflight recommends `make ui-smoke`.

## Validation

Passed:

- `python3 automation/context/build_context.py --slice-id owlory-ui-test-seed-and-xcuitest-harness`
- `python3 automation/supervisor/run_next.py --dry-run`
- `xcodebuild -list -project owlory_xcode/Owlory.xcodeproj`
- `make architecture`
- `make ui-smoke`
- `make automation-check`
- `make review-preflight`
- `make test-domain DOMAIN=runtime`
- `make build-provenance`
- `make test-domain DOMAIN=today`
- `git diff --check`

Notes:

- The first `make ui-smoke` run failed because the initial test expected the old welcome surface. Inspection showed a fresh local store creates Today's dashboard, so the seed/test/docs were corrected and the smoke passed.
- A concurrent `make test-domain DOMAIN=today` run failed with an Xcode build database lock because `DOMAIN=runtime` was using the same `/tmp/owlory-validate-xcode` path. The Today command passed when rerun sequentially.

## Proof

Proof level: `running-app-smoke`.

This proves the app builds, installs, launches under XCUITest, applies the deterministic fresh-day seed, and renders the Today dashboard surface with stable accessibility identifiers.

Not claimed:

- broad UI regression coverage
- multi-screen flow verification
- screenshot-verified proof
- device proof
- TestFlight proof

## Remaining Risk

The seed path intentionally covers a fresh-day dashboard only. Future UI proof flows should add focused fixture seeding for their records instead of overloading this smoke test.

## Next Slice

`owlory-ui-test-fixture-seeder-batch-2`: add one richer deterministic fixture plus one focused XCUITest flow if Owlory needs repeatable multi-screen proof.
