# app-localization-review-drift-check-stringsdict-coverage

## Prompt

> "start next slice" — execute the supervisor-selected slice `app-localization-review-drift-check-stringsdict-coverage`.

## What was done

Tooling slice. Extended `Tools/localization-review-drift-check.py` so per-plural-category stringsdict drift and stringsdict english_value drift are detected, not silently passed.

### Tool changes

**New function:**

```python
def parse_stringsdict_entries(path: Path) -> dict[tuple[str, str, str], str]:
    """{(key, plural_variable, plural_category): english_value}, skipping
    NSStringLocalizedFormatKey + NSStringFormat*TypeKey metadata."""
```

**Parameter rename and new drift dimensions in `analyze_locale`:**

| Field | Meaning |
|---|---|
| `missing_stringsdict_tuples` | Source tuple absent from return file (per-plural-category granularity) |
| `stale_stringsdict_tuples` | Return file row whose source tuple no longer exists |
| `changed_stringsdict_english_values` | Source `english_value` differs from return file's `english_value` for the same `(key, plural_variable, plural_category)` tuple |

Existing strings-level drift dimensions preserved unchanged. Top-level stringsdict key drift (`missing_stringsdict_keys` / `stale_stringsdict_keys`) preserved alongside the new tuple-level fields for cross-referencing.

**Human-readable output additions:**

```
localization-review-drift-check: 377 strings keys + 13 stringsdict keys (42 plural tuples) in source (owlory_xcode/Owlory/Resources/en.lproj/Localizable.strings)
  locales inspected: 18; locales with drift: 0; total drift count: 0
  result: no drift
```

Per-locale drift lines now print missing/stale stringsdict plural tuples + changed stringsdict english_value sections when present.

### Tests

`automation/tests/test_localization_review_drift_check.py`:

- 3 new tests under `ParseStringsdictEntriesTests`: missing-file, key+plural+category enumeration, metadata-key skipping.
- 4 new tests under `AnalyzeLocaleStringsdictDriftTests`: detects missing/stale/changed tuples + no-drift when tuples match.
- Updated 4 existing `AnalyzeLocaleTests` to pass the new `source_stringsdict_entries` dict shape.
- Updated `test_no_drift_when_keys_and_english_match` to include a complete stringsdict tuple row in the return payload.

Drift module test count: 15 → 22. `make automation-check`: 86 → 93. All green.

### Doc update

`docs/workflows/localization-translation-quality.md` — "Review Drift Check" section now describes stringsdict per-plural-category tuple drift alongside strings drift.

### Baseline

```
Source: 377 strings keys + 13 stringsdict keys (42 plural tuples)
Locales inspected: 18
Locales with drift: 0
Total drift count: 0
```

The 18 non-English return files (after the all-locale native review intake at 2026-05-18T07:55) carry every (key, plural_variable, plural_category) tuple from source and every `english_value` matches. Drift baseline preserved.

## Validation

- `python3 automation/context/build_context.py --slice-id app-localization-review-drift-check-stringsdict-coverage` — ran.
- `python3 automation/supervisor/run_next.py --dry-run` — selected this slice pre-commit.
- `make architecture` — passed.
- `make localization-check` — 19 / 377 / 13.
- `make localization-review-drift-check` — 0 drift across 18 locales.
- `make automation-check` — 93 tests passed (7 new).
- `make pyright` — 0 errors / 0 warnings.
- `git diff --check` — clean.

## Lane Boundary

`build-tested`. New parse function + drift dimensions + tests + doc. No app source change, no translation change, no return-file mutation.

## Residual Risk

- `NSStringFormatSpecTypeKey` / `NSStringFormatValueTypeKey` changes in stringsdict are intentionally NOT tracked — they're non-translatable metadata; tracking them would create noise.
- Older return-file formats lacking the three fields per row would now appear as drift (missing tuples). Owlory's current return files all carry `key + plural_variable + plural_category + english_value` per the 2026-05-18 native-review intake, so no regression.
- `make localization-review-drift-check` is still a separate gate, not folded into `make automation-check`. The follow-up `app-localization-review-drift-check-gate-promotion` (pri 59) is now eligible.

## Not Claimed

- Every CLDR plural category is exhaustively covered (tracked whatever appears in source; new categories show as missing-in-return, which is the intended signal).
- Stringsdict format-specifier integrity is now verified (separate concern; out of scope).
- The gate has been promoted (the promotion slice is now eligible but not run).

## Next slice

`app-localization-review-drift-check-gate-promotion` (pri 59) is now eligible. Per Owlory's supervisor convention (lower priority number = picked first), the supervisor's next pick may be a lower-numbered slice if any remain queued.
