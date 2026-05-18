# app-localization-hig-remediation-triage

## Prompt

> "start next slice" — execute the supervisor-selected slice `app-localization-hig-remediation-triage`. Convert every failed HIG finding into a narrow implementation or proof-rerun slice. Do not make UI source changes in this slice.

## What was done

Planning/queue slice. No UI source changes, no translation changes, no proof artifacts produced. Two effects:

1. Updated the all-locale HIG evidence matrix at `automation/proofs/app-localization-hig-ui-matrix/manifest.json` with the full set of open findings and per-finding remediation_slice pointers.
2. Queued 3 narrow remediation slices in `automation/queue/slices.json`.

### Finding inventory (11 open)

| ID | State | Area | Locale | Remediation slice |
|---|---|---|---|---|
| `HIG-DE-001` | in-progress (source-fix-confirmed) | labels-actions | de | `app-localization-hig-multisurface-screenshot-capture` (post-fix rerun) |
| `HIG-AR-001` | open | right-to-left | ar | `app-localization-rtl-sf-symbol-fix` |
| `HIG-AR-002` | open | right-to-left | ar | `app-localization-rtl-sf-symbol-fix` |
| `HIG-AR-003` | open | adaptive-layout | ar | `app-localization-tab-bar-truncation-fix` |
| `HIG-DE-002` | open | adaptive-layout | de | `app-localization-tab-bar-truncation-fix` |
| `HIG-FR-001` | open | adaptive-layout | fr | `app-localization-tab-bar-truncation-fix` |
| `HIG-JA-001` | open | adaptive-layout | ja | `app-localization-tab-bar-truncation-fix` |
| `HIG-NL-001` | open | adaptive-layout | nl | `app-localization-tab-bar-truncation-fix` |
| `HIG-RU-001` | open | adaptive-layout | ru | `app-localization-tab-bar-truncation-fix` |
| `HIG-TR-001` | open | adaptive-layout | tr | `app-localization-tab-bar-truncation-fix` |
| `HIG-UK-001` | open | adaptive-layout | uk | `app-localization-tab-bar-truncation-fix` |

### Queued remediation slices

| Slice | Pri | Target proof level | Closes |
|---|---:|---|---|
| `app-localization-rtl-sf-symbol-fix` | 79 | build-tested | HIG-AR-001 + HIG-AR-002 source fix (`chevron.right` → `chevron.forward`; `arrow.right.circle` → `arrow.forward.circle` × 2) |
| `app-localization-hig-multisurface-screenshot-capture` | 78 | screenshot-verified | HIG-DE-001 rerun + screenshot evidence for all 8 tab-truncation findings; depends on the RTL fix landing first |
| `app-localization-tab-bar-truncation-fix` | 77 | build-tested + ui-regression-tested | Adaptive-layout: HIG-AR-003 + HIG-DE-002 + HIG-FR-001 + HIG-JA-001 + HIG-NL-001 + HIG-RU-001 + HIG-TR-001 + HIG-UK-001; conditional on screenshot capture confirming each |

The chain is intentional: fix RTL icons → capture screenshots (now showing post-fix RTL state for ar + reflection-nudge for de + truncation-candidate tabs for the other 6 locales) → if truncation is confirmed, apply tab-bar layout tweak → re-run screenshot capture (or a targeted variant) to confirm closure.

### Matrix update

`automation/proofs/app-localization-hig-ui-matrix/manifest.json`:

- `updated_at` 2026-05-18T10:22:27Z.
- `notes` appended with the triage summary.
- `open_findings` now lists all 11 findings with the per-finding remediation_slice_id set.
- `remediation_slice_pointers` populated for every finding.
- `downstream_slices.remediation_triage` marked DONE.
- `downstream_slices.remediation_slices_queued` lists the 3 new slices.

## Validation

- `python3 automation/context/build_context.py --slice-id app-localization-hig-remediation-triage` — ran.
- `python3 -m json.tool` on queue + matrix — both valid.
- `make architecture` — passed.
- `make localization-check` — 19 / 377 / 13.
- `python3 Tools/localization-review-status.py` — ran (7478 passed / 64 warning / 0 reverted).
- `make automation-check` — 71 tests passed.
- `git diff --check` — clean.

## Lane Boundary

`doc-only`. No UI source, no test, no translation, no resource changes. The slice contract explicitly forbade source changes.

## Residual Risk

- HIG-DE-001 remains in-progress until the post-fix German Today screenshot is preserved.
- All 10 newly-allocated findings remain open. The 3 remediation slices are the queued path to close them, not the closure itself.
- The all-locale HIG closure slice (`app-localization-all-locale-hig-ui-closure`) remains blocked on the 3 new remediation slices.

## Not Claimed

- Any HIG finding is closed by this slice.
- Any locale is `hig-ui-reviewed`.
- Any UI source changed in this slice.

## Next slice

`app-localization-rtl-sf-symbol-fix` (priority 79) is now the supervisor-eligible next slice. It is the only remediation slice with no proof-capture dependency — it should land before the multisurface screenshot capture so the captured Arabic evidence shows the fixed icons.
