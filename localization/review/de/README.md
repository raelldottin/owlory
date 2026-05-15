# German Review Packet

- Target locale: `de`
- Target language: German / Deutsch
- Source locale: `en`
- Purpose: reviewer input for the first localization intake slice

This packet is review input only. It does not replace app resources, does not claim German translation quality, and does not prove the manual per-app language picker.

Regenerate the packet against current resources with:

```bash
python3 Tools/german-review-packet-regenerate.py
```

## Files

- `german-review-packet.csv` - flat reviewer packet with one row per English source value or plural category.
- `german-review-packet.json` - structured packet with the same entries and summary metadata.
- `german-review-return.json` - reviewer return file recording the LLM-drafted German values that were ingested on 2026-05-15 by `claude-opus-4-7` (NOT native-reviewed). See `provenance` block inside that file.

The German values currently in `de.lproj` are predominantly LLM-drafted German produced by `claude-opus-4-7` on 2026-05-15. They are `draft-translation` quality and have NOT been accepted by a native or fluent German reviewer.

```text
review entries: 356
strings entries: 314
plural entries: 42
current_status counts:
  draft-translation: 340  (LLM-drafted German values that differ from English)
  english-placeholder: 16 (brand / format / loanword entries kept identical to English: OK, URL, Build, Podcast, Video, Check-in, %@, %@ / 5, %d/%d, etc.)
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

`app-localization-first-locale-review-intake` was completed on 2026-05-15 by ingesting LLM-drafted German values (recorded in `german-review-return.json` with status `needs-layout-check` / `keep-english-term`). A real native-reviewed intake still requires reviewer-supplied values to return through this packet with `review_status = native-reviewed` and a non-LLM `reviewer` identity. Until that happens, German remains `draft-translation` quality and must not be claimed as `native-reviewed`.
