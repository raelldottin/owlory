# Design System Tokens

Implementation source of truth: `owlory_xcode/Owlory/DesignSystem/AppTheme.swift` and the `owlory_xcode/Owlory/Resources/Assets.xcassets/*.colorset` folders. This doc mirrors the resolved values so agents do not need to grep the asset catalog or convert sRGB components.

If a value here disagrees with the asset catalog, the asset catalog wins — update this doc.

## Brand Palette

Restrained navy and royal blue. Both light and dark appearances are defined; the ramp shifts one step lighter in dark mode so contrast holds, and pressed states drop one step darker.

| Token (`OwloryColor.*`) | Asset name | Light | Dark | Role |
| --- | --- | --- | --- | --- |
| `brandPrimary` | `brandPrimary` | `#14539D` | `#216FC6` | Primary brand surface, default CTA fill. |
| `brandPrimaryPressed` | `brandPrimaryPressed` | `#0F447F` | `#14539D` | Pressed/active state for brand-primary controls. |
| `brandSecondary` | `brandSecondary` | `#216FC6` | `#2E7FE0` | Secondary brand surface, supporting accents. |
| `brandAccent` | `brandAccent` | `#2E7FE0` | `#4C94EA` | Highlights, focus, decorative emphasis. |
| `brandOnPrimary` | `brandOnPrimary` | `#FBFBFB` | `#F8FBFF` | Text/icons rendered on top of brand-tinted surfaces. |

## Semantic Roles (Non-Brand)

The remaining `OwloryColor` roles resolve to named assets that adapt to light/dark and to system semantic colors. Use these roles instead of hardcoded colors or raw system colors for non-brand surfaces:

- Background: `backgroundPrimary`, `backgroundSecondary`, `backgroundTertiary`
- Surface: `surfacePrimary`, `surfaceSecondary`, `surfaceElevated`, `surfaceSelected`
- Text: `textPrimary`, `textSecondary`, `textTertiary`, `textOnBrand`
- Border & separator: `borderSubtle`, `borderStrong`, `separatorSubtle`
- State: `success` (`owlorySuccess`, muted green), `warning` (`owloryWarning`, muted amber), `error` (system red for platform consistency), `info` (`owloryInfo`)

System semantic colors (`.primary`, `.secondary`, etc.) remain appropriate for standard text hierarchy and destructive actions.

## Layout Tokens (`AppTheme.*`)

| Token | Value |
| --- | --- |
| `cardCornerRadius` | `16` |
| `sectionSpacing` | `16` |
| `compactSpacing` | `8` |
| `cardPadding` | `12` |
| `elevationShadowRadius` | `4` |
| `elevationShadowY` | `2` |

## Accessibility Helpers

`OwloryAccessibilityContrast` and `OwloryMotion` in `AppTheme.swift` adapt tinted fills, borders, border widths, and animations to Reduce Transparency, Increase Contrast, and Reduce Motion preferences. Prefer these helpers over open-coded opacity/animation guards so every site honors the same accessibility floor.
