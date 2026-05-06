# Localization Translation Quality

Use this workflow before replacing English placeholder values in non-English localization files. It separates translation quality from resource readiness, launch stability, and screenshot proof.

## Current Status

- English (`en`) is the source language and remains the key source of truth.
- Approved non-English locales are resource-ready but translation-unreviewed: `ar`, `nl`, `fr`, `de`, `it`, `ja`, `ko`, `nb`, `pt`, `pt-BR`, `ru`, `es`, `sv`, `zh-Hans`, `zh-Hant`, `tr`, `uk`, `vi`.
- As of this plan, every non-English `Localizable.strings` file has 282 values exactly matching English, and every non-English `Localizable.stringsdict` file has the same 11 plural resources as English.
- Locale packaging, parity, representative running-app smoke, and representative launch-surface screenshot proof are complete. Translation quality is still deferred.

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
2. Start from English source keys in `owlory_xcode/Owlory/Resources/en.lproj/`.
3. Translate only existing keys unless the slice is explicitly a source-string extraction slice.
4. Preserve placeholders for keys outside the slice. Do not delete or invent locale-only keys.
5. For `.stringsdict`, review grammar for `one` and `other` forms even when the locale does not use English plural categories naturally.
6. Record the reviewer basis in the handoff: native reviewer, fluent reviewer, vendor, or machine draft awaiting review.
7. Run validation before claiming the locale is accepted.

Machine or AI translation may produce `draft-translation`, but it cannot produce `native-reviewed` without a human reviewer record.

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

Translation replacement slices should add the affected locale smoke command and screenshot proof when the changed keys affect high-visibility launch or navigation surfaces.
