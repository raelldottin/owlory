# CJK Apple HIG Localized UI Gate

## Scope

This is the Apple Human Interface Guidelines localized UI gate for the four CJK locales:

- `ja` (Japanese)
- `ko` (Korean)
- `zh-Hans` (Simplified Chinese)
- `zh-Hant` (Traditional Chinese)

Ran 2026-05-18 under the internal-reviewer signoff baseline recorded in each locale's `localization/review/<locale>/<locale>-review-return.json` (`provenance.internal_reviewer_signoff`). The signoff is the project owner's attestation, not a native or fluent reviewer signoff. See `docs/workflows/localization-translation-quality.md` for the internal-reviewer-signoff label.

## Gate Result

Result: **fail**

Reason: no preserved screenshot evidence for any of the 4 locales. Source-trace inspection surfaced one major HIG risk:

- **HIG-JA-001**: Japanese `Train` tab `トレーニング` (6 katakana chars; each CJK glyph ~2x Latin width).

Korean, Simplified Chinese, and Traditional Chinese have no source-level HIG findings — their compact 1-2 ideograph tab labels are ideal for tab-bar use — but cannot pass without preserved screenshots for the scoped surfaces.

## Methodology

1. **Source-trace inspection.** Read each of the 4 locales' `Localizable.strings` and compared lengths/values of tab labels (Today, Train, Write, Career, Home), primary actions (Save, Cancel, Continue), and Build Info row label against English. Recorded the values in `manifest.json` under `source_trace_per_locale`. Adjusted character-count comparisons for CJK glyph width (~2x Latin per character).
2. **Multisurface harness dry-run.** Ran `python3 automation/smoke/capture_localized_surfaces.py --dry-run --locales ja ko zh-Hans zh-Hant --surfaces today root-tab-train root-tab-write root-tab-career root-tab-home build-info date-count-plural-today`. Plan: 28 captures (4 × 7); idb + idb_companion `ready`.
3. **Settled-label inventory.** All four CJK today labels (`今日`, `오늘`, `今天`, `今天`) are already in the harness default catalog. No `--label-overrides` required for the today surface.

No screenshot binaries are committed in this proof directory, so this remains a doc-only gate.

## Findings

| ID | Locale | Severity | Area | State | Summary |
|---|---|---|---|---|---|
| `HIG-JA-001` | ja | major | adaptive-layout | open | Train tab `トレーニング` (6 katakana chars); tab-bar truncation likely on smaller iPhone widths |

## Per-Locale Notes

| Locale | Today | Train | Write | Career | Home | Build Info | Notable risk |
|---|---|---|---|---|---|---|---|
| `ja` | `今日` (2) | **`トレーニング` (6)** | `書く` (2) | `キャリア` (4) | `ホーム` (3) | `ビルド情報` (5) | **HIG-JA-001** |
| `ko` | `오늘` (2) | `훈련` (2) | `쓰기` (2) | `경력` (2) | `홈` (1) | `빌드 정보` (5) | None at source level |
| `zh-Hans` | `今天` (2) | `训练` (2) | `写作` (2) | `事业` (2) | `家` (1) | `构建信息` (4) | None at source level |
| `zh-Hant` | `今天` (2) | `訓練` (2) | `寫作` (2) | `事業` (2) | `家` (1) | `建置資訊` (4) | None at source level |

Japanese is the CJK outlier on tab-label width because of katakana loanwords. The Korean / Simplified Chinese / Traditional Chinese labels are uniformly compact (1-2 ideographs) and are tab-bar ideal.

## Translation-Quality Notes (NOT HIG defects)

Need native review to confirm or correct:

- `ja/トレーニング` for Train, `ja/キャリア` for Career, `ja/ホーム` for Home, `ja/キャンセル` for Cancel — modern katakana loanwords; valid Japanese but a native reviewer could prefer kanji alternatives (e.g., `訓練` for Train, which would also resolve HIG-JA-001).
- `ko/쓰기` for Write — the noun form (the act of writing); native reviewer's call on whether `작성` (composition) is preferable.
- Simplified vs Traditional Chinese differences (`训练`/`訓練`, `事业`/`事業`, `保存`/`儲存`, etc.) — review separately, do not bulk-edit one into the other.

## HIG Areas Per Locale

See `manifest.json` `hig_areas_per_locale`. Highlights:

- `adaptive-layout`: `fail (HIG-JA-001)` for Japanese; `not-reviewed` for the other three.
- `labels-actions`: `source-trace-only` for all four.
- All other areas: `not-reviewed` everywhere, because no screenshot or device pass was preserved.

## Missing Evidence For Pass

To claim any of these 4 CJK locales `hig-ui-reviewed`, the following preserved evidence is required (per locale):

- Build Info screenshot with complete gate fields.
- Today screenshot with no visible app-owned English strings.
- All five root tabs (especially Japanese Train tab for HIG-JA-001 confirmation).
- Primary empty states.
- Primary actions.
- High-risk date/count/plural surfaces — CJK typography is character-density-sensitive.
- Dynamic Type pass (standard text size + Larger Accessibility Text).
- Accessibility labels/hints/values for the reviewed surfaces.

Plus native or fluent reviewer signoff for any `translation-quality` claim (still required; internal-reviewer signoff does not satisfy this).

## Status

Do not claim `hig-ui-reviewed` for any of these 4 CJK locales. Do not claim `screenshot-reviewed`, `device-verified`, or `testflight-verified` for any of them.

## Downstream Recommendations

1. Run a focused screenshot-capture slice that invokes the multisurface harness with `--capture` for these 4 CJK locales and the listed scoped surfaces. No `--label-overrides` required.
2. After capture, append the screenshot file references to this gate manifest and to the all-locale HIG evidence matrix per_locale_state for these 4 locales.
3. HIG-JA-001 shares fix shape with HIG-FR-001 + HIG-DE-002/NL-001/RU-001/TR-001/UK-001 (tab-bar truncation across 7 locales now). After screenshot confirmation, a single tab-bar UI-tweak slice should address all seven together.
