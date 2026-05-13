# TestFlight Proof Gate Pass

- Attempt: `20260513T205620Z`
- Slice: `owlory-ui-test-testflight-proof`
- Installed build: Owlory `0.2.0 (20260513202827)`
- Stamped commit: `adb5de52bf90233e64257d5c0aa1dc37f59a6bf2`
- Device: paired iPhone, iOS `26.4.2`

## Gate Verdict

Passed.

The installed TestFlight build's Build Info screenshots show:

```text
Version:       0.2.0
Build:         20260513202827
Commit:        adb5de52bf90
Full commit:   adb5de52bf90233e64257d5c0aa1dc37f59a6bf2
Branch:        main
Git status:    clean
Built:         2026-05-13T20:29:26Z
Configuration: Release
Bundle:        com.raelldottin.owlory
Build source:  Xcode CURRENT_PROJECT_VERSION
```

The stamped commit is present on `origin/main`, and its committed Xcode project records:

```text
CURRENT_PROJECT_VERSION = 20260513202827;
```

## Behavior Captured

The preserved behavior proof is intentionally narrow:

- `03-continue-surface.png` shows the TestFlight Today surface with natural-data Continue rows.
- `04-route-or-result.png` shows the `Morning Routine` Continue row opening the active Home protocol run sheet.

This reaches `testflight-verified` for the captured natural-data TestFlight path only: Today Continue launch surface plus one Home protocol run route.

## What This Does Not Prove

- It does not prove every Continue source.
- It does not prove all Continue routing.
- It does not prove debug-seeded parity; no debug seed flags were used.
- It does not prove broad UI regression coverage.
- It does not prove App Store production behavior beyond this TestFlight install.

## Verification Commands

```bash
git cat-file -e adb5de52bf90233e64257d5c0aa1dc37f59a6bf2^{commit}
git show adb5de52bf90233e64257d5c0aa1dc37f59a6bf2:owlory_xcode/Owlory.xcodeproj/project.pbxproj | rg 'CURRENT_PROJECT_VERSION' | sort -u
git branch --contains adb5de52bf90233e64257d5c0aa1dc37f59a6bf2 --all
shasum -a 256 automation/proofs/owlory-ui-testflight-proof/20260513T205620Z-provenance-intake/*.png
sips -g pixelWidth -g pixelHeight automation/proofs/owlory-ui-testflight-proof/20260513T205620Z-provenance-intake/*.png
```
