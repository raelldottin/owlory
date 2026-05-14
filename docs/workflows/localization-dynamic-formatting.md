# Localization Dynamic Formatting

Use this contract before localizing counts, dates, statuses, notifications, display labels, or interpolated copy. The goal is to keep localization work readable without moving presentation concerns into pure product rules.

## Boundary Rule

```text
Domain returns meaning.
Application coordinates runtime-owned messages.
SwiftUI presents localized display text.
```

Layer ownership:

- `Core/Domain`: enums, IDs, counts, dates, windows, statuses, and other semantic values. No SwiftUI, UserNotifications, presentation copy ownership, or localized string construction.
- `Core/Application`: runtime orchestration and application-owned messages. Notification planning/copy may live here or in runtime adapters when scheduling side effects require it, but application code should not become a dumping ground for screen labels.
- `Features`: screen-facing localization, visible plural/display formatting, accessibility presentation text, `String(localized:)`, `LocalizedStringResource`, `FormatStyle`, and `.stringsdict` use.
- UI-adjacent formatting helpers: allowed only when boring and reusable. They may format semantic values for display, but must not encode product rules.

## API Guidance

- Static visible copy: keep using `Localizable.strings` and SwiftUI literal localization where the string is direct, stable, and already covered by parity checks.
- Counts and plurals: use `.stringsdict` or a localized plural API. Do not build product copy with `"\(count) item(s)"`, manual singular/plural branches in views, or English-only suffixes.
- Dates and week labels: use `Date.FormatStyle`, `DateIntervalFormatStyle`, or existing formatter helpers with explicit calendar/time-zone context when the product rule already carries one.
- Dynamic screen copy: pass semantic values from domain/application layers and format them in `Features` or a UI-adjacent presentation helper.
- Notifications: localize titles and bodies in the reminder/runtime application path that owns notification scheduling. Keep `UserNotifications` and notification copy out of `Core/Domain`.
- Model display names: map enums/statuses/source types to localized display text in a presentation adapter outside pure domain code. Do not add localized labels directly to domain models.

## Implementation Batches

| Batch | Owner | Recommended API | Validation | Risk | Out of scope |
| --- | --- | --- | --- | --- | --- |
| Today dashboard count/plural strings | Today feature views or a Today UI formatting helper | `.stringsdict` for counts; `LocalizedStringResource` or `String(localized:)` for dynamic labels; accessibility text from the same localized values | `make localization-check`; `make architecture`; `make test-domain DOMAIN=today` when Today code changes; unsigned build for SwiftUI source edits | High-visibility dashboard copy and accessibility interpolation can drift from visual text | Translation quality and Today product-rule changes |
| Digest count/date labels | Digest presentation in Today/Patterns UI; digest domain rules keep semantic counts/dates | `.stringsdict` for counts; `Date.FormatStyle` or `DateIntervalFormatStyle` with explicit calendar/time-zone context | `make localization-check`; `make architecture`; digest/pattern domain tests when rules are touched; unsigned build for UI source edits | Calendar semantics must stay aligned with digest content generation | Weekly digest cadence, stale counting, and digest product-rule refactors |
| Protocol schedule/status text projection | Home feature presentation or a Home UI projection helper; protocol rules keep schedule/window/status meaning | Localized projection from semantic schedule/status values; `.stringsdict` for duration/count phrases | `make localization-check`; `make architecture`; `make test-domain DOMAIN=home` when Home code changes | Existing schedule/status `String` helpers may need careful migration to preserve visible behavior | Protocol lifecycle, scheduling behavior, archive behavior, and copy rewrites |
| Notification titles/bodies | Reminder scheduler/application runtime path | `String(localized:)`/`NSLocalizedString` from runtime-owned notification keys; localized arguments for item titles/counts; notification-specific tests | `make localization-check`; `make architecture`; reminder domain/runtime tests when scheduling code changes | Notifications are not SwiftUI surfaces and can regress silently without tests | Reminder timing, suppression, delivery policy, and device notification proof |
| Domain model display-name adapters | Feature presentation adapters or small UI-adjacent formatting helpers | Enum/status/source-type to `LocalizedStringResource` or localized `String` outside `Core/Domain` | `make localization-check`; `make architecture`; affected domain tests when adapters replace existing helpers | Many callers may depend on existing English helper strings | Enum renames, persistence migration, and data-model behavior changes |

## Queue Order

Recommended implementation order:

1. `app-localization-today-plurals` - implemented for the Today dashboard card summaries and readiness-scale accessibility interpolation.
2. `app-localization-digest-formatting` - implemented for weekly digest presentation counts, ratios, compact streaks, relative labels, and week-range labels.
3. `app-localization-protocol-schedule-projection` - implemented for Home protocol schedule row labels and schedule-picker help text.
4. `app-localization-notification-copy` - implemented for delivered prediction, Today prompt, and protocol schedule notification titles/bodies.
5. `app-localization-display-name-adapters` - implemented for the first low-risk presentation adapters: LifeDomain labels in Today and digest presentation, Focus/previous-day statuses in Today history, TrainingStatus labels in Train, WritingStage/WritingSourceType labels in Write, and CareerRecordType labels in Career/Today quick capture.
6. `app-localization-recurrence-interval-formatting` - implemented for recurring task/session interval copy. `recurrence.interval.days` (one/other plural) and `recurrence.interval.compact` (single form) in `Localizable.stringsdict`, routed through `Core/Application/RecurrenceIntervalPresentation.swift`; the six HomeView/TodayView/TrainView call sites that previously interpolated `"Every n day(s)"` inline now use the presentation helper. Domain models keep `recurrenceIntervalDays: Int?` semantic; localization stays in the presentation layer.
7. `app-localization-readiness-summary-formatting` - implemented for readiness summary copy. Added `readiness.checkin.summary.*` (tap / tap.compact / strong / strong.compact / low / low.compact / mixed), `readiness.axis.tier.*` (low / okay / high format strings using `%@`), `readiness.summary.tier.*` (Train compact form), and `readiness.session.readout` (Train readout using `%d`) keys to `Localizable.strings` across all 19 locales. Routed through `Core/Application/ReadinessSummaryPresentation.swift` with `todayCheckInLabel(energy:mood:sleep:layout:)`, `trainingReadinessSummary(for:)`, and `sessionReadinessReadout(level:)`. `TodayView.readinessSummaryLabel` and `TrainView.trainingReadinessSummary(for:)` plus the Train session-card readout now delegate to the helper. Domain ints stay semantic; layout flags (`usesAccessibilityCompactHeader`, `usesCompactHeightAccessibilityLayout`) are passed through unchanged.
8. `app-localization-digest-insight-summary-formatting` - implemented for weekly digest insight and highlight summaries. Refactored `WeeklyDigestRules` to emit semantic data: `generateInsight` now writes a `WeeklyDigest.InsightKind` rawValue into `keyInsight`, `bestDayHighlight` populates `doneCount`/`plannedCount` on `DayHighlight`, and `hardestDayHighlight` populates `readinessBand`. WeeklyDigest model carries optional structured fields with backwards-compatible Codable decoding (old digests on disk continue to read their pre-composed English `summary` and fall through). Added `WeeklyDigestPresentationFormatting.bestDayHighlightSummary(_:calendar:)`, `hardestDayHighlightSummary(_:calendar:)`, and `keyInsightLabel(_:)`. Added keys `weeklyDigest.highlight.bestDay.summary` (`%@: %d of %d completed`), `weeklyDigest.highlight.hardestDay.summary.{low,moderate}`, and one `weeklyDigest.insight.*` key per InsightKind case (8 total). The three call sites in DigestDetailView (best/hardest summary text and keyInsight text) now use the helpers. WeeklyDigestRulesTests assertions for `bestDay.summary.contains` and `keyInsight.contains` were updated to assert on structured fields and rawValue equality; the calendar-handling test now asserts that the DayHighlight date is preserved and that the two calendars assign that date different weekday components.
9. `app-localization-home-action-accessibility-formatting` - implemented for the Home-action accessibility labels surfaced by the accessibility-interpolation audit (Group A). Added seven `%@`-format keys (`home.task.accessibility.{edit,skip,markComplete,markIncomplete,restore}` and `home.protocol.step.accessibility.{complete,skip}`) in `Localizable.strings` and routed five HomeView call sites through `Core/Application/HomeAccessibilityLabels.swift`: the Edit task swipe action, the Skip task swipe action, `leadingButtonAccessibilityLabel` (three branches: Mark complete / Mark incomplete / Restore), the Complete protocol step swipe action, and the Skip protocol step swipe action. Domain models are unchanged. Audit Groups B (VoiceCaptureButton + AudioPlaybackButton state phrases), C (Train readiness scale row), and D (BuildInfoView label:value diagnostic) remain documented but unqueued.

Keep each implementation batch narrow. Add English source keys first, mirror keys across every locale, and leave non-English values as English placeholders until a translation-quality slice replaces them.

## Verification

For this planning contract:

```bash
make architecture
make localization-check
./Tools/validate.sh localization
make automation-check
```

For implementation batches, also run the affected domain command and an unsigned simulator build when SwiftUI or Xcode resource packaging changes.
