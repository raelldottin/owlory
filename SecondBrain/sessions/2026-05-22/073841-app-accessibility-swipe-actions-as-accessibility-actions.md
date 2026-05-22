# app-accessibility-swipe-actions-as-accessibility-actions

## Prompt

> "start next slice" (after the accessibility survey landed and queued 5 follow-up fix slices)

Supervisor pick: lowest-priority among queued fix slices (pri 76). Largest concrete user-impact gap — 12 swipe actions were invisible to Switch Control + VoiceOver users.

## What was done

Added `.accessibilityActions { ... }` (SwiftUI ViewBuilder form, iOS 17+) alongside the existing `.swipeActions` blocks at all 12 swipe-action sites. Switch Control users can now reach the actions via tab traversal and VoiceOver users can invoke them via the rotor (`Actions`).

### Site-by-site

| File | Row | Actions added |
| --- | --- | --- |
| WriteView | note row | Advance (conditional), Delete (destructive), Archive (conditional) |
| WriteView | archive note row | Restore, Delete (destructive) |
| HomeView | protocol row | Edit |
| HomeView | archived protocol row | Restore |
| HomeView | active run row | Abandon (destructive) |
| HomeView | task row | Delete (destructive) |
| HomeView | protocol step row | Mark Pending (conditional on `step.status != .pending`) |
| TodayView | continue row | Done OR Add to Focus (primary, conditional), Defer (conditional), Drop (destructive, conditional) |
| CareerView | record row | Delete (destructive) |

### Today's continue row got a builder

The existing `continuePrimarySwipeActions(for:)` and `continueStatusSwipeActions(for:)` ViewBuilders each contain conditional branches based on focus state. To keep the accessibility-actions parallel structure intact, added a `continueAccessibilityActions(for:)` builder that:

- Emits `Done` when there's a focus item and it's not done.
- Emits `Add to Focus` otherwise, when `store.canAddContinueItemToFocus(item)` is true.
- Emits `Defer` and `Drop` (destructive) for the focus-item path, gated on the same status checks the swipe-action builder uses.

Future changes to either swipe-action builder must be mirrored in the new one. Named as a residual risk in the handoff.

### Approach

- **ViewBuilder form, not chained modifier.** `.accessibilityActions { ... }` (iOS 17+) accepts `if` statements inside the closure. That lets the accessibility-action structure mirror the swipe-action conditional structure exactly, without needing per-site custom view modifiers or `.modifier(...)` tricks.
- **Reuse existing localized strings.** Every action label uses the same `L(...)` string that the swipe-action button uses. No new localization keys; `make localization-check` shows 386 keys (unchanged).
- **Reuse role: .destructive.** Where the swipe button has `role: .destructive`, the accessibility action passes the same role so VoiceOver's destructive treatment applies in the rotor.
- **Real compile-check.** Ran `xcodebuild build-for-testing` end-to-end — TEST BUILD SUCCEEDED. SourceKit's editor diagnostics flagged spurious "Cannot find type X in scope" warnings during the edits; the real swiftc pass had zero errors.

### Files touched (8 of 12 cap)

1. `owlory_xcode/Owlory/Features/Write/WriteView.swift` — 2 sites
2. `owlory_xcode/Owlory/Features/Home/HomeView.swift` — 5 sites
3. `owlory_xcode/Owlory/Features/Today/TodayView.swift` — 1 site + new builder
4. `owlory_xcode/Owlory/Features/Career/CareerView.swift` — 1 site
5. `automation/queue/slices.json` — slice marked done
6. `automation/handoffs/20260522T073841Z-app-accessibility-swipe-actions-as-accessibility-actions.json`
7. `SecondBrain/INDEX.md`
8. `SecondBrain/sessions/2026-05-22/073841-app-accessibility-swipe-actions-as-accessibility-actions.md`

## Validation

- `git fetch origin main` — fetched.
- `xcodebuild -project owlory_xcode/Owlory.xcodeproj -scheme Owlory build-for-testing` — TEST BUILD SUCCEEDED.
- `python3 automation/context/build_context.py --slice-id app-accessibility-swipe-actions-as-accessibility-actions` — built.
- `python3 automation/supervisor/run_next.py --dry-run` — picks the next accessibility fix slice.
- `make architecture` — passed.
- `make localization-check` — 19 locales, 386 keys, 13 plural keys (unchanged).
- `make automation-check` — 124 tests OK.
- `make pyright` — 0 errors.
- `git diff --check` — clean.

## Lane Boundary

`build-tested`. Swift source change in 4 feature views + queue/handoff/INDEX/session. No localization changes (no new keys). No accessibility-survey manifest change.

## Not Claimed

- On-device behavior under VoiceOver, Switch Control, or Voice Control has been verified. xcodebuild succeeded but runtime accessibility behavior under each AT was not exercised.
- Voice Control commands work cleanly for these actions. The same labels are used as Button labels, which means Voice Control will still announce / accept the full localized string. Short verb-noun aliases would help — that work belongs to `app-accessibility-voice-control-input-labels` (still queued).
- Each accessibilityAction is strictly necessary. Some rows already have tappable buttons for related (but not identical) actions; in those cases the accessibilityAction adds the swipe-only action. Per-site verification confirmed swipe-only-ness, but a future redesign could make some entries redundant.

## Next

Supervisor's next pick is `app-accessibility-reduce-motion-helper` (pri 77) — 5 unguarded animation sites in AppTheme + TodayView + TrainView.
