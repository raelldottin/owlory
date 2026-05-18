# app-localization-remaining-ltr-hig-ui-gate

## Prompt

> "start next slice" — execute the supervisor-selected slice `app-localization-remaining-ltr-hig-ui-gate`, which runs the HIG localized UI gate for the 7 remaining LTR locales (`fr`, `it`, `nb`, `pt`, `pt-BR`, `es`, `vi`) under the internal-reviewer signoff baseline.

## What was done

Proof/review slice. Doc-only HIG gate intake. No screenshots captured, no app source touched, no translation changes.

### Methodology

1. **Source-trace inspection.** Read each of the 7 locales' `Localizable.strings` and compared lengths/values of:
   - Tab labels: `Today`, `Train`, `Write`, `Career`, `Home`
   - Primary actions: `Save`, `Cancel`, `Continue`
   - `Build Info` row label
   - `display.lifeDomain.*` keys
2. **Multisurface harness dry-run.** Ran `python3 automation/smoke/capture_localized_surfaces.py --dry-run --locales fr it nb pt pt-BR es vi --surfaces today root-tab-train root-tab-write root-tab-career root-tab-home build-info date-count-plural-today`. Plan: 49 captures (7 × 7); idb + idb_companion `ready`.
3. **Settled-label inventory.** Today-surface localized labels for `fr` (`Aujourd'hui`), `it` (`Oggi`), `pt` (`Hoje`), `pt-BR` (`Hoje`), `es` (`Hoy`) are already in the harness default catalog. `nb` (`I dag`) and `vi` (`Hôm nay`) require entries in `--label-overrides` for the `today` surface.

### Gate Outcome

Result: **fail** for all 7 locales.

Reason: no screenshot evidence preserved for any locale. The scoped HIG surface set (Build Info, Today, root tabs, primary empty states, primary actions, date/count/plural, Dynamic Type) requires preserved screenshots before any locale can pass.

### Findings

#### HIG-FR-001 (major, adaptive-layout, open)

French `Localizable.strings` sets `"Today" = "Aujourd'hui";`. At 11 characters, it is the longest Today tab label across all 19 supported locales (compare: en/de/nb = 5, es = 3, it/pt/pt-BR = 4, vi = 7). Tab-bar truncation likely on smaller iPhone widths (iPhone SE / standard iPhone portrait) and at larger Dynamic Type settings.

Remediation options recorded in the gate manifest:

- Capture French Today tab screenshots on iPhone SE / standard iPhone portrait and confirm whether the label truncates or shrinks legibly.
- If truncation is confirmed, queue a UI-tweak slice (likely under `Features/Today/` or shared tab-bar UI).
- Add accessibility identifiers to TabView items so XCUITests + the multisurface harness can target tabs without translated labels.

### Per-locale notes (highlights)

| Locale | Today | Train | Build Info | Notable |
|---|---|---|---|---|
| `fr` | `Aujourd'hui` (11) | `Entraîner` | `Infos de version` | **HIG-FR-001** |
| `it` | `Oggi` (4) | `Allenare` | `Informazioni build` | Build Info row is long |
| `nb` | `I dag` (5) | `Tren` | `Build-info` | Translation-quality risk: `Tren` is noun form; not a HIG defect |
| `pt` | `Hoje` (4) | `Treinar` | `Info da build` | `Guardar` for Save correct for Portugal |
| `pt-BR` | `Hoje` (4) | `Treinar` | `Info da build` | `Salvar` for Save correct for Brazil |
| `es` | `Hoy` (3) | `Entrenar` | `Info de build` | No source-level HIG risk |
| `vi` | `Hôm nay` (7) | `Tập luyện` | `Thông tin bản dựng` | Diacritics render wider than char count suggests |

The full data, per-locale source trace, and remediation recommendations live in `automation/proofs/app-localization-remaining-ltr-hig-ui-gate/manifest.json`.

### Doc updates

| File | Change |
|---|---|
| `docs/workflows/localization-hig-ui-completion.md` | Locale-bucket table row for "Remaining LTR" now references this gate's 2026-05-18 doc-only run, HIG-FR-001, and the pending screenshot capture |
| `docs/workflows/localization-translation-quality.md` | Updated the all-locale HIG matrix bullet to count 2 open findings (DE-001 in-progress + FR-001 open); added a new bullet for the Remaining-LTR HIG gate |

## Validation

- `python3 automation/context/build_context.py --slice-id app-localization-remaining-ltr-hig-ui-gate` — ran.
- `python3 automation/supervisor/run_next.py --dry-run` — selected this slice pre-commit.
- `make architecture` — passed.
- `make localization-check` — 19 / 377 / 13.
- `python3 Tools/localization-review-status.py` — ran (7478 passed / 64 warning / 0 reverted).
- `make automation-check` — 71 tests passed.
- `git diff --check` — clean.
- `python3 -m json.tool automation/proofs/app-localization-remaining-ltr-hig-ui-gate/manifest.json` — passed.

## Lane Boundary

`doc-only`. No app source, test, or resource changes. No screenshot artifact captured. No `screenshot-reviewed`, `device-verified`, or `testflight-verified` claim made.

## Residual Risk

- HIG-FR-001 is a source-trace inference. Whether the tab label actually truncates depends on iPhone width and Dynamic Type setting; needs screenshot confirmation.
- Six locales (`it`, `nb`, `pt`, `pt-BR`, `es`, `vi`) have no recorded HIG finding only because no screenshots were captured. Live screenshots may surface additional issues.
- Norwegian `Tren` for Train tab is a translation-quality concern (noun form vs verb intent), not a HIG defect; native reviewer still needed.
- The multisurface harness needs `--label-overrides` for `nb` (`I dag`) and `vi` (`Hôm nay`) for the today surface; the default catalog does not include those localized labels.

## Not Claimed

- Any of these 7 LTR locales is `hig-ui-reviewed`.
- Any of these 7 LTR locales is `native-reviewed`.
- Translation quality for any of these 7 LTR locales.
- `screenshot-reviewed`, `device-verified`, or `testflight-verified` for any of these 7 LTR locales.

## Next slice in the HIG ladder

Per the supervisor / queue, the next eligible slice is one of the other unblocked bucket gates (`rtl-hig-ui-gate-ar`, `cjk-hig-ui-gate`, `long-script-hig-ui-gate`) — order TBD by priority. A separate screenshot-capture slice will need to run the multisurface harness with `--capture` for the 7 LTR locales before any of them can move past the doc-only state.
