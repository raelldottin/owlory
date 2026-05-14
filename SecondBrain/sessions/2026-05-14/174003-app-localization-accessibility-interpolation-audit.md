# app-localization-accessibility-interpolation-audit

## Prompt

Inventory remaining `.accessibilityLabel` / `.accessibilityValue` / `.accessibilityHint` interpolations in the Owlory app target. Classify each as already-localized, real gap, system-generated, or deferred. Queue an implementation slice only if concrete gaps remain. Doc-only; do not touch Swift source.

## Method

Grepped all 25 `.accessibility(Label|Value|Hint)` call sites across `owlory_xcode/Owlory` (test target excluded). For each, read the surrounding context and the helper function (if any), then matched against the existing keyset in `en.lproj/Localizable.strings`.

## Findings

**Already localized: 12 sites.** Plain literals matched by existing keys (`Capture new note`, `Note options`, `Add task or protocol`, `Opens task details.`, `Add career record`, `Open build info`, `Plan training session`, two BuildInfoView hint strings) or routed through existing helpers (`writeRowAccessibilityHint`, `continueAccessibilityHint`, `readinessScaleAccessibilityLabel`, `trainingStatusAccessibilityLabel`).

**Real gaps: 10 sites in 4 thematic groups.**

- **Group A** (queued as `app-localization-home-action-accessibility-formatting`) — Home task and protocol-step action accessibility:
  - `HomeView.swift:529` `"Edit \(task.title)"`
  - `HomeView.swift:547` `"Skip \(task.title)"`
  - `HomeView.swift:577-585` `leadingButtonAccessibilityLabel`: three branches (`"Mark \(task.title) complete"`, `"Mark \(task.title) incomplete"`, `"Restore \(task.title)"`)
  - `HomeView.swift:1123` `"Complete \(step.title)"`
  - `HomeView.swift:1152` `"Skip \(step.title)"`

- **Group B** (documented, not queued) — Voice/Audio button state phrases:
  - `VoiceCaptureButton.swift:70-76` 5 state strings, one interpolated error
  - `AudioPlaybackButton.swift:40-46` 3 state strings, one interpolated error

- **Group C** (documented, not queued) — Train readiness scale row accessibility:
  - `TrainView.swift:494` per-button label with conditional ", selected" suffix
  - `TrainView.swift:498` container label
  - Both mirror the existing `today.readiness.scale.accessibility` stringsdict shape

- **Group D** (documented, not queued, low priority) — `BuildInfoView.swift:102` `"\(label): \(value)"` engineering diagnostic line

**System-generated: 1 site.** `TrainView.swift:499` `.accessibilityValue("\(value)")` — bare integer; Apple expects raw values here.

## Files Edited

- `docs/workflows/localization-string-inventory.md` — added the "Accessibility Label Interpolation Audit" section with the inventory and group classifications. Updated the deferred-bucket paragraph to point at the audit.
- `automation/queue/slices.json` — audit slice flipped to `done`; queued the Group A follow-up `app-localization-home-action-accessibility-formatting`.
- `automation/handoffs/20260514T214003Z-app-localization-accessibility-interpolation-audit.json`
- `SecondBrain/INDEX.md`
- `SecondBrain/sessions/2026-05-14/174003-app-localization-accessibility-interpolation-audit.md`

## Validation

- `python3 automation/context/build_context.py --slice-id app-localization-accessibility-interpolation-audit` — exit 0.
- `python3 automation/supervisor/run_next.py --dry-run` — selected this slice before completion; post-completion picks the queued Group A slice next.
- `make architecture` — passed.
- `make localization-check` — passed (19 locales, 307 keys, 13 plural keys; no change in this slice).
- `make automation-check` — 57 tests passed.
- `git diff --check` — clean.

## Lane Boundary

`doc-only`. No Swift source touched; no keys added; no rendered copy changed. The slice's claim is the inventory itself.

## Residual Risk

- Group A is the only follow-up actually queued. Groups B/C/D are documented but their concrete keys/helpers are not yet decided; each will need its own scoped slice when prioritized.
- The audit only inspects the `Owlory` app target. Widget extension and test targets were intentionally excluded — they have separate accessibility concerns.
- I matched literals against `en.lproj/Localizable.strings` for the "already localized" group. SwiftUI's literal-as-key auto-localization makes that match meaningful, but a string passed as a non-literal `String` argument (rather than a `LocalizedStringKey`) bypasses auto-localization even when the same text exists as a key. The audit relies on call-site shape to distinguish; spot-checks confirmed the helper-routed sites use explicit `NSLocalizedString` / `String(localized:)`, but a future regression that converts a literal to a String variable would be missed.
- I did not exercise any UI surface; the audit is static-analysis only.
