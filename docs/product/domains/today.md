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

- `DailyEntry.carryForward` is persisted historical fact for Previous Days. Do not migrate or rename it unless the persisted schema intentionally changes.
- Continue is a derived Today projection, not stored carry-forward data. Rendering Continue, refreshing Focus Suggestions, or routing Continue rows must not mutate `carryForward`.
- Continue can derive rows from planned training due today, stale carried focus items, active Home protocol runs, active Home tasks, and in-progress Writing notes.
- Active Home protocol runs may surface in Continue, but Today must not turn them into duplicate Focus/carry-forward artifacts just to keep them visible across days. Their lifecycle stays Home-owned.
- Carried Home focus rows that match a Home protocol template or known protocol run are protocol artifacts, not standalone Today work. Suppress them at the Continue projection boundary unless they are represented by an active Home protocol-run source.
- Carried Train focus rows linked to a training session may surface only when the linked session is still planned and actionable today. If the linked session is skipped, completed, modified, missing, or no longer today's session, suppress the carried row rather than implying the Train session carried forward.
- Continue rows must be actionable and routable to Train, Write, Career, or Home. If a future candidate cannot map to a real destination or Today-owned action, keep it out of Continue until that contract exists.
- Continue rows must carry source provenance at derivation time. Current source-backed rows come from planned training sessions, carried focus items, active Home protocol runs, active Home tasks, and active Writing notes.
- Retired scaffold prompts belong behind centralized candidate rules. Suppress unlinked retired scaffolds such as "Log one writing intention" and "Capture one career win" without suppressing linked or source-backed user records with the same title.

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
- Carried focus rows support source-aware Defer and Drop actions against the original focus item.
- Carried focus rows do not expose Recommit/Add to Focus because they are already in Focus Three; tapping the row routes to the owning domain without resetting carry-forward aging.
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
- Weekly digest summaries must be count-first and scope-honest. If a digest has planned Focus items, show `done of planned`; if it has zero planned Focus items, say `No planned Focus items` instead of `0% done`. Only label a digest `Last Week` when its window is the immediately previous calendar week.
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
- Today Continue can show stale carry-forward context with a badge.
- Tapping a Continue row routes to a concrete domain tab.
- Continue has no General or otherwise orphaned destination.
- Focus Suggestions can accept into Focus Three without mutating `carryForward`.
- Focus Suggestions can be dismissed without persisting anything.
