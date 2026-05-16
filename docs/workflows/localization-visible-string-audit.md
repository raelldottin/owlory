# Localization Visible-String Bypass Audit

Audit-first inventory of localization bypasses across the Owlory app target.

**Source slice:** `app-localization-visible-string-bypass-audit` (doc-only).
**Method:** static scan of `*.swift` files under `owlory_xcode/Owlory/` and `owlory_xcode/OwloryWidgets/`, regex-matched against SwiftUI initializers that take a title/label/key argument, cross-referenced with `Localizable.strings` keys.
**Scan date:** 2026-05-16.

This report does NOT fix any strings. It catalogs candidates and queues narrow follow-up slices. It does NOT make a translation-quality claim. It does NOT change `provenance.native_reviewed` for any locale.

## Aggregate counts

- Total app-target Swift files scanned: **82**.
- Total candidate visible-string call sites found: **400**.
- `must-fix` (real bypasses): **116**.
- `should-fix` (suspected but not user-reported): **37**.
- `low` / already-OK / debug / intentional-english: **247**.

### By classification

| Classification | Count | Tier |
| --- | ---: | --- |
| `ok-literal-text` | 72 | low/ok |
| `bypass-label-literal` | 60 | must-fix |
| `ok-user-content` | 56 | low/ok |
| `ok-other-literal` | 50 | low/ok |
| `bypass-button-literal-suspect` | 37 | should-fix |
| `ok-localized-display-helper` | 31 | low/ok |
| `bypass-section-literal` | 31 | must-fix |
| `ok-literal-navtitle` | 19 | low/ok |
| `missing-key` | 17 | must-fix |
| `ok-accessibility-literal` | 10 | low/ok |
| `bypass-string-var-true` | 8 | must-fix |
| `intentional-english` | 8 | low/ok |
| `debug-internal` | 1 | low/ok |

### By surface

| Surface | Total | must-fix | should-fix | low/ok |
| --- | ---: | ---: | ---: | ---: |
| Today | 145 | 42 | 9 | 94 |
| Home | 95 | 37 | 9 | 49 |
| Write | 77 | 20 | 12 | 45 |
| Train | 45 | 5 | 3 | 37 |
| Career | 28 | 3 | 4 | 21 |
| Root/Tabs | 5 | 5 | 0 | 0 |
| Widgets | 3 | 2 | 0 | 1 |
| DesignSystem | 2 | 2 | 0 | 0 |

## Classification dictionary

| Classification | Meaning | Tier |
| --- | --- | --- |
| `ok-literal-text` | `Text("...")` with a string literal — SwiftUI routes literals through `LocalizedStringKey`; key exists. | low/ok |
| `ok-literal-navtitle` | `.navigationTitle("...")` literal — routes through `LocalizedStringKey`; key exists. | low/ok |
| `ok-accessibility-literal` | `.accessibilityLabel/Hint/Value("...")` literal — routes through `LocalizedStringKey`; key exists. | low/ok |
| `ok-other-literal` | `TextField/LabeledContent/alert/Picker/Toggle/DisclosureGroup/...` literal — typically routes through `LocalizedStringKey`; key exists. | low/ok |
| `ok-user-content` | Variable passed to `Text(...)` whose value is user-supplied content (note title, task title, transcription, etc.). Should NOT be localized. | low/ok |
| `ok-localized-display-helper` | Variable passed to `Text(...)` whose value comes from an already-localized helper (`stage.localizedDisplayName`, `readinessSummaryLabel`, `nudge.message`, etc.). | low/ok |
| `intentional-english` | Literal matches a brand/format/loanword keep-list (OK, URL, Build, Podcast, Video, Check-in, `%@`, etc.). | low/ok |
| `debug-internal` | Inside `#if DEBUG` or `#Preview` block, or pure punctuation/separator (e.g., `Text("·")`). | low/ok |
| `bypass-section-literal` | `Section("Literal")` initializer — empirical evidence (Batch 7 fixes) that SwiftUI's overload resolution can select the StringProtocol overload here, bypassing `Localizable.strings`. **Confirmed bypass class.** | must-fix |
| `bypass-label-literal` | `Label("Literal", systemImage: "...")` initializer — empirical evidence that SwiftUI's overload resolution prefers the StringProtocol overload due to the second `String` parameter. **Confirmed bypass class.** | must-fix |
| `bypass-string-var-true` | Runtime `String` passed to `Text(...)`/`Label(...)`/`Button(...)`. If the upstream is not already-localized, the visible text will be the raw English string. | must-fix |
| `missing-key` | Literal that does NOT match any existing `Localizable.strings` key. Most are interpolated copy ("Next: %@", "Step N") that should route through a presentation formatter. | must-fix |
| `bypass-button-literal-suspect` | `Button("Literal", action:)` — overload resolution **likely** prefers LocalizedStringKey for single-argument inits, but not user-confirmed. Should be verified during the per-surface fix slice rather than mass-converted. | should-fix |

## User-reported gaps (must-fix, all already covered in prior commit `2dfd2d0`)

| Observed surface | Source | Cause | Status |
| --- | --- | --- | --- |
| Train tab "Training" label (readiness rows) | `TrainView.swift:189, 313` `Label("Training", systemImage:)` | `bypass-label-literal` | Fixed in 2dfd2d0 |
| Train tab first section header | `TrainView.swift:82, 128, 167` `Section("Today" / "History" / "Plan")` | `bypass-section-literal` | Fixed in 2dfd2d0 |
| Home Check-in section labels (Check-in / Energy / Mood / Sleep) | `TodayView.swift` `Label(checkInTitle, systemImage:)` + `readinessRow(label: String) → Label(label, ...)` | `bypass-string-var` (String passed to Label) + missing `Check-in` / `Check in` keys | Fixed in 2dfd2d0; new keys added across 19 locales |
| Home Focus explanation (`Focus lives in Continue. ...`) | `TodayView.swift:279` `Text("...")` literal | `ok-literal-text` per audit; if still observed in non-English locale this is a deeper SwiftUI behavior or simulator cache issue. | Not modified — observe and re-report |
| Write tab first section | `WriteView.swift:122` `Label("Capture a Note", systemImage:)` (empty-state captureSection) | `bypass-label-literal` | Fixed in 2dfd2d0 |

## Per-surface findings

### Today

| classification | count |
| --- | ---: |
| `ok-literal-text` | 29 |
| `ok-localized-display-helper` | 23 |
| `ok-user-content` | 19 |
| `bypass-label-literal` | **19** |
| `bypass-section-literal` | **12** |
| `ok-other-literal` | 10 |
| `bypass-button-literal-suspect` (suspect) | 9 |
| `missing-key` | **8** |
| `ok-literal-navtitle` | 7 |
| `ok-accessibility-literal` | 3 |
| `bypass-string-var-true` | **3** |
| `intentional-english` | 2 |
| `debug-internal` | 1 |

**Top must-fix samples** (deduplicated by visible text):

- `Section-literal` `Version` — `BuildInfoView.swift:24`
- `Section-literal` `Source` — `BuildInfoView.swift:28`
- `accessibilityLabel-literal` `\(label): \(value)` — `BuildInfoView.swift:102`
- `Section-literal` `Overview` — `DigestDetailView.swift:26`
- `LabeledContent-literal` `Stalled items` — `DigestDetailView.swift:48`
- `Section-literal` `Highlights` — `DigestDetailView.swift:58`
- `Section-literal` `Domain Activity` — `DigestDetailView.swift:95`
- `Section-literal` `Insight` — `DigestDetailView.swift:111`
- `Label-systemImage-literal` `Done` — `TodayView.swift:291`
- `Label-systemImage-literal` `Add to Focus` — `TodayView.swift:299`
- `Label-systemImage-literal` `Defer` — `TodayView.swift:312`
- `Label-systemImage-literal` `Drop` — `TodayView.swift:322`
- `Text-var` `item.reason` — `TodayView.swift:387`
- `Text-literal` `\(staleDayCount)d` — `TodayView.swift:395`
- `Text-literal` `Next: \(next.plannedActivity)` — `TodayView.swift:523`
- _… 27 more (see CSV)_

### Home

| classification | count |
| --- | ---: |
| `bypass-label-literal` | **22** |
| `ok-literal-text` | 14 |
| `ok-other-literal` | 13 |
| `ok-user-content` | 12 |
| `bypass-section-literal` | **10** |
| `bypass-button-literal-suspect` (suspect) | 9 |
| `ok-literal-navtitle` | 5 |
| `missing-key` | **5** |
| `ok-accessibility-literal` | 3 |
| `intentional-english` | 1 |
| `ok-localized-display-helper` | 1 |

**Top must-fix samples** (deduplicated by visible text):

- `Label-systemImage-literal` `Add Task` — `HomeView.swift:40`
- `Label-systemImage-literal` `Add Protocol` — `HomeView.swift:45`
- `Label-systemImage-literal` `Add a Task` — `HomeView.swift:133`
- `Section-literal` `Skipped` — `HomeView.swift:180`
- `Label-systemImage-literal` `Add a Protocol` — `HomeView.swift:208`
- `Text-literal` `\(index + 1).` — `HomeView.swift:216`
- `Label-systemImage-literal` `Edit` — `HomeView.swift:234`
- `Label-systemImage-literal` `Restore` — `HomeView.swift:278`
- `Label-systemImage-literal` `Abandon` — `HomeView.swift:351`
- `Label-systemImage-literal` `Protocol Runs` — `HomeView.swift:356`
- `Text-literal` `\(run.completedStepCount)/\(run.totalStepCount) completed` — `HomeView.swift:378`
- `Label-systemImage-literal` `Continue Run` — `HomeView.swift:430`
- `Label-systemImage-literal` `Start New Run` — `HomeView.swift:440`
- `Label-systemImage-literal` `Run Protocol` — `HomeView.swift:450`
- `Label-systemImage-literal` `Skipped` — `HomeView.swift:522`
- _… 22 more (see CSV)_

### Train

| classification | count |
| --- | ---: |
| `ok-literal-text` | 12 |
| `ok-user-content` | 11 |
| `ok-other-literal` | 7 |
| `ok-localized-display-helper` | 3 |
| `bypass-button-literal-suspect` (suspect) | 3 |
| `missing-key` | **3** |
| `ok-literal-navtitle` | 2 |
| `bypass-label-literal` | **2** |
| `ok-accessibility-literal` | 1 |
| `intentional-english` | 1 |

**Top must-fix samples** (deduplicated by visible text):

- `Label-systemImage-literal` `Plan a Session` — `TrainView.swift:91`
- `Label-systemImage-literal` `Add another session` — `TrainView.swift:114`
- `accessibilityLabel-literal` `\(label) \(level) of 5\(level == value ? ` — `TrainView.swift:512`
- `accessibilityLabel-literal` `\(label), \(value) of 5` — `TrainView.swift:516`
- `accessibilityValue-literal` `\(value)` — `TrainView.swift:517`

### Write

| classification | count |
| --- | ---: |
| `ok-literal-text` | 13 |
| `ok-other-literal` | 12 |
| `bypass-button-literal-suspect` (suspect) | 12 |
| `bypass-label-literal` | **11** |
| `ok-user-content` | 8 |
| `bypass-section-literal` | **7** |
| `ok-literal-navtitle` | 4 |
| `intentional-english` | 3 |
| `ok-localized-display-helper` | 3 |
| `ok-accessibility-literal` | 2 |
| `missing-key` | **1** |
| `bypass-string-var-true` | **1** |

**Top must-fix samples** (deduplicated by visible text):

- `Label-systemImage-literal` `Advance` — `WriteView.swift:168`
- `Label-systemImage-literal` `Delete` — `WriteView.swift:177`
- `Label-systemImage-literal` `Archive` — `WriteView.swift:183`
- `Text-literal` `\((store.notesByStage[stage] ?? []).count)` — `WriteView.swift:195`
- `Label-systemImage-literal` `Restore` — `WriteView.swift:231`
- `Section-literal` `Voice Recording` — `WriteView.swift:256`
- `Section-literal` `Content` — `WriteView.swift:437`
- `Section-literal` `Source` — `WriteView.swift:465`
- `LabeledContent-literal` `Type` — `WriteView.swift:467`
- `LabeledContent-literal` `Source Title` — `WriteView.swift:469`
- `LabeledContent-literal` `Author / Creator` — `WriteView.swift:472`
- `Section-literal` `Stage` — `WriteView.swift:487`
- `LabeledContent-literal` `Current` — `WriteView.swift:488`
- `Label-systemImage-literal` `Archive Note` — `WriteView.swift:542`
- `Label-systemImage-literal` `Delete Note` — `WriteView.swift:548`
- _… 5 more (see CSV)_

### Career

| classification | count |
| --- | ---: |
| `ok-other-literal` | 8 |
| `ok-user-content` | 5 |
| `ok-literal-text` | 4 |
| `bypass-button-literal-suspect` (suspect) | 4 |
| `bypass-section-literal` | **2** |
| `ok-literal-navtitle` | 1 |
| `ok-accessibility-literal` | 1 |
| `intentional-english` | 1 |
| `ok-localized-display-helper` | 1 |
| `bypass-label-literal` | **1** |

**Top must-fix samples** (deduplicated by visible text):

- `Label-systemImage-literal` `Delete` — `CareerView.swift:140`
- `Section-literal` `Voice Recording` — `CareerView.swift:193`

### Root/Tabs

| classification | count |
| --- | ---: |
| `bypass-label-literal` | **5** |

**Top must-fix samples** (deduplicated by visible text):

- `Label-systemImage-literal` `Today` — `RootTabView.swift:43`
- `Label-systemImage-literal` `Train` — `RootTabView.swift:55`
- `Label-systemImage-literal` `Write` — `RootTabView.swift:75`
- `Label-systemImage-literal` `Career` — `RootTabView.swift:86`
- `Label-systemImage-literal` `Home` — `RootTabView.swift:105`

### DesignSystem

| classification | count |
| --- | ---: |
| `bypass-string-var-true` | **2** |

**Top must-fix samples** (deduplicated by visible text):

- `accessibilityLabel-var` `accessibilityText` — `AudioPlaybackButton.swift:16`

### Widgets

| classification | count |
| --- | ---: |
| `bypass-string-var-true` | **2** |
| `ok-user-content` | 1 |

**Top must-fix samples** (deduplicated by visible text):

- `Text-var` `primaryText` — `OwloryTodayWidget.swift:98`
- `Text-var` `secondaryText` — `OwloryTodayWidget.swift:101`

## Recommended follow-up slices

Narrow, per-surface implementation slices. Each fixes Section/Label/Button literals and known String-variable bypasses on its surface. Do NOT combine surfaces into one slice.

| Slice ID | Scope | Estimated must-fix count |
| --- | --- | ---: |
| `app-localization-today-shell-copy-routing` | Today tab Section/Label literals + interpolated "Next: %@" patterns + missing-key fixes in `TodayView.swift`, `DigestDetailView.swift`, `DigestListView.swift`, `BuildInfoView.swift`. | 42 |
| `app-localization-home-shell-copy-routing` | Home tab Section/Label literals + interpolated "\\(completedStepCount)/\\(totalStepCount) completed" patterns in `HomeView.swift`. | 37 |
| `app-localization-write-shell-copy-routing` | Write tab Section/Label/Button literals across `WriteView.swift`. | 20 |
| `app-localization-train-shell-copy-routing-followup` | Train tab remaining Section/Label/Button literals beyond what `2dfd2d0` already fixed. | 5 |
| `app-localization-career-shell-copy-routing` | Career tab Section/Label/Button literals in `CareerView.swift`. | 3 |
| `app-localization-root-tab-shell-labels` | Root tab `Label("Train", systemImage: "figure.run")` etc. in `RootTabView.swift`. | 5 |
| `app-localization-widget-shell-strings` | Widget visible strings in `OwloryWidgetsExtension`. | 2 |
| `app-localization-string-interpolation-formatters` | Replace `"Next: \\(x)"` / `"Active protocol: \\(x)"` / `"\\(n)/\\(m) completed"` patterns with presentation formatters in `Core/Application/`. These are dynamic-formatter gaps, not view-layer ones. | ~12 |
| `app-localization-button-literal-verify` | Verify whether `Button("...")` literals actually localize at runtime; if not, convert to explicit `Button { Text("...") } action: { ... }`. Audit-then-fix. | 37 suspect |
| `app-localization-accessibility-bypass-audit` | Verify `.accessibilityLabel/Hint/Value(var)` upstream is already-localized. | 10 accessibility-vars |

## Out-of-scope of follow-up slices

- Native review of any locale. `app-localization-native-review-intake` remains blocked.
- Rewriting product copy. Slices only re-route existing copy; they do not change English source.
- Moving localization into pure domain logic. View-adjacent helpers stay in `Features/` or `Core/Application/`.
- Persistence / model changes. None of these slices touch storage or domain rules.
- Parity check weakening. New keys added by follow-ups must land in all 19 locales (LLM-drafted) and pass `make localization-check`.

## What this audit does NOT prove

- Runtime behavior of every SwiftUI initializer overload — this is a static heuristic. Some `bypass-label-literal` findings may localize correctly in some iOS versions or SDK builds; verification happens in each per-surface fix slice.
- Visual layout of translated text on small screens / Dynamic Type / RTL / CJK.
- Native review of any translated value. All non-English locale values remain LLM-drafted; the per-locale review return files explicitly use `needs-layout-check` / `keep-english-term`, never `native-reviewed`.
- That `Text("Focus lives in Continue. ...")` actually shows German on device — the audit classifies it `ok-literal-text` because the key exists and the SwiftUI initializer is the localizing overload; the user-observed gap, if reproduced, would require simulator-cache reset and re-test.
