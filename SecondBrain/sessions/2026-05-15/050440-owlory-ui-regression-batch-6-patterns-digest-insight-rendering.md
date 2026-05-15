# owlory-ui-regression-batch-6-patterns-digest-insight-rendering

## Prompt

Implement Lane 2 Batch 6: prove that the Patterns digest detail insight + best/hardest highlight sentences render correctly through the structured path introduced by `app-localization-digest-insight-summary-formatting`. The triage targeted `running-app-smoke` via XCUITest.

## Scope Reduction

The XCUITest path hit a runtime blocker (see "Why the XCUITest path was dropped" below). On the user's call, the slice's proof_level was dropped from `running-app-smoke` to `domain-tested`. The contract is now proved by unit tests in `OwloryCoreTests` against `WeeklyDigestPresentationFormatting`. The XCUITest scaffolding + seed-arg + navigation chase were reverted. The only inline product change that survived from the XCUITest attempt is a one-line `DigestListView` bug fix (see below).

## Files Edited

- `owlory_xcode/Owlory/Core/Application/WeeklyDigestPresentationFormatting.swift` — **new file**. Extracted verbatim from `DigestListView.swift` so the helper enum can compile into both the Owlory app target *and* the OwloryCoreTests target. `DigestListView.swift` imports SwiftUI and is not in the test target, which is why the helper had to move. No behavior change.
- `owlory_xcode/Owlory/Features/Today/DigestListView.swift` — removed the extracted enum, kept the row view + list view. Also routed `DigestRowView`'s key-insight `Text` through `WeeklyDigestPresentationFormatting.keyInsightLabel(_:)` so the row renders the localized sentence instead of the raw `InsightKind` rawValue (`"strongWeek"`, `"toughWeek"`, etc.). This bug was discovered during the running-app-smoke attempt; `DigestDetailView` already routed through `keyInsightLabel(_:)`, but `DigestRowView` did not.
- `owlory_xcode/OwloryCoreTests/WeeklyDigestPresentationFormattingTests.swift` — **new file**. Eight test methods covering: all eight `WeeklyDigest.InsightKind` rawValue → localized sentence resolutions for `keyInsightLabel(_:)`; the legacy-sentence and empty-string fallthrough behavior of `keyInsightLabel(_:)`; the structured `doneCount` + `plannedCount` path of `bestDayHighlightSummary(_:calendar:)` (asserts the localized "2 of 2 completed" substring) plus the legacy `summary` fallthrough when counts are absent; the low/moderate `readinessBand` paths of `hardestDayHighlightSummary(_:calendar:)` (asserts "low readiness" / "moderate readiness" substrings) plus the legacy `summary` fallthrough when the band is absent.
- `owlory_xcode/Owlory.xcodeproj/project.pbxproj` — registered `WeeklyDigestPresentationFormatting.swift` in the Owlory target and OwloryCoreTests target (A083 / B096 build files + A182 file reference); registered `WeeklyDigestPresentationFormattingTests.swift` in OwloryCoreTests (B095 / B140). Confirmed no ID collisions with existing entries.
- `Tools/validate.sh` — added `-only-testing:OwloryCoreTests/WeeklyDigestPresentationFormattingTests` to the `patterns` domain case so `make test-domain DOMAIN=patterns` exercises the new class alongside the other pattern-engine and digest tests.
- `automation/queue/slices.json` — slice `owlory-ui-regression-batch-6-patterns-digest-insight-rendering` flipped from `queued` to `done`. Title changed to "Prove Patterns digest insight + highlight rendering (domain-tested)". `required_validations` reduced to remove `make ui-regression DOMAIN=patterns` (which would have required a non-existent `PatternsDigestRegression` class) and added `make localization-check` instead. Notes field rewritten to document the scope reduction.
- `automation/handoffs/20260515T090440Z-owlory-ui-regression-batch-6-patterns-digest-insight-rendering.json`
- `SecondBrain/INDEX.md`
- `SecondBrain/sessions/2026-05-15/050440-owlory-ui-regression-batch-6-patterns-digest-insight-rendering.md`

## Why the XCUITest path was dropped

The intended approach: seed a `WeeklyDigest` JSON file with `keyInsight = InsightKind.strongWeek.rawValue` + structured `bestDay`/`hardestDay`, launch the app, navigate `Today.lastWeekSection` → `DigestListView` → `DigestDetailView`, assert the localized insight + highlight strings render.

The blocker: `PatternStore.refreshLatestDigestIfNeeded()` regenerates the digest from the current entries on every refresh (via `makeDigest(...)`), then routes through `withStableID`. The seed file is overwritten on first refresh unless the regenerated digest happens to compute to the same fields. After multiple debug rounds — seeding compatible entries that should compute to the desired output, verifying both the seeded digest JSON and the regenerated digest JSON via `simctl get_app_container`, verifying the disk write path, dumping the XCUITest accessibility tree — `patternStore.latestDigest` still did not propagate to `Today.lastWeekSection` in time for the disclosure group to render `today.digest.lastWeek.label`. The chase was diverging from the slice's stated contract (rendering correctness), so the running-app-smoke proof was abandoned in favor of a domain-tested unit proof of the same rendering contract.

## What domain-tested coverage proves vs. what it does not

Proves:

- Every known `WeeklyDigest.InsightKind` rawValue resolves to its localized English sentence via `keyInsightLabel(_:)`.
- Legacy English-sentence values stored in `keyInsight` (from before the refactor) fall through unmapped and render verbatim.
- Empty `keyInsight` falls through and renders as empty.
- `bestDayHighlightSummary(_:calendar:)` uses the structured `doneCount` + `plannedCount` path when both are present, falling back to the legacy `summary` field otherwise.
- `hardestDayHighlightSummary(_:calendar:)` uses the structured `readinessBand` path with separate `.low` / `.moderate` sentence templates, falling back to the legacy `summary` field when the band is absent.

Does not prove:

- That `DigestDetailView` actually invokes these helpers (this remained untested at running-app level; the helpers are private to the presentation layer but their wiring into SwiftUI Text views is not proved).
- That `PatternStore.refreshLatestDigestIfNeeded` produces a `latestDigest` that propagates to `Today.lastWeekSection` on cold launch with a seeded entries fixture.
- Navigation: `Today.lastWeekSection` → `DigestListView` → `DigestDetailView`.
- The `2026-05-14 app-localization-digest-insight-summary-formatting` slice's *use* of the structured fields in the running app (only the *output* of the helpers given structured inputs).
- Screenshot / device / TestFlight proof for this surface.

The `DigestRowView` keyInsight bug fix is itself unproved at running-app level — the inline change routes the value through `keyInsightLabel(_:)` and the helper is tested, but the row's wiring is not.

## Validation

- `python3 automation/context/build_context.py --slice-id owlory-ui-regression-batch-6-patterns-digest-insight-rendering` — exit 0.
- `python3 automation/supervisor/run_next.py --dry-run` — selected this slice before completion.
- `make architecture` — passed.
- `make test-domain DOMAIN=patterns` — TEST SUCCEEDED. Includes the eight new `WeeklyDigestPresentationFormattingTests` cases alongside the existing PatternEngineTests / CalibrationRulesTests / PatternNudgeRulesTests / ReadinessOutcomeRulesTests / WeeklyDigestRulesTests / WeeklyDigestCadenceRulesTests classes.
- `make localization-check` — 19 locales, 314 keys, 13 plural keys.
- `make automation-check` — 57 tests passed.
- `git diff --check` — clean.

`make ui-regression DOMAIN=patterns` was **not** required for this slice (per the rewritten required_validations) because no `PatternsDigestRegression` class was added.

## Lane Boundary

`domain-tested`. The contract proof is the eight test cases against `WeeklyDigestPresentationFormatting`. The Swift compiles into both targets, the tests pass deterministically. Not running-app-smoke, not screenshot, not device, not TestFlight.

## Residual Risk

- The wiring of `DigestDetailView` and `DigestRowView` into `WeeklyDigestPresentationFormatting` is unproved at running-app level. A regression that bypassed the helper would not be caught by these unit tests; it would need a re-attempt at the XCUITest approach.
- `PatternStore.refreshLatestDigestIfNeeded` propagation to `Today.lastWeekSection` for a seeded fixture remains an open question. A future slice that wants to running-app-smoke this surface needs to either (a) seed entries that the regenerator computes to the target digest deterministically, (b) inject a stub digest writer that bypasses regeneration, or (c) add a test-only seed entrypoint to `PatternStore` that sets `latestDigest` directly.
- The `DigestRowView` keyInsight bug fix flips an old behavior: previously the row rendered raw `"strongWeek"`-style strings; now it renders the localized sentence. If any screenshot fixture or accessibility expectation depended on the raw rendering, it would need adjustment. None known.
- The other Patterns UI sub-behaviors (lastWeekSection card numeric rendering, DigestListView routing, Focus Suggestions, pattern-driven nudges) remain deferred from prior triage.
- Localized rendering is asserted against the English `.lproj` strings only. Non-English values for the eight `InsightKind` keys and the new highlight templates are out of scope here; localization parity is enforced separately by `make localization-check`.
