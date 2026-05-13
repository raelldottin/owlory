# app-localization-manual-language-setting-diagnostic

## Summary

Recorded the manual finding that German / Deutsch did not appear in per-app language testing.

This is not a translation-quality failure yet. It is a manual/TestFlight diagnostic finding.

## Findings

- Source has `owlory_xcode/Owlory/Resources/de.lproj/Localizable.strings`.
- Source has `owlory_xcode/Owlory/Resources/de.lproj/Localizable.stringsdict`.
- Xcode `knownRegions` contains `de`.
- `make localization-check` passes.
- An unsigned simulator build packages `Owlory.app/de.lproj/Localizable.strings` and `Owlory.app/de.lproj/Localizable.stringsdict`.
- Built app `Info.plist` has `CFBundleDevelopmentRegion = en`.
- Built app `Info.plist` does not contain `CFBundleLocalizations`.
- No local TestFlight `.ipa` or `.xcarchive` was available for direct archive inspection.

## Docs Updated

- `docs/workflows/validation.md`
- `docs/workflows/localization-translation-quality.md`
- `docs/workflows/ui-testing-hygiene.md`

## Proof Artifact

```text
automation/proofs/app-localization-manual-language-setting-diagnostic/
```

## Next

If German still does not appear after German is added under `Settings > General > Language & Region`, inspect the actual TestFlight IPA or xcarchive for `de.lproj` and `CFBundleLocalizations` before changing app metadata.
