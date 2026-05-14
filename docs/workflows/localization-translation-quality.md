# Localization Translation Quality

Use this workflow before replacing English placeholder values in non-English localization files. It separates translation quality from resource readiness, launch stability, and screenshot proof.

## Current Status

Localization is not complete. Treat resource readiness, runtime proof, and translation quality as separate tracks:

- **Infrastructure**: implemented. Owlory has Apple-native `Localizable.strings` and `Localizable.stringsdict` resources for all approved locales.
- **Packaging and parity**: implemented. `make localization-check` verifies locale folders, key parity, plural resources, and Xcode variant-group packaging.
- **Representative runtime proof**: implemented for `en`, `es`, `fr`, `ar`, and `zh-Hans` only. This proves representative resource loading and launch stability, not every locale.
- **Representative screenshot proof**: implemented for `en`, `es`, `fr`, `ar`, and `zh-Hans` launch surfaces only. This does not prove translation quality or full layout correctness.
- **Translation review input**: prepared. The generated review packet exists, and the German-first packet is ready under `localization/review/de/`.
- **All-locale smoke**: implemented. `app-localization-all-locale-smoke` passed for all 19 supported locales and proves launch/resource loading only.
- **Reviewed translations**: incomplete. No non-English locale may be claimed as reviewed until translated values return with reviewer/status metadata and are ingested.
- **Translation quality**: incomplete. Non-English resources remain English placeholders unless a scoped intake slice explicitly records reviewed replacements.

English (`en`) remains the source language and key source of truth. The approved non-English locales are: `ar`, `nl`, `fr`, `de`, `it`, `ja`, `ko`, `nb`, `pt`, `pt-BR`, `ru`, `es`, `sv`, `zh-Hans`, `zh-Hant`, `tr`, `uk`, and `vi`.

As of the all-locale smoke proof, every non-English `Localizable.strings` file has 282 values exactly matching English, and every non-English `Localizable.stringsdict` file has the same 11 plural resources as English. German appearing in Settings while the app still displays English is expected until `de.lproj` contains reviewed German values instead of English placeholders.

## Status Labels

Use these labels in handoffs and review notes:

| Label | Meaning | Can claim translation quality? |
| --- | --- | --- |
| `english-source` | English source key/value reviewed as product copy. | Only for `en`. |
| `english-placeholder` | Non-English locale value is intentionally copied from English. | No. |
| `draft-translation` | Candidate translated value exists but has not been reviewed by a native or fluent reviewer. | No. |
| `native-reviewed` | Native or fluent reviewer accepted the locale values for the scoped keys. | Yes, for reviewed keys only. |
| `runtime-smoked` | The locale launched in the simulator after translation replacement. | No by itself. |
| `screenshot-reviewed` | Repo-managed screenshot evidence exists for the translated surface. | No by itself; it proves visual evidence, not language quality. |

## Review Workflow

1. Pick one locale or one small language family per slice. Do not bulk-replace all locales in one pass.
2. Start from the review packet in `localization/review/`, regenerated from current resources when needed.
3. Translate only existing keys unless the slice is explicitly a source-string extraction slice.
4. Preserve placeholders for keys outside the slice. Do not delete or invent locale-only keys.
5. For `.stringsdict`, review grammar for `one` and `other` forms even when the locale does not use English plural categories naturally.
6. Record the reviewer basis in the handoff: native reviewer, fluent reviewer, vendor, or machine draft awaiting review.
7. Run validation before claiming the locale is accepted.

Machine or AI translation may produce `draft-translation`, but it cannot produce `native-reviewed` without a human reviewer record.

## Review Export Packet

Regenerate the reviewer packet before translation replacement work:

```bash
python3 Tools/localization-review-export.py --output-dir localization/review
```

The export reads `Localizable.strings` and `Localizable.stringsdict` from all approved locales, keeps English as the source row, labels non-English values that still match English as `english-placeholder`, and writes:

- `localization/review/translation-review-export.csv`
- `localization/review/translation-review-export.json`
- `localization/review/README.md`

The packet is reviewer input only. It does not claim translation completeness, native review, launch stability, layout correctness, device behavior, or TestFlight behavior.

## Acceptance Criteria

A future translation replacement slice may claim translation quality only for its scoped locale and keys when all of these are true:

- `make localization-check` passes.
- `./Tools/validate.sh localization` passes.
- `make architecture` passes.
- No approved locale has missing or extra keys.
- No new locale folder is introduced unless the target locale list is deliberately changed.
- The handoff identifies which keys changed and which reviewer accepted them.
- Placeholders outside the slice remain explicitly classified as placeholders.
- A locale smoke or screenshot proof is run when the slice changes high-visibility navigation, Today launch surfaces, notification copy, or RTL/CJK text.

## Locale Review Notes

- `ar`: Requires Arabic review and RTL screenshot review for visible surfaces before release-quality claims.
- `zh-Hans` and `zh-Hant`: Review separately. Do not treat Simplified and Traditional Chinese as interchangeable.
- `pt` and `pt-BR`: Review separately. Do not copy one into the other without explicit reviewer acceptance.
- `nb`: Treat as Norwegian Bokmål. Do not replace with generic Norwegian without review.
- `ja` and `ko`: Review typography-sensitive short labels and truncation-prone surfaces with screenshots.
- `de`, `nl`, `sv`, `ru`, `uk`, and `tr`: Watch compound words, grammatical case, and truncation in tab labels, buttons, and notification bodies.

## Terminology To Review Deliberately

These product terms should not be translated casually or inconsistently:

- `Owlory`
- `Today`
- `Train`
- `Write`
- `Career`
- `Home`
- `Continue`
- `Focus Three`
- `Check-in`
- `Protocol`
- `Reminder`
- `Weekly Digest`
- `Reflection`

For each locale, the reviewer may choose translated or retained product terms, but the choice must be consistent across the locale.

## What Not To Do

- Do not change English product copy inside a translation slice unless the slice explicitly owns English source copy.
- Do not localize persisted identifiers, enum raw values, storage paths, telemetry names, route names, SF Symbol names, color asset names, or build diagnostics.
- Do not add user-visible placeholder warnings.
- Do not claim translation completeness from parity checks, simulator launch, or screenshots alone.
- Do not use translation work to fix layout; queue a separate layout slice if translated text exposes a UI issue.

## Validation

Planning-only slices use:

```bash
python3 automation/context/build_context.py --slice-id app-localization-translation-quality-plan
python3 automation/supervisor/run_next.py --dry-run
make architecture
make localization-check
./Tools/validate.sh localization
make automation-check
git diff --check
```

Translation review export slices use:

```bash
python3 Tools/localization-review-export.py --output-dir localization/review
make architecture
make localization-check
./Tools/validate.sh localization
make automation-check
git diff --check
```

Translation replacement slices should add the affected locale smoke command and screenshot proof when the changed keys affect high-visibility launch or navigation surfaces.

## German First Review Packet

The first locale review packet is prepared under:

```text
localization/review/de/
```

It contains:

- `german-review-packet.csv`
- `german-review-packet.json`
- `README.md`

Use this packet to collect reviewed German values and reviewer/status metadata. It is not an app-resource replacement and does not claim German translation quality. `app-localization-first-locale-review-intake` stays blocked until reviewed rows return with `reviewed_de_value`, `review_status`, reviewer identity, and review date.

As of 2026-05-14, manual follow-up confirmed that tested German translation values do not exist yet. Do not start `app-localization-first-locale-review-intake` from the current packet alone; it remains review input with English placeholders until reviewed German values are returned with the required metadata.

## Manual Device Review

For TestFlight or physical-device translation review, testers may switch only Owlory's app language instead of changing the whole phone:

```text
Settings > Apps > Owlory > Language
```

If the Owlory language picker does not appear, add the target language first:

```text
Settings > General > Language & Region > Add Language
```

Keep the current iPhone language as primary unless the slice is explicitly testing full-device language behavior. Then return to Owlory's per-app language setting, select the target language, close Owlory, and reopen it.

Use this only for manual/TestFlight review. Automated localization smoke should continue using `python3 automation/smoke/running_app_smoke.py --locale <locale>` and launch arguments, not the Settings app.

If German or another target language does not appear in Owlory's per-app language picker, do not classify the locale as translation-failed yet. First run the manual language-setting diagnostic from [Validation Workflows](validation.md#manual-per-app-language-testing): confirm the language is in the iPhone's preferred language list, verify the installed build packages the matching `.lproj` resources, and inspect whether the installed build needs explicit `CFBundleLocalizations` metadata.
