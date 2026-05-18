# app-localization-cjk-hig-ui-gate

## Prompt

> "start next slice" — execute the supervisor-selected slice `app-localization-cjk-hig-ui-gate`, which runs the HIG localized UI gate for the 4 CJK locales (`ja`, `ko`, `zh-Hans`, `zh-Hant`).

## What was done

Proof/review slice. Doc-only HIG gate intake. No screenshots captured, no app source touched, no translation changes.

### Methodology

1. **Source-trace inspection.** Read each of the 4 locales' `Localizable.strings` and compared lengths/values of tab labels (Today, Train, Write, Career, Home), primary actions (Save, Cancel, Continue), and Build Info row label against English. Adjusted comparisons for CJK glyph width (~2x Latin per character).
2. **Multisurface harness dry-run.** Ran `python3 automation/smoke/capture_localized_surfaces.py --dry-run --locales ja ko zh-Hans zh-Hant --surfaces today root-tab-train root-tab-write root-tab-career root-tab-home build-info date-count-plural-today`. Plan: 28 captures (4 × 7); idb + idb_companion `ready`.
3. **Settled-label inventory.** All four CJK today labels (`今日`, `오늘`, `今天`, `今天`) are already in the harness default catalog. No `--label-overrides` required for the today surface.

### Gate Outcome

Result: **fail** for all 4 locales.

Reason: no screenshot evidence preserved for any locale.

### Findings (1 new)

| ID | Locale | Severity | Area | State | Summary |
|---|---|---|---|---|---|
| `HIG-JA-001` | ja | major | adaptive-layout | open | Train tab `トレーニング` (6 katakana chars; CJK ~2x Latin width); tab-bar truncation likely on smaller iPhone widths |

Korean, Simplified Chinese, and Traditional Chinese have no source-level HIG findings — uniformly 1-2 ideograph tab labels are ideal for tab-bar use.

### Per-locale notes

| Locale | Today | Train | Write | Career | Home | Build Info | Notable risk |
|---|---|---|---|---|---|---|---|
| `ja` | `今日` (2) | **`トレーニング` (6)** | `書く` (2) | `キャリア` (4) | `ホーム` (3) | `ビルド情報` (5) | **HIG-JA-001** |
| `ko` | `오늘` (2) | `훈련` (2) | `쓰기` (2) | `경력` (2) | `홈` (1) | `빌드 정보` (5) | None at source level |
| `zh-Hans` | `今天` (2) | `训练` (2) | `写作` (2) | `事业` (2) | `家` (1) | `构建信息` (4) | None at source level |
| `zh-Hant` | `今天` (2) | `訓練` (2) | `寫作` (2) | `事業` (2) | `家` (1) | `建置資訊` (4) | None at source level |

Japanese is the CJK outlier on tab-label width because of katakana loanwords. The other three CJK locales' labels are compact and tab-bar ideal.

### Translation-quality notes (NOT HIG defects)

- `ja/トレーニング` for Train, `ja/キャリア` for Career, `ja/ホーム` for Home, `ja/キャンセル` for Cancel — valid Japanese loanwords; native reviewer could prefer kanji alternatives (e.g., `訓練` would also resolve HIG-JA-001).
- `ko/쓰기` for Write — noun form; `작성` is an alternative.
- Simplified vs Traditional Chinese differences (`训练`/`訓練`, `事业`/`事業`, `保存`/`儲存`, etc.) require separate native review; do not bulk-edit one into the other.

### Doc updates

| File | Change |
|---|---|
| `docs/workflows/localization-hig-ui-completion.md` | Locale-bucket table row for "CJK" references this gate's 2026-05-18 doc-only run and HIG-JA-001 |
| `docs/workflows/localization-translation-quality.md` | Added a new bullet for the CJK HIG gate |

## Validation

- `python3 automation/context/build_context.py --slice-id app-localization-cjk-hig-ui-gate` — ran.
- `python3 automation/supervisor/run_next.py --dry-run` — selected this slice pre-commit.
- `make architecture` — passed.
- `make localization-check` — 19 / 377 / 13.
- `python3 Tools/localization-review-status.py` — ran (7478 passed / 64 warning / 0 reverted).
- `make automation-check` — 71 tests passed.
- `git diff --check` — clean.
- `python3 -m json.tool automation/proofs/app-localization-cjk-hig-ui-gate/manifest.json` — passed.

## Lane Boundary

`doc-only`. No app source, test, or resource changes. No screenshot artifact captured.

## Residual Risk

- HIG-JA-001 is a source-trace inference. Whether the katakana tab label actually truncates depends on iPhone width + Dynamic Type; needs screenshot confirmation.
- ko/zh-Hans/zh-Hant have no recorded HIG finding only because no screenshots were captured. Live screenshots may surface line-breaking or density issues that source trace cannot detect.
- Japanese katakana-vs-kanji loanword choice is a native-review decision; this HIG gate noted the alternative but did not override.

## Not Claimed

- Any of these 4 CJK locales is `hig-ui-reviewed`.
- Any of these 4 CJK locales is `native-reviewed`.
- Translation quality for any of these 4 CJK locales.
- `screenshot-reviewed`, `device-verified`, or `testflight-verified` for any of these 4 CJK locales.

## Pattern across bucket gates so far

Counting tab-bar truncation findings (`adaptive-layout`):

| Bucket | Findings |
|---|---|
| Remaining LTR | HIG-FR-001 |
| Long-script | HIG-DE-002, HIG-NL-001, HIG-RU-001, HIG-TR-001, HIG-UK-001 |
| CJK | HIG-JA-001 |
| **Total** | **7 tab-truncation findings across 7 locales** |

Plus HIG-DE-001 (in-progress, labels-actions, source-fix-confirmed) from the German gate.

A single tab-bar UI-tweak slice should address all 7 truncation findings together once screenshot evidence confirms them.

## Next slice in the HIG ladder

Per the queue, the next eligible slice is `app-localization-rtl-hig-ui-gate-ar` (priority 85) for the Arabic bucket (RTL mirroring + label clarity). After all four bucket gates complete, the HIG remediation triage slice can run.
