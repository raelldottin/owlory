# app-localization-rtl-hig-ui-gate-ar

## Prompt

> "start next slice" — execute the supervisor-selected slice `app-localization-rtl-hig-ui-gate-ar`, which runs the Arabic RTL HIG localized UI gate.

## What was done

Proof/review slice. Doc-only HIG gate intake with **higher-confidence source-level defects** than the other bucket gates — the RTL-specific SwiftUI mirroring rule lets me allocate findings without screenshot dependence.

### Methodology

1. **Source-trace inspection.** Read Arabic `Localizable.strings` and compared tab labels, primary actions, Build Info row against English and the other 18 locales.
2. **App-source RTL audit.** Grepped Owlory feature views for the explicit directional SF Symbols `chevron.right`, `chevron.left`, `arrow.right`, `arrow.left`, plus `flipsForRightToLeft` markers. Found three call sites using the non-mirroring `.right` form.
3. **Multisurface harness dry-run.** Ran `python3 automation/smoke/capture_localized_surfaces.py --dry-run --locales ar --surfaces today root-tab-train root-tab-write root-tab-career root-tab-home build-info date-count-plural-today`. Plan: 7 captures; idb + idb_companion `ready`. `--label-overrides` needed for `today.ar` (`اليوم`) before actual capture.

### Gate Outcome

Result: **fail**.

### Findings (3 new)

| ID | Severity | Area | State | Summary |
|---|---|---|---|---|
| `HIG-AR-001` | major | right-to-left | open | `chevron.right` in `TodayView.swift:566` does not auto-mirror under RTL |
| `HIG-AR-002` | major | right-to-left | open | `arrow.right.circle` in `WriteView.swift:88,181` does not auto-mirror under RTL |
| `HIG-AR-003` | major | adaptive-layout | open | Arabic `Career` tab `المسيرة المهنية` (15 chars; longest Career label across all 19 locales) |

### Why HIG-AR-001 + HIG-AR-002 are stronger than the other bucket findings

SF Symbols follow a deterministic naming rule for RTL mirroring:

- Names ending in `.right` / `.left` (explicit directional): do **not** auto-mirror.
- Names ending in `.forward` / `.backward` (semantic / reading-order): **do** auto-mirror under RTL.

Apple HIG specifically calls out `.forward` / `.backward` as the correct choice for affordances meaning "advance" / "next in reading order" — which is exactly what TodayView:566 (Continue chevron) and WriteView:88/181 (Advance action) need. Using `.right` is a defect under Arabic regardless of how the screenshot looks, because the chevron will point left-to-right when it should point right-to-left (leading→trailing in RTL).

This is a source-level defect, not a layout inference. Screenshot evidence is useful to measure visible impact, not to confirm the defect exists.

### Per-locale notes (Arabic only)

| Surface | Arabic label | Length | Notes |
|---|---|---|---|
| Today | `اليوم` | 5 | Fits typical tab-bar width |
| Train | `تدريب` | 5 | Fits |
| Write | `كتابة` | 5 | Fits |
| Career | **`المسيرة المهنية`** | **15** | **HIG-AR-003**; longest Career label across all 19 locales |
| Home | `المنزل` | 6 | Fits |
| Build Info | `معلومات الإصدار` | 15 | Detail row; should accommodate |
| Save | `حفظ` | 3 | Fits |
| Cancel | `إلغاء` | 5 | Fits |
| Continue | `متابعة` | 6 | Fits |

### Doc updates

| File | Change |
|---|---|
| `docs/workflows/localization-hig-ui-completion.md` | Locale-bucket table row for "RTL" references this gate's 2026-05-18 doc-only run, HIG-AR-001/AR-002 (source-level), and HIG-AR-003 (tab truncation) |
| `docs/workflows/localization-translation-quality.md` | Added a new bullet for the Arabic RTL HIG gate; tab-truncation count now 8 across HIG-AR-003 + HIG-DE-002 + HIG-FR-001 + HIG-JA-001 + HIG-NL-001 + HIG-RU-001 + HIG-TR-001 + HIG-UK-001 |

## Validation

- `python3 automation/context/build_context.py --slice-id app-localization-rtl-hig-ui-gate-ar` — ran.
- `python3 automation/supervisor/run_next.py --dry-run` — selected this slice pre-commit.
- `make architecture` — passed.
- `make localization-check` — 19 / 377 / 13.
- `python3 Tools/localization-review-status.py` — ran (7478 passed / 64 warning / 0 reverted).
- `make automation-check` — 71 tests passed.
- `git diff --check` — clean.
- `python3 -m json.tool automation/proofs/app-localization-rtl-hig-ui-gate-ar/manifest.json` — passed.

## Lane Boundary

`doc-only`. No app source touched, no test, no resource changes. The RTL SF Symbol defects are flagged but **not fixed** in this slice — that's a separate Swift slice scope.

## Residual Risk

- HIG-AR-001 and HIG-AR-002 are source-level defects with a deterministic SwiftUI rule; they should be fixed as a small targeted slice regardless of screenshot evidence.
- HIG-AR-003 is a source-trace inference; needs screenshot confirmation.
- RTL layout mirroring beyond directional icons (alignment, navigation affordances, control ordering, text flow) is **not** verified by this gate. Only directional SF Symbols + tab-label width were inspected.
- Arabic native review is still required for any translation-quality claim.

## Not Claimed

- Arabic is `hig-ui-reviewed`.
- Arabic is `native-reviewed`.
- Translation quality for Arabic.
- `screenshot-reviewed`, `device-verified`, or `testflight-verified` for Arabic.
- RTL mirroring is proven correct on Owlory localized surfaces.

## Bucket Gate Summary (all 4 complete)

| Bucket Gate | Result | New Findings | Notable |
|---|---|---|---|
| Remaining LTR (fr/it/nb/pt/pt-BR/es/vi) | fail | HIG-FR-001 | Tab-truncation: French Today |
| Long-script (de/nl/ru/sv/tr/uk) | fail | HIG-DE-002, HIG-NL-001, HIG-RU-001, HIG-TR-001, HIG-UK-001 | Tab-truncation across Train/Write |
| CJK (ja/ko/zh-Hans/zh-Hant) | fail | HIG-JA-001 | Tab-truncation: Japanese Train (katakana) |
| **Arabic RTL** (ar) | fail | **HIG-AR-001, HIG-AR-002, HIG-AR-003** | **Source-level RTL defects** + tab-truncation |

**Totals**: 10 new open findings + HIG-DE-001 (in-progress, carried from the original German gate). 8 of the 10 share the tab-bar truncation fix shape and should be addressed by a single UI-tweak slice. 2 (HIG-AR-001 + HIG-AR-002) are RTL-specific source defects that should be fixed in a small targeted Swift slice independent of screenshot capture.

## Next slice in the HIG ladder

Per the queue, the next eligible slice is `app-localization-hig-remediation-triage` (priority 81). All 4 bucket gates have now run; the triage slice can synthesize the 10 open findings into focused remediation slices.
