# app-localization-hig-ui-matrix

Durable repo-managed matrix that records the all-locale Apple HIG localized UI completion state per locale per scoped surface, plus the canonical finding taxonomy. This is a planning/evidence index, not a proof artifact. It does not claim any locale passed.

Source references checked on 2026-05-18:

- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines)
- [Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility/)
- [Writing](https://developer.apple.com/design/human-interface-guidelines/writing)
- [Right to left](https://developer.apple.com/design/human-interface-guidelines/right-to-left)

## What this directory is

- `manifest.json` — the canonical matrix. Per-locale state, scoped surface coverage, open and closed HIG findings, finding taxonomy, and downstream slice pointers.
- This `README.md` — purpose, lifecycle, and how to update.

The matrix is intentionally text-only. Screenshot artifacts live in per-slice proof directories under `automation/proofs/<slice-id>/`. The matrix references those paths so the same finding ID can be traced from intake through remediation and reverification.

## What this directory is not

- It is not a screenshot bundle.
- It is not native-review evidence.
- It is not a `hig-ui-reviewed`, `screenshot-reviewed`, `device-verified`, or `testflight-verified` claim for any locale.

## Finding taxonomy

Finding IDs use the form `HIG-<LOCALE_UPPER>-<NNN>`:

- `HIG-DE-001` is the first German HIG finding.
- `HIG-AR-001` is reserved for the first Arabic HIG finding.

Each finding records `severity` (`blocking`, `major`, `minor`, `info`), `area` (one of `platform-consistency`, `adaptive-layout`, `typography-dynamic-type`, `accessibility`, `labels-actions`, `locale-aware-formatting`, `right-to-left`), `state` (`open`, `in-progress`, `closed-fixed`, `closed-wont-fix`, `duplicate`), an `observed_evidence` list, a `source_trace` list, a `proof_path_or_chat_observation`, and a `remediation_slice_id_or_null`.

Severity rubric:

- `blocking`: prevents calling the surface UI-ready in that locale. Untranslated visible label, truncated meaning-bearing label, broken RTL mirroring, inaccessible action.
- `major`: visible degradation but action remains discoverable. Long compound truncation that loses a qualifier, inconsistent terminology, missed locale-aware date format.
- `minor`: cosmetic, does not impair comprehension.
- `info`: observation tracked but not a defect. Deliberately retained English product term, locale-specific phrasing.

## Scoped surfaces

The matrix tracks coverage per locale across the surfaces below. RTL mirroring applies only to `ar`.

- Build Info (version, build, commit short, commit full, branch, source-clean/releaseability fields)
- Today launch (header greeting, focus three, readiness band, visible nudge copy)
- Root tabs (all root labels visible, reachable, ordered per locale direction)
- Primary empty states (Today/Train/Write/Career/Home/Patterns/Settings)
- Primary actions (primary CTA labels remain idiomatic and recognizable)
- High-risk date/count/plural surfaces (locale-aware `Date.FormatStyle` + stringsdict)
- Dynamic Type and accessibility pass (standard size, Larger Accessibility Text, localized accessibility labels/values/hints, tab reachability, touch targets)
- RTL mirroring (ar only): mirrored layout, alignment, navigation affordances, ordered controls, directional symbols; digits inside numbers not reversed; non-direction-bearing artwork not flipped

## Locale buckets

The matrix records each locale's bucket to keep HIG gate slices bounded by risk:

- `source`: `en`
- `german_reviewed`: `de`
- `rtl`: `ar`
- `cjk`: `ja`, `ko`, `zh-Hans`, `zh-Hant`
- `long_script_or_inflection_heavy`: `nl`, `ru`, `sv`, `tr`, `uk`
- `remaining_ltr`: `fr`, `it`, `nb`, `pt`, `pt-BR`, `es`, `vi`

## Lifecycle and update protocol

1. When a new HIG gate slice runs for a locale or bucket, append a `proof_references` entry to that locale block and update its `scoped_surface_status` per surface using the existing labels (`not-reviewed`, `partial`, `passed-scoped`, `fail`, `build-info-observed`, `not-applicable`).
2. When the gate uncovers a problem, allocate the next free `HIG-<LOCALE_UPPER>-<NNN>` ID and append it to `open_findings` with all required fields populated. If the finding cannot be remediated in the same slice, queue a narrow remediation slice and record its ID in `remediation_slice_id_or_null`.
3. When a remediation slice ships the source fix, the finding stays in `open_findings` with `state: in-progress` until a rerun proof captures the fixed surface in a per-slice proof directory.
4. When the rerun proof is committed, move the finding to `closed_findings` with `state: closed-fixed`, fill in `closed_at_or_null`, and append the rerun proof path to the locale's `proof_references`.
5. When a HIG-area gate for a locale is fully covered with passing evidence across all scoped surfaces, set `gate_state` for that locale to `passed-scoped`. Set `hig_ui_reviewed_claim` to `true` only after `app-localization-all-locale-hig-ui-closure` accepts the locale.
6. Never mark a finding `closed-wont-fix` without a written rationale, and never mark any locale `hig_ui_reviewed_claim: true` while open findings exist.

## Linked workflows

- [Localization HIG UI Completion](../../../docs/workflows/localization-hig-ui-completion.md) — completion contract, locale buckets, and the queued slice ladder.
- [Localization Translation Quality](../../../docs/workflows/localization-translation-quality.md) — status labels, native-review protocol, and Apple HIG localized UI gate definition.

## Current state (snapshot)

- 1 open finding: `HIG-DE-001` (in-progress; source fix landed under `app-localization-evening-reflection-nudge-routing`; rerun screenshot still missing).
- 0 closed findings.
- 0 locales claimed `hig-ui-reviewed`.
- 17 non-German locales remain `blocked-on-native-review` for HIG gate purposes.
- German is `partial-fail` until HIG-DE-001 reruns are captured and all other scoped surfaces are reviewed.
