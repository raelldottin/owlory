# Today Domain

## Owns

- Daily entry lifecycle and state.
- Focus items and focus suggestions.
- Readiness check-in values and readiness nudges.
- Carry-forward from previous days.
- Evening reflection and historical review.
- Continue-section composition, eligibility, candidate caps, and ranking for the Today surface that presents cross-domain work.

## Does Not Own

- Training session recurrence or completion semantics.
- Writing stage transition rules.
- Home task recurrence or protocol run lifecycle.
- Notification scheduling.

## Depends On

- Domain rules: `DailyPlanningRules`, `FocusSuggestionRules`, `CarryForwardRules`, `ReadinessRules`, `ContinueCandidateRules`, `ContinueRankingRules`, `CompletionTimePredictor`.
- Stores from other domains only for Today dashboard and Continue presentation.

## Exposes

- `TodayStore` as the app-facing state owner.
- `TodayContinuationRules.ContinueItem` for cross-domain continuation UI.

## Continue And Carry-Forward Contract

Implementation status: `Implemented` for current Continue ownership and Focus-backed Done / Defer / Drop behavior; `Needs UI proof` for action discoverability.
Proof level: Domain and core regression tests cover source-aware Continue composition and Focus-backed action routing.
Missing/deferred: Large Dynamic Type screenshot proof, visible fallback review for hidden actions, future Skip-for-today, stable deep links, generated-item provenance, and prune/migrate behavior.

- `DailyEntry.carryForward` is persisted historical fact for Previous Days. Do not migrate or rename it unless the persisted schema intentionally changes.
- Continue is a derived Today projection, not stored carry-forward data. Rendering Continue, refreshing Focus Suggestions, or routing Continue rows must not mutate `carryForward`.
- Continue can derive rows from current Focus items, planned training due today, stale carried Focus items, active Home protocol runs, active Home tasks, and in-progress Writing notes.
- Continue is the only Today-tab surface for Focus work. Do not add a standalone Focus section to the Today dashboard; current Focus, carried Focus, and source-backed Focus actions must live in Continue.
- Active Home protocol runs may surface in Continue, but Today must not turn them into duplicate Focus/carry-forward artifacts just to keep them visible across days. Their lifecycle stays Home-owned.
- Home protocol drafts/templates promoted from Write notes must not surface in Continue until Home has an active protocol run or Today-owned work item for them. Typed Write-note origin metadata on the template is source context, not an execution signal.
- Carried Home focus rows that match a Home protocol template or known protocol run are protocol artifacts, not standalone Today work. Suppress them at the Continue projection boundary unless they are represented by an active Home protocol-run source.
- Active Home tasks, including tasks promoted from Write notes via Turn into Task, are Continue-eligible by the same `isActiveHomeTaskCandidate` rule that applies to any Home task. Within the per-domain Home cap, active protocol runs are admitted before standalone tasks; when both Home slots are taken by active runs, standalone tasks are correctly excluded from Continue. To force a specific Home task into Today's Continue regardless of cap pressure, use the Today-owned Add to Focus path. Promotion origin does not bypass admission.
- Carried Train focus rows linked to a training session may surface only when the linked session is still planned and actionable today. If the linked session is skipped, completed, modified, missing, or no longer today's session, suppress the carried row rather than implying the Train session carried forward.
- Continue rows must be actionable and routable to Train, Write, Career, or Home. If a future candidate cannot map to a real destination or Today-owned action, keep it out of Continue until that contract exists.
- Continue rows must carry source provenance at derivation time. Current source-backed rows come from current Focus items, planned training sessions, carried Focus items, active Home protocol runs, active Home tasks, and active Writing notes.
- Write notes promoted into Today become Today-owned Focus work in the writing domain. The Focus item must keep the note ID as source linkage and typed origin metadata so Continue can route back to the original note.
- Write note detail may show that a Today Focus item already exists for the note by reading Today-owned source metadata. That status display must not move Focus ownership into Write or imply a required daily Write cadence.
- Retired scaffold prompts belong behind centralized candidate rules. Suppress unlinked retired scaffolds such as "Log one writing intention" and "Capture one career win" without suppressing linked or source-backed user records with the same title.
- Focus Three is a current-day commitment surface, not just planning metadata. The Today dashboard must expose Focus status actions through Continue, including a direct Done action for Focus-backed Continue rows.
- Source-backed Focus items should be marked done when their linked source has unambiguous completion semantics. Current automatic sources are completed or modified Train sessions, completed Home tasks, and published Write notes. Do not infer completion from ambiguous states such as archived notes, skipped work, pending protocol steps, or reusable protocol templates.
- Continue removes completed work when its owning Focus item is marked done, when the source-derived item is no longer eligible, or when linked-source synchronization marks the Focus artifact done. Manually created Focus items without source identity are not auto-completed by matching title alone.

## Continue UI Source Coverage

`TodayContinueSourceComposer.sourceOrder` is the source of truth for current Continue source composition. The maintained XCUITest smoke suite proves selected high-value paths, not exhaustive UI behavior.

| Composer step | Continue source | Current UI source proof | Needed proof |
| --- | --- | --- | --- |
| `currentFocus` | `.focusItem` | Covered by `testSeededTodayContinueItemAppears`; Done action also covered. | None for source visibility. |
| `dueTodayTraining` | `.trainingSession` | Covered by `testSeededDueTodayTrainingAppearsInTodayContinue`. | None for source visibility. |
| `carriedForwardFocus` | `.carriedFocusItem` | Covered by `testSeededCarriedForwardFocusAppearsInTodayContinue`. | None for source visibility. |
| `activeHomeProtocolRun` | `.homeProtocolRun` | Covered by `testSeededHomeProtocolRunContinueRowRoutesToActiveRun`. | None for source visibility. |
| `activeHomeTask` | `.homeTask` | Covered by `testSeededHomeTaskAppearsInTodayContinue`; routing also covered. | None for source visibility. |
| `inProgressWriting` | `.writingNote` | Covered by `testSeededInProgressWritingAppearsInTodayContinue`. | None for source visibility. |

Career records and reminders are not standalone Continue sources in the current composer. They may appear only through Today-owned Focus/carried Focus records or future source work; do not add UI smoke for them until a concrete source contract exists.

## Continue UI Routing Coverage

`TodayContinuationRules.ContinueItem.highlightTarget` is the source of truth for what each Continue row routes to. The tap handler in `RootTabView` then sets `continueHighlightTarget` and switches `selectedTab` to `OwloryTab(domain: item.domain)`; each destination view consumes the highlight via its `highlighted<Kind>ID` parameters and may auto-present a detail sheet.

| Composer step | Continue source | Tap behavior | Destination behavior | Current UI route proof | Needed proof |
| --- | --- | --- | --- | --- | --- |
| `currentFocus` | `.focusItem` | Route to `item.domain`; highlight computed from typed `FocusItemOrigin` or `linkedRecordID` per `domain`. | Varies: writingNote auto-presents note detail; homeProtocolRun auto-opens active run sheet; others scroll + visual highlight only. | None for tap routing. `testSeededTodayContinueItemCanBeMarkedDone` covers the Done swipe action only. | Deferred. Focus rows are primarily action-routed (Done/Defer/Drop); add a dedicated focus-with-typed-origin route smoke only when product asks for it. |
| `dueTodayTraining` | `.trainingSession` | Route to `.train`; highlight `.trainingSession(id)`. | `TrainView` scrolls to the highlighted row; no auto-detail sheet. | Covered by `testSeededDueTodayTrainingContinueRowRoutesToTrain`. | None for routing. |
| `carriedForwardFocus` | `.carriedFocusItem` | Route to `item.domain`; highlight computed identically to `.focusItem`. Tap must not reset carry-forward aging (`DailyEntry.carryForward` is read-only at projection time). | Identical to `.focusItem` per destination view. | None. | Deferred. Carry-forward routing follows the focus routing contract; classify a dedicated smoke after focus-routing is added or after a carry-forward-specific destination contract emerges. |
| `activeHomeProtocolRun` | `.homeProtocolRun` | Route to `.home`; highlight `.homeProtocolRun(id)`. | `HomeView` scrolls + auto-presents the active run sheet via `presentHighlightedRunSheetIfNeeded`. | Covered by `testSeededHomeProtocolRunContinueRowRoutesToActiveRun`. | None for routing. |
| `activeHomeTask` | `.homeTask` | Route to `.home`; highlight `.homeTask(id)`. | `HomeView` scrolls to the task and applies the visual highlight; no auto-detail sheet. | Covered by `testSeededHomeTaskContinueRowRoutesToHomeTask`. | None for routing. |
| `inProgressWriting` | `.writingNote` | Route to `.write`; highlight `.writingNote(id)`. | `WriteView` scrolls + auto-presents the note detail sheet via `presentHighlightedNoteIfNeeded`. | Covered by `testSeededInProgressWritingContinueRowRoutesToWriteNoteDetail`. | None for routing. |

Action affordances are separate from routing. The Continue Actions section above is authoritative for Done/Defer/Drop, Add to Focus capacity, and the Active Home protocol-run Add-to-Focus exception; do not collapse routing and action coverage into a single UI test. `careerRecord` is reachable as a `HighlightTarget` only when a Focus row carries a typed `FocusItemOrigin.careerRecord` or linkedRecordID-by-domain; there is no first-class career Continue source, so career routing is out of scope until a career source contract exists.

## Artifact Lifecycle

- Stop surfacing invalid artifacts at the projection boundary before migrating data. For Continue, the boundary is the source-composition/admission path that feeds `TodayContinuationRules`.
- Preserve compatibility: keep old records decoding, keep Previous Days readable, and avoid mutating `DailyEntry.carryForward` while rendering derived surfaces.
- Future persisted generated items need source kind, source ID, creator, created-by version, and retired-by version before they can become canonical records.
- New projections should fail closed when a generated item has no valid source or Today-owned action.
- Prune or migrate confirmed system artifacts only after compatibility behavior has shipped. If old records contain user-authored payload, migrate that payload to the closest domain object instead of deleting it.
- Do not use UI-specific title blacklists as migrations; keep retired artifact suppression in domain/application policy with tests.

## Continue Actions

- Tapping a Continue row routes to the row's domain and may provide a highlight target for source-backed records.
- Tapping an active Home protocol-run row should open the active run itself after routing to Home, not strand the user at the reusable protocol template list.
- Tapping an in-progress Write note row should open that note's detail sheet after routing to Write, not stop at the broader note list.
- Non-carried source-backed Continue rows may expose Add to Focus when Focus Three has capacity and the work is not already represented there. Adding from Continue preserves the source linkage on the created focus item.
- Active Home protocol runs do not expose Add to Focus. A protocol run already persists as Home-owned active work, and duplicating it into Today Focus creates invalid carry-forward artifacts.
- Focus-backed Continue rows support source-aware Done, Defer, and Drop actions against the original focus item.
- Current and carried Focus rows do not expose Recommit/Add to Focus because they are already in Focus Three; tapping the row routes to the owning domain without resetting carry-forward aging.
- Future "Skip for today" behavior should hide the derived row for the day without mutating the source object by default. Domain-native skips, such as Home task skip or Training session skipped status, must remain explicit domain actions.
- Deep links should use source kind, stable source IDs, or completion keys where available to open or highlight exact records after tab routing.

## Change Safely

- Put deterministic rule changes in `Core/Domain`; keep `TodayContinuationRules` focused on Continue orchestration.
- Daily plan assembly, focus item admission cap, removal, and status mutation belong in `DailyPlanningRules`; `TodayStore` owns clock, repository lookup, generated IDs, persistence, and published entry state.
- Focus suggestion fallback policy belongs in `FocusSuggestionRules`: historical completion weighting, readiness-band matching, active/current item exclusion, prediction fallback admission, deterministic tie-breaks, and draft caps/dedupe.
- `TodayStore` owns focus suggestion orchestration: calibration lookup, dismissed draft state, accept/dismiss actions, and persistence. ML-generated user-facing suggestions are not currently active; statistical completion-time predictions may enrich the fallback but do not own suggestion generation.
- Carry-forward eligibility belongs in `CarryForwardRules`; daily planning consumes the carried items without deduping or reordering them.
- Continue source composition and source order belong in `TodayContinueSourceComposer`.
- Continue item assembly and prediction urgency enrichment belong in `TodayContinueItemAssembler`.
- Continue candidate eligibility and admission caps belong in `ContinueCandidateRules`; Continue ordering belongs in `ContinueRankingRules`.
- Today-owned check-in and reflection prompt timing belongs in `TodayStore` static prompt helpers; reminder/runtime code may schedule or mirror those prompts, but it must not redefine when Today should ask for them.
- Continue runtime diagnostics belong in `ContinuePipelineTrace` and are emitted from `TodayContinuationRules`; keep telemetry out of domain policies.
- "Close the day" reflection nudges are evening prompts. Home completion may change the prompt title and body after the evening window starts, but it must not ask the user to close the day just because Home tasks finished earlier.
- Today may present Pattern-owned domain-balance nudges, but it must preserve their Focus framing. Do not relabel them as broad domain inactivity or "quiet lately" messages.
- Weekly digest summaries must be count-first and scope-honest. If a digest has Focus items or completed Home protocol steps, show `done of total`; if it has zero planned Focus items and no completed protocol steps, say `No planned Focus items` instead of `0% done`. Only label a digest `Last Week` when its window is the immediately previous calendar week. The `done` count depends on Focus items being marked done directly in Today or through source-backed completion propagation before digest generation.
- Weekly digest is informational. Per-stat affordances may deep-link to existing Today-owned surfaces that already render the same underlying data (e.g., Best Day and Hardest Day rows may route to that specific calendar day in Previous Days). The digest must not host its own next-week-planning CTAs because carry-forward (`CarryForwardRules`/`DailyPlanningRules`) and Focus Suggestions already own that path, and it must not surface pattern-driven prompts in the digest body because Patterns owns nudge content via `PatternNudgeRules`/`CalibrationRules`. `View all digests` remains the digest's primary navigation affordance.
- Keep `TodayView` focused on presentation and user actions.
- Today presentation must adapt to Dynamic Type without capping accessibility sizes. When the header or check-in summary no longer fits honestly in its standard one-line layout, prefer shorter date formatting, shorter accessibility-only labels, stacked supporting text, and compact-height summary layouts over compressed or misleading truncation.
- In compact-height accessibility layouts, do not stack a large Today hero title above the readiness message just because portrait does. Reuse the actual readiness summary as the primary header message when that preserves meaning and keeps the next actionable surface visible.
- Preserve daily-entry state distinctions: missing, setup incomplete, active, reflected, historical.

## Verify

- `make test-domain DOMAIN=today`
- `xcodebuild test -project Owlory.xcodeproj -scheme Owlory -destination "$OWLORY_XCODE_DESTINATION" -only-testing:OwloryCoreTests/DailyPlanningRulesTests -only-testing:OwloryCoreTests/FocusSuggestionRulesTests -only-testing:OwloryCoreTests/TodayStoreTests`
- `xcodebuild test -project Owlory.xcodeproj -scheme Owlory -destination "$OWLORY_XCODE_DESTINATION" -only-testing:OwloryCoreTests/TodayContinueSourceComposerTests -only-testing:OwloryCoreTests/TodayContinueItemAssemblerTests -only-testing:OwloryCoreTests/ContinuePipelineTraceTests -only-testing:OwloryCoreTests/ContinueCandidateRulesTests -only-testing:OwloryCoreTests/ContinueRankingRulesTests`

Continue/carry-forward acceptance checks:

- Previous Days still renders recorded carry-forward facts.
- Today Continue can show non-carry-forward work.
- Today Continue can show current Focus commitments without a separate Focus section.
- Today Continue can show stale carry-forward context with a badge.
- Tapping a Continue row routes to a concrete domain tab.
- Continue has no General or otherwise orphaned destination.
- Focus Suggestions can accept into Focus Three without mutating `carryForward`.
- Focus Suggestions can be dismissed without persisting anything.
