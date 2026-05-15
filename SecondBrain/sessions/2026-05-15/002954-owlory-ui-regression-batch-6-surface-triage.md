# owlory-ui-regression-batch-6-surface-triage

## Prompt

The user picked Patterns UI from the parked candidate list as the next surface to triage. Pick exactly one sub-behavior within Patterns UI for Batch 6. Doc-only.

## Decision

Sub-behavior: **Patterns UI — DigestDetailView insight + best/hardest highlight sentence rendering** (Batch 6).

Rationale:

- The 2026-05-14 `app-localization-digest-insight-summary-formatting` slice refactored `WeeklyDigestRules` to emit semantic data and moved sentence composition to `WeeklyDigestPresentationFormatting`. That's an active Patterns UI contract change with no UI regression proof.
- Surface is bounded to one `DigestDetailView` sheet.
- Asserts the new structured path end-to-end: `WeeklyDigest.InsightKind` rawValue → `keyInsightLabel(_:)` localized output; `DayHighlight.doneCount` + `plannedCount` → `bestDayHighlightSummary(_:calendar:)`; `DayHighlight.readinessBand` → `hardestDayHighlightSummary(_:calendar:)`.
- Domain rule changes are out of scope; the test asserts presentation only.

Not selected (deferred):

- **Today lastWeekSection digest summary card** — mostly numeric rendering through existing `WeeklyDigestPresentationFormatting` helpers; lower contract-change pressure.
- **DigestListView → detail routing** — a useful routing smoke, but less leverage than the insight-rendering sub-behavior.
- **Focus Suggestions section** — deterministic, no recent contract change.
- **Pattern-driven nudges** (readiness, evening reflection, Write pipeline, Train consistency) — overlaps existing nudge unit tests; the visible text is already routed through localized keys.

## Files Edited

- `docs/workflows/ui-regression-plan.md` — added "### Batch 6 decision" under "Latest Regression Expansion" with the sub-behavior comparison and the narrowed scope. Updated the lead paragraph to record Batch 5 shipped and Batch 6 selected.
- `automation/queue/slices.json` — triage classified, then flipped to `done`. Queued the implementation slice `owlory-ui-regression-batch-6-patterns-digest-insight-rendering` with explicit allowed_paths and required_validations.
- `automation/handoffs/20260515T042954Z-owlory-ui-regression-batch-6-surface-triage.json`
- `SecondBrain/INDEX.md`
- `SecondBrain/sessions/2026-05-15/002954-owlory-ui-regression-batch-6-surface-triage.md`

## Coverage goal for the queued implementation slice

- New seed launch arg (e.g., `--owlory-ui-seed-weekly-digest-insight-fixture`) writing one `WeeklyDigest` JSON file with: `keyInsight = WeeklyDigest.InsightKind.strongWeek.rawValue`, `bestDay` with `doneCount=2`, `plannedCount=2`, empty `summary`; `hardestDay` with `readinessBand="low"`, empty `summary`. Use a consistent calendar/timezone so the rendered weekday is deterministic.
- Open the digest detail from Today via the existing route.
- Assert the localized insight sentence renders: `"Strong week. High readiness translated into follow-through."`
- Assert the best-day highlight renders the structured-path sentence — at minimum the `2 of 2 completed` substring.
- Assert the hardest-day highlight renders the localized low-readiness form.

Required new infrastructure (inside the implementation slice scope):

- Accessibility identifiers on `DigestListView` row, `DigestDetailView` insight section, and best/hardest highlight rows (e.g., `today.digest.row.<uuid>`, `today.digest.detail.insight`, `today.digest.detail.highlight.{best,hardest}`).
- New XCUITest class `OwloryUITests/PatternsDigestRegression`.
- `DOMAIN=patterns` matrix branch in `make ui-regression` consistent with the existing today/write/train/home pattern.

proof_level target for the implementation slice: `running-app-smoke`.

## Validation

- `python3 automation/context/build_context.py --slice-id owlory-ui-regression-batch-6-surface-triage` — exit 0.
- `python3 automation/supervisor/run_next.py --dry-run` — selected this slice before completion; post-completion picks the queued implementation slice next.
- `make architecture` — passed.
- `make automation-check` — 57 tests passed.
- `git diff --check` — clean.

## Lane Boundary

`doc-only`. No XCUITest code, no product behavior changes, no screenshot/device/TestFlight claims. The triage's claim is the sub-behavior decision and the scoped implementation slice queued behind it.

## Residual Risk

- The implementation slice will need to seed a WeeklyDigest JSON file directly into the `PatternStore.digestRepository` storage path. The seed writer must mirror the file format the production code reads; getting that wrong yields a no-digest state rather than a test failure.
- Asserting "the best-day highlight renders the structured-path sentence" depends on the test calendar resolving the seeded `date` to a known weekday. The implementer should either pick a fixed Date such that the rendered weekday is locale-deterministic across iOS Simulator defaults, or assert only the count substring.
- The other Patterns UI sub-behaviors (lastWeekSection, DigestListView routing, Focus Suggestions, nudges) remain deferred; each needs its own scoped triage when prioritized.
- This slice does not prove anything about running-app behavior, screenshot integrity, device behavior, or TestFlight identity. proof_level is doc-only.
