# Legacy Xcode Docs

Use this workflow before moving or deleting markdown under `owlory_xcode/Docs/`.

## Rule

Treat `owlory_xcode/Docs/` as historical context unless this file says otherwise. Do not delete a legacy Xcode doc just because it is old. Delete only when repo evidence proves one of these:

- the still-useful content already exists in maintained root docs or code/tests, or
- the doc is clearly obsolete and no active workflow depends on it.

If the doc has unique roadmap, privacy, QA, or product-contract content, keep it until a focused slice promotes that content into root `docs/`.

## Current Classifications

| Legacy doc | Evidence | Classification | Action |
| --- | --- | --- | --- |
| `owlory_xcode/Docs/HOME_PROTOCOL_ROADMAP.md` | Implemented multi-day active-run, duplicate prevention, terminal-state, and template-preservation behavior is covered by `docs/product/domains/home.md`, `ProtocolLifecycleRules`, and Home tests. Still-useful optional run-window and Home-project guidance now lives in `docs/product/domains/home.md` and is summarized in `docs/workflows/roadmap-status.md`. | Fully promoted and safe to remove. | Removed. |
| `owlory_xcode/Docs/LESSONS_FROM_GYMPHANT.md` | Exact duplicate of the removed root lessons file; active principles live in `docs/golden-principles.md`, `AGENTS.md`, and validation/review workflows. | Fully superseded and safe to remove. | Removed. |
| `owlory_xcode/Docs/ML_PARALLEL_ROADMAP.md` | Still-useful Foundation Models, MLX/custom-model, context-window, draft-only architecture, and runtime-boundary guidance now lives in `docs/runtime/ml-model-posture.md`; stale parallel-lane ownership and deleted implementation-status claims were omitted. | Fully promoted and safe to remove. | Removed. |
| `owlory_xcode/Docs/ML_PRIVACY_NOTES.md` | Still-useful local-first, draft-only, fallback, cloud/custom-model, speech, and reviewer guidance now lives in `docs/runtime/ml-privacy.md`; stale implementation-status claims were omitted because current ML drafting/model-availability services are placeholders or deleted. | Fully promoted and safe to remove. | Removed. |
| `owlory_xcode/Docs/ML_QA_PLAN.md` | Still-useful fallback categories, eval fixture taxonomy, layer responsibilities, and device sanity expectations now live in `docs/workflows/ml-qa.md`; stale lane ownership and old direct SwiftPM/Xcode command guidance were replaced with current root validation workflows. | Fully promoted and safe to remove. | Removed. |
| `owlory_xcode/Docs/PERFORMANCE_OBSERVABILITY_ROADMAP.md` | Still-useful MetricKit, OSLog/signpost, Instruments, performance-gate, privacy, and device-profiling guidance now lives in `docs/workflows/performance-observability.md`; implemented runtime surfaces remain mapped in `docs/runtime/observability.md`. Stale roadmap phase/status detail was omitted. | Fully promoted and safe to remove. | Removed. |
| `owlory_xcode/Docs/PROJECT_SPEC.md` | Near-duplicate of the removed root `PROJECT_SPEC.md`; the still-useful cross-domain product posture and architecture guidance now lives in `docs/product/overview.md`, `docs/architecture/overview.md`, and maintained domain/workflow docs. `owlory_xcode/README.md` no longer points here as source of truth. | Fully superseded and safe to remove. | Removed. |
| `owlory_xcode/Docs/ROADMAP_EXECUTION_TRACKER.md` | Current open-slice guidance now lives in `docs/workflows/roadmap-status.md`; completed-slice evidence remains discoverable through `SecondBrain/INDEX.md`, domain docs, workflow docs, and tests. Stale legacy claims about active ML/structured-capture services were omitted because current maintained ML docs classify those files as placeholders or deleted. | Fully promoted and safe to remove. | Removed. |
| `owlory_xcode/Docs/TODAY_CONTINUE_CARRY_FORWARD.md` | Still-useful Continue/carry-forward artifact lifecycle, source provenance, retired scaffold, action, and verification guidance now lives in `docs/product/domains/today.md`; implemented behavior remains covered by Today Continue policy files and tests. Stale standalone roadmap framing was omitted. | Fully promoted and safe to remove. | Removed. |

## Verification

After a legacy Xcode docs cleanup, run:

```bash
make drift-report
make architecture
./Tools/validate.sh handoff
./Tools/validate.sh review-preflight
git diff --check
```

Use `make review-preflight` when the cleanup touches workflow scripts.
