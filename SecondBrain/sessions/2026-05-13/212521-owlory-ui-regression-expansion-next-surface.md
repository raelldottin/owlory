# owlory-ui-regression-expansion-next-surface

## Prompt

Implement the Lane 2 UI regression batch chosen by the preceding triage slice: Train active/history transition. proof_level target: `running-app-smoke`. Branch off `origin/main` to avoid stacking on the unmerged Write regression PR from a parallel agent.

## Files Edited

- `owlory_xcode/Owlory/Core/Application/OwloryUITestSupport.swift`
- `owlory_xcode/Owlory/Features/Train/TrainView.swift`
- `owlory_xcode/OwloryUITests/OwloryUITests.swift`
- `Makefile`
- `docs/workflows/ui-regression-plan.md`
- `docs/workflows/ui-testing-hygiene.md`
- `docs/workflows/roadmap-status.md`
- `docs/workflows/validation.md`
- `automation/queue/slices.json`
- `automation/handoffs/20260514T012521Z-owlory-ui-regression-expansion-next-surface.json`
- `SecondBrain/INDEX.md`
- `SecondBrain/sessions/2026-05-13/212521-owlory-ui-regression-expansion-next-surface.md`

## Outcome

- Added a new deterministic seed launch arg `--owlory-ui-seed-planned-train-session-today` under `OwloryUITestSupport` that resets app-local state and writes one planned `TrainingSession` dated today.
- Added accessibility identifiers on `TrainView`:
  - `train.session.action.setStatus.<status>.<uuid>` on each status pill Button (e.g., `train.session.action.setStatus.completed.<uuid>`).
  - `train.session.action.save.<uuid>` on the Save Button inside the active session card.
  - `train.history.item.<uuid>` on each History row.
- Applied `.accessibilityElement(children: .contain)` to the `SessionCardView` row alongside the existing `train.session.item.<uuid>` identifier. Without `.contain`, SwiftUI collapsed the row into a single accessibility element and the inner pill and Save buttons could not be reached by XCUITest. The fix preserves both the existing row identifier (used by `TodayContinueRegression`'s `app.otherElements[...]` lookup) and the inner buttons (used by the new regression).
- Added `OwloryUITests/TrainActiveHistoryRegression` with one test:
  - `testSeededPlannedTrainSessionResolvesFromActiveTodayIntoHistory` — opens the Train tab, asserts the seeded session in active Today, taps Completed, taps Save, asserts the row leaves active Today and appears in History.
- Wired `DOMAIN=` matrix into `make ui-regression`:
  - `make ui-regression` runs every regression class.
  - `make ui-regression DOMAIN=today` narrows to `TodayContinueRegression`.
  - `make ui-regression DOMAIN=train` narrows to `TrainActiveHistoryRegression`.
- Updated `docs/workflows/ui-regression-plan.md`, `ui-testing-hygiene.md`, `roadmap-status.md`, and `validation.md` to describe both regression classes, the matrix, and the new seed arg.

## Validation

- `make architecture` - passed.
- `make ui-regression DOMAIN=train` - passed (1 test, 34.3s) after applying the documented simulator preflight recovery (`xcrun simctl shutdown all` / `erase <udid>` / `rm -rf /tmp/owlory-ui-regression-derived-data` / `xcrun simctl boot <udid>` / `xcrun simctl bootstatus <udid>`). The recovery was needed because the iPhone 17 simulator was reaching a Mach error -308 state from a prior session.
- `make automation-check` - 50 tests passed.
- `git diff --check` - clean.
- The full `make ui-regression` (both classes) was not re-run because Train passes in isolation and the Today regression code/seed is unchanged from `origin/main`; the user explicitly skipped that re-run.

Test session results live transiently at `/tmp/owlory-ui-regression-derived-data/Logs/Test/Test-Owlory-2026.05.13_21-16-42--0400.xcresult` per Lane 2's transient-artifact policy.

## Multi-Agent Context

This slice was started on a fresh branch `claude/train-active-history-batch` off `origin/main`, deliberately not stacked on the unmerged `claude/awesome-wing-934def` PR. That PR was opened by a parallel agent (Agent A) that picked Write capture inbox for the same triage slice. Agent A's `WriteCaptureRegression` does not exist on `origin/main` yet; this branch implements the Train scope that the parallel `owlory-ui-regression-next-surface-triage` chose. When either PR merges, the other will need to rebase and reconcile `automation/queue/slices.json` (both PRs touch `owlory-ui-regression-expansion-next-surface`), `Makefile` (both add `DOMAIN=` matrix entries), and `docs/workflows/*` (both describe a second regression class). The non-destructive reconciliation pattern is to keep both regression classes and both `DOMAIN=` branches.

## Lane Boundary

This slice is `running-app-smoke` (Lane 2 regression). It is not a screenshot proof, not a device proof, and not a TestFlight proof. The captured xcresult is transient and not promoted into `automation/proofs/`.

## Residual Risk

- Recurrence rollover, voice/reflection fallback, multiple Train statuses in one slice, Continue routing, screenshot proof, device proof, and TestFlight proof are intentionally out of scope; follow-up slices own those.
- The simulator preflight recovery was needed once during this slice; future runs may need the same recovery if the simulator gets into a Mach -308 state. The recovery steps are already documented in `ui-testing-hygiene.md` and were followed verbatim here.
- The merge with the parallel Write batch PR will require manual reconciliation of `Makefile` and `slices.json`; the test classes themselves do not conflict.
