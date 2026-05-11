# owlory-ui-test-continue-routing-deferred-coverage

Closed the routing/action gaps the routing matrix triage deferred. Added accessibility identifiers and XCUITests for `.focusItem` Defer and Drop swipe actions; classified `.carriedFocusItem` routing and actions as `N/A by contract` because they flow through the same `onContinueItemSelected` tap handler and the same `focusItem(for:)` swipe-action helpers as `.focusItem`. Every row in the Continue UI Routing Coverage matrix now reads either `covered` or `N/A by contract` with a one-line reason.

## Implementation

`owlory_xcode/Owlory/Features/Today/TodayView.swift`:

- Added `.accessibilityIdentifier(continueActionAccessibilityIdentifier("defer", for: item))` to the Defer button in `continueStatusSwipeActions`.
- Added `.accessibilityIdentifier(continueActionAccessibilityIdentifier("drop", for: item))` to the Drop button in `continueStatusSwipeActions`.
- Both follow the existing `done` action's pattern. Identifiers are emitted via the helper that produces `today.continue.action.<action>.<sourceKind>.<UUID>`.

`owlory_xcode/OwloryUITests/OwloryUITests.swift`:

- `testSeededTodayContinueItemCanBeDeferred`: launches with `--owlory-ui-seed-today-continue-item`, locates the seeded Focus row, swipes left (trailing edge for status actions), asserts the `today.continue.action.defer.focusItem.<UUID>` button appears, taps it, and waits for the row to disappear (because `isCurrentFocusCandidate` only admits `.planned` items).
- `testSeededTodayContinueItemCanBeDropped`: identical shape but for the Drop action.

No new launch arguments, no new seed fixtures, no new product behavior.

## carriedFocusItem classification

The matrix decision is N/A by contract, not deferred. The rationale, recorded in today.md:

- Tap routing flows through `onContinueItemSelected(item)` in `RootTabView`, the same handler that switches `selectedTab = OwloryTab(domain: item.domain)` and sets `continueHighlightTarget = item.highlightTarget`. `.carriedFocusItem`'s `highlightTarget` is computed identically to `.focusItem`'s (origin-first, then linkedRecordID-by-domain). The same code path is already exercised by the four source-kind routing tests.
- Action affordances flow through `continuePrimarySwipeActions` and `continueStatusSwipeActions`. Both helpers call `focusItem(for: item)` which resolves the underlying `FocusItem` for both `.focusItem` and `.carriedFocusItem` sources. The Done/Defer/Drop tests on `.focusItem` transitively prove the same action code paths for `.carriedFocusItem`.
- Adding dedicated `.carriedFocusItem` XCUITests would duplicate already-exercised code without proving a separate contract; the matrix records that as N/A by contract with a one-line reason.

## Docs

- `docs/product/domains/today.md` — Continue UI Routing Coverage matrix updated. The `currentFocus / .focusItem` row now lists three action tests and explicitly marks tap-to-linked-source as N/A by contract. The `carriedForwardFocus / .carriedFocusItem` row now reads `N/A by contract` with the rationale above. Every other row already read `covered` or `None for routing` (= no remaining work).
- Added a short paragraph after the matrix documenting the swipe-action identifier convention (`today.continue.action.<action>.<sourceKind>.<UUID>`) and noting why Add-to-Focus has no UI smoke in this slice (no current seed produces a row where it is exposed).

## Validation

- `python3 automation/context/build_context.py --slice-id owlory-ui-test-continue-routing-deferred-coverage`
- `python3 automation/supervisor/run_next.py --dry-run`
- `make architecture`
- `make ui-smoke` (now 13 tests; both new Defer/Drop tests pass alongside the existing 11)
- `make test-domain DOMAIN=today`
- `make automation-check`
- `git diff --check`

## Boundary kept

- No carry-forward aging reset.
- No new product behavior.
- No screenshot/device/TestFlight claim.
- No Add-to-Focus UI smoke (out of scope; seed would need to expose a non-Focus-backed row).
- No tap-to-linked-source XCUITest on Focus rows (classified N/A; the source-kind routing tests already exercise the routing handler).

## Next

The routing matrix has no remaining `Needed proof` entries other than the deliberately-deferred lanes (screenshot/device/TestFlight/regression-suite). The next queued slice is `owlory-ui-test-screenshot-proof-pack`.
