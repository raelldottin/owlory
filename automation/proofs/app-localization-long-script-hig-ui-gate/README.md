# Long-Script Apple HIG Localized UI Gate

## Scope

This is the Apple Human Interface Guidelines localized UI gate for the six long-script / inflection-heavy locales:

- `de` (German, native-reviewed; carries prior HIG-DE-001)
- `nl` (Dutch)
- `ru` (Russian)
- `sv` (Swedish)
- `tr` (Turkish)
- `uk` (Ukrainian)

Ran 2026-05-18 under the existing per-locale review signoff baselines:

- German: native-reviewed by Karoline on 2026-05-18.
- Other 5: internal-reviewer signoff (project owner attestation, not a native speaker) recorded in each locale's `localization/review/<locale>/<locale>-review-return.json` (`provenance.internal_reviewer_signoff`).

See `docs/workflows/localization-translation-quality.md` for the internal-reviewer-signoff label and Native Language Review Protocol.

## Gate Result

Result: **fail**

Reason: no preserved screenshot evidence for any of the 6 locales. Source-trace inspection surfaced 5 new major HIG risks (one per locale except Swedish):

- **HIG-DE-002**: German `Write` tab `Schreiben` (9 chars)
- **HIG-NL-001**: Dutch `Write` tab `Schrijven` (9 chars)
- **HIG-RU-001**: Russian `Train` tab `Тренировка` (10 chars, Cyrillic)
- **HIG-TR-001**: Turkish `Train` tab `Antrenman` (9 chars)
- **HIG-UK-001**: Ukrainian `Train` tab `Тренування` (10 chars, Cyrillic)

German also carries the prior **HIG-DE-001** (in-progress, source-fix-confirmed) from `app-localization-german-hig-ui-regate` and is reported here for bucket completeness; that finding's lifecycle stays in the original German gate proof.

## Methodology

1. **Source-trace inspection.** Read each of the 6 locales' `Localizable.strings` and compared lengths/values of tab labels (Today, Train, Write, Career, Home), primary actions (Save, Cancel, Continue), and Build Info row label against English. Recorded the values in `manifest.json` under `source_trace_per_locale`.
2. **Multisurface harness dry-run.** Ran `python3 automation/smoke/capture_localized_surfaces.py --dry-run --locales de nl ru sv tr uk --surfaces today root-tab-train root-tab-write root-tab-career root-tab-home build-info date-count-plural-today`. Plan: 42 captures (6 × 7); idb + idb_companion `ready`.
3. **Settled-label inventory.** The default catalog covers `de` (`Heute`). `nl` (`Vandaag`), `ru` (`Сегодня`), `sv` (`Idag`), `tr` (`Bugün`), and `uk` (`Сьогодні`) require entries in `--label-overrides` for the `today` surface.

No screenshot binaries are committed in this proof directory, so this remains a doc-only gate.

## Findings

| ID | Locale | Severity | Area | State | Summary |
|---|---|---|---|---|---|
| `HIG-DE-001` | de | blocking | labels-actions | in-progress (source-fix-confirmed) | (Tracked in `app-localization-german-hig-ui-gate`; not duplicated here.) |
| `HIG-DE-002` | de | major | adaptive-layout | open | Write tab `Schreiben` 9 chars; tab-bar truncation risk |
| `HIG-NL-001` | nl | major | adaptive-layout | open | Write tab `Schrijven` 9 chars; tab-bar truncation risk |
| `HIG-RU-001` | ru | major | adaptive-layout | open | Train tab `Тренировка` 10 chars (Cyrillic); tab-bar truncation likely |
| `HIG-TR-001` | tr | major | adaptive-layout | open | Train tab `Antrenman` 9 chars; tab-bar truncation risk |
| `HIG-UK-001` | uk | major | adaptive-layout | open | Train tab `Тренування` 10 chars (Cyrillic); tab-bar truncation likely |

All five new findings share the same shape: a tab label is significantly longer than English; truncation likely on smaller iPhone widths and at larger Dynamic Type settings; needs screenshot confirmation before queuing a UI-tweak fix.

## Per-Locale Notes

| Locale | Today | Train | Write | Career | Home | Build Info | Notable risk |
|---|---|---|---|---|---|---|---|
| `de` | `Heute` (5) | `Training` (8) | **`Schreiben` (9)** | `Karriere` (8) | `Haushalt` (8) | `Build-Info` (10) | **HIG-DE-002**; carries HIG-DE-001 |
| `nl` | `Vandaag` (7) | `Trainen` (7) | **`Schrijven` (9)** | `Carrière` (8) | `Thuis` (5) | `Build-info` (10) | **HIG-NL-001** |
| `ru` | `Сегодня` (7) | **`Тренировка` (10)** | `Запись` (6) | `Карьера` (7) | `Дом` (3) | `Информация о сборке` (19) | **HIG-RU-001**; translation-quality risk on Write |
| `sv` | `Idag` (4) | `Träna` (5) | `Skriv` (5) | `Karriär` (7) | `Hem` (3) | `Build-info` (10) | None at source level |
| `tr` | `Bugün` (5) | **`Antrenman` (9)** | `Yaz` (3) | `Kariyer` (7) | `Ev` (2) | `Yapı bilgisi` (12) | **HIG-TR-001** |
| `uk` | `Сьогодні` (8) | **`Тренування` (10)** | `Запис` (5) | `Кар'єра` (7) | `Дім` (3) | `Інформація про збірку` (21) | **HIG-UK-001**; translation-quality risk on Write |

Translation-quality concerns surfaced in source trace (NOT HIG defects; native review still required):

- `ru/Запись` and `uk/Запис` for Write mean "entry" / "recording" rather than the action "write". A native reviewer should confirm or correct.
- `de/Haushalt` for Home is the German "household" framing — Karoline's native-review choice for the Owlory home domain; not a defect.
- `nl/Bewaren` for Save is correct Dutch but `Opslaan` is the more common modern alternative; native reviewer's call.

## HIG Areas Per Locale

See `manifest.json` `hig_areas_per_locale`. Highlights:

- `adaptive-layout`: `fail` for de/nl/ru/tr/uk (each carrying a HIG-XX-001 or 002 finding); `not-reviewed` for sv.
- `labels-actions`: `source-fix-confirmed-pending-rerun` for de (HIG-DE-001 from the original gate); `source-trace-only` for the rest.
- All other areas: `not-reviewed` everywhere, because no screenshot or device pass was preserved.

## Missing Evidence For Pass

To claim any of these 6 locales `hig-ui-reviewed`, the following preserved evidence is required (per locale):

- Build Info screenshot with complete gate fields.
- Today screenshot with no visible app-owned English strings.
- All five root tabs (especially Train and Write where the source-trace findings cluster).
- Primary empty states.
- Primary actions.
- High-risk date/count/plural surfaces.
- Dynamic Type pass (standard text size + **Larger Accessibility Text** — the long-script bucket especially needs the AccessibilityXL pass to confirm the new tab-truncation findings).
- Accessibility labels/hints/values for the reviewed surfaces.

Plus native or fluent reviewer signoff for any `translation-quality` claim on the 5 non-German locales (still required; internal-reviewer signoff does not satisfy this).

## Status

Do not claim `hig-ui-reviewed` for any of these 6 locales. Do not claim `screenshot-reviewed`, `device-verified`, or `testflight-verified` for any of them. German remains `native-reviewed` for language entries via `localization/review/de/german-review-return.json`; that is unchanged.

## Downstream Recommendations

1. Run a focused screenshot-capture slice that invokes the multisurface harness with `--capture` for these 6 locales and the listed scoped surfaces. Include `--label-overrides` covering `nl/ru/sv/tr/uk` for the `today` surface.
2. After capture, append the screenshot file references to this gate manifest and to the all-locale HIG evidence matrix per_locale_state for these 6 locales.
3. The 5 new tab-truncation findings (`HIG-DE-002`, `HIG-NL-001`, `HIG-RU-001`, `HIG-TR-001`, `HIG-UK-001`) share a fix shape with `HIG-FR-001` from the remaining-LTR gate. After screenshot confirmation, queue a **single** UI-tweak slice that addresses tab-bar layout / truncation handling across all six locales together, rather than per-locale fix slices.
