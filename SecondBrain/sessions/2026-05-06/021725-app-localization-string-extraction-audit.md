# app-localization-string-extraction-audit

## Prompt

Audit remaining user-facing strings after the localization foundation, classify what should be keyed now versus deferred, and avoid translation work.

## Assessment

- The previous slice established `Localizable.strings` for 19 locales and validation parity.
- Source scanning found a mix of direct SwiftUI literals, dynamic/interpolated strings, SF Symbols, color assets, telemetry identifiers, storage keys, date format tokens, and domain/application strings returned as `String`.
- The safe implementation path was to add only direct SwiftUI/accessibility literal keys to `Localizable.strings` and document the deferred buckets that need explicit formatting or code-routing work.

## Changes

- Added `docs/workflows/localization-string-inventory.md` with the classification rule, extracted key groups, deferred buckets, and verification path.
- Linked the inventory from `docs/README.md` and `docs/workflows/validation.md`.
- Added 58 English source keys to every locale file; non-English locales remain English placeholders.
- Did not edit Swift source or product copy.

## Validation

- `python3 automation/context/build_context.py --slice-id app-localization-string-extraction-audit`
- `python3 automation/supervisor/run_next.py --dry-run`
- `make architecture`
- `make localization-check`
- `./Tools/validate.sh localization`
- `make automation-check`
- `xcodebuild build -quiet -project owlory_xcode/Owlory.xcodeproj -scheme Owlory -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/owlory-localization-extraction-build CODE_SIGNING_ALLOWED=NO`
- `git diff --check`

## Residual Risk

- Dynamic/interpolated strings, plural forms, notification text, and domain/application `String` helpers still need a separate code-routing or formatting slice.
- Non-English values are still placeholders and have not received translation review.
- The build still reports the pre-existing `TodayView` `onChange` deprecation warning unrelated to localization.
