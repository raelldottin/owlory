# Localization Review Export

This packet exports Owlory's current localization resources for translation review. It is reviewer input, not a translation-quality claim.

Generated with:

```bash
python3 Tools/localization-review-export.py --output-dir localization/review
```

Files:

- `translation-review-export.csv` - reviewer-friendly flat rows for `Localizable.strings` and `Localizable.stringsdict` values. Newlines are escaped as `\n` so each review row stays on one CSV line.
- `translation-review-export.json` - structured packet preserving locale values, status labels, and summary counts.
- Per-locale return files under `<locale>/` record accepted review state. All 18 non-English locale return files are native/fluent-reviewed as of 2026-05-18.

Status labels:

- `english-source`: English source value.
- `english-placeholder`: non-English value currently matches English and still needs translation review.
- `draft-translation`: non-English value differs from English but has not been accepted by a native or fluent reviewer.

Use `docs/workflows/localization-translation-quality.md` before replacing placeholder values. Do not claim native review from this export alone.
