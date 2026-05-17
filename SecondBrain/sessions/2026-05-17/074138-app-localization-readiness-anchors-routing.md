# app-localization-readiness-anchors-routing

## Prompt

> "start app-localization-readiness-anchors-routing" — the first follow-up surfaced by the helper-generated-copy audit. Approach: in-place wrap (anchors are call-site tuples in Features/, no Domain boundary concern).

## What was done

Added 9 new localization keys with LLM-drafted translations across all 19 locales:

| Key | English | German |
|---|---|---|
| `readiness.anchor.low` | Low | Niedrig |
| `readiness.anchor.okay` | Okay | Okay |
| `readiness.anchor.high` | High | Hoch |
| `readiness.anchor.rough` | Rough | Mies |
| `readiness.anchor.steady` | Steady | Stabil |
| `readiness.anchor.good` | Good | Gut |
| `readiness.anchor.poor` | Poor | Schlecht |
| `readiness.anchor.fine` | Fine | In Ordnung |
| `readiness.anchor.great` | Great | Großartig |

Wired 6 anchor tuple call sites to build the tuple from `String(localized: "readiness.anchor.<word>")`:

| File:Line | Context | Anchor set |
|---|---|---|
| `TodayView.swift:194` | Energy check-in row | Low/Okay/High |
| `TodayView.swift:197` | Mood check-in row | Rough/Steady/Good |
| `TodayView.swift:200` | Sleep check-in row | Poor/Fine/Great |
| `TodayView.swift:1579` | PreviousDay Train readiness | Low/Okay/High |
| `TrainView.swift:181` | Train inline readiness disclosure | Low/Okay/High |
| `TrainView.swift:299` | Train session-editor readiness | Low/Okay/High |

The internal display code (`readinessRow` body in TodayView, `TrainingReadinessScaleRow` body in TrainView) was NOT modified. Both use `Text(anchors.0/1/2)` which displays the now-localized String verbatim. The fix is entirely at the call site.

## Why the same key serves both Energy and Training

`readiness.anchor.low/okay/high` is used by both the Today Energy check-in row and the Train readiness disclosure. The semantic context is similar enough (low/medium/high intensity) that one set of translations applies. If a future locale needs distinct translations, the keys can be split (e.g., `readiness.anchor.energy.low` vs `readiness.anchor.training.low`).

## Files Edited

- `owlory_xcode/Owlory/Features/Today/TodayView.swift` — 4 anchor tuples updated
- `owlory_xcode/Owlory/Features/Train/TrainView.swift` — 2 anchor tuples updated
- 19 × `Localizable.strings` — 9 new keys appended each
- `automation/queue/slices.json` — slice flipped to `done`
- `automation/handoffs/20260517T074138Z-app-localization-readiness-anchors-routing.json` (new)
- `SecondBrain/INDEX.md`
- `SecondBrain/sessions/2026-05-17/074138-app-localization-readiness-anchors-routing.md` (this note)

## Validation

- `make architecture` — passed.
- `make localization-check` — 19 / **339** / 13 (up from 330).
- `./Tools/validate.sh localization` — passed.
- `make automation-check` — 57/57.
- `xcodebuild build -quiet -destination 'generic/platform=iOS Simulator'` — exit 0.
- `git diff --check` — clean.

## Lane Boundary

`build-tested`. The compile is clean, parity holds, no test regressions. The fix is entirely localized to view-call-site code + `Localizable.strings` keys. No view structural changes, no helper changes, no Domain boundary impact.

## Residual Risk

- LLM-drafted translations are unverified. Subtle wording (e.g., "Mies" for Rough is conversational; might not match Owlory voice). Native review needed.
- Same `readiness.anchor.{low,okay,high}` key is reused for Energy and Training contexts — generic enough that one translation likely works, but a native reviewer may want to split.
- Internal `Text(anchors.X)` path still uses the runtime-String overload. If a future caller passes a non-localized tuple, the fix silently breaks. Cannot enforce via type system without changing the readinessRow / TrainingReadinessScaleRow signature.
- Per-locale review return files (372 entries snapshot from 2026-05-16) are now 9 entries stale per locale. Run `python3 Tools/localization-return-files-refresh.py --apply` to refresh.
- Native review remains outstanding for every locale. `app-localization-native-review-intake` still blocked.

## What remains queued

6 of 7 helper-generated-copy follow-ups still queued:

| Priority | Slice | Approach |
|---:|---|---|
| 83 | `app-localization-calibration-rules-helper-copy-routing` | structural |
| 82 | `app-localization-readiness-rules-helper-copy-routing` | structural |
| 81 | `app-localization-pattern-nudge-rules-helper-copy-routing` | structural |
| 80 | `app-localization-focus-suggestion-reason-routing` | structural |
| 79 | `app-localization-continue-row-subtitle-routing` | structural |
| 78 | `app-localization-today-header-greeting-routing` | in-place |
