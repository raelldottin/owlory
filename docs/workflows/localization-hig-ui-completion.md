# Localization HIG UI Completion

Use this record to preserve Apple Human Interface Guidelines adherence for Owlory's localized UI without mixing proof levels or overclaiming translation quality.

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

Simulator screenshots can prove screenshot-reviewed surfaces. They do not prove physical-device or TestFlight behavior — but **TestFlight HIG proof is not required to call a locale `hig-ui-reviewed`.** Repo-managed automated proof (multisurface screenshot capture under `idb` + maintained `make ui-regression DOMAIN=localization` Dynamic Type coverage) is the accepted bar for the HIG UI claim. Translation quality, `device-verified`, and `testflight-verified` remain separate proof tracks; they are not implied by the HIG UI claim and they are not preconditions for it. Native/fluent review is recorded complete for non-English locales. As of 2026-05-18, all 19 supported locales are `hig-ui-reviewed` for the scoped simulator surfaces recorded in the evidence matrix.

## Closure Status

`app-localization-all-locale-hig-ui-closure` closed on 2026-05-18 for scoped simulator HIG UI evidence:

- Repo-managed proof: [`automation/proofs/app-localization-hig-multisurface-screenshot-harness/20260518T170353Z-closure-capture/`](../../automation/proofs/app-localization-hig-multisurface-screenshot-harness/20260518T170353Z-closure-capture/)
- Coverage: 19 locales x 8 surfaces = 152 screenshots, all passed.
- Build: iPhone 17 / iOS 26.5 simulator, clean app build from git commit `a7813a8`.
- Surfaces: Build Info, Today launch, root tabs, primary empty states/actions, date/count/plural Today sample, and RTL root-tab order for Arabic.
- Dynamic Type and touch target coverage: maintained through `make ui-regression DOMAIN=localization`.

Not claimed (and not required for the `hig-ui-reviewed` bar): physical-device HIG proof, TestFlight HIG proof, or automated accessibility-tree settled assertions for the 2026-05-18 screenshots. The simulator returned an application-only AX tree through `idb`, so the capture manifest records screenshot-only AX fallback and deterministic coordinate navigation. HIG-DE-001 is closed by source/key routing plus post-fix German screenshot evidence; the specific evening trigger state was not force-captured. HIG-AR-002 is closed by source verification of `.forward` SF Symbol usage plus Arabic Write/root-tab screenshots.

## Locale Buckets

Use buckets to keep UI review slices bounded by risk:

| Bucket | Locales | Primary HIG Risk |
| --- | --- | --- |
| Source | `en` | Passed scoped simulator HIG gate; source UI baseline and comparison state preserved in the closure capture. |
| German reviewed | `de` | Passed scoped simulator HIG gate; HIG-DE-001 closed after source/key routing and post-fix German screenshot evidence. |
| RTL | `ar` | Passed scoped simulator HIG gate; RTL root-tab order captured, directional SF Symbol findings closed, and tab-length risk covered by maintained accessibility regression. |
| CJK | `ja`, `ko`, `zh-Hans`, `zh-Hant` | Passed scoped simulator HIG gate; dense labels and tab-length risks covered by screenshot evidence plus maintained accessibility regression. |
| Long-script / inflection-heavy | `nl`, `ru`, `sv`, `tr`, `uk` (plus `de` as native-reviewed cross-cut) | Passed scoped simulator HIG gate; long-label risks covered by screenshot evidence plus maintained accessibility regression. |
| Remaining LTR | `fr`, `it`, `nb`, `pt`, `pt-BR`, `es`, `vi` | Passed scoped simulator HIG gate; button, plural/date, and region-variant surfaces covered by closure screenshots. |

All 18 non-English locales are native/fluent-reviewed as of 2026-05-18. All 19 supported locales have scoped simulator HIG UI closure evidence as of the same date.

## Evidence Matrix

The all-locale HIG evidence matrix and canonical finding taxonomy live under [`automation/proofs/app-localization-hig-ui-matrix/`](../../automation/proofs/app-localization-hig-ui-matrix/). Per-locale `gate_state`, `scoped_surface_status`, `proof_references`, and `open_findings` are tracked there. New HIG findings allocate the next free `HIG-<LOCALE_UPPER>-<NNN>` ID and append to that matrix.

## Dynamic Type + Accessibility Regression

Use `make ui-regression DOMAIN=localization` to run the maintained accessibility and layout XCUITest classes:

- `LocalizationLayoutRegression` — Today shell settles and the root tab bar exposes 5 hittable buttons under `en`, `de`, `ar`, `zh-Hans`.
- `LocalizationAccessibilityRegression` — Today shell settles under `UICTContentSizeCategoryAccessibilityXL` for `en`, `de`, `fr`, `ja`, `nl`, `ru`, `tr`, `uk`, `ar` (9 locales total — the 8 locales flagged for tab-bar truncation risk by the bucket gates, plus English source); root tab buttons expose non-empty accessibility labels under `en`, `de`, `ar`, `ja`, `ru` (representative coverage across source / native-reviewed / RTL / CJK / long-Cyrillic, recorded under [`automation/proofs/app-localization-voiceover-verification/`](../../automation/proofs/app-localization-voiceover-verification/)); each root tab button has ≥44pt hittable width and height per Apple HIG.

These classes do not prove translation quality, full HIG layout correctness for other locales, device behavior, or TestFlight behavior. They prove launch-shell stability under accessibility text-size launch arguments and tab-bar reachability across the maintained representative and risk-driven locale set.

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

Capture output lands under [`automation/proofs/app-localization-hig-multisurface-screenshot-harness/`](../../automation/proofs/app-localization-hig-multisurface-screenshot-harness/) with a per-capture `manifest.json` (locale, surface, file, bytes, sha256, navigation step count, git commit short, idb target). The directory must be empty before `--capture`. Captures whose settled-state assertion fails are recorded as `blocked`, not silently treated as proof. The 2026-05-18 closure run used localized label lookup, fresh-day seeding, RTL-aware coordinate navigation, and screenshot-only AX fallback because `idb` exposed only the application node for that simulator session.

The harness does not claim translation quality, full layout correctness, device behavior, TestFlight behavior, or `hig-ui-reviewed` for any locale. Per-bucket HIG gate slices consume these proofs and update the evidence matrix.

## Slice Ladder

The queue encodes the path to completion:

1. `app-localization-hig-evidence-matrix` creates the all-locale HIG evidence matrix and finding taxonomy.
2. `app-localization-hig-multisurface-screenshot-harness` broadens screenshot capture beyond one Today launch screenshot per locale. **Initial capture ran 2026-05-18**: 18 today-surface screenshots preserved under `automation/proofs/app-localization-hig-multisurface-screenshot-harness/20260518T103428Z-today-capture/`. **Closure capture ran 2026-05-18**: 152 screenshots preserved under `automation/proofs/app-localization-hig-multisurface-screenshot-harness/20260518T170353Z-closure-capture/`.
3. `app-localization-hig-dynamic-type-accessibility-harness` adds maintained checks for Dynamic Type, accessibility labels/values/hints, tab reachability, and touch target regressions.
4. Per-locale native-review slices unblock non-German final claims.
5. Bucketed HIG gate slices run the evidence review and queue remediation for failures.
6. `app-localization-hig-remediation-triage` turns remaining findings into narrow fix slices. **Completed 2026-05-18**: 11 open findings triaged into 3 remediation slices — `app-localization-rtl-sf-symbol-fix`, `app-localization-hig-multisurface-screenshot-capture`, `app-localization-tab-bar-truncation-fix`.
7. `app-localization-all-locale-hig-ui-closure` is done. The matrix has zero open or in-progress findings, all 19 supported locales have `gate_state=passed-scoped`, and proof references point at committed screenshot artifacts.

Do not collapse this ladder into one broad implementation slice. A single all-locale HIG claim is only honest after the native-review, automation, proof, gate, and remediation slices converge.
