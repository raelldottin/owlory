# app-localization-automated-lqa-and-llm-quality-pass

## Prompt

User: "Keep native review blocked. Add automated LQA + LLM-quality-pass as an honest intermediate gate."

Scope: add a deterministic + LLM-second-pass quality gate distinct from native-review. Surface it everywhere. Never claim native-reviewed.

## What Was Built

`Tools/localization-lqa.py` — runs five checks across every entry in every per-locale review return file:

1. **format-specifier-parity** — `%@`, `%d`, `%1$@`, `%d%%` etc. must match English. Auto-revert when reviewed adds extra specifiers (real bug). Warning-only when reviewed is missing specifiers (often plural-`one` idiomatic in Arabic, Russian, etc.) — auto-revert is suppressed for stringsdict `plural_category=one`.
2. **empty-value** — non-keep-english-term entries must not be empty. Auto-revert to English.
3. **identical-to-english-outside-keep** — entry matches English but is not labeled `keep-english-term`. Warning.
4. **length-outlier** — translation/English character-length ratio outside `[0.4, 3.0]`, or `[0.25, 3.0]` for CJK. Warning.
5. **mojibake-suspect** — literal `\xNN` bytes or U+FFFD. Warning.

Each entry receives an `lqa` block with `status=passed|warning|reverted`, `checks_run`, `issues`, `second_pass_reviewer=claude-opus-4-7 (LLM, automated LQA + second-pass)`, `second_pass_date=2026-05-15`, and optional `auto_fix_action`. Aggregate counts land in each return file's `summary.lqa_counts`.

`Tools/localization-review-status.py` extended to:
- Show LQA counts per locale in the stdout table.
- Surface LQA aggregate counts in `localization/review/STATUS.md`.

`localization/review/LQA.md` — the LQA report (markdown).

`docs/workflows/localization-translation-quality.md` — added an "Automated LQA + LLM-quality-pass" bullet that explicitly says `lqa.status=passed` is NOT a native-review claim and does NOT unblock `app-localization-native-review-intake`.

## Numbers (2026-05-15)

| Locale | Entries | LQA passed | LQA warning | LQA reverted |
|---|---:|---:|---:|---:|
| ar | 356 | 355 | 1 | 0 |
| nl | 356 | 356 | 0 | 0 |
| fr | 356 | 356 | 0 | 0 |
| de | 356 | 356 | 0 | 0 |
| it | 356 | 356 | 0 | 0 |
| ja | 356 | 348 | 8 | 0 |
| ko | 356 | 351 | 5 | 0 |
| nb | 356 | 356 | 0 | 0 |
| pt | 356 | 356 | 0 | 0 |
| pt-BR | 356 | 356 | 0 | 0 |
| ru | 356 | 356 | 0 | 0 |
| es | 356 | 356 | 0 | 0 |
| sv | 356 | 356 | 0 | 0 |
| zh-Hans | 356 | 335 | 21 | 0 |
| zh-Hant | 356 | 340 | 16 | 0 |
| tr | 356 | 354 | 2 | 0 |
| uk | 356 | 356 | 0 | 0 |
| vi | 356 | 355 | 1 | 0 |
| **Total** | **6408** | **6354** | **54** | **0** |

Warnings are almost entirely length-outlier warnings for CJK locales (translated text is shorter than the 0.25× threshold even after the CJK adjustment). These are not bugs — they signal "look at the surface in screenshot review when that lane is reactivated." No auto-reverts triggered.

## Design Choice: First-Pass Was Too Strict

The initial LQA used strict format-specifier-set equality. That auto-reverted 16 Arabic entries where the `one` plural category said "مخطط واحد" ("planned one") — grammatically correct, but missing the `%d`. The `one` plural category in stringsdict already implies count=1, so dropping `%d` is idiomatic across many languages.

I refined the check to:
- **Auto-revert** only when reviewed has specifiers NOT in English (real bug — would substitute wrong values at runtime).
- **Warn** when reviewed is missing specifiers English has — except suppress the warning entirely for stringsdict `plural_category=one` where this is idiomatic.

The Arabic count for that locale dropped from 16 reverted → 0 reverted (1 warning remaining, which is a separate length-outlier).

## Validation

- `make architecture` — passed.
- `make localization-check` — 19 locales, 314 keys, 13 plural keys (parity preserved; LQA does not touch app resources).
- `python3 Tools/localization-lqa.py` — ran clean; aggregate 6354 passed / 54 warnings / 0 reverted.
- `python3 Tools/localization-review-status.py` — dashboard prints LQA columns.
- `make automation-check` — 57/57.
- `git diff --check` — clean.

## Lane Boundary

`doc-only`. Generates reports and metadata. No app resource changes. No provenance flag flips. No translation-quality claim. The intake slice `app-localization-native-review-intake` remains blocked.

## Residual Risk

- LQA checks deterministic surface properties only — it cannot catch wrong gender, formality, idiom, or argument order. Those still need a native reviewer.
- The format-specifier check skips strict equality for stringsdict `plural_category=one` to honor idiomatic plurals. A real bug in that specific case would slip through.
- Length-outlier warnings for CJK are noisy. Use them as "needs screenshot verification" hints, not as "translation is wrong."
- `lqa.status=passed` is easy to misread as a quality claim. The dashboard, report, tool docstring, and docs all explicitly say it isn't, but downstream agents must read those before drawing conclusions.
- `auto_fix_action="reverted-to-english"` is currently never triggered. If a future LLM pass introduces a bad specifier, it would be silently auto-reverted; downstream tooling that ignores `auto_fix_action` would not know.

## Multi-Agent Note

`localization/review/LQA.md` and `localization/review/STATUS.md` are derived artifacts. Future agents who modify any `<locale>-review-return.json` should re-run:

```bash
python3 Tools/localization-lqa.py --apply --write-md
python3 Tools/localization-review-status.py --write-doc
```

before committing so both reports stay in sync with the return files.
