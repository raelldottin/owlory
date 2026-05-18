# app-localization-review-drift-check

## Prompt

> "start next slice" — execute the supervisor-selected slice `app-localization-review-drift-check`.

## What was done

Tooling slice. Added a maintained drift check that compares Owlory's current source strings against each per-locale review return file. No app source change, no translation change, no proof artifact.

### `Tools/localization-review-drift-check.py` (new)

CLI tool with three modes:

- Default: prints a human-readable per-locale drift report; exit 0 even if drift.
- `--check`: exit non-zero on any drift.
- `--json`: machine-readable structured report.

Per-locale drift dimensions:

| Dimension | Meaning |
|---|---|
| `missing_strings_keys` | Source key added; not yet reviewed |
| `stale_strings_keys` | Return-file entry references a key no longer in source |
| `missing_stringsdict_keys` | Stringsdict key added; not yet in return file |
| `stale_stringsdict_keys` | Return file lists a stringsdict key no longer in source |
| `changed_english_values` | Source `english_value` edited after the review entry was recorded |

Reads:

- `owlory_xcode/Owlory/Resources/en.lproj/Localizable.strings`
- `owlory_xcode/Owlory/Resources/en.lproj/Localizable.stringsdict` (via `plutil`)
- `localization/review/<locale>/<locale>-review-return.json` (German uses the legacy `german-review-return.json` filename)

Writes: nothing. Reporting only.

### `automation/tests/test_localization_review_drift_check.py` (new)

10 unit tests:

- `parse_strings_file` parses simple pairs, returns empty when file missing, unescapes escaped quotes.
- `analyze_locale` reports `status=ok` with `drift_count=0` when source and return agree, plus dedicated tests for missing-in-return, stale-in-return, changed-english-value, and missing-return-file scenarios.
- `main(--check)` exits non-zero on drift; reporting-only mode exits zero.

`make automation-check` now runs 81 tests (was 71); all green.

### `Makefile` target

`make localization-review-drift-check` runs the tool with default flags. It is **not** folded into `make automation-check`; CI/agents invoke it deliberately.

### Doc updates

| File | Change |
|---|---|
| `docs/workflows/validation.md` | New `make localization-review-drift-check` bullet under Common Commands |
| `docs/workflows/localization-translation-quality.md` | New "Review Drift Check" section after the review packet section, explaining the three drift dimensions and the reporting-only/`--check` modes |

### Baseline

```
377 strings keys + 13 stringsdict keys in source
locales inspected: 18; locales with drift: 0; total drift count: 0
result: no drift
```

The 18 non-English return files (after the all-locale native review intake at 2026-05-18T07:55) are in sync with the current source key set.

## Validation

- `python3 automation/context/build_context.py --slice-id app-localization-review-drift-check` — ran.
- `python3 automation/supervisor/run_next.py --dry-run` — selected this slice pre-commit.
- `make architecture` — passed.
- `make localization-check` — 19 / 377 / 13.
- `make localization-review-drift-check` — 0 drift across 18 locales.
- `make automation-check` — 81 tests passed (10 new for drift check).
- `make pyright` — 0 errors / 0 warnings.
- `git diff --check` — clean.

## Lane Boundary

`build-tested`. Tool + tests + Makefile + docs. No app source, no translation, no proof artifact.

## Residual Risk

- Per-stringsdict-key plural-category drift (e.g., a new `one` or `other` form added) is not detected — the tool tracks top-level stringsdict keys only.
- If a stringsdict entry's translated `english_value` changes, it is not detected — only strings rows are compared on `english_value`.
- `parse_stringsdict_keys` shells out to `plutil` (Apple-only). On a non-macOS host the function silently returns an empty set, which would surface as drift; consider raising an explicit error if Owlory ever runs this outside macOS.
- `make localization-review-drift-check` is a separate gate, not folded into `make automation-check`. Future work could add it to a release-preflight or a periodic CI check.

## Not Claimed

- The drift check validates translation quality (it only compares keys + english_value).
- The drift check is automatically gated by CI (separate `make` target, must be invoked deliberately).
- All translation-relevant drift surfaces are covered (stringsdict plural-category drift is out of scope).

## Next slice

`app-localization-smaller-width-accessibility-regression` (pri 65) is the next queued slice with the highest priority.
