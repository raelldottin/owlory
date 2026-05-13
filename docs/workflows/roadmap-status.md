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

- Maintained schedule-window ownership lives in `docs/product/domains/home.md` and `ProtocolScheduleRules`.
- Current protocol schedule windows are template-owned labels only; they must not auto-abandon or auto-complete runs when a window ends.
- Overdue/stale treatment beyond Home template labels and the future Home-project model remain open.

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

- The maintained XCUITest smoke suite proves selected high-value Today Continue paths, not exhaustive UI behavior.
- Current open proof gaps are tracked against the lanes defined in [UI Regression Plan](ui-regression-plan.md): the regression suite (Lane 2) is now wired via `make ui-regression` against `OwloryUITests/TodayContinueRegression`, with the first batch covering Today Continue source visibility, source-derived routing, and Focus row actions; screenshot, device, and TestFlight lanes already have at least one slice's worth of preserved evidence and remain extendable.
- The immediate UI proof queue continues to broaden source and routing smoke and to grow the regression batch with edge cases when new product surfaces ship. Screenshot, device, TestFlight, and full-regression coverage is governed by the five-lane plan; one lane does not imply another.
- Do not claim snapshot/UI proof beyond the specific proof lane that has preserved evidence; record manual/device/TestFlight gaps honestly.

## Parked Proof And Localization Work

The following items are intentionally represented as blocked/deferred slices so future agents do not lose them or start them prematurely:

- `owlory-ui-test-testflight-proof-retry` - blocked until a fresh clean TestFlight build exists.
- `owlory-ui-test-testflight-proof-capture` - blocked until the TestFlight Build Info gate passes.
- `app-localization-first-locale-review-intake` - blocked until reviewed translation values and reviewer/status metadata exist.
- `owlory-ui-regression-expansion-next-surface` - blocked until the next regression surface is explicitly chosen.

Do not convert blocked slices to active implementation work without satisfying their entry conditions. `make clean-stop` verifies this parking lot mechanically.

## Suggested Order

For implementation work, prefer this order unless a user request or concrete bug changes priority:

1. Performance observability expansion.
2. UI proof source/routing triage and focused smoke batches already queued in `automation/queue/slices.json`.
3. Continue Skip for today.
4. ML eval fixtures and manual device checklist.
5. Continue persisted provenance and later prune/migrate pass.
6. Home protocol overdue/stale treatment and future Home-project modeling.

## Update Rule

- Update this file only when an open roadmap item is completed, retired, or replaced by a more specific domain/workflow doc.
- Keep completed histories in `SecondBrain`; do not grow this into a changelog.
- Do not recreate `owlory_xcode/Docs/ROADMAP_EXECUTION_TRACKER.md`.

## Verify

For roadmap/docs-only changes:

```bash
make drift-report
make clean-stop
make architecture
./Tools/validate.sh handoff
./Tools/validate.sh review-preflight
git diff --check
```

For implementation slices, also run the affected domain command from [Validation Workflows](validation.md).
