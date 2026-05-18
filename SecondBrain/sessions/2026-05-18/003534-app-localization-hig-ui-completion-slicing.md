# app-localization-hig-ui-completion-slicing

## Prompt

The user asked to complete localized UI adherence to Apple HIG across all localization and create all necessary slices for completion.

## Interpretation

Treat "HID" as Apple HIG. Do not claim all-locale HIG readiness in one broad step. Create a durable completion contract and queue the remaining proof, review, gate, remediation, and closure slices.

## Context

- Existing docs require Apple HIG localized UI review before localized UI readiness claims.
- German is the only native-reviewed non-English locale.
- The German HIG gate previously failed on HIG-DE-001; the visible evening reflection source path is now fixed, but German still needs preserved rerun evidence.
- The other 17 non-English locales remain LLM-drafted and cannot receive final label/action clarity claims without native or fluent review.
- Apple's current HIG source pages were checked for the plan: main HIG, accessibility, writing, and right-to-left guidance.

## Results

Implemented the slicing and documentation pass.

- Added `docs/workflows/localization-hig-ui-completion.md`.
- Linked the new workflow from `docs/README.md`.
- Updated localization quality status to say all-locale HIG completion is queued, not claimed.
- Added 28 queue records:
  - 1 completed slicing slice.
  - 3 queued setup slices for evidence matrix, multisurface screenshots, and Dynamic Type/accessibility harnessing.
  - 17 blocked native-review intake slices for non-German locales.
  - 5 queued bucketed HIG gate/remediation slices.
  - 1 blocked final all-locale HIG closure slice.

## Validation

Passed:

- `python3 -m json.tool automation/queue/slices.json`
- queue schema validation via `automation.supervisor.policy.validate_document`
- `python3 automation/context/build_context.py --slice-id app-localization-hig-ui-completion-slicing`
- `python3 automation/supervisor/run_next.py --dry-run` (selected `app-localization-hig-evidence-matrix`)
- `make architecture`
- `make localization-check`
- `python3 Tools/localization-review-status.py`
- `make automation-check`
- `git diff --check`

## Residual Risk

- All-locale `hig-ui-reviewed` is not claimed.
- Native/fluent reviewer input is still required for 17 non-German locales before final HIG label/action clarity claims.
- Screenshot, Dynamic Type/accessibility, device, and TestFlight evidence are still future slices.
