# reorderable-list-coverage-triage (doc-only)

Inventoried every visible list surface across Today, Train, Write, Home, Career, and Patterns. Classified each as user-ordered, derived/ranked, chronological, rule-derived, or not worth reordering. No code changed.

## Classification table

| Surface | Classification | Reorderable? | Persistence note |
| --- | --- | --- | --- |
| Today Continue | derived/ranked | No — ContinueRankingRules + urgency scoring | N/A |
| Focus Suggestions | derived/ranked | No — FocusSuggestionRules priority scoring | N/A |
| Focus Three (in entry) | user-ordered | No — max 3 items, reorder cost exceeds value | N/A |
| Carry Forward | derived | No — produced from previous day's focus state | N/A |
| Previous Days | chronological | No — date-driven | N/A |
| Domain Intentions | rule-derived | No — alphabetical by domain key | N/A |
| Last Week Digest | rule-derived | No — single digest, not a sortable list | N/A |
| All Digests | chronological | No — reverse chronological by week | N/A |
| Train Today Sessions | user-ordered (small) | No — typically 1–3 planned sessions, low reorder value | N/A |
| Train History | chronological | No — sorted by date newest first | N/A |
| **Home Active Tasks** | **user-ordered** | **Candidate** | Needs `order: Int` on HomeTask or array-position mutation |
| Home Completed Tasks | resolved state | No — completed work, no reorder value | N/A |
| Home Skipped Tasks | resolved state | No — skipped work, no reorder value | N/A |
| **Home Protocols** | **user-ordered** | **Candidate** | Needs `order: Int` on HouseholdProtocol or array-position mutation |
| **Protocol Steps** | **user-ordered** | **Candidate** | Steps are `[String]` — array position IS the order, no new field needed |
| Home Active Runs | insertion order | No — typically 0–2 active runs, low reorder value | N/A |
| Home Recent Completed Runs | chronological (truncated) | No — resolved history, truncated to 5 | N/A |
| **Write Notes by Stage** | **user-ordered** | **Candidate** | Needs `order: Int` on WritingNote or array-position mutation |
| Write Archive | insertion order | No — archived, low-priority reorder | N/A |
| Career Records | chronological | No — sorted by date newest first | N/A |

## Must NOT become reorderable

These lists must not accept manual reorder because reorder would break ranking, chronology, or derived contracts:

- **Today Continue**: ranking is deterministic via ContinueRankingRules + CompletionTimePredictor urgency. Manual reorder would conflict with the derived ordering contract and break the Continue pipeline trace expectations.
- **Train History**: sorted newest-first by session date. Manual reorder would break the timeline.
- **Career Records**: sorted newest-first by date. Same constraint.
- **Focus Suggestions**: scored by FocusSuggestionRules. Reorder would conflict with suggestion ranking.
- **All Digests / Previous Days**: calendar-anchored.
- **Domain Intentions**: alphabetical by domain key at render time.
- **Carry Forward**: derived from yesterday's focus state, not user-curated.

## Candidates: persistence decision

No domain model currently has an explicit order field. All user-ordered lists rely on array insertion order in JSON storage via `ItemListRepository`.

Two approaches for persistence:

1. **Explicit `order: Int` field** on the model. More robust for filtered/grouped views that need to reconstruct original order. Requires a defaulted Codable init for legacy decode. Better if future sync/merge is expected.
2. **Array-position mutation** (swap in storage array, persist). Simpler, no schema change. Works today because stores persist `[Model]` arrays directly. Fragile if filtering/sorting is ever added at the store level.

**Recommendation**: use array-position mutation for the initial implementation slices. Add explicit order fields only if a concrete filtering or sync need surfaces. Protocol steps already use array position as the canonical order.

## Suggested implementation slices (not auto-queued)

If the user wants drag-to-reorder, these are the scoped follow-up slices:

1. **home-task-reorder**: Add `onMove` to Home active tasks in HomeView. HomeStore gets `moveTask(from:to:)` that swaps array indices and persists. Allowed paths: HomeView.swift, HomeStore.swift, HomeStoreTests.swift, home.md, slices.json.
2. **home-protocol-reorder**: Same pattern for the protocols list.
3. **protocol-step-reorder**: Add `onMove` to protocol steps in the template editor. Steps are `[String]`, so this is a simple array swap.
4. **write-note-stage-reorder**: Add `onMove` to notes within each stage section. WriteStore gets `moveNote(from:to:inStage:)`.

Each slice is small (2–4 files) and independent. None requires schema migration.

## Proof level

`doc-only`. No code, persistence, or domain rule changed.

## Validation

- `make architecture` — passed
- `make automation-check` — passed (36 tests)
- `git diff --check` — clean

## Next

Queue plays in priority order: `home-protocol-archive` (p=143) is next.
