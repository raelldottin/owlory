# Manual App-Language Setting Diagnostic

- Slice: `app-localization-manual-language-setting-diagnostic`
- Trigger: manual TestFlight language testing found that German / Deutsch did not appear as expected.
- Proof level: `doc/build-diagnostic`

## Finding

German missing from the manual per-app language picker is a real diagnostic finding. It is not enough to claim manual German localization proof, and it is not yet a translation-quality failure.

The finding has two possible shapes that future captures should distinguish:

- `no-language-row`: `Settings > Apps > Owlory` has no **Language** or **Preferred Language** row.
- `target-language-missing`: the row exists, but **German / Deutsch** is not listed.

## Local Checks Completed

Repo source has German resources:

```text
owlory_xcode/Owlory/Resources/de.lproj/Localizable.strings
owlory_xcode/Owlory/Resources/de.lproj/Localizable.stringsdict
```

The Xcode project lists `de` in `knownRegions`, and `make localization-check` passes for all 19 approved locales.

An unsigned simulator build from current source packages:

```text
Owlory.app/de.lproj/Localizable.strings
Owlory.app/de.lproj/Localizable.stringsdict
```

The generated app `Info.plist` does not contain `CFBundleLocalizations`; it does contain `CFBundleDevelopmentRegion = en`.

## Not Yet Proven

No local `.ipa` or `.xcarchive` was available in the repository workspace during this diagnostic, so the actual installed TestFlight archive has not been inspected for `de.lproj` packaging.

## Next Diagnostic Step

If German still does not appear after adding German under **Settings > General > Language & Region**, inspect the TestFlight archive or IPA directly:

```bash
unzip -l Owlory.ipa | rg 'de\.lproj/(Localizable\.strings|Localizable\.stringsdict)'

find "Owlory.xcarchive/Products/Applications/Owlory.app" \
  -path '*de.lproj*' -maxdepth 4 -type f

/usr/libexec/PlistBuddy -c 'Print :CFBundleLocalizations' \
  "Owlory.xcarchive/Products/Applications/Owlory.app/Info.plist"
```

If `de.lproj` is packaged in the TestFlight app but iOS still does not expose German, consider a narrow follow-up to add explicit `CFBundleLocalizations` metadata and verify it through a new TestFlight build.

## References

- Apple Support: <https://support.apple.com/en-us/109358>
- Apple Developer QA1828: <https://developer.apple.com/library/archive/qa/qa1828/_index.html>
