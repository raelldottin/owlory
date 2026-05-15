# owlory-ui-regression-batch-7-localization-layout-triage

## Prompt

The user selected "localization layout" as the next UI regression surface beyond Today Continue.

## Decision

Surface: **Localization layout — representative locale launch-shell regression** (Batch 7).

Rationale:

- All-locale running smoke and all-locale screenshot proof already prove resource loading and one settled launch-surface screenshot per supported locale.
- Non-English resources are still English placeholders, so no slice can honestly prove real translated-text expansion, grammar, truncation, or translation quality yet.
- A maintained XCUITest regression can still catch a valuable class of risk: app launch and Today shell stability under locale launch arguments, including RTL and CJK resource-loading paths.
- The slice stays narrow by using a representative locale set instead of rerunning all 19 locales in Lane 2.

Selected representative locales:

- `en` — baseline English source.
- `de` — Latin locale with known placeholder status and future compound-word risk.
- `ar` — RTL shell pressure.
- `zh-Hans` — CJK resource-loading path.

Deferred:

- Reviewed-translation layout — blocked until reviewed translated values exist and are ingested.
- Pseudo/long-text layout — useful later, but requires a separate harness decision.
- Manual/TestFlight app-language layout — belongs in manual/device/TestFlight proof lanes.
- All 19 locales in Lane 2 — all-locale smoke/screenshots already exist; this regression should stay fast and representative.

## Files Edited

- `docs/workflows/ui-regression-plan.md` — added Batch 7 decision memo and queued implementation target.
- `docs/workflows/ui-testing-hygiene.md` — recorded the selected but not-yet-implemented Batch 7 lane.
- `docs/workflows/roadmap-status.md` — updated UI/localization status so the next surface is no longer "none selected."
- `docs/workflows/localization-translation-quality.md` — clarified that layout regression is separate from translation quality.
- `automation/queue/slices.json` — marked triage done and queued `owlory-ui-regression-batch-7-localization-layout-shell`.
- `automation/handoffs/20260515T045854Z-owlory-ui-regression-batch-7-localization-layout-triage.json`
- `SecondBrain/INDEX.md`
- `SecondBrain/sessions/2026-05-15/005854-owlory-ui-regression-batch-7-localization-layout-triage.md`

## Coverage Goal For Queued Implementation

`owlory-ui-regression-batch-7-localization-layout-shell` should:

- Add a new XCUITest class such as `LocalizationLayoutRegression`.
- Launch with `--owlory-ui-testing`, `--owlory-ui-seed-fresh-day`, `-AppleLanguages`, and `-AppleLocale`.
- Run the representative locale set: `en`, `de`, `ar`, `zh-Hans`.
- Assert the Today dashboard shell settles through stable identifiers rather than translated labels.
- Assert the core app shell remains reachable/hittable enough to prove the locale launch did not blank, crash, or hide navigation.
- Add `DOMAIN=localization` to `make ui-regression`.

## Validation

- `python3 automation/context/build_context.py --slice-id owlory-ui-regression-batch-7-localization-layout-triage` — passed.
- `python3 automation/supervisor/run_next.py --dry-run` — after completion, selected `owlory-ui-regression-batch-7-localization-layout-shell`.
- `make architecture` — passed.
- `make automation-check` — passed.
- `git diff --check` — clean.

## Lane Boundary

`doc-only`. No XCUITest code, no product behavior changes, no localization resources changed, no screenshot/device/TestFlight claims.

## Residual Risk

- The implementation slice may need stable tab or shell identifiers if the shell currently relies on translated labels.
- This does not prove all 19 locales in Lane 2.
- This does not prove real translated-text layout because non-English resources remain English placeholders.
- The Patterns Batch 6 implementation remains queued but lower priority after the user-directed localization layout selection.
