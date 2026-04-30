# Roadmap Status

Use this when choosing the next slice or checking whether legacy roadmap state has already moved into maintained docs. Completed work belongs in domain/workflow docs, tests, and `SecondBrain/INDEX.md`; this file lists only current open or deferred guidance.

## Current Posture

- No known P0 roadmap item is active in maintained docs. Treat a new P0 as a regression only when old data can crash, silently mutate state, or block current user flows.
- Stabilized areas should not be revisited without a concrete bug: Continue pipeline, recurring rollover, reminder scheduling, weekly digest cadence/content/calendar labels, stale-item gaps, domain nudges, readiness-to-outcome, protocol lifecycle, daily planning, focus suggestions, voice transcription routing, build provenance, and current docs/handoff harnesses.
- For completed-slice evidence, search `SecondBrain/INDEX.md` and the owning domain doc instead of relying on historical roadmap files.

## Contract Implementation Status

Use [Product Overview](../product/overview.md) for the status-marker vocabulary. These labels prevent future agents from reading a contract as shipped behavior without checking implementation evidence.

| Contract area | Status | Proof level | Remaining gap |
| --- | --- | --- | --- |
| Today / Continue ownership | `Implemented` plus `Needs UI proof` | Domain/core regression tests cover source-aware Continue composition and Focus-backed Done, Defer, and Drop. | Swipe/accessibility-only action discoverability still needs user-visible evaluation or UI proof. |
| Weekly digest rule-versioning | `Implemented` | Patterns tests cover `digestRuleVersion`, latest stale digest refresh, cadence, and scope-honest counts. | Historical backfill is `Deferred` unless legacy rows need rewriting. |
| Train stale planned-session rollover | `Implemented` | Train tests and `make fast` cover auto-skip before recurring spawn. | Future affect/check-in relationship design remains `Contract only`. |
| Build provenance | `Implemented` | `BuildInfo`, Xcode stamp scripts, `make build-provenance`, and `BuildInfoTests`. | No known gap for local build identity. |
| GitHub / Xcode release mirroring | `Partially implemented`, `Needs automation enforcement` | Xcode build metadata and Git identity are stamped and validated locally. | The repo does not yet mechanically prove a release commit/tag has been pushed to GitHub before archive. |
| Write Lab capture inbox | `Partially implemented` | Fast Write capture, source-note conversion, Add to Today, task promotion, protocol promotion, and visible destination status exist; the product contract allows todo-like thoughts to enter Write Lab. | Processing prompts, running-app proof, and user-legibility proof still need implementation. |
| Write Lab promotion model | `Partially implemented` | `Turn into Source Note` preserves note content; Add to Today creates Today-owned Focus work; task promotion creates Home-owned tasks; protocol promotion creates Home-owned protocol drafts/templates without active runs or Today Continue leakage. Destination promotions preserve typed Write-note origin metadata; Write note detail shows Today/task/protocol status; Home task/protocol detail routes back to existing source notes. | Permanent-note conversion, richer duplicate choices, running-app proof, and screenshot/UI proof for route/status affordances remain future work. |
| UI / screenshot regression coverage | `Needs UI proof` | Manual UI review guidance exists. | Broad snapshot or screenshot regression infrastructure is not present. |

## Open Slices

Today Continue later work:

- Add Skip for today as a derived-row hide action that does not mutate source objects by default.
- Add stable source IDs/deep links where available to open or highlight exact domain records.
- Add persisted generated-item provenance only where a persisted generated record actually exists.
- Add prune/migrate behavior only after invalid artifact suppression has shipped safely and user-authored payload has a migration path.

Home protocol roadmap:

- Optional run-window and future Home-project guidance lives in `docs/product/domains/home.md`.
- Implement windows such as Today, Weekend, This Week, or Custom only as labels, stale treatment, or overdue treatment.
- Do not auto-abandon or auto-complete protocol runs when a future window ends unless an explicit product rule lands with tests.

ML, speech, and generated-output readiness:

- Current production suggestion and digest behavior is deterministic. The old Foundation Models drafting, structured-capture, model-availability, and prompt-budgeting files are placeholders or deleted.
- Any future model/draft reintroduction must follow `docs/runtime/ml-model-posture.md`, `docs/runtime/ml-privacy.md`, and `docs/workflows/ml-qa.md`.
- Expand eval fixtures and fake-response coverage before treating new generated-output surfaces as release-ready.
- Real-device sanity remains required for microphone permission, on-device speech availability, transcription latency, model availability, and fallback behavior.

Performance observability expansion:

- Add signposts only for important runtime paths that support, release, or performance work needs to explain later, such as voice capture, transcription, future generated-output adapters, and Home protocol run lifecycle.
- Use MetricKit custom signposts only for critical release metrics whose count or duration should appear in daily aggregate payloads.
- Add local/internal MetricKit payload export only after a diagnostics retention decision.

Custom compute or model feasibility:

- Do not introduce MLX, BNNS, MPS Graph, or custom model runtimes without a named workload and measured evidence that Foundation Models, Speech, Natural Language, Vision, Core ML, or deterministic Swift rules are insufficient.
- Follow both ML posture and performance-observability gates before shipping any custom runtime path.

UI regression and snapshot coverage:

- The repo still lacks broad UI regression or snapshot infrastructure for shipped user-visible workflows.
- Do not claim snapshot/UI proof until that infrastructure exists; record manual/device gaps honestly.

## Suggested Order

For implementation work, prefer this order unless a user request or concrete bug changes priority:

1. Performance observability expansion.
2. Continue Skip for today.
3. ML eval fixtures and manual device checklist.
4. Continue persisted provenance and later prune/migrate pass.
5. Home protocol optional run windows from the maintained Home domain contract.

## Update Rule

- Update this file only when an open roadmap item is completed, retired, or replaced by a more specific domain/workflow doc.
- Keep completed histories in `SecondBrain`; do not grow this into a changelog.
- Do not recreate `owlory_xcode/Docs/ROADMAP_EXECUTION_TRACKER.md`.

## Verify

For roadmap/docs-only changes:

```bash
make drift-report
make architecture
./Tools/validate.sh handoff
./Tools/validate.sh review-preflight
git diff --check
```

For implementation slices, also run the affected domain command from [Validation Workflows](validation.md).
