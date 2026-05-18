# app-localization-hig-evidence-matrix

## Prompt

> "start hig-ui-reviewed" — execute the supervisor-selected slice `app-localization-hig-evidence-matrix`, which creates the durable repo-managed matrix and finding taxonomy that downstream HIG gate, remediation, and closure slices share.

## What was done

Planning/proof slice. Created the all-locale HIG evidence matrix under `automation/proofs/app-localization-hig-ui-matrix/` and wired it into the two HIG-relevant workflow docs.

### Matrix manifest

`automation/proofs/app-localization-hig-ui-matrix/manifest.json` records:

- 19 supported locales × locale bucket (`source`, `german_reviewed`, `rtl`, `cjk`, `long_script_or_inflection_heavy`, `remaining_ltr`).
- 8 scoped HIG surfaces per locale: Build Info, Today launch, root tabs, primary empty states, primary actions, high-risk date/count/plural, Dynamic Type + accessibility pass, RTL-only mirroring (ar only).
- Finding taxonomy: `HIG-<LOCALE_UPPER>-<NNN>` IDs; severity (`blocking`, `major`, `minor`, `info`); HIG area (`platform-consistency`, `adaptive-layout`, `typography-dynamic-type`, `accessibility`, `labels-actions`, `locale-aware-formatting`, `right-to-left`); state (`open`, `in-progress`, `closed-fixed`, `closed-wont-fix`, `duplicate`); plus `observed_evidence`, `source_trace`, `proof_path_or_chat_observation`, `remediation_slice_id_or_null`, `created_at`, `closed_at_or_null`.
- Per-locale `gate_state`, `native_review_state`, `scoped_surface_status`, `proof_references`, `hig_ui_reviewed_claim`, and `blockers`.
- Downstream slice pointers (`app-localization-hig-multisurface-screenshot-harness`, `app-localization-hig-dynamic-type-accessibility-harness`, per-bucket HIG gate slices, `app-localization-hig-remediation-triage`, `app-localization-all-locale-hig-ui-closure`).

### Matrix README

`automation/proofs/app-localization-hig-ui-matrix/README.md` documents:

- What the matrix is (planning/evidence index) and what it is not (not a screenshot/device proof, not a `hig-ui-reviewed` claim).
- Apple HIG source references (HIG, Accessibility, Writing, Right to left) anchored on 2026-05-18.
- Finding ID format, severity rubric, scoped surface list, locale buckets.
- A 6-step lifecycle/update protocol for adding findings, allocating IDs, recording rerun proofs, moving findings to `closed_findings`, and gating `hig_ui_reviewed_claim`.
- Linked workflows (`localization-hig-ui-completion.md`, `localization-translation-quality.md`).
- Snapshot of the current state.

### Doc wiring

| File | Change |
|---|---|
| `docs/workflows/localization-hig-ui-completion.md` | Added "Evidence Matrix" section pointing at the matrix directory and stating that new findings allocate the next free `HIG-<LOCALE_UPPER>-<NNN>` ID into it |
| `docs/workflows/localization-translation-quality.md` | Added an "All-locale HIG evidence matrix" status bullet describing the matrix path, contents, and current state (1 open / 0 closed / 0 locales claimed) |

`docs/README.md` already links the `localization-hig-ui-completion.md` workflow; no top-level docs index change was needed.

### Snapshot

- 1 open finding: `HIG-DE-001` (severity `blocking`, area `labels-actions`, state `in-progress`; source fix landed under `app-localization-evening-reflection-nudge-routing`; rerun screenshot evidence still missing).
- 0 closed findings.
- 0 locales claimed `hig-ui-reviewed`.
- 1 locale `partial-fail`: `de`.
- 17 locales `blocked-on-native-review`.
- 1 source baseline: `en` (`not-started`, awaiting source baseline evidence).

## Validation

- `python3 automation/context/build_context.py --slice-id app-localization-hig-evidence-matrix` — ran.
- `python3 automation/supervisor/run_next.py --dry-run` — selected this slice prior to the work, supervisor pre-flight passes.
- `python3 -m json.tool automation/queue/slices.json` — passed.
- `python3 -m json.tool automation/proofs/app-localization-hig-ui-matrix/manifest.json` — passed.
- `make architecture` — passed.
- `make localization-check` — 19 locales / 377 keys / 13 plural keys.
- `python3 Tools/localization-review-status.py` — ran; LQA shows 7478 passed / 64 warning / 0 reverted across 18 locales.
- `make automation-check` — 57/57 passed.
- `git diff --check` — clean.

## Lane Boundary

`doc-only`. No app source changes, no test changes, no resource changes, no localization key changes. The matrix is a planning index that downstream HIG gate and remediation slices reference and update.

## Residual Risk

- The matrix is text-only. It does not stand in for screenshot, device, or TestFlight proof for any locale.
- `HIG-DE-001` stays in `open_findings` with `state: in-progress` until a rerun proof captures the fixed German Today surface under a per-slice proof directory.
- 17 non-German locales remain blocked on native or fluent review before any HIG gate can be evaluated for label/action clarity.
- The matrix is manually maintained. Every HIG gate, remediation, or rerun slice must update `per_locale_state`, `open_findings`, `closed_findings`, and `proof_references` as part of its lane.

## Not Claimed

- Any locale is `hig-ui-reviewed`.
- Any locale beyond German is `native-reviewed`.
- `screenshot-reviewed` for non-German locales.
- `device-verified` for any locale.
- `testflight-verified` for any locale.
- RTL mirroring for `ar` has been proven on Owlory surfaces.

## Next slices in the HIG ladder

The queue still encodes:

1. `app-localization-hig-multisurface-screenshot-harness` — broadens screenshot capture beyond one Today launch screenshot per locale.
2. `app-localization-hig-dynamic-type-accessibility-harness` — adds maintained Dynamic Type, accessibility, tab reachability, and touch target checks.
3. 17 per-locale native-review slices (currently blocked, awaiting reviewer input).
4. 5 per-bucket HIG gate slices.
5. `app-localization-hig-remediation-triage`.
6. `app-localization-all-locale-hig-ui-closure` (blocked until every HIG gate and remediation slice passes).
