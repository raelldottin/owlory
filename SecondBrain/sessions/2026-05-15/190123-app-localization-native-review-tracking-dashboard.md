# app-localization-native-review-tracking-dashboard

## Prompt

User explicitly selected this slice. Scope (paraphrased from user's earlier triage): summarize per-locale counts by status; show needs-layout-check / keep-english-term / native-reviewed; do not change app resources; do not claim quality.

## Files Edited

- `Tools/localization-review-status.py` — **new file**. Reads every per-locale return file under `localization/review/<locale>/` and emits a status summary. Supports both the canonical `<locale>-review-return.json` filename (used by 17 locales) and the legacy `german-review-return.json` filename (used by `de/`). Outputs a stdout table by default; with `--write-doc` also writes `localization/review/STATUS.md`. Reports a locale as native-reviewed only when its return file's `provenance.native_reviewed` flag is `true`.
- `localization/review/STATUS.md` — **new file**. The dashboard output written by `python3 Tools/localization-review-status.py --write-doc`. Markdown table per locale showing entries, native-reviewed flag, per-status counts, reviewer string, and review date. Plus aggregate totals across all 18 non-English locales.
- `automation/queue/slices.json` — added two slices:
  - `app-localization-native-review-tracking-dashboard` (done, priority 110, depends_on `app-localization-first-locale-review-intake`).
  - `app-localization-native-review-intake` (blocked, priority 105, depends_on this dashboard; entry condition requires at least one human/native-supplied native-reviewed return file).
- `SecondBrain/INDEX.md` — index entry for this slice.

## Current Dashboard Output (2026-05-15)

```
Locales tracked: 18
Locales with return files: 18
Native-reviewed locales: 0

Aggregate status counts (across all locale return files):
  native-reviewed           0
  needs-layout-check        6132
  needs-product-decision    0
  keep-english-term         242
  needs-translation         34
  reject                    0
```

All 18 non-English locales (ar, nl, fr, de, it, ja, ko, nb, pt, pt-BR, ru, es, sv, zh-Hans, zh-Hant, tr, uk, vi) hold 356 entries each. None are native-reviewed. The 34 `needs-translation` entries come from the multi-locale script's fallback path where the LLM-drafter did not provide a target for a specific (rare) string key — those rows fall back to English placeholder, awaiting either a native review or a follow-up LLM pass.

## Validation

- `make architecture` — passed.
- `make automation-check` — 57 tests passed.
- `git diff --check` — clean.
- `python3 Tools/localization-review-status.py` — table renders, totals correct.
- `python3 Tools/localization-review-status.py --write-doc` — writes `localization/review/STATUS.md`.

## Lane Boundary

`doc-only`. The dashboard is reporting infrastructure: it reads, it does not write app resources or alter review return files. It cannot make a translation-quality claim — it can only surface whatever each return file already says. The aggregate "0 native-reviewed locales" line is a direct read of `provenance.native_reviewed` flags.

## Residual Risk

- **The dashboard does not validate return-file correctness.** If a future return file ships with `provenance.native_reviewed: true` but the underlying `reviewed_value` rows are still LLM-drafted, the dashboard will faithfully report it as native-reviewed. A second tool (or a manual review gate) is needed before flipping the flag.
- **Status labels in return files are advisory, not enforced.** A LLM-generated return file could mistakenly use `native-reviewed` — the dashboard would surface it but not fail. The `app-localization-native-review-intake` slice will need its own input validation when unblocked.
- **The dashboard counts include both strings and stringsdict entries.** Per-resource breakdown (282 strings + 38 stringsdict in the original packet schema, or 314 + 42 in the current resources) is not split out. If reviewers want to track string-only vs plural-only progress, a follow-up enhancement would add a per-resource_type breakdown.
- **The all-locale review export tool (`Tools/localization-review-export.py`) overwrites `localization/review/README.md` on every run** and would not know to update the new `STATUS.md`. Treat `STATUS.md` as separately maintained — re-run the dashboard tool whenever a return file changes.

## Multi-Agent Note

`localization/review/STATUS.md` is a derived artifact. Future agents who modify any `<locale>-review-return.json` should re-run `python3 Tools/localization-review-status.py --write-doc` before committing so the dashboard stays in sync.
