# Remaining LTR Apple HIG Localized UI Gate

## Scope

This is the Apple Human Interface Guidelines localized UI gate for the seven remaining LTR locales:

- `fr` (French)
- `it` (Italian)
- `nb` (Norwegian Bokmål)
- `pt` (Portuguese, Portugal)
- `pt-BR` (Brazilian Portuguese)
- `es` (Spanish)
- `vi` (Vietnamese)

This gate intake ran on 2026-05-18 under the internal-reviewer signoff baseline recorded in each locale's `localization/review/<locale>/<locale>-review-return.json` (`provenance.internal_reviewer_signoff`). The signoff is the project owner's attestation, not a native or fluent reviewer signoff. See `docs/workflows/localization-translation-quality.md` for the internal-reviewer-signoff label.

## Gate Result

Result: **fail**

Reason: no preserved screenshot evidence for any of the seven locales. Source-trace inspection surfaced one major HIG risk (HIG-FR-001). The remaining six locales have no source-level HIG findings but cannot pass without screenshot evidence for the scoped surfaces.

## Methodology

This gate is doc-only:

1. **Source-trace inspection.** Read each locale's `Localizable.strings` and compared lengths of the tab labels, primary actions (Save / Cancel / Continue), and Build Info row label against English. Recorded the values in `manifest.json` under `source_trace_per_locale`.
2. **Multisurface harness dry-run.** Ran `python3 automation/smoke/capture_localized_surfaces.py --dry-run --locales fr it nb pt pt-BR es vi --surfaces today root-tab-train root-tab-write root-tab-career root-tab-home build-info date-count-plural-today`. The plan reports 49 captures (7 × 7) with `idb + idb_companion ready`. Actual capture is deferred to a separate follow-up slice.
3. **Settled-label inventory.** Noted that the default harness catalog covers `fr` (`Aujourd'hui`), `it` (`Oggi`), `pt` (`Hoje`), `pt-BR` (`Hoje`), `es` (`Hoy`). `nb` (`I dag`) and `vi` (`Hôm nay`) require entries in `--label-overrides` for the `today` surface.

No screenshot binaries are committed in this proof directory, so this remains a doc-only gate.

## Findings

### HIG-FR-001: French Today tab label truncation risk

Severity: **major**
Area: **adaptive-layout**
State: **open**

`owlory_xcode/Owlory/Resources/fr.lproj/Localizable.strings` sets `"Today" = "Aujourd'hui";`. At 11 characters, it is the longest Today tab label across all 19 supported locales (compare: en/de/nb = 5, es = 3, it/pt/pt-BR = 4, vi = 7). Tab-bar truncation is likely on smaller iPhone widths and at larger Dynamic Type settings.

Source trace: `owlory_xcode/Owlory/Resources/fr.lproj/Localizable.strings`.

Remediation options:

- Capture French Today tab screenshots on iPhone SE / standard iPhone portrait and confirm whether the label truncates or shrinks legibly. If truncation is visible, queue a UI tweak slice (likely under `Features/Today/` or shared tab-bar UI) that addresses tab-bar layout, sets a localized abbreviation key, or enables `truncationMode`/`lineLimit` deliberately.
- Add an accessibility identifier to each TabView item so XCUITests can target tabs without relying on translated labels. This also helps `capture_localized_surfaces.py` recipes use `tap_identifier` rather than `tap_label`.

No remediation slice has been queued by this gate. Treat HIG-FR-001 as the seed for a UI-tweak slice triggered after screenshot capture confirms or denies the risk.

## Per-Locale Notes

The full per-locale `source_trace_per_locale` block lives in `manifest.json`. Highlights:

| Locale | Today label | Train label | Build Info label | Notable risk |
|---|---|---|---|---|
| `fr` | `Aujourd'hui` (11) | `Entraîner` | `Infos de version` | **HIG-FR-001** Today tab truncation |
| `it` | `Oggi` (4) | `Allenare` | `Informazioni build` | Build Info row is long; detail row layout should accommodate |
| `nb` | `I dag` (5) | `Tren` | `Build-info` | Translation-quality risk: `Tren` is the noun form (a train), not the verb (to train); NOT a HIG defect |
| `pt` | `Hoje` (4) | `Treinar` | `Info da build` | None at source level |
| `pt-BR` | `Hoje` (4) | `Treinar` | `Info da build` | `Salvar` for Save is correct for Brazil; differs from pt `Guardar` |
| `es` | `Hoy` (3) | `Entrenar` | `Info de build` | None at source level |
| `vi` | `Hôm nay` (7) | `Tập luyện` | `Thông tin bản dựng` | Vietnamese diacritics render wider than character count suggests; Build Info row is the longest across these 7 |

## HIG Areas Per Locale

See `manifest.json` `hig_areas_per_locale`. Every locale shows the same shape:

- `labels-actions`: `source-trace-only` (`fail (HIG-FR-001)` for French)
- `adaptive-layout`: `fail (HIG-FR-001)` for French; `not-reviewed` for the rest
- Other areas: `not-reviewed` everywhere, because no screenshot or device pass was preserved

## Missing Evidence For Pass

To claim any of these 7 locales `hig-ui-reviewed`, the following preserved evidence is required (per locale):

- Build Info screenshot with complete gate fields.
- Today screenshot with no visible app-owned English strings.
- All five root tabs.
- Primary empty states.
- Primary actions.
- High-risk date/count/plural surfaces.
- Dynamic Type pass (standard text size + Larger Accessibility Text).
- Accessibility labels/hints/values for the reviewed surfaces.

Plus native or fluent reviewer signoff for any `translation-quality` claim (still required; internal-reviewer signoff does not satisfy this).

## Status

Do not claim `hig-ui-reviewed` for any of these 7 LTR locales. Do not claim `screenshot-reviewed`, `device-verified`, or `testflight-verified` for any of them.

## Downstream Recommendations

1. Run a focused screenshot-capture slice that invokes the multisurface harness with `--capture` for these 7 locales and the listed scoped surfaces. Include `--label-overrides` covering `nb` (`I dag`) and `vi` (`Hôm nay`) for the `today` surface.
2. After capture, append the screenshot file references to this gate manifest and to the all-locale HIG evidence matrix per_locale_state for these 7 locales.
3. If HIG-FR-001 is confirmed by screenshot evidence, queue a UI-tweak slice to address tab-bar truncation.
