# app-localization-today-header-greeting-routing

## Prompt

> "start app-localization-today-header-greeting-routing"

Second follow-up from the helper-generated-copy audit. Scope: localize the 6 English branches of `TodayView.headerGreeting`. Approach: in-place wrap (Features-located, no Domain boundary concern).

## What was done

Added 6 new keys with LLM-drafted translations across all 19 locales:

| Key | English | German |
|---|---|---|
| `today.header.greeting.dayComplete` | Day complete | Tag abgeschlossen |
| `today.header.greeting.inProgress.compact` | In progress | Im Gange |
| `today.header.greeting.inProgress.regular` | Day in progress | Tag läuft |
| `today.header.greeting.readyWhenYouAre` | Ready when you are | Bereit, wenn Sie es sind |
| `today.header.greeting.todaysPlan` | Today's plan | Heutiger Plan |
| `today.header.greeting.whatsActiveToday` | What's active today? | Was ist heute aktiv? |

Wrapped each return branch of `TodayView.headerGreeting` (line 149-164) in `String(localized:)`. The two display paths — `standardDashboardHeader` (line 1187) and `compactHeightDashboardHeader` (line 1241) — both render `Text(headerGreeting)` and don't need changes; the returned String is now already-localized.

## Files Edited

- `owlory_xcode/Owlory/Features/Today/TodayView.swift` — headerGreeting body
- 19 × `Localizable.strings` — 6 new keys each
- `automation/queue/slices.json` — slice flipped to `done`
- `automation/handoffs/20260517T075934Z-app-localization-today-header-greeting-routing.json` (new)
- `SecondBrain/INDEX.md`
- `SecondBrain/sessions/2026-05-17/075934-app-localization-today-header-greeting-routing.md` (this note)

## Validation

- `make architecture` — passed.
- `make localization-check` — 19 / **345** / 13 (up from 339).
- `./Tools/validate.sh localization` — passed.
- `make automation-check` — 57/57.
- `xcodebuild build -quiet -destination 'generic/platform=iOS Simulator'` — exit 0.
- `git diff --check` — clean.

## Lane Boundary

`build-tested`. headerGreeting is in `Features/Today/`, so no Domain boundary concern. In-place `String(localized:)` wrap is the correct approach.

## Residual Risk

- LLM-drafted translations unverified by a native speaker. "Im Gange" for German "In progress" is correct but may not be the conversational form a native designer would choose.
- The compact and regular branches use distinct keys (`inProgress.compact` / `inProgress.regular`) — semantically the same in English, may diverge in some locales.
- Each branch only renders under specific accessibility/Dynamic Type conditions; full visual proof would require running the simulator in each combination × each of 19 locales.
- Per-locale review return files now 6 entries stale per locale (15 entries stale total since 2026-05-16, counting the prior anchors slice). Run `python3 Tools/localization-return-files-refresh.py --apply` to refresh.
- Native review remains outstanding for every locale.

## Helper-generated-copy queue status

5 of 7 follow-ups remain queued:

| Priority | Slice | Approach |
|---:|---|---|
| 83 | `app-localization-calibration-rules-helper-copy-routing` | structural |
| 82 | `app-localization-readiness-rules-helper-copy-routing` | structural |
| 81 | `app-localization-pattern-nudge-rules-helper-copy-routing` | structural |
| 80 | `app-localization-focus-suggestion-reason-routing` | structural |
| 79 | `app-localization-continue-row-subtitle-routing` | structural |
