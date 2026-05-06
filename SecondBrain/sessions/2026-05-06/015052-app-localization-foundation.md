# app-localization-foundation

## Prompt

Add first-class app localization support for Owlory for 19 target locales without changing product behavior, architecture boundaries, or UI intent.

## Assessment

- Owlory had no existing `*.lproj`, `Localizable.strings`, `.stringsdict`, or string catalog resources.
- `owlory_xcode/Owlory.xcodeproj/project.pbxproj` used `developmentRegion = en`, `knownRegions = (en, Base)`, and packaged only `Assets.xcassets` in the app Resources phase.
- The safest first slice was an Apple-native `Localizable.strings` foundation under `owlory_xcode/Owlory/Resources`, wired through a `PBXVariantGroup`, plus parity validation.

## Changes

- Added `Localizable.strings` for `en`, `ar`, `nl`, `fr`, `de`, `it`, `ja`, `ko`, `nb`, `pt`, `pt-BR`, `ru`, `es`, `sv`, `zh-Hans`, `zh-Hant`, `tr`, `uk`, and `vi`.
- Kept English as the source values. Non-English locales intentionally retain English placeholder values with developer comments only.
- Added `Tools/localization-parity.sh` and `make localization-check` to verify locale folders, key parity, and Xcode variant-group packaging.
- Wired `Localizable.strings` into the app target using `PBXVariantGroup` and expanded Xcode `knownRegions`.
- Added localization validation guidance to `docs/workflows/validation.md`.

## Validation

- `python3 automation/context/build_context.py --slice-id app-localization-foundation`
- `python3 automation/supervisor/run_next.py --dry-run`
- `make architecture`
- `make localization-check`
- `./Tools/validate.sh localization`
- `plutil -lint owlory_xcode/Owlory.xcodeproj/project.pbxproj`
- `xcodebuild build -project owlory_xcode/Owlory.xcodeproj -scheme Owlory -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/owlory-localization-build CODE_SIGNING_ALLOWED=NO`
- `find /tmp/owlory-localization-build/Build/Products/Debug-iphonesimulator/Owlory.app -maxdepth 2 -path '*/Localizable.strings' -print`
- `make automation-check`
- `git diff --check`

## Residual Risk

- Non-English translations are placeholders, not reviewed localized copy.
- This slice seeds common visible copy keys and relies on existing SwiftUI localized-string literal APIs; it does not exhaustively rewrite every hardcoded string or dynamic interpolation.
- The simulator build still reports a pre-existing `TodayView` `onChange` deprecation warning unrelated to localization.
