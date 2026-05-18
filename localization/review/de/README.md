# German Review Packet

- Target locale: `de`
- Target language: German / Deutsch
- Source locale: `en`
- Purpose: reviewer input for the first localization intake slice

This packet is review input only. It does not replace app resources and does not prove the manual per-app language picker. The accepted German review state is recorded in `german-review-return.json`.

Regenerate the packet against current resources with:

```bash
python3 Tools/german-review-packet-regenerate.py
```

## Files

- `german-review-packet.csv` - flat reviewer packet with one row per English source value or plural category.
- `german-review-packet.json` - structured packet with the same entries and summary metadata.
- `german-review-return.json` - reviewer return file recording the German values accepted by user-reported native/human German review on 2026-05-18. See the `provenance` block inside that file. The previous LLM-draft provenance is preserved under `previous_draft_provenance`.

The German values currently in `de.lproj` originated as LLM-drafted German produced by `claude-opus-4-7` on 2026-05-15 and were accepted by user-reported native/human German review on 2026-05-18. German is the only native-reviewed non-English locale as of this update.

```text
review entries: 419
strings entries: 377
plural entries: 42
review_status counts:
  native-reviewed: 419
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

`app-localization-first-locale-review-intake` was completed on 2026-05-15 by ingesting LLM-drafted German values. `app-localization-native-review-intake` then accepted the current German return file on 2026-05-18 based on user-reported native/human German review. The German return file now has `provenance.native_reviewed=true` and 419 `native-reviewed` entries.
