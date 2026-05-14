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
| GitHub / Xcode release mirroring | `Implemented` locally, `Needs operator discipline` for Xcode Organizer | Xcode build metadata and Git identity are stamped and validated locally; `.githooks/pre-push` protects pushes; `make release-preflight` protects Archive readiness. | Git hooks cannot stop Xcode Organizer archive clicks; operators must still run `make release-preflight` immediately before archive. |
| Localization | `Partially implemented` | Apple-native resources, parity checks, dynamic formatting boundaries, all-locale smoke, representative screenshot proof, German review packet, and an idb-first all-locale screenshot harness exist. | Translation quality and reviewed translations are incomplete; all-locale screenshot proof remains blocked until idb dependencies are ready and clean screenshots are captured. |
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
- Current open proof gaps are tracked against the lanes defined in [UI Regression Plan](ui-regression-plan.md): the regression suite (Lane 2) is now wired via `make ui-regression` against `OwloryUITests/TodayContinueRegression` (Today Continue source visibility, source-derived routing, Focus row actions), `OwloryUITests/WriteCaptureRegression` (Write capture inbox row, capture entry affordance, Add to Today promotion visibility), and `OwloryUITests/TrainRegression` (Train active Today -> History transition), with `DOMAIN=today`, `DOMAIN=write`, and `DOMAIN=train` matrix support. Screenshot, device, and TestFlight lanes already have at least one slice's worth of preserved evidence and remain extendable. TestFlight proof currently covers the natural-data Today Continue launch surface and one Home protocol run route in `automation/proofs/owlory-ui-testflight-proof/20260513T205620Z-provenance-intake/`.
- No next Lane 2 surface is selected. Screenshot, device, TestFlight, and full-regression coverage is governed by the five-lane plan; one lane does not imply another.
- Do not claim snapshot/UI proof beyond the specific proof lane that has preserved evidence; record manual/device/TestFlight gaps honestly.

## Parked Proof And Localization Work

The following items are intentionally represented as blocked/deferred slices so future agents do not lose them or start them prematurely:

- `app-localization-all-locale-screenshot-proof` - blocked until all-locale smoke passes, full-locale launch-surface visual evidence is explicitly requested, and `make localization-screenshot-idb-check` reports ready.
- `app-localization-first-locale-review-intake` - blocked until reviewed translation values and reviewer/status metadata exist.

Do not convert blocked slices to active implementation work without satisfying their entry conditions. `make clean-stop` verifies this parking lot mechanically.
When a blocked slice needs progress, work on its `recommended_unblocker` instead of the blocked target.

Current unblocker chain:

- `owlory-release-clean-testflight-build-prep` recorded clean local release-prep evidence in `automation/proofs/owlory-release-clean-testflight-build-prep/`. The follow-up TestFlight proof passed for the captured natural-data path in `automation/proofs/owlory-ui-testflight-proof/20260513T205620Z-provenance-intake/`.
- `app-localization-review-packet-for-first-locale` prepared the German-first packet in `localization/review/de/`. As of 2026-05-14, manual follow-up confirmed tested German translation values do not exist yet. The intake slice remains blocked until reviewed German values return with reviewer/status metadata.
- `app-localization-completion-status-audit` corrected the maintained status: localization infrastructure is implemented, but localization as a product-quality claim is not complete until reviewed translations and all-locale proof land.
- `app-localization-all-locale-smoke` passed for all 19 supported locales and preserved JSON proof under `automation/proofs/app-localization-all-locale-smoke/`. This proves launch/resource loading only, not translation quality.
- `localization-screenshot-proof-idb-harness` added a check-only idb dependency gate and idb-first capture helper for all-locale screenshot proof. It does not claim screenshot proof until the idb client is installed and all 19 settled screenshots are captured and preserved.
- `owlory-ui-regression-next-surface-triage` ran in parallel by two agents on 2026-05-13. Agent A selected Write capture inbox and `owlory-ui-regression-expansion-next-surface` shipped the `WriteCaptureRegression` Lane 2 batch with `running-app-smoke` proof. Agent B selected Train active/history transition and `owlory-ui-regression-batch-3-train-active-history` shipped the `TrainRegression` Lane 2 batch with `running-app-smoke` proof.

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
