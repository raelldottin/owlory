# app-localization-recurrence-interval-formatting

## Prompt

First dynamic-formatting slice off the deferred bucket: route the six "Every n day(s)" / "Every nd" copy sites through plural-aware `Localizable.stringsdict` entries and a shared presentation helper. Keep domain rules semantic; do not translate non-English values.

## Files Edited

- `owlory_xcode/Owlory/Resources/en.lproj/Localizable.stringsdict` — added `recurrence.interval.days` (one/other) and `recurrence.interval.compact` (single form).
- 18 non-English `.lproj/Localizable.stringsdict` files mirrored with the same English placeholder values, preserving locale parity (`ar`, `nl`, `fr`, `de`, `it`, `ja`, `ko`, `nb`, `pt`, `pt-BR`, `ru`, `es`, `sv`, `zh-Hans`, `zh-Hant`, `tr`, `uk`, `vi`).
- `owlory_xcode/Owlory/Core/Application/RecurrenceIntervalPresentation.swift` — new helper with `longLabel(days:)` and `compactBadge(days:)`.
- `owlory_xcode/Owlory.xcodeproj/project.pbxproj` — added the new Swift file as a PBXBuildFile, PBXFileReference, group child, and Sources build phase entry (matches the OwloryUITestSupport.swift pattern).
- `owlory_xcode/Owlory/Features/Home/HomeView.swift` — three sites: add-task sheet stepper, edit-task sheet stepper, recurring-row compact badge.
- `owlory_xcode/Owlory/Features/Today/TodayView.swift` — one site: quick-capture sheet stepper.
- `owlory_xcode/Owlory/Features/Train/TrainView.swift` — two sites: plan-session sheet stepper, session-card recurring badge.
- `docs/workflows/localization-string-inventory.md` — moved recurrence-interval copy out of the deferred bucket.
- `docs/workflows/localization-dynamic-formatting.md` — added a new queue-order entry recording the implementation.
- `automation/queue/slices.json` — slice classified, then flipped to `done`.
- `automation/handoffs/20260514T122207Z-app-localization-recurrence-interval-formatting.json`
- `SecondBrain/INDEX.md`
- `SecondBrain/sessions/2026-05-14/082207-app-localization-recurrence-interval-formatting.md`

## Pattern

```swift
// before
Stepper("Every \(recurrenceDays) days", value: $recurrenceDays, in: 1...365)

// after
Stepper(value: $recurrenceDays, in: 1...365) {
    Text(RecurrenceIntervalPresentation.longLabel(days: recurrenceDays))
}
```

`RecurrenceIntervalPresentation` calls `String.localizedStringWithFormat(NSLocalizedString("recurrence.interval.days", comment: …), days)` so the runtime resolves through `Localizable.stringsdict`'s plural rules. The compact badge form mirrors the existing `weeklyDigest.streak.compact` pattern (single form, no plural variation in the English source) so future locales can pluralize independently.

## Validation

- `python3 automation/context/build_context.py --slice-id app-localization-recurrence-interval-formatting` — exit 0.
- `python3 automation/supervisor/run_next.py --dry-run` — selected this slice before the work; post-completion it returns to clean-stop state.
- `make architecture` — passed.
- `make localization-check` — passed (19 locales, 282 keys, 13 plural keys; up from 11).
- `make test-domain DOMAIN=home` — TEST SUCCEEDED.
- `make test-domain DOMAIN=train` — TEST SUCCEEDED.
- `make automation-check` — 57 tests passed.
- `xcodebuild build -quiet -project owlory_xcode/Owlory.xcodeproj -scheme Owlory -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/owlory-locale-recurrence-build CODE_SIGNING_ALLOWED=NO` — BUILD SUCCEEDED.
- `git diff --check` — clean.

## Lane Boundary

This is `build-tested` — Swift compiles, plural keys exist with parity, domain tests pass for Home and Train. It is not running-app smoke, not screenshot proof, not device proof, not TestFlight proof. A user running the app under a non-English locale still sees English placeholders, by policy.

## Residual Risk

- Non-English locales render English placeholder text for the new keys. That matches the policy in `localization-translation-quality.md`; reviewed translations remain gated on the reviewer-intake workflow.
- I did not exercise the new UI strings under the all-locale screenshot harness; that would be a separate slice if visual verification is needed (the launch surface screenshots already shipped don't drill into the add-task / plan-session sheets where the new copy lives).
- `Stepper("Every \(n) days", value:in:)` previously produced a `LocalizedStringKey` containing the interpolated literal — that key was never present in `Localizable.strings`, so SwiftUI fell back to the rendered literal verbatim. Switching to `Stepper(value:in:label:)` with an explicit `Text` is the deliberate change; this might affect UI-test selectors that targeted the old auto-generated accessibility label string. None of the current XCUITests target those steppers by label.
- The recurring-row compact badge in Home now reads "Every nd" instead of just "nd" — the visual width is slightly larger. Not a regression, but worth knowing for any future screenshot proof packs that captured the old form.
