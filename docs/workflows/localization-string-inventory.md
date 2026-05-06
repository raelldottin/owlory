# Localization String Inventory

Use this inventory before starting translation work. It separates source-string readiness from translation quality so agents do not overclaim localization completeness.

## Current Contract

- Localization foundation: `Implemented`.
- Translation completeness: `Deferred`.
- String extraction completeness: `Partially implemented`.
- English source of truth: `owlory_xcode/Owlory/Resources/en.lproj/Localizable.strings`.
- Validation: `make localization-check` and `./Tools/validate.sh localization`.

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

## Deferred Buckets

- Dynamic/pluralized copy such as `Every <n> day(s)`, digest item counts, record counts, and readiness/accessibility interpolation needs `.stringsdict` or explicit localized formatting.
- Domain/application `String` values such as readiness summaries, protocol schedule summaries, weekly digest insights, writing-stage titles, and source-type titles need a separate code-routing slice before keys alone can affect runtime output.
- Notification titles and bodies should be localized in the reminder/runtime layer together with notification-specific tests.
- SF Symbol names, color asset names, telemetry event names, URL routes, storage directories, date format tokens, and separators are not product copy.

## Verification

Use:

```bash
make localization-check
./Tools/validate.sh localization
make architecture
```

Run an unsigned simulator build when changing Xcode localization packaging or when a string extraction slice also edits Swift source.
