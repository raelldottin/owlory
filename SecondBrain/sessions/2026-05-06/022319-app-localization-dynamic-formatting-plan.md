# app-localization-dynamic-formatting-plan

## Prompt

Define where dynamic localization is allowed to live so Owlory can localize counts, dates, statuses, notifications, and display labels without leaking presentation concerns into pure domain logic.

## Assessment

- Localization resources and parity checks already exist for 19 locales.
- The string extraction audit identified deferred dynamic buckets: plural/count strings, digest dates/counts, notification copy, protocol schedule/status text, and domain/application display-name helpers.
- A code implementation slice would be risky before writing the ownership contract because dynamic localization can easily push SwiftUI or presentation copy into `Core/Domain`.

## Changes

- Added `docs/workflows/localization-dynamic-formatting.md` with the boundary rule, API guidance, implementation batches, validation paths, risks, and out-of-scope items.
- Linked the contract from `docs/README.md`, `docs/workflows/localization-string-inventory.md`, and `docs/workflows/validation.md`.
- Added a concise localization boundary to `docs/architecture/boundaries.md`.
- Did not edit Swift source, localization resource keys, or translations.

## Validation

- `python3 automation/context/build_context.py --slice-id app-localization-dynamic-formatting-plan`
- `python3 automation/supervisor/run_next.py --dry-run`
- `make architecture`
- `make localization-check`
- `./Tools/validate.sh localization`
- `make automation-check`
- `git diff --check`

## Residual Risk

- Dynamic localization remains unimplemented. The next slices must still extract counts/plurals, digest formatting, protocol schedule/status projection, notification copy, and display-name adapters.
- Non-English locale values remain English placeholders until translation-quality work.
- Runtime locale smoke and screenshot proof remain deferred.
