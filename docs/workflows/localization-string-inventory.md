# Localization String Inventory

Use this inventory before starting translation work. It separates source-string readiness from translation quality so agents do not overclaim localization completeness.

## Current Contract

- Localization foundation: `Implemented`.
- Translation completeness: `Deferred`.
- String extraction completeness: `Partially implemented`.
- Dynamic/plural formatting completeness: `Partially implemented` for Today dashboard summaries, weekly digest presentation count/date labels, Home protocol schedule projection, delivered notification copy, and the first presentation-owned display-name adapter batch.
- English source of truth: `owlory_xcode/Owlory/Resources/en.lproj/Localizable.strings`.
- Validation: `make localization-check` and `./Tools/validate.sh localization`.
- Dynamic formatting contract: [Localization Dynamic Formatting](localization-dynamic-formatting.md).

Non-English locales intentionally keep English placeholder values until a translation-quality slice replaces them.

## Classification Rule

When auditing Swift strings, classify each literal as one of:

- `already localized by SwiftUI literal behavior`: direct literals in `Text`, `Label`, `Button`, `Section`, `DisclosureGroup`, `LabeledContent`, `TextField`, `Picker`, `Toggle`, `Stepper`, `.alert`, `.confirmationDialog`, `.navigationTitle`, `.accessibilityLabel`, or `.accessibilityHint` with a matching English key.
- `should extract now`: direct user-facing literals in those same APIs that are missing from English and do not require copy changes, plural rules, or interpolation changes.
- `accessibility/user-facing but needs careful wording`: spoken labels or hints built from variables or interpolation, where key extraction alone would not prove localized output.
- `debug/dev-only`: build metadata keys, telemetry names, diagnostics, repository/build provenance labels used for engineering diagnosis, or fallback values such as `unknown`.
- `system/generated`: SF Symbols, color asset names, URL schemes, file extensions, date format tokens, separators, and storage directory names.
- `deferred`: dynamic strings returned from domain/application helpers, pluralized/interpolated strings, notification body composition, schedule/readiness summaries, and model display names that need explicit `String(localized:)`, `LocalizedStringKey`, or `.stringsdict` treatment.

## Extracted In This Audit

This pass added 58 low-risk source keys for direct SwiftUI or accessibility literals. Representative groups:

- Update alerts: `Couldn't Update Today`, `Couldn't Update Session`, `Couldn't Update Write`, `Couldn't Update Career`, `Couldn't Update Home`.
- Today dashboard copy: `Focus Suggestions`, `No sessions today`, `No active notes`, `No records yet`, `No home work yet`, `What mattered today?`, `Evening Reflection`, `Browse Previous Days`.
- Digest labels: `Days active`, `Completion`, `Avg readiness`, `Streak`, `Stalled items`, `View all digests`.
- Home/Write sections and actions: `Completed`, `Recent Runs`, `Abandon`, `Archived Notes`, `Source Title`, `Author / Creator`, `Current`, `Edit Note`, `Delete this note?`.
- Accessibility strings: `Open build info`, `Shows the app version, build number, and git commit for bug reports.`, `Opens task details.`, `Copies the full build identity to the clipboard so you can paste it into a bug report.`

The extraction changed only `Localizable.strings` keys and docs; it did not modify product copy or Swift source.

## Dynamic Formatting Implemented

- Today dashboard summary counts for Train, Write, Career, and Home use `Localizable.stringsdict` keys instead of inline singular/plural branches or English suffixes.
- Today readiness scale accessibility labels use the same `Localizable.stringsdict` resource path so spoken dynamic labels can be translated later with the plural resource set.
- Weekly digest presentation counts and labels in Today, digest rows, and digest detail use a Today presentation formatter backed by `Localizable.strings` and `Localizable.stringsdict`. Week-range labels now format dates with the digest calendar/time-zone in presentation code; digest cadence, stale counting, insight text, and rule-version behavior remain domain-owned and unchanged.
- Home protocol schedule row labels and schedule-picker help text use Home presentation formatting backed by `Localizable.strings`. `ProtocolScheduleRules` now returns semantic preset/date/status summaries instead of English display strings.
- Delivered local notification titles and bodies use `ReminderNotificationCopy` in the reminder application layer. Prediction reminders, Today prompt notifications as scheduled, and protocol schedule notifications are backed by `Localizable.strings`; reminder timing, suppression, dedupe, deep links, and protocol schedule rules remain unchanged.
- Presentation-owned display-name adapters now localize the first low-risk enum/status label batch outside pure domain models: LifeDomain labels in Today and digest presentation, Focus/previous-day statuses in Today history, TrainingStatus labels in Train, WritingStage/WritingSourceType labels in Write, and CareerRecordType labels in Career/Today quick capture. Domain enum raw values and persistence formats remain unchanged.

## Deferred Buckets

- Dynamic/pluralized copy such as `Every <n> day(s)`, previous-day record counts, non-Today-dashboard readiness/accessibility interpolation, and digest insight/highlight summaries still needs `.stringsdict`, explicit localized formatting, or a separate presentation-adapter slice.
- Domain/application `String` values such as readiness summaries, weekly digest insights/highlight summaries, recurrence interval labels, and remaining model-backed accessibility interpolation still need separate code-routing slices before keys alone can affect runtime output.
- Notification preference UI, delivered-notification locale smoke, and real device notification proof remain separate validation slices.
- SF Symbol names, color asset names, telemetry event names, URL routes, storage directories, date format tokens, and separators are not product copy.

Use [Localization Dynamic Formatting](localization-dynamic-formatting.md) before extracting any deferred dynamic bucket. It defines which layer owns counts, dates, notification copy, and model display labels so future implementation slices do not leak UI copy into domain rules.

## Verification

Use:

```bash
make localization-check
./Tools/validate.sh localization
make architecture
```

Run an unsigned simulator build when changing Xcode localization packaging or when a string extraction slice also edits Swift source.
