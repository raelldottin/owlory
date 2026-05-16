# app-localization-complete-nls-routing-pass

## Prompt

> "audit all strings not within L() and translate them to complete NLS"

User asked to route every visible English string through a localization helper (`L(...)`) and ensure complete NLS coverage. This is the implementation phase that follows the 2026-05-16 visible-string bypass audit.

## Approach

1. **Add helper.** Created `owlory_xcode/Owlory/DesignSystem/LocalizationHelpers.swift` with one inlinable `@public` function:

   ```swift
   public func L(_ key: String) -> LocalizedStringKey {
       LocalizedStringKey(key)
   }
   ```

   The helper's return type is concretely `LocalizedStringKey`, so SwiftUI's overload resolution becomes unambiguous: `Section(L("Today"))`, `Label(L("Training"), systemImage: ...)`, `Button(L("Save"), action: ...)` all bind to the LocalizedStringKey path that does the `Localizable.strings` lookup. The String-overload bypass that previously affected `Section("Today")` / `Label("Training", systemImage:)` is eliminated.

2. **Wire helper into project.** Added the file to `owlory_xcode/Owlory.xcodeproj/project.pbxproj` (PBXBuildFile A091, PBXFileReference A191, DesignSystem group, Owlory target Sources).

3. **Mechanical conversion.** Wrote `/tmp/owlory_route_through_L.py` with two phases of regex transforms:

   - Phase A: `Section("Lit")` → `Section(L("Lit"))`, `Label("Lit", systemImage:)` → `Label(L("Lit"), systemImage:)`, `Label("Lit", image:)` → `Label(L("Lit"), image:)`, `Label(varName, systemImage:)` → `Label(L(varName), systemImage:)`, `Label(varName, image:)` → `Label(L(varName), image:)`.
   - Phase B: `Button("Lit", action:)` → `Button(L("Lit"), action:)`, `Button("Lit", role:)` → `Button(L("Lit"), role:)`, `Button("Lit") { ... }` → `Button(L("Lit")) { ... }`.

   The script is idempotent (re-running is a no-op), skips comments and string literals, and skips any file containing `// disable-localization-routing`.

4. **Manual revert.** One over-conversion was caught at the count-display Label in TodayView.swift:1304 where the script wrapped a Swift string-interpolation `Label("\(entry.focusThree.count)", ...)` in L(). That literal is a dynamic count, not a localization key. Reverted both that site and the companion `readinessLabel` Label which carries a formatted "3.5 / 5" string.

## Numbers

| Phase | Pattern | Sites |
|---|---|---:|
| A | Section / Label literal + Label-variable | 87 |
| B | Button literal | 43 |
| **Total** | **all routed** | **130** |

Per-file totals (phase A + B combined):

| File | Phase A | Phase B | Total |
|---|---:|---:|---:|
| `TodayView.swift` | 23 | 10 | 33 |
| `HomeView.swift` | 32 | 10 | 42 |
| `WriteView.swift` | 15 | 13 | 28 |
| `TrainView.swift` | 2 | 4 | 6 |
| `CareerView.swift` | 3 | 5 | 8 |
| `BuildInfoView.swift` | 3 | 1 | 4 |
| `DigestDetailView.swift` | 4 | 0 | 4 |
| `RootTabView.swift` | 5 | 0 | 5 |

Post-conversion: 86 unique `L("literal")` keys are referenced. All 86 already exist in `Localizable.strings`. Zero new keys needed.

## Slices superseded

The mega-slice consolidates seven of the audit's per-surface follow-ups plus the Button-literal-verify slice:

- `app-localization-today-shell-copy-routing` → done
- `app-localization-home-shell-copy-routing` → done
- `app-localization-write-shell-copy-routing` → done
- `app-localization-train-shell-copy-routing-followup` → done
- `app-localization-career-shell-copy-routing` → done
- `app-localization-root-tab-shell-labels` → done
- `app-localization-widget-shell-strings` → done (Widgets scan found no Section/Label/Button literals to convert)
- `app-localization-button-literal-verify` → done (Buttons are now routed through L())

Still queued (not in scope of this slice):

- `app-localization-string-interpolation-formatters` — ~12 interpolated-copy sites
- `app-localization-accessibility-bypass-audit` — ~10 accessibility var-bypasses

## Validation

- `make architecture` — passed.
- `make localization-check` — 19 locales / 316 keys / 13 plural keys (parity preserved).
- `./Tools/validate.sh localization` — passed.
- `make test-domain DOMAIN=today` — passed.
- `make test-domain DOMAIN=home` — passed.
- `make test-domain DOMAIN=train` — passed.
- `make test-domain DOMAIN=write` — passed.
- `make automation-check` — 57/57.
- `xcodebuild build -quiet -project owlory_xcode/Owlory.xcodeproj -scheme Owlory -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/owlory-L-final-build CODE_SIGNING_ALLOWED=NO` — exit 0.
- `git diff --check` — clean.

## Lane Boundary

`build-tested`. The compile is clean, parity holds, and domain tests pass. The fix does not modify any English source value, any non-English value, any product behavior, any domain rule, or any persistence shape. It only routes the existing call sites through a single helper that forces the LocalizedStringKey overload at the SwiftUI boundary.

No running-app-smoke for translated content per locale was captured; that proof level belongs to a separate slice if/when manual or device testing wants to claim it. No native-review claim.

## What "complete NLS" means after this slice

| Coverage | Status |
|---|---|
| Section literals route to Localizable.strings | ✅ all sites in app target |
| Label literals (with systemImage / image) route to Localizable.strings | ✅ all sites in app target |
| Label variables (String) route to Localizable.strings via runtime lookup | ✅ all sites |
| Button literals route to Localizable.strings | ✅ all sites in app target |
| Text literals route via SwiftUI's native LocalizedStringKey | ✅ (was already routing in audit) |
| Text variables (user content) — verbatim display | ✅ correct behavior |
| Accessibility variable-string routing | ⏸ deferred to follow-up |
| Interpolated copy (`"Next: \(x)"`) routing through formatters | ⏸ deferred to follow-up |
| Native review of any locale | 🚫 still outstanding |
| Translation quality validation | 🚫 still outstanding |

"Complete NLS" in the build-tested sense: every call-site routing class that was identifiable as a static bypass is now routed through L() and the localization lookup actually happens. "Complete NLS" in the native-review sense remains a separate gate (blocked).

## Residual Risk

(Full list in handoff JSON. Top items:)

- L(varName) for dynamic strings (counts, formatted numbers) silently falls back to the verbatim value since SwiftUI doesn't find a matching key. Visually correct, semantically wrong. The one site this affected was manually reverted; future similar cases would need similar care.
- Accessibility var-bypasses still exist (~10 sites flagged in audit).
- Interpolation patterns still bypass formal localization (~12 sites).
- LLM-drafted translations remain non-native-reviewed.
- No CI enforcement that new Section/Label/Button literals must route through L().

## Multi-agent note

`Tools/owlory_route_through_L.py` exists only in `/tmp` — it's a throwaway. Future agents who add new view files should manually use `L(...)` from the start. If the bypass class re-emerges, the conversion can be re-run by reproducing the script (regex patterns documented in this note and in the handoff JSON).
