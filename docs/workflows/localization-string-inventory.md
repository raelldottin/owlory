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
- Translation quality contract: [Localization Translation Quality](localization-translation-quality.md).

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

- Dynamic/pluralized copy such as previous-day record counts, non-Today-dashboard readiness/accessibility interpolation, and digest insight/highlight summaries still needs `.stringsdict`, explicit localized formatting, or a separate presentation-adapter slice. Recurrence-interval copy (`Every n day(s)` and the compact `Every nd` badge) is now backed by `recurrence.interval.days` and `recurrence.interval.compact` in `Localizable.stringsdict` and routed through `RecurrenceIntervalPresentation`; it is no longer in the deferred bucket.
- Readiness summaries (Today check-in header label and Train session readiness summary/readout) are now backed by `readiness.checkin.summary.*`, `readiness.axis.tier.*`, `readiness.summary.tier.*`, and `readiness.session.readout` keys and routed through `ReadinessSummaryPresentation`. Weekly digest insight and highlight summaries now flow through `WeeklyDigest.InsightKind`, the structured `DayHighlight` fields (`doneCount`, `plannedCount`, `readinessBand`), and `WeeklyDigestPresentationFormatting`'s `bestDayHighlightSummary`, `hardestDayHighlightSummary`, and `keyInsightLabel`; the eight `weeklyDigest.insight.*` keys and the three `weeklyDigest.highlight.{bestDay,hardestDay}.summary*` keys cover the rendered sentences. Both buckets are no longer deferred.
- Remaining accessibility-label interpolations are audited (see [Accessibility Label Interpolation Audit](#accessibility-label-interpolation-audit) below). Concrete gaps remain in four thematic groups; the first (Home action labels) is queued as `app-localization-home-action-accessibility-formatting`. The rest are documented but not yet queued.
- Notification preference UI, delivered-notification locale smoke, and real device notification proof remain separate validation slices.
- SF Symbol names, color asset names, telemetry event names, URL routes, storage directories, date format tokens, and separators are not product copy.

Use [Localization Dynamic Formatting](localization-dynamic-formatting.md) before extracting any deferred dynamic bucket. It defines which layer owns counts, dates, notification copy, and model display labels so future implementation slices do not leak UI copy into domain rules.

Use [Localization Translation Quality](localization-translation-quality.md) before replacing non-English placeholder values. It defines placeholder status, reviewer expectations, locale-specific risks, and the proof required before claiming translation quality.

## Accessibility Label Interpolation Audit

Recorded by `app-localization-accessibility-interpolation-audit` on 2026-05-14. The audit walked every `.accessibilityLabel`, `.accessibilityValue`, and `.accessibilityHint` call in the Owlory app target (25 sites) and classified each one.

### Already localized (12 sites)

- Literal-key direct hits: `Capture new note`, `Note options`, `Add task or protocol`, `Opens task details.`, `Add career record`, `Open build info`, `Plan training session`, `Shows the app version, build number, and git commit for bug reports.`, `Copies the full build identity to the clipboard so you can paste it into a bug report.` — all matched by existing entries in `en.lproj/Localizable.strings`.
- Helper-routed: `writeRowAccessibilityHint` (uses `write.row.accessibility.advanceHint` / `.defaultHint`), `continueAccessibilityHint` (uses `today.continue.accessibility.{focusStatusActions,addToFocus,openDomain}`), `readinessScaleAccessibilityLabel` (uses `today.readiness.scale.accessibility{,.selected}` stringsdict), `trainingStatusAccessibilityLabel` (uses `display.trainingStatus.accessibility{,.selected,.status}`).

### Real gaps — concrete groups for follow-up slices

**Group A — Home action accessibility labels (queued as `app-localization-home-action-accessibility-formatting`):**

- `HomeView.swift:529` `"Edit \(task.title)"`
- `HomeView.swift:547` `"Skip \(task.title)"` (top-level Home task swipe action)
- `HomeView.swift:577-585` `leadingButtonAccessibilityLabel`: `"Mark \(task.title) incomplete"`, `"Restore \(task.title)"`, `"Mark \(task.title) complete"`
- `HomeView.swift:1123` `"Complete \(step.title)"` (protocol step swipe action)
- `HomeView.swift:1152` `"Skip \(step.title)"` (protocol step swipe action)

All five live in `HomeView`, all interpolate a task or step title into a verb phrase. Implementation: add `%@`-format keys (`home.task.accessibility.edit`, `.skip`, `.markComplete`, `.markIncomplete`, `.restore`, `home.protocol.step.accessibility.complete`, `.skip`) and route through a `HomeAccessibilityLabels` helper.

**Group B — Voice / Audio button accessibility (not queued):**

- `VoiceCaptureButton.swift:70-76 accessibilityText` returns `Start voice capture`, `Stop recording`, `Transcribing`, `Voice capture complete`, and `Error: \(msg)` for an interpolated transcription error. None are in `Localizable.strings`.
- `AudioPlaybackButton.swift:40-46 accessibilityText` returns `Play recording`, `Stop playback`, `Playback error: \(msg)`. None are in `Localizable.strings`.

These are DesignSystem-scoped. A `voice.capture.accessibility.*` / `audio.playback.accessibility.*` key set plus a small helper (or inline `String(localized:)` calls) closes the gap. The error-state interpolations need `%@` format strings.

**Group C — Train readiness scale row accessibility (not queued):**

- `TrainView.swift:494` per-button: `"\(label) \(level) of 5\(level == value ? ", selected" : "")"`.
- `TrainView.swift:498` container: `"\(label), \(value) of 5"`.

Same shape as `today.readiness.scale.accessibility{,.selected}` stringsdict. The implementation can either reuse those keys (the contract is identical) or add a parallel `train.readiness.scale.accessibility{,.selected}` pair for clarity. The `.accessibilityValue("\(value)")` at line 499 is a bare numeric value — Apple expects raw values here and it does not need localization.

**Group D — BuildInfoView label:value accessibility (not queued):**

- `BuildInfoView.swift:102` `"\(label): \(value)"` combines a Build Info field label with its value into a single accessibility label. The label is itself a translated string (Version, Build, Git commit, etc.) but the colon separator and the order are hardcoded. Low priority — Build Info is engineering diagnostic copy and the colon-separated form reads naturally in most locales.

### System-generated / not product copy

- `TrainView.swift:499` `.accessibilityValue("\(value)")` — bare integer; SF Symbol-style. No translation needed.
- `.accessibilityIdentifier(...)` modifiers everywhere are test selectors, not user-facing copy, and were intentionally excluded from this audit.

### Summary

| Category | Sites |
| --- | --- |
| Already localized | 12 |
| Real gaps (Group A queued, B/C/D documented) | 10 |
| System-generated | 1 (`.accessibilityValue` on Train readiness) |
| Total accessibility modifier sites in app target | 25 (test target excluded) |

## Verification

Use:

```bash
make localization-check
./Tools/validate.sh localization
make architecture
```

Run an unsigned simulator build when changing Xcode localization packaging or when a string extraction slice also edits Swift source.
