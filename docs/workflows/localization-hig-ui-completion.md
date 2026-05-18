# Localization HIG UI Completion

Use this plan to finish Apple Human Interface Guidelines adherence for Owlory's localized UI without mixing proof levels or overclaiming translation quality.

Source references checked on 2026-05-18:

- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines)
- [Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility/)
- [Writing](https://developer.apple.com/design/human-interface-guidelines/writing)
- [Right to left](https://developer.apple.com/design/human-interface-guidelines/right-to-left)

## Completion Contract

All supported locales can be called localized-UI HIG complete only when every item below is true:

1. The locale has reviewed language input for visible labels, actions, accessibility copy, date/count/plural text, and terminology.
2. The app launches with that locale and the packaged resources match the committed source.
3. Repo-managed evidence exists for the scoped HIG surfaces: Build Info, Today launch, root tabs, primary empty states, primary actions, high-risk date/count/plural surfaces, and one accessibility text-size pass.
4. RTL locales prove mirrored layout, alignment, navigation affordances, ordered controls, and directional symbols where relevant.
5. Any HIG finding has a queued remediation slice or a completed fix with rerun evidence.
6. `docs/workflows/localization-translation-quality.md`, review return files, proof manifests, and SecondBrain agree on the claim being made.

Simulator screenshots can prove screenshot-reviewed surfaces. They do not prove physical-device or TestFlight behavior. Native/fluent review is still required before claiming translated label/action clarity for non-English locales.

## Locale Buckets

Use buckets to keep UI review slices bounded by risk:

| Bucket | Locales | Primary HIG Risk |
| --- | --- | --- |
| Source | `en` | Source UI baseline and comparison state |
| German reviewed | `de` | Long compounds, already native-reviewed, HIG-DE-001 source fix landed and in-progress, needs post-fix screenshot capture |
| RTL | `ar` | Mirroring, text alignment, directional controls, Arabic typography. Gate ran 2026-05-18 (doc-only); HIG-AR-001/AR-002 open for non-mirroring `chevron.right`/`arrow.right.circle` SF Symbols (source-level defects, deterministic SwiftUI rule); HIG-AR-003 open for `Career` tab label truncation risk. |
| CJK | `ja`, `ko`, `zh-Hans`, `zh-Hant` | Dense labels, line breaking, CJK typography, terminology. Gate ran 2026-05-18 (doc-only); HIG-JA-001 open for Japanese Train katakana tab truncation; ko/zh-Hans/zh-Hant clean at source level; screenshot capture pending. |
| Long-script / inflection-heavy | `nl`, `ru`, `sv`, `tr`, `uk` (plus `de` as native-reviewed cross-cut) | Long words, grammatical case, truncation. Gate ran 2026-05-18 (doc-only); HIG-DE-002/NL-001/RU-001/TR-001/UK-001 open for Train/Write tab truncation; screenshot capture pending. |
| Remaining LTR | `fr`, `it`, `nb`, `pt`, `pt-BR`, `es`, `vi` | Button length, plural/date phrasing, region variants. Gate ran 2026-05-18 (doc-only); HIG-FR-001 open for French Today tab truncation risk; screenshot capture pending. |

German is the only native-reviewed non-English locale as of 2026-05-18. All other non-English locales need a native or fluent review intake before a final HIG UI-ready claim can include label/action clarity.

## Evidence Matrix

The all-locale HIG evidence matrix and canonical finding taxonomy live under [`automation/proofs/app-localization-hig-ui-matrix/`](../../automation/proofs/app-localization-hig-ui-matrix/). Per-locale `gate_state`, `scoped_surface_status`, `proof_references`, and `open_findings` are tracked there. New HIG findings allocate the next free `HIG-<LOCALE_UPPER>-<NNN>` ID and append to that matrix.

## Dynamic Type + Accessibility Regression

Use `make ui-regression DOMAIN=localization` to run the maintained accessibility and layout XCUITest classes:

- `LocalizationLayoutRegression` — Today shell settles and the root tab bar exposes 5 hittable buttons under `en`, `de`, `ar`, `zh-Hans`.
- `LocalizationAccessibilityRegression` — Today shell settles under `UICTContentSizeCategoryAccessibilityXL` for `en` and `de` (long compounds); root tab buttons expose non-empty accessibility labels; each root tab button has ≥44pt hittable width and height per Apple HIG.

These classes do not prove translation quality, full HIG layout correctness for other locales, device behavior, or TestFlight behavior. They prove launch-shell stability under accessibility text-size launch arguments and tab-bar reachability across two representative locales.

## Multisurface Screenshot Harness

Use `automation/smoke/capture_localized_surfaces.py` to capture scoped HIG surfaces beyond the single Today launch surface that `capture_locale_screenshots.py` already covers.

```bash
make localization-multisurface-screenshot-idb-check
python3 automation/smoke/capture_localized_surfaces.py --list-surfaces
python3 automation/smoke/capture_localized_surfaces.py \
    --dry-run --locales en de --surfaces today build-info
python3 automation/smoke/capture_localized_surfaces.py \
    --capture --udid <simulator-udid> \
    --locales en de --surfaces today build-info
```

Capture output lands under [`automation/proofs/app-localization-hig-multisurface-screenshot-harness/`](../../automation/proofs/app-localization-hig-multisurface-screenshot-harness/) with a per-capture `manifest.json` (locale, surface, file, bytes, sha256, navigation step count, git commit short, idb target). The directory must be empty before `--capture`. Captures whose settled-state assertion fails are recorded as `blocked`, not silently treated as proof. Add locale-specific settled labels via `--label-overrides` when an English fallback label does not match the localized accessibility label.

The harness does not claim translation quality, full layout correctness, device behavior, TestFlight behavior, or `hig-ui-reviewed` for any locale. Per-bucket HIG gate slices consume these proofs and update the evidence matrix.

## Slice Ladder

The queue encodes the path to completion:

1. `app-localization-hig-evidence-matrix` creates the all-locale HIG evidence matrix and finding taxonomy.
2. `app-localization-hig-multisurface-screenshot-harness` broadens screenshot capture beyond one Today launch screenshot per locale.
3. `app-localization-hig-dynamic-type-accessibility-harness` adds maintained checks for Dynamic Type, accessibility labels/values/hints, tab reachability, and touch target regressions.
4. Per-locale native-review slices unblock non-German final claims.
5. Bucketed HIG gate slices run the evidence review and queue remediation for failures.
6. `app-localization-hig-remediation-triage` turns remaining findings into narrow fix slices.
7. `app-localization-all-locale-hig-ui-closure` remains blocked until every HIG gate and remediation slice has passed.

Do not collapse this ladder into one broad implementation slice. A single all-locale HIG claim is only honest after the native-review, automation, proof, gate, and remediation slices converge.
