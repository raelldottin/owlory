# Owlory Docs Map

Use this tree for progressive disclosure. Load the smallest doc that answers the task.

## Start Here

- [Repo Map](repo-map.md) is the cold-start guide for future agents and context-compacted sessions.
- [Golden Principles](golden-principles.md) states the compact drift-control principles for architecture, validation, and handoff.
- [Architecture Overview](architecture/overview.md) explains the current repo shape and major seams.
- [Boundary Model](architecture/boundaries.md) defines allowed dependency direction and shared-code rules.
- [Product Overview](product/overview.md) captures cross-domain product posture, core surfaces, and experience principles.
- [Domain Index](product/domain-index.md) maps product areas to owning code, tests, and validation.
- [Validation Workflows](workflows/validation.md) lists invokable checks, including the `make clean-stop` completion gate, and when to use them.
- [Localization String Inventory](workflows/localization-string-inventory.md) classifies source-string extraction status before translation work.
- [Localization Dynamic Formatting](workflows/localization-dynamic-formatting.md) defines layer ownership for counts, dates, statuses, notifications, and display-label localization.
- [Localization Translation Quality](workflows/localization-translation-quality.md) defines placeholder status, completion status, formal native-review intake, Apple HIG localized UI review, locale expectations, and acceptance criteria before replacing English placeholders. Localization infrastructure does not imply translation quality.
- [Localization Review Export](../localization/review/README.md) is the generated reviewer packet for current English source values, plural entries, and placeholder status labels.
- [Agent Handoff](workflows/agent-handoff.md) explains the continuity command and expected handoff behavior.
- [Automation Harness](../automation/README.md) explains the queue-driven supervisor for fresh-run slice chaining.
- [PR Hygiene](workflows/pr-hygiene.md) defines the PR claim, proof, validation, and merge-handoff expectations.
- [UI Testing Hygiene](workflows/ui-testing-hygiene.md) defines running-app, screenshot, device, and future XCUITest proof boundaries.
- [ML Model Posture](runtime/ml-model-posture.md) defines Foundation Models, MLX/custom-model, context-window, and adapter-boundary rules.
- [ML Privacy And Drafts](runtime/ml-privacy.md) defines local-first, draft-only, fallback, and reviewer expectations for ML/speech/generated-output work.
- [ML QA](workflows/ml-qa.md) defines fallback categories, eval fixture expectations, and device sanity checks for ML/speech/generated-output work.
- [Performance Observability](workflows/performance-observability.md) defines MetricKit, signpost, Instruments, profiling, and performance-claim rules.
- [Roadmap Status](workflows/roadmap-status.md) lists current open/deferred slices after completed work has moved into domain docs and SecondBrain.
- [App Icon Assets](workflows/app-icons.md) explains the shipped app-icon source of truth and conservative archive cleanup rule.
- [Drift Control](workflows/drift-control.md) explains read-only clutter reports and safe cleanup remediation.
- [Historical Root Docs](workflows/historical-docs.md) classifies root markdown that predates the progressive docs tree.
- [Archived Code Artifacts](workflows/archived-code-artifacts.md) classifies root duplicate test trees and project archives before cleanup.
- [Legacy Xcode Docs](workflows/legacy-xcode-docs.md) classifies historical docs still under `owlory_xcode/Docs/`.
- [OSS Evaluation](workflows/oss-evaluation.md) guides external project/library assessment.
- [Review Workflow](workflows/review.md) explains reviewer preflight, findings, and validation expectations.

## Directories

- `architecture/` - module shape, dependency rules, enforcement, and repo assessment.
- `../automation/` - queue-driven agent supervisor, schemas, prompt fragments, examples, and tests.
- `product/` - user-facing domains and product-rule ownership.
- `runtime/` - telemetry, build identity, reminders, widgets, and other runtime concerns.
- `workflows/` - commands an agent can run to prove a change.
- `decisions/` - short architecture decision records.

Legacy roadmap notes still exist in `owlory_xcode/Docs/`. Treat those as historical/contextual through [Legacy Xcode Docs](workflows/legacy-xcode-docs.md) until promoted into this root docs tree. Use [Roadmap Status](workflows/roadmap-status.md) for current open-slice guidance.
