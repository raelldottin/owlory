# app-localization-long-script-hig-ui-gate

## Prompt

> "start next slice" — execute the supervisor-selected slice `app-localization-long-script-hig-ui-gate`, which runs the HIG localized UI gate for the 6 long-script / inflection-heavy locales (`de`, `nl`, `ru`, `sv`, `tr`, `uk`).

## What was done

Proof/review slice. Doc-only HIG gate intake. No screenshots captured, no app source touched, no translation changes.

### Methodology

1. **Source-trace inspection.** Read each of the 6 locales' `Localizable.strings` and compared lengths/values of tab labels (Today, Train, Write, Career, Home), primary actions (Save, Cancel, Continue), and Build Info row label against English.
2. **Multisurface harness dry-run.** Ran `python3 automation/smoke/capture_localized_surfaces.py --dry-run --locales de nl ru sv tr uk --surfaces today root-tab-train root-tab-write root-tab-career root-tab-home build-info date-count-plural-today`. Plan: 42 captures (6 × 7); idb + idb_companion `ready`.
3. **Settled-label inventory.** Default catalog covers `de` (`Heute`). `nl/ru/sv/tr/uk` today labels require entries in `--label-overrides`.

### Gate Outcome

Result: **fail** for all 6 locales.

Reason: no screenshot evidence preserved for any locale. The scoped HIG surface set requires preserved screenshots before any locale can pass.

### Findings (5 new + 1 carried)

| ID | Locale | Severity | Area | State | Summary |
|---|---|---|---|---|---|
| `HIG-DE-001` | de | blocking | labels-actions | in-progress (carried) | Tracked in `app-localization-german-hig-ui-gate`; not duplicated here |
| `HIG-DE-002` | de | major | adaptive-layout | open | Write tab `Schreiben` (9 chars vs en 5); tab-bar truncation risk |
| `HIG-NL-001` | nl | major | adaptive-layout | open | Write tab `Schrijven` (9 chars); tab-bar truncation risk |
| `HIG-RU-001` | ru | major | adaptive-layout | open | Train tab `Тренировка` (10 chars, Cyrillic); tab-bar truncation likely |
| `HIG-TR-001` | tr | major | adaptive-layout | open | Train tab `Antrenman` (9 chars); tab-bar truncation risk |
| `HIG-UK-001` | uk | major | adaptive-layout | open | Train tab `Тренування` (10 chars, Cyrillic); tab-bar truncation likely |

All five new findings share the same fix shape: a tab label is significantly longer than English, truncation likely on smaller iPhone widths and at larger Dynamic Type settings. Combined with `HIG-FR-001` from the remaining-LTR gate, six locales now have an adaptive-layout finding on the same surface (tab bar).

### Translation-quality concerns (NOT HIG defects)

Surfaced in source trace; need native review to confirm or correct:

- `ru/Запись` and `uk/Запис` for Write — these mean "entry" / "recording" rather than the action "write".
- `de/Haushalt` for Home — German "household" framing; this is Karoline's native-review choice for the Owlory home domain, not a defect.
- `nl/Bewaren` for Save — correct Dutch, but `Opslaan` is the more common modern alternative.

### Per-locale notes (highlights)

| Locale | Today | Train | Write | Career | Home | Build Info | Notable risk |
|---|---|---|---|---|---|---|---|
| `de` | `Heute` (5) | `Training` (8) | **`Schreiben` (9)** | `Karriere` (8) | `Haushalt` (8) | `Build-Info` (10) | **HIG-DE-002**; carries HIG-DE-001 |
| `nl` | `Vandaag` (7) | `Trainen` (7) | **`Schrijven` (9)** | `Carrière` (8) | `Thuis` (5) | `Build-info` (10) | **HIG-NL-001** |
| `ru` | `Сегодня` (7) | **`Тренировка` (10)** | `Запись` (6) | `Карьера` (7) | `Дом` (3) | `Информация о сборке` (19) | **HIG-RU-001**; translation-quality risk on Write |
| `sv` | `Idag` (4) | `Träna` (5) | `Skriv` (5) | `Karriär` (7) | `Hem` (3) | `Build-info` (10) | None at source level |
| `tr` | `Bugün` (5) | **`Antrenman` (9)** | `Yaz` (3) | `Kariyer` (7) | `Ev` (2) | `Yapı bilgisi` (12) | **HIG-TR-001** |
| `uk` | `Сьогодні` (8) | **`Тренування` (10)** | `Запис` (5) | `Кар'єра` (7) | `Дім` (3) | `Інформація про збірку` (21) | **HIG-UK-001**; translation-quality risk on Write |

### Doc updates

| File | Change |
|---|---|
| `docs/workflows/localization-hig-ui-completion.md` | Locale-bucket table row for "Long-script / inflection-heavy" now references this gate's 2026-05-18 doc-only run and the 5 new findings; noted German cross-cut |
| `docs/workflows/localization-translation-quality.md` | Updated the all-locale HIG matrix bullet to count 7 open findings; added a new bullet for the Long-script HIG gate |

## Validation

- `python3 automation/context/build_context.py --slice-id app-localization-long-script-hig-ui-gate` — ran.
- `python3 automation/supervisor/run_next.py --dry-run` — selected this slice pre-commit.
- `make architecture` — passed.
- `make localization-check` — 19 / 377 / 13.
- `python3 Tools/localization-review-status.py` — ran (7478 passed / 64 warning / 0 reverted).
- `make automation-check` — 71 tests passed.
- `git diff --check` — clean.
- `python3 -m json.tool automation/proofs/app-localization-long-script-hig-ui-gate/manifest.json` — passed.

## Lane Boundary

`doc-only`. No app source, test, or resource changes. No screenshot artifact captured. No `screenshot-reviewed`, `device-verified`, or `testflight-verified` claim made.

## Residual Risk

- The 5 new findings are source-trace inferences. Whether the tab labels actually truncate depends on iPhone width + Dynamic Type; needs screenshot confirmation.
- Swedish has no recorded HIG finding only because no screenshots were captured. Live screenshots may surface additional issues.
- The 5 new findings share fix shape with HIG-FR-001 from the remaining-LTR gate. A single tab-bar layout slice (not per-locale) should address all six after screenshot confirmation.
- The multisurface harness needs `--label-overrides` for `nl/ru/sv/tr/uk` for the today surface; default catalog covers `de` only in this bucket.

## Not Claimed

- Any of these 6 locales is `hig-ui-reviewed`.
- Any non-German locale in this bucket is `native-reviewed`.
- Translation quality for any non-German locale in this bucket.
- `screenshot-reviewed`, `device-verified`, or `testflight-verified` for any locale in this bucket.

## Next slice in the HIG ladder

Per the supervisor / queue, the next eligible slice is one of the remaining unblocked bucket gates (`rtl-hig-ui-gate-ar` priority 85, `cjk-hig-ui-gate` priority 84). After all four bucket gates complete, the HIG remediation triage slice can run. A separate screenshot-capture slice should cover the 13 locales now in failing-bucket-gate state (fr/it/nb/pt/pt-BR/es/vi from remaining-LTR + de/nl/ru/sv/tr/uk from long-script) before any `screenshot-reviewed` claim.
