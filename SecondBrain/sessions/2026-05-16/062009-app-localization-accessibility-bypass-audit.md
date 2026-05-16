# app-localization-accessibility-bypass-audit

## Prompt

> "start app-localization-accessibility-bypass-audit" — keep it audit-first; do not do another broad regex pass; queue narrow implementation slices only where needed.

## What was done

Wrote `/tmp/owlory_accessibility_audit.py` — scans `.accessibilityLabel(...)` / `.accessibilityHint(...)` / `.accessibilityValue(...)` call sites under `owlory_xcode/Owlory/` and `owlory_xcode/OwloryWidgets/` in both literal and variable forms, with a 3-line context snippet.

Then manually traced each variable-form finding to its upstream definition (computed property / helper function / store-derived value) to determine whether the value is already routed through `NSLocalizedString` / `String(localized:)` upstream.

## Findings (22 total)

| Pattern | Count |
|---|---:|
| `.accessibilityLabel("Lit")` | 9 |
| `.accessibilityLabel(var)` | 7 |
| `.accessibilityHint("Lit")` | 3 |
| `.accessibilityHint(var)` | 2 |
| `.accessibilityValue("Lit")` | 1 |

## Classification (9 variable sites)

| Site | Upstream | Verdict |
|---|---|---|
| `AudioPlaybackButton.swift:16` | `accessibilityText: String` returns hardcoded English | **real-bypass** |
| `VoiceCaptureButton.swift:44` | `accessibilityText: String` returns hardcoded English | **real-bypass** |
| `HomeView.swift:496` `leadingButtonAccessibilityLabel` | wraps `HomeAccessibilityLabels.*` | already-safe |
| `HomeView.swift:532` `HomeAccessibilityLabels.taskEdit(title:)` | `NSLocalizedString` + `localizedStringWithFormat` | already-safe |
| `HomeView.swift:550` `HomeAccessibilityLabels.taskSkip(title:)` | same | already-safe |
| `HomeView.swift:1133` `HomeAccessibilityLabels.protocolStepComplete(title:)` | same | already-safe |
| `HomeView.swift:1163` `HomeAccessibilityLabels.protocolStepSkip(title:)` | same | already-safe |
| `TodayView.swift:269` `continueAccessibilityHint(for:)` | `NSLocalizedString` + `localizedStringWithFormat` + `localizedDisplayName` | already-safe |
| `WriteView.swift:188` `writeRowAccessibilityHint(for:)` | `NSLocalizedString` + `localizedStringWithFormat` + `String(localized:)` | already-safe |

**Result:** 7 of 9 variable sites are already correctly localized through helpers; 2 are real bypasses, both in `DesignSystem/` audio/voice buttons.

## Classification (13 literal sites)

11 already-safe (key exists + SwiftUI `LocalizedStringKey` overload), 1 interpolation-pattern bypass already covered by the queued `app-localization-string-interpolation-formatters` slice (`TrainView.swift:516` — `"\(label), \(value) of 5"`), 1 acceptable-as-is (`BuildInfoView.swift:102` — `"\(label): \(value)"` displays developer fields).

## Files Edited

- `docs/workflows/localization-accessibility-bypass-audit.md` — **new file**. The catalog.
- `automation/queue/slices.json` — flipped `app-localization-accessibility-bypass-audit` to `done`; queued 1 follow-up `app-localization-audio-voice-button-accessibility-routing`.
- `automation/handoffs/20260516T062009Z-app-localization-accessibility-bypass-audit.json` — new handoff.
- `SecondBrain/INDEX.md` — index entry.
- `SecondBrain/sessions/2026-05-16/062009-app-localization-accessibility-bypass-audit.md` — this note.

## Follow-up queued

| Slice | Scope | Estimated new keys |
|---|---|---:|
| `app-localization-audio-voice-button-accessibility-routing` | Wrap `AudioPlaybackButton.accessibilityText` and `VoiceCaptureButton.accessibilityText` switch returns in `NSLocalizedString` / `String(localized:)` + `String.localizedStringWithFormat` for the two `%@`-interpolated error cases. | ~7 new keys × 19 locales (LLM-drafted) |

The follow-up's allowed_paths is intentionally narrow to the 2 DesignSystem files plus Localizable.strings. No view code, no helper changes elsewhere.

## What this audit reveals about the broader NLS state

The 2026-05-16 visible-string audit flagged ~10 accessibility var-bypasses as candidates. This deeper audit found **only 2** are real bypasses. The other 7 are correctly routed through helpers that the visible-string audit could not statically trace. So the accessibility-bypass risk is much smaller than the visible-string audit suggested. The same pattern likely applies elsewhere: helpers like `HomeAccessibilityLabels` and `*AccessibilityHint(for:)` are doing the right thing, and call-site-level audits over-flag without upstream tracing.

## Validation

- `python3 automation/context/build_context.py --slice-id app-localization-accessibility-bypass-audit` — exit 0.
- `python3 automation/supervisor/run_next.py --dry-run` — selected this slice at start.
- `make architecture` — passed.
- `make localization-check` — 19 / 316 / 13.
- `./Tools/validate.sh localization` — passed.
- `make automation-check` — 57/57.
- `git diff --check` — clean.

## Lane Boundary

`doc-only`. No view code, resources, or helper code touched. No native-review claim. No `provenance.native_reviewed` flag flipped for any locale.

## Residual Risk

- Static + manual trace; VoiceOver runtime output not verified per locale.
- The `BuildInfoView` `"\(label): \(value)"` line is classified acceptable-as-is. If a future locale needs different punctuation, it would resurface.
- The follow-up slice will add 7 new keys + 2 `%@`-formatted patterns; preserving parity will require LLM-draft values for all 19 locales.
- Native review remains outstanding for every locale.
