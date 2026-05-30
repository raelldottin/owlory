# Today Continue Source ID Audit

This doc catalogs the ID stability of every Continue source so future
deep-link, persistence, or migration work has a single reference for
which IDs can be relied on across reorder, app launches, and day
rollovers. The audit is intentionally narrow: it does not propose new
data model fields or new persistence — that belongs to follow-up
slices (`today-continue-persisted-provenance`,
`today-continue-prune-migrate`).

Source of truth in code: `TodayContinuationRules.ContinueSource`
(`owlory_xcode/Owlory/Core/Application/TodayContinuationRules.swift`).

## Definitions

- **Record-stable ID** — a UUID that lives on a persisted record
  (`TrainingSession`, `HomeTask`, `ProtocolRun`, `WritingNote`) and
  does not regenerate when the user reorders, archives, or rolls a day
  forward. Safe to use for deep links and external references.
- **Carry-forward synthetic ID** — a UUID that lives on a
  `FocusItem`. `CarryForwardRules.nextDayItems(...)` generates a fresh
  `FocusItem.id` every time it rolls an item forward, so the value
  changes day-to-day even when the underlying intent is the same.
  Routing must dereference via `linkedRecordID` or `origin` instead of
  the raw focus-item UUID.
- **Composite assembly ID** — `ContinueItem.id` produced by
  `TodayContinueItemAssembler.assembleItem(...)`. It joins
  `(sourceIndex, source.key, domain, title)` and changes on reorder,
  title edit, or domain reassignment. Useful for in-session list
  diffing; not safe as a stable external reference.

## Per-source verdict

| Continue source | Underlying ID | Stability | Routing today |
| --- | --- | --- | --- |
| `trainingSession(UUID)` | `TrainingSession.id` | **Record-stable.** Persisted on the session record; survives reorder, recurrence rollover, and app relaunch. | `HighlightTarget.trainingSession(id)` opens the session directly. |
| `homeTask(UUID)` | `HomeTask.id` | **Record-stable.** Persisted on the task; recurrence interval mutates `lastCompleted`/`lastSkipped` but never `id`. | `HighlightTarget.homeTask(id)`. |
| `homeProtocolRun(UUID)` | `ProtocolRun.id` | **Record-stable.** Run records are immutable identity-wise. | `HighlightTarget.homeProtocolRun(id)`. |
| `writingNote(UUID)` | `WritingNote.id` | **Record-stable.** Stage transitions (capture → source → … → archived) preserve the note's UUID. | `HighlightTarget.writingNote(id)`. |
| `focusItem(UUID)` | `FocusItem.id` (today's `focusThree`) | **Carry-forward synthetic.** A fresh UUID per `CarryForwardRules.nextDayItems(...)` call; the same conceptual item gets a new ID each day. | `HighlightTarget` routes via `origin` first, then `linkedRecordID`, then domain heuristic. Never via the focus UUID directly. |
| `carriedFocusItem(UUID)` | `FocusItem.id` (today's `focusThree`, carried from prior day) | **Carry-forward synthetic.** Same instability as `focusItem`. | Same `origin` → `linkedRecordID` → domain fallback chain. |

## Composite IDs

`ContinueItem.id` is built from `sourceIndex|source.key|domain|title`.
Implications:

- Stable within a single ranking pass (deterministic for a given
  source-composer output).
- Changes if any of these mutate: position in the source-composer
  output (`sourceIndex`), the underlying source UUID (`source.key`),
  the domain reassignment (rare), or a title rename.
- Useful as a SwiftUI `Identifiable` hash for `ForEach`. Do not
  persist or expose across app launches.

## What this means for callers

- **Deep links and external IDs:** prefer the four record-stable
  sources. For focus-backed Continue rows, dereference via
  `ContinueItem.highlightTarget` which already does the chained
  fallback — do not extract the raw focus UUID and treat it as
  durable.
- **Persistence-keyed metadata** (provenance, prune-migrate, future
  ML annotations): key by `(originKind, originID)` derived from the
  `FocusItemOrigin` envelope, not by `FocusItem.id`. The origin survives
  day rollover; the focus UUID does not.
- **UI list rendering:** keep using `ContinueItem.id` — it is the
  least-bad in-session identity. The reorder churn it introduces is
  acceptable for `ForEach` diffing because the list re-derives on
  state change anyway.

## What this audit does NOT do

- Does not add a new domain field.
- Does not change carry-forward UUID generation.
- Does not add deep links for `focusItem` / `carriedFocusItem` that
  the existing `origin` chain doesn't already cover.

If a follow-up needs stable focus IDs across days, the cleanest path
is to attach a parent `lifecycleID` to the first-day `FocusItem` and
propagate it through `CarryForwardRules.nextDayItems(...)`. That is
explicitly out of scope here; queue it as a separate slice.
