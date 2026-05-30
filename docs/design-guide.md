# Owlory Design Guide

This is the canonical design contract every tab adheres to. Read it before adding screens, components, or visual primitives. If a pattern is not in this guide, default to the closest Apple HIG pattern rather than inventing one.

Token values live in [Design System Tokens](design-system.md). This guide governs *how* to use them.

## 1. Experience Principles

The five anchors. When two principles conflict, the earlier one wins.

1. **Serious, structured, trustworthy.** A life command center, not a toy. No gamification, no celebratory animation, no mascot.
2. **Calm and information-dense.** Surface real signal; suppress visual noise. White space is a feature, not a void.
3. **Apple-native.** Conform to Human Interface Guidelines; honor system semantics over invention.
4. **Time is visible.** Signature moments (`LineageRibbon`, `DuskMode`) make the passage of time tangible — that is Owlory's unique aesthetic.
5. **Accessibility is a floor, not a setting.** Reduce Motion, Increase Contrast, Reduce Transparency, Dynamic Type up to Accessibility XL, and VoiceOver are all first-class baselines.

## 2. Apple HIG Anchors

Specific HIG sections we adhere to verbatim. Cite these when defending a decision.

- **Foundations → Layout.** Safe areas, leading/trailing inset, minimum 44×44pt touch targets.
- **Foundations → Typography.** Use system fonts and Dynamic Type. Never hardcode point sizes outside the design system.
- **Foundations → Color.** Use system semantic colors (`.primary`, `.secondary`, `.tertiary`, `Color.red` for destructive) and Owlory brand tokens. Never raw hex.
- **Foundations → Motion.** Animations must be purposeful, brief, and respectful of Reduce Motion.
- **Components → Lists and Tables.** Inset grouped lists are the default container. Use `List` with `Section`; do not handroll list rows.
- **Components → Buttons.** `.borderedProminent` for primary CTAs, `.bordered` for secondary, `.plain` for inline navigation rows, system role `.destructive` for destructive.
- **Components → Toolbars.** `+` in `.primaryAction` for capture; `info.circle` in `.topBarTrailing` for diagnostics; never both flanking a title.
- **Components → Sheets.** Modals for capture and detail. Avoid stacking more than one sheet at a time.
- **Accessibility.** Every interactive element has a meaningful `accessibilityLabel` and (where action exists) an `accessibilityHint`.

## 3. Layout Conventions

**The spine.** Every primary tab is:

```swift
NavigationStack {
    SomeView()
}
.tabItem { Label(L("Title"), systemImage: "…") }
```

Inside each tab view:

```swift
List {
    Section { … }      // grouped, one concept per section
    Section { … }
}
.navigationTitle("Tab Name")
.toolbar {
    ToolbarItem(placement: .primaryAction) { /* + capture */ }
}
```

Do not introduce `ScrollView` as the top-level container on a primary tab. `List` is the convention; deviating fragments the cross-tab feel.

**Sections.** Each section presents one concept (Continue, Train, Reflection). Optional `Section` header text uses default `Text` styling. No custom styled section headers.

**Card vs row.** Two valid containers inside a List:
- **Inset row (default):** plain content inside a `Section`. Use for every list item.
- **Card (rare):** for surfaces that need elevation — e.g. the Today greeting block. Use `RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)` and `AppTheme.cardPadding`. Do not invent custom corner radii.

## 4. Typography

Use system fonts with semantic styles. Dynamic Type must work at every size from xSmall through AccessibilityXXXL.

| Role | Style | Where |
| --- | --- | --- |
| Tab title | `navigationTitle` (system .title) | Top of each tab |
| Section header | system default | `Section { … } header: { Text("…") }` |
| Row primary | `.subheadline` | Continue row title, focus item title |
| Row secondary | `.caption` foregroundStyle `.secondary` | Domain + subtitle |
| Row tertiary | `.caption2` foregroundStyle `.tertiary` | Timestamps, chevrons |
| Badge | `.caption2.weight(.medium)` | Stale-day badge, status pills |
| Emphasis | `.weight(.semibold)` or `.weight(.medium)` | Sparingly |

Forbidden:
- `font(.system(size: 14))` — breaks Dynamic Type.
- `.bold()` on body text — reserve weight for hierarchy, not emphasis.
- Mixing `.subheadline` and `.body` in adjacent rows.

## 5. Color

Use **brand tokens** for Owlory identity surfaces (CTA, signature moments, focus indicators). Use **system semantic colors** for hierarchy and standard UI.

| Use case | Token / system color |
| --- | --- |
| Primary CTA fill | `OwloryColor.brandPrimary` |
| Domain icon, in-context emphasis | `OwloryColor.brandPrimary` |
| Selection highlight | `OwloryColor.brandPrimary.opacity(0.10)` via `.continueHighlight` |
| Success state | `OwloryColor.success` |
| Warning / deferred / stale | `OwloryColor.warning` |
| Destructive | `Color.red` (system) |
| Body text | `.primary` (system) |
| Caption text | `.secondary`, `.tertiary` (system) |
| Surfaces | `OwloryColor.surfacePrimary` / `surfaceElevated` / `surfaceSecondary` |

Forbidden:
- Hex literals (`Color(red:…)`) anywhere outside `AppTheme.swift`/assets.
- Raw system colors like `.blue` or `.orange` — use brand or warning tokens.

Light/dark adaptation is handled by the asset catalog; never check `colorScheme` to pick a color.

## 6. Spacing

Use `AppTheme` tokens, not magic numbers.

| Token | Value | Use |
| --- | --- | --- |
| `AppTheme.compactSpacing` | 8 | Tight within-row gaps, badge padding |
| `AppTheme.cardPadding` | 12 | Card inner padding |
| `AppTheme.rowSpacing` | 12 | Between elements inside an HStack/VStack row |
| `AppTheme.sectionSpacing` | 16 | Between major sections inside a card |
| `AppTheme.cardCornerRadius` | 16 | All card-shaped surfaces |
| `AppTheme.elevationShadowRadius` | 4 | Card shadow blur |
| `AppTheme.elevationShadowY` | 2 | Card shadow Y offset |

Today, only `Onboarding/OnboardingView.swift` uses these — that is a known gap. New code MUST use the tokens; refactors should opportunistically migrate magic numbers.

## 7. Component Patterns

### 7.1 Toolbar capture button

Every non-Today primary tab has a `+` capture button in `.primaryAction`. Today is the exception — it uses `info.circle` in `.topBarTrailing` because Today does not own the capture concept.

```swift
.toolbar {
    ToolbarItem(placement: .primaryAction) {
        Button { showingCapture = true } label: {
            Image(systemName: "plus")
        }
        .accessibilityLabel("Capture new …")
        .accessibilityIdentifier("…")
    }
}
```

### 7.2 Continue row pattern (Today only)

The Continue row is Owlory's signature row. Lineage ribbon → domain icon → title/subtitle stack → optional badge → chevron.

```swift
HStack(spacing: 10) {
    HStack(spacing: 6) {
        LineageRibbon(...)            // optional, only when carry-forward
        Image(systemName: domainIcon)
            .frame(width: 24)
            .foregroundStyle(OwloryColor.brandPrimary)
    }
    VStack(alignment: .leading, spacing: 2) {
        Text(title).font(.subheadline)
        HStack(spacing: 6) {
            Text(domain).font(.caption).foregroundStyle(.secondary)
            Text("·").font(.caption).foregroundStyle(.tertiary)
            Text(subtitle).font(.caption).foregroundStyle(.tertiary)
        }
    }
    Spacer()
    optionalBadge
    Image(systemName: "chevron.forward")
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.tertiary)
}
```

### 7.3 Status badges

Pill-shaped, `.caption2.weight(.medium)`, 6pt horizontal padding, 2pt vertical, capsule background at 12% opacity. Use `OwloryAccessibilityContrast.tintedFill` so Reduce Transparency and Increase Contrast are honored.

### 7.4 Swipe actions

Leading: primary affirmative action (`Done`, `Add to Focus`) with `.tint(OwloryColor.success)` or `.tint(OwloryColor.brandPrimary)`. Trailing: defer (`warning`) and drop (`destructive`).

### 7.5 Sheets

Capture and detail use `.sheet`. Never use `.fullScreenCover` except for onboarding. Sheet drag indicator on (system default). One sheet at a time.

## 8. Motion

All animation goes through `OwloryMotion` so Reduce Motion is honored centrally.

```swift
.animation(
    OwloryMotion.animation(.easeOut(duration: 0.2), reduce: reduceMotion),
    value: someValue
)
```

| Intent | Animation | Duration |
| --- | --- | --- |
| Row insert / state change | `.easeOut` | 200–320ms |
| Sheet present | system default | system |
| Scroll-to-highlight | `.easeInOut` | 200ms |
| Signature moment (Lineage Ribbon segment draw) | `.easeOut` | 320ms with 40ms stagger |

Forbidden:
- Spring animations with bounce on functional UI — feels playful, conflicts with principle 1.
- `withAnimation` without a Reduce Motion guard.
- Animation durations > 500ms (except sheet present which is system-owned).

## 9. Accessibility

Required floors. Every PR touching UI must verify all of these on the touched surface.

- **Dynamic Type:** layout must remain functional from xSmall through AccessibilityXXXL. Use `@Environment(\.dynamicTypeSize)` to adapt layouts at `>= .accessibility1`.
- **VoiceOver:** every interactive element has `accessibilityLabel`. Decorative elements (like `LineageRibbon`) use `.accessibilityHidden(true)` and contribute their meaning via the parent row's label.
- **Reduce Motion:** animations skip via `OwloryMotion`.
- **Increase Contrast:** tinted fills go to full alpha via `OwloryAccessibilityContrast.tintedFill`; borders thicken via `OwloryAccessibilityContrast.borderWidth`.
- **Reduce Transparency:** tinted fills get an opacity floor (≥ 0.35 for fills, ≥ 0.55 for borders).
- **Color-blind safety:** never encode meaning in color alone. Pair color with shape, count, or label (the ribbon does this — color *and* segment count both encode age).

## 10. Signature Moments

Owlory's distinctive aesthetic comes from a small, deliberate set of signature moments. **Do not multiply them.** Two is the cap.

### 10.1 Lineage Ribbon — shipped

A thin vertical thread on Continue rows visualizing how many days each Focus item has been carried, segmented per day, dashed on deferred days. Implementation: `DesignSystem/LineageRibbon.swift`. Spec: this guide §7.2 and `Core/Domain/FocusItemHistoryRules.swift`.

### 10.2 Dusk Mode — v1 shipping

After local evening hours, Today's surface dims to a warmer palette so the app visibly responds to time of day.

**v1 (this slice).**
- Activation: deterministic local-time threshold (active 18:00–05:00 local). No geolocation, no astronomical sunset.
- User control: none yet — always Auto. A Settings sheet is queued (see Target).
- Color shift: a single `OwloryColor.duskOverlay` warm overlay at low opacity over the Today List background. No row-level color changes in v1.
- Motion: 600ms cross-fade on activation, instant under Reduce Motion.
- Accessibility: skipped entirely under Increase Contrast (readability wins). Never reduces text contrast below WCAG AA at the chosen opacity.
- Scope: Today tab only. Other tabs stay neutral.

**Target state (subsequent slices).**
- User control: `Settings → Appearance → Dusk Mode` with values `Auto / On / Off`, default `Auto`.
- Color shift: asset-catalog `dusk*` token variants for principled, dark-mode-aware adaptation.
- Astronomical sunset via system APIs where available.
- Possible row-level type/icon tonal shift, not just background.

No third signature moment ships without explicit revision of this guide.

## 11. Per-Tab Adherence Checklist

Each tab MUST pass all of these. Failures are bugs.

- [ ] `NavigationStack { … }` wrapping; one tab = one stack.
- [ ] `List` as top-level scrollable container.
- [ ] `Section`s organize content; no bare `VStack` standing in for one.
- [ ] `navigationTitle` set; title appears in default placement.
- [ ] Toolbar follows the §7.1 convention.
- [ ] All rows use the system Dynamic Type ramp.
- [ ] All colors are tokens (brand) or system semantic. Zero raw hex, zero raw system color names.
- [ ] All animations route through `OwloryMotion`.
- [ ] All interactive elements have an accessibility label.
- [ ] No `accessibilityHidden(true)` on a control.
- [ ] Touch targets ≥ 44×44pt.
- [ ] Text wraps and truncates predictably at Accessibility5.
- [ ] Empty states present (not blank rows) and explain next action.
- [ ] Localization keys exist for every visible English string (`L("…")` / `String(localized:…)`).

A tab failing any of the above is "drift" and should be fixed in the smallest possible follow-up, not deferred.

## 12. When This Guide Changes

This is a living contract. To revise:

1. Open a slice that names the rule being changed and why.
2. Update this doc and the affected token table in `design-system.md`.
3. Run the per-tab checklist on every primary tab.
4. Land the doc change in the same commit as the implementation.

Do not introduce a one-off exception without documenting it. Drift starts with "just this once."
