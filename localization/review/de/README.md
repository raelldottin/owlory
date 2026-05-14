# German Review Packet

- Target locale: `de`
- Target language: German / Deutsch
- Source locale: `en`
- Purpose: reviewer input for the first localization intake slice

This packet is review input only. It does not replace app resources, does not claim German translation quality, and does not prove the manual per-app language picker.

## Files

- `german-review-packet.csv` - flat reviewer packet with one row per English source value or plural category.
- `german-review-packet.json` - structured packet with the same entries and summary metadata.

The current German values are all `english-placeholder` values copied from English:

```text
review entries: 320
strings entries: 282
plural entries: 38
```

## Reviewer Return Format

For each row being reviewed, fill these fields:

- `reviewed_de_value`: accepted German value, or the intentionally retained English term.
- `review_status`: one of:
  - `native-reviewed`
  - `needs-product-decision`
  - `keep-english-term`
  - `needs-layout-check`
  - `reject`
- `reviewer`: reviewer name, initials, vendor, or review source.
- `review_date`: ISO date, for example `2026-05-13`.
- `reviewer_notes`: short note for product terminology, layout risk, or unresolved wording.

Do not add, delete, or rename keys. If a source value is unclear, mark `needs-product-decision` instead of guessing.

## Plurals

Plural rows come from `Localizable.stringsdict`. Review the German grammar for each plural category even when the English placeholder looks usable. The intake slice must preserve key and plural parity.

## After Review

The next implementation slice is `app-localization-first-locale-review-intake`, but it remains blocked until reviewed German values return with reviewer/status metadata.
