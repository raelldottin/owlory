# App Icon Asset Workflow

Use this workflow before cleaning app-icon artifacts or deciding which icon path is canonical.

## Canonical Source

The shipped app icon source of truth is:

```text
owlory_xcode/Owlory/Resources/Assets.xcassets/AppIcon.appiconset
```

The Xcode project includes `Assets.xcassets` in Resources and sets `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`.

No root-level `Owlory_*AppIcon*` folder, loose PNG, or historical zip archive is a shipping source of truth.

## Export / Build Path

There is one supported icon build path:

1. update the canonical `owlory_xcode/Owlory/Resources/Assets.xcassets/AppIcon.appiconset`
2. let Xcode compile that asset catalog with `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`
3. verify the result with `./Tools/verify-app-icons.sh`

If a design variant is worth remembering, keep the note in this doc rather than a second drop-in `AppIcon.appiconset` bundle at the repository root.

## Verification

Run:

```bash
./Tools/verify-app-icons.sh
```

The verifier is read-only. It confirms:

- the canonical asset catalog exists
- required shipped icon files exist
- Xcode compiles `AppIcon`
- any root icon bundles are treated as non-canonical
- any loose root icon references are treated as non-canonical

## Cleanup Rule

- Keep the canonical shipped asset catalog.
- Treat every root-level app-icon bundle, export folder, mockup, or loose reference image as non-canonical by default.
- Promote any still-useful variant note into this document before deleting the root artifact.
- Remove root-level asset sets that can be mistaken for shipping truth once the verifier proves the canonical catalog remains the build input.

Do not combine app-icon cleanup with legacy docs, duplicate code, or project-archive cleanup.

## Classified Root Icon Sets

Root `AppIcon.appiconset` bundles are more dangerous than historical notes because they look like live shipping assets.

| Folder | Evidence | Classification | Action |
| --- | --- | --- | --- |
| `Owlory_AppIcon` | Differs from the canonical shipped catalog; README only gives generic "replace AppIcon.appiconset" instructions; includes legacy `ItunesArtwork@2x.png`; no active script or Xcode reference points to it. | Non-canonical generated icon set. | Removed after preserving the only durable fact: it was a generic replacement bundle, not the shipped source of truth. |
| `Owlory_BlueWhite_AppIcon` | Differs from the canonical shipped catalog; README says the variant enforced a white owl on blue background. | Non-canonical historical variant. | Removed after preserving the variant note in this doc. |
| `Owlory_Fixed_AppIcon` | Differs from the canonical shipped catalog; README only gives generic replacement instructions. | Non-canonical generated icon set. | Removed after preserving that it was another replacement bundle, not a shipping input. |
| `Owlory_RC_AppIcon` | Differs from the canonical shipped catalog; README says `ios-marketing-1024.png` was treated as the single 1024 master and the set was regenerated without cropping salvage. | Non-canonical historical variant. | Removed after preserving the master/regeneration note in this doc. |
| `Owlory_TransparentBase_AppIcon` | Differs from the canonical shipped catalog; README describes a transparent-canvas variant and warns it may not meet App Store requirements. | Non-canonical rejected/alternate design variant. | Removed after preserving the warning in this doc. |
| `Owlory_UnifiedBlue_AppIcon` | Differs from the canonical shipped catalog; README describes a unified-blue-background variant. | Non-canonical historical variant. | Removed after preserving the variant note in this doc. |
| `Owlory_WhiteBG_BlueOwl_AppIcon` | Differs from the canonical shipped catalog; README says the failure condition was anything other than white background plus blue owl. | Non-canonical historical variant. | Removed after preserving the variant note in this doc. |

## Classified Loose Root References

Loose root images and clippings are reference artifacts, not shipping assets. Keep them out of the repo root once the canonical icon path is documented.

| Artifact | Evidence | Classification | Action |
| --- | --- | --- | --- |
| `Angry owl face on blue backdrop.png` | 1024x1024 PNG; no docs, scripts, Xcode settings, or asset import path reference it; does not hash-match the canonical shipped catalog or the removed historical variants; no durable design guidance accompanies it. | Non-canonical loose reference artifact. | Removed. |
| `Fierce owl logo with nest.png` | 1024x1024 PNG; exact SHA-256 match for canonical `ios-marketing-1024.png`; no active docs, scripts, Xcode settings, or asset import path reference the root copy. | Obsolete generated artifact safe to remove. | Removed after preserving the canonical shipped catalog copy. |
| `Owlory_BlueWhite_AppIcon.app.textClipping` | Apple binary text clipping containing only `Owlory_BlueWhite_AppIcon.appiconset`; no active docs, scripts, Xcode settings, or asset import path reference it. | Obsolete generated artifact safe to remove. | Removed. |
