# app-localization-hig-ui-review-gate

## Prompt

The user said: "each localization ui must adhere Apple HIG standards".

## Interpretation

Make Apple Human Interface Guidelines adherence a formal gate for localized UI claims, not an informal reviewer preference. This should affect review policy and the reusable native review intake template.

## Context

Checked current official Apple HIG pages for the applicable review areas:

- Human Interface Guidelines
- Layout
- Typography
- Accessibility
- Labels
- Right to left

Added the supervisor slice `app-localization-hig-ui-review-gate` and confirmed supervisor dry-run selected it.

## Results

Implemented.

- Updated `docs/workflows/localization-translation-quality.md` with an Apple HIG localized UI gate.
- Added `hig-ui-reviewed` status semantics.
- Updated the native language review protocol to require the HIG gate before localized UI readiness claims.
- Updated `localization/review/native-review-intake-template.md` with a structured HIG checklist.
- Updated docs map wording.
- Marked the queue slice done.

## Validation

Passed:

- `python3 automation/context/build_context.py --slice-id app-localization-hig-ui-review-gate`
- `python3 automation/supervisor/run_next.py --dry-run`
- `make architecture`
- `make localization-check`
- `python3 Tools/localization-review-status.py`
- `make automation-check`
- `git diff --check`

Additional checks passed:

- `python3 -m json.tool automation/queue/slices.json`
- `python3 -m json.tool automation/handoffs/20260518T022159Z-app-localization-hig-ui-review-gate.json`
- Handoff schema validation for `automation/handoffs/20260518T022159Z-app-localization-hig-ui-review-gate.json`
