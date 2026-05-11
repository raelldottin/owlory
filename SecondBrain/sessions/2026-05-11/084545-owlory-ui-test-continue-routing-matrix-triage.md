# owlory-ui-test-continue-routing-matrix-triage

Classification-only triage of Today Continue routing. Produced a routing matrix in `docs/product/domains/today.md` covering all six composer-backed Continue sources, classified which routes need new XCUITest smoke vs. which are already covered or deferred, and updated the queued `owlory-ui-test-continue-routing-smoke-batch` slice's notes to embed the matrix decision so its implementation scope is now narrow.

## What the matrix says

The matrix grounds every classification in live code, not wishful product copy:

- **`ContinueItem.highlightTarget`** ([TodayContinuationRules.swift:105](../../owlory_xcode/Owlory/Core/Application/TodayContinuationRules.swift#L105)) is the source of truth for what each row routes to. For first-class sources (trainingSession, homeProtocolRun, homeTask, writingNote) the highlight is direct; for focusItem/carriedFocusItem it is computed from typed `FocusItemOrigin` first, then `linkedRecordID`-by-domain, otherwise `nil`.
- **Tap handler** ([RootTabView.swift:35](../../owlory_xcode/Owlory/RootTabView.swift#L35)) sets `continueHighlightTarget` and switches `selectedTab` to `OwloryTab(domain: item.domain)`.
- **Destination behavior** varies per view: WriteView and HomeView auto-present a detail sheet via `presentHighlightedNoteIfNeeded` / `presentHighlightedRunSheetIfNeeded`; TrainView, HomeView (for tasks), and CareerView only scroll + visual highlight.

The matrix rows:

| Source | Destination behavior | Current proof | Needed proof |
| --- | --- | --- | --- |
| `.focusItem` | Routes to `item.domain`; varies by destination. | `testSeededTodayContinueItemCanBeMarkedDone` (Done action only). | Deferred — focus rows are action-routed; classify dedicated route smoke only when product asks. |
| `.trainingSession` | Train tab + scroll-to-highlight; no auto-detail. | None. | Add deterministic Train-route smoke (highest value). |
| `.carriedFocusItem` | Same as `.focusItem`; tap must not reset carry-forward aging. | None. | Deferred behind focus routing. |
| `.homeProtocolRun` | Home tab + auto-present active run sheet. | `testSeededHomeProtocolRunContinueRowRoutesToActiveRun`. | None. |
| `.homeTask` | Home tab + scroll-to-highlight. | `testSeededHomeTaskContinueRowRoutesToHomeTask`. | None. |
| `.writingNote` | Write tab + auto-present note detail sheet. | None. | Add deterministic Write-route smoke (second-highest value; exercises auto-present). |

## Routing-smoke-batch scope (queued)

The matrix narrows `owlory-ui-test-continue-routing-smoke-batch` to two tests:

1. `inProgressWriting / .writingNote` -> Write tab + auto-presented note detail sheet via `WriteView.presentHighlightedNoteIfNeeded`.
2. `dueTodayTraining / .trainingSession` -> Train tab + scroll-to-highlight via `TrainView.highlightedSessionID`.

That slice's notes are updated to reflect this. The fixtures (`seedInProgressWritingContinueItem`, `seedDueTodayTrainingContinueItem`) already exist from the source-smoke batch; no new seed argument is needed.

## Honest gap recorded in residual risks

Both destinations currently lack stable accessibility identifiers (the matrix calls them out: `write.note.detail.<UUID>`, `train.session.item.<UUID>`). HomeView already follows the convention (`home.task.item.<UUID>`, `home.protocolRun.sheet.<UUID>`) so the implementation slice has a pattern to mirror. Adding those identifiers is in scope for the implementation slice, not for this triage.

## Boundary kept

- No XCUITest code added.
- No accessibility identifiers added (the routing-smoke-batch owns that).
- No product behavior changed.
- No change to ContinueSource enum, composer, ranking, or admission.
- Action affordances (Done/Defer/Drop, Add to Focus, Skip-for-today) are explicitly out of the routing matrix; the Continue Actions section in today.md remains authoritative for them.

## Validation

- `python3 automation/context/build_context.py --slice-id owlory-ui-test-continue-routing-matrix-triage`
- `python3 automation/supervisor/run_next.py --dry-run`
- `make architecture`
- `make automation-check`
- `git diff --check`

## Next

`owlory-ui-test-continue-routing-smoke-batch` is unblocked and its scope is now narrow (Write + Train route tests, plus the two destination identifiers needed for assertion). Deferred lanes (screenshot, device, TestFlight, regression-suite-plan) remain not queued per the UI proof roadmap.
