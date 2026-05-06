# app-localization-today-plurals

## Prompt

Localize Today dashboard count strings and accessibility interpolation only, using the dynamic localization boundary from the previous planning slice.

## Assessment

- Today dashboard summaries still built several count strings inline in `TodayView`.
- The affected visible surfaces were the Train, Write, Career, and Home dashboard cards plus the readiness-scale accessibility label.
- Digest copy, notification copy, protocol schedule/status text, quick-add recurrence text, and translation quality were explicitly out of scope.

## Changes

- Routed Today dashboard count summaries through localized formatting helpers in `TodayView`.
- Added `Localizable.stringsdict` resources for all 19 approved locales with 7 English placeholder plural/dynamic keys.
- Added `Localizable.stringsdict` to the Xcode app target through a `PBXVariantGroup`.
- Extended `Tools/localization-parity.sh` to validate `.stringsdict` syntax, key parity, and Xcode packaging.
- Updated localization workflow docs to record that Today dashboard plural formatting is partially implemented.

## Validation

- `python3 automation/context/build_context.py --slice-id app-localization-today-plurals`
- `python3 automation/supervisor/run_next.py --dry-run`
- `make architecture`
- `make localization-check`
- `./Tools/validate.sh localization`
- `make automation-check`
- `make test-domain DOMAIN=today`
- `xcodebuild build -quiet -project owlory_xcode/Owlory.xcodeproj -scheme Owlory -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/owlory-today-plurals-build CODE_SIGNING_ALLOWED=NO`
- `git diff --check`

## Residual Risk

- Non-English `.stringsdict` values are still English placeholders and need translation-quality review.
- Digest counts, notification copy, protocol schedule/status projection, quick-add recurrence text, and model display-name adapters remain deferred dynamic localization work.
- The unsigned simulator build still reports the pre-existing `TodayView` `onChange` deprecation warning unrelated to this slice.
