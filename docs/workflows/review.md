# Review Workflow

Use this when reviewing a dirty workspace, branch, or handoff from another agent.

## Command

```bash
make review-preflight
```

This calls `Tools/review-preflight.sh`, a read-only classifier that recommends:

- touched areas inferred from changed paths
- docs to load before reviewing
- validation commands to run
- path-specific risks to check

Use `./Tools/review-preflight.sh --base <git-ref>` when reviewing committed branch changes against a base ref.

## Review Order

1. Run `make handoff`.
2. Run `make review-preflight`.
3. Read only the recommended docs plus nearby code/tests.
4. Review for behavior regressions, boundary drift, missing tests, missing docs, and unclear failure remediation.
5. Run the narrowest suggested validation.
6. Report exact checks, findings, assumptions, and residual risk.

## Findings Standard

Lead with bugs and risks. For each finding, include:

- affected file and line when available
- expected behavior
- actual risk
- why it matters
- concrete remediation

If there are no findings, say that clearly and name any validation or coverage that still was not run.

## PR Hygiene

Use [PR Hygiene](pr-hygiene.md) before approving or merging a branch. A PR should state the slice, proof level, exact validations, intended artifacts, residual risk, and clean/mirror status. Do not treat a clean diff as a complete claim unless the PR body or handoff names what behavior was proven and what remains unproven.

For screenshot or UI-flow claims, also load [UI Testing Hygiene](ui-testing-hygiene.md). Check that proof artifacts are durable, not temporary `/tmp` screenshots, and that the claimed proof level does not exceed the evidence.

## Review Guardrails

- Do not review against hidden chat memory; use repo docs and code.
- Do not ask a human where to look before running the preflight.
- Do not revert unrelated dirty work.
- Do not accept product-rule changes buried in UI or persistence code.
- Do not accept new workflow commands unless they are documented and validated.
- Do not approve UI proof claims unless the proof lane is explicit: running-app-smoke, flow-verified, screenshot-verified, device-verified, or testflight-verified.
- Do not accept UI-test failures as vague flakiness; require a failure classification or a narrow follow-up slice.
- For ML, speech, or generated-output changes, load [ML Model Posture](../runtime/ml-model-posture.md), [ML Privacy And Drafts](../runtime/ml-privacy.md), and [ML QA](ml-qa.md). Verify model-runtime boundaries, local-first behavior, draft-only output, fallback, fake-response coverage, and privacy-claim behavior.
- For telemetry, profiling, MetricKit, signpost, or performance-sensitive changes, load [Runtime Observability](../runtime/observability.md) and [Performance Observability](performance-observability.md). Verify no user content is logged, signpost labels are stable and low-cardinality, and any performance claim has measured evidence.
