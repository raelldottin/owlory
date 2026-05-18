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
| German reviewed | `de` | Long compounds, already native-reviewed, needs rerun after HIG-DE-001 fix |
| RTL | `ar` | Mirroring, text alignment, directional controls, Arabic typography |
| CJK | `ja`, `ko`, `zh-Hans`, `zh-Hant` | Dense labels, line breaking, CJK typography, terminology |
| Long-script / inflection-heavy | `nl`, `ru`, `sv`, `tr`, `uk` | Long words, grammatical case, truncation |
| Remaining LTR | `fr`, `it`, `nb`, `pt`, `pt-BR`, `es`, `vi` | Button length, plural/date phrasing, region variants |

German is the only native-reviewed non-English locale as of 2026-05-18. All other non-English locales need a native or fluent review intake before a final HIG UI-ready claim can include label/action clarity.

## Evidence Matrix

The all-locale HIG evidence matrix and canonical finding taxonomy live under [`automation/proofs/app-localization-hig-ui-matrix/`](../../automation/proofs/app-localization-hig-ui-matrix/). Per-locale `gate_state`, `scoped_surface_status`, `proof_references`, and `open_findings` are tracked there. New HIG findings allocate the next free `HIG-<LOCALE_UPPER>-<NNN>` ID and append to that matrix.

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
