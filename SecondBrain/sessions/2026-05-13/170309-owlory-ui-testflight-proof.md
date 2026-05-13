# owlory-ui-testflight-proof

## Summary

Promoted the fresh clean TestFlight screenshots into a maintained proof packet.

The Build Info gate passed for:

- Owlory `0.2.0 (20260513202827)`
- clean commit `adb5de52bf90233e64257d5c0aa1dc37f59a6bf2`
- branch `main`
- Git status `clean`
- configuration `Release`
- bundle `com.raelldottin.owlory`
- Build source `Xcode CURRENT_PROJECT_VERSION`

The stamped commit is present on `origin/main`, and its committed Xcode project has `CURRENT_PROJECT_VERSION = 20260513202827`.

## Proof

Artifacts live in:

```text
automation/proofs/owlory-ui-testflight-proof/20260513T205620Z-provenance-intake/
```

Captured screenshots:

- `01-build-info-overview.png`
- `02-build-info-provenance.png`
- `03-continue-surface.png`
- `04-route-or-result.png`

The behavior claim is intentionally narrow: Today Continue launch surface plus one natural-data Home protocol run route into the active run sheet.

## Not Claimed

- every Continue source
- broad Continue routing matrix
- debug-seeded parity on TestFlight
- full UI regression coverage
- App Store production behavior

## Verification

```bash
git cat-file -e adb5de52bf90233e64257d5c0aa1dc37f59a6bf2^{commit}
git show adb5de52bf90233e64257d5c0aa1dc37f59a6bf2:owlory_xcode/Owlory.xcodeproj/project.pbxproj | rg 'CURRENT_PROJECT_VERSION' | sort -u
git branch --contains adb5de52bf90233e64257d5c0aa1dc37f59a6bf2 --all
shasum -a 256 automation/proofs/owlory-ui-testflight-proof/20260513T205620Z-provenance-intake/*.png
sips -g pixelWidth -g pixelHeight automation/proofs/owlory-ui-testflight-proof/20260513T205620Z-provenance-intake/*.png
```

## Next

Clean stop is valid. Broaden TestFlight proof only if a new concrete release-channel path needs proof.
