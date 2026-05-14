# app-localization-readiness-summary-formatting

## Prompt

Second dynamic-formatting slice off the deferred bucket. Route readiness summary copy (Today check-in header label, per-axis Energy/Mood/Sleep tier phrases, Train summary, Train session readout) through localization keys and a shared presentation helper. Keep domain rules semantic. Do not translate non-English values; do not touch digest insight copy.

## Files Edited

- `owlory_xcode/Owlory/Resources/en.lproj/Localizable.strings` — added 14 readiness.* keys.
- 18 non-English `.lproj/Localizable.strings` files — same keys with English placeholder values for parity.
- `owlory_xcode/Owlory/Core/Application/ReadinessSummaryPresentation.swift` — new helper exposing `todayCheckInLabel(energy:mood:sleep:layout:)`, `trainingReadinessSummary(for:)`, and `sessionReadinessReadout(level:)` plus an internal `CheckInLayout` struct and a private `axisTier` helper.
- `owlory_xcode/Owlory.xcodeproj/project.pbxproj` — registered the new Swift file (PBXBuildFile A081, PBXFileReference A180, group child, Sources build phase).
- `owlory_xcode/Owlory/Features/Today/TodayView.swift` — `readinessSummaryLabel` now delegates to the helper.
- `owlory_xcode/Owlory/Features/Train/TrainView.swift` — `trainingReadinessSummary(for:)` is a thin pass-through; session-card readonly readout calls `sessionReadinessReadout(level:)`.
- `docs/workflows/localization-string-inventory.md` — moved readiness summaries out of the deferred bucket.
- `docs/workflows/localization-dynamic-formatting.md` — added queue-order entry (#7).
- `automation/queue/slices.json` — slice classified, then flipped to `done`.
- `automation/handoffs/20260514T135404Z-app-localization-readiness-summary-formatting.json`
- `SecondBrain/INDEX.md`
- `SecondBrain/sessions/2026-05-14/095404-app-localization-readiness-summary-formatting.md`

## Key map

- `readiness.checkin.summary.tap` / `.tap.compact` — "Tap to check in" / "Check in now"
- `readiness.checkin.summary.strong` / `.strong.compact` — "Feeling strong today" / "Strong today"
- `readiness.checkin.summary.low` / `.low.compact` — "Low reserves today" / "Low reserves"
- `readiness.checkin.summary.mixed` — "Mixed readiness"
- `readiness.axis.tier.low` / `.okay` / `.high` — `"%@ low"` / `"%@ okay"` / `"%@ high"` (axis name supplied by the caller via existing Energy/Mood/Sleep keys)
- `readiness.summary.tier.low` / `.okay` / `.high` — "Readiness low" / "Readiness okay" / "Readiness high"
- `readiness.session.readout` — "Readiness %d/5"

The `·` separator between axis tiers is hardcoded in the helper per the inventory rule (separators are not product copy).

## Validation

- `python3 automation/context/build_context.py --slice-id app-localization-readiness-summary-formatting` — exit 0.
- `python3 automation/supervisor/run_next.py --dry-run` — selected this slice before the work; post-completion returns to clean stop.
- `make architecture` — passed.
- `make localization-check` — passed (19 locales, 296 keys, 13 plural keys; up from 282 keys).
- `make test-domain DOMAIN=today` — TEST SUCCEEDED.
- `make test-domain DOMAIN=train` — TEST SUCCEEDED.
- `make automation-check` — 57 tests passed.
- `xcodebuild build -quiet -project owlory_xcode/Owlory.xcodeproj -scheme Owlory -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/owlory-localization-readiness-build CODE_SIGNING_ALLOWED=NO` — BUILD SUCCEEDED.
- `git diff --check` — clean.

## Lane Boundary

`build-tested`. Swift compiles, key parity is preserved, Today and Train domain test suites pass. Not running-app smoke; not screenshot/device/TestFlight. A user under a non-English locale still sees English placeholder readiness copy, by policy.

## Residual Risk

- Non-English locales render English placeholder text for the new readiness keys; this matches the existing translation-quality policy and is gated on the reviewer-intake workflow.
- The per-axis tier format `"%@ low"` puts the axis name first. Some target languages may prefer reversed order ("low Energy"); reviewers can rewrite the format string in their `.lproj/Localizable.strings` without code changes.
- I did not exercise the new copy under the all-locale screenshot harness; the existing launch-surface screenshots show the Today dashboard's check-in section in a near-default state (no readiness signal), where the rendered label is "Tap to check in" — visually unchanged.
- Today's `readinessSummaryLabel` is now an indirection through the helper. The helper computes the same branching that TodayView used to do inline; tests that target the literal strings produced by `readinessSummaryLabel` should still pass because the rendered English text is identical.
- The Train session card readout text rendering is unchanged ("Readiness 4/5"); only the localization plumbing differs.

## Notes For Next Slice

The remaining deferred dynamic-formatting buckets are now narrowed to:

- Weekly digest insight/highlight summaries (DigestListView/DigestDetailView interpolations).
- Remaining model-backed accessibility interpolation outside Today readiness scale (which already uses the `today.readiness.scale.accessibility` stringsdict).

Pick one explicitly before reopening the queue.
