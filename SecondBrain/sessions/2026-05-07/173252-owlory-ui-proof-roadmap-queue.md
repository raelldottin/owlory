# owlory-ui-proof-roadmap-queue

## Prompt

Treat the remaining UI proof gaps as a roadmap, not one giant slice. Queue source coverage and routing proof work first, then defer screenshot, device, TestFlight, and full regression lanes until the model is clearer.

## Interpretation

This was a harness roadmap slice. The repo already had a clean, mirrored XCUITest smoke ladder, but no queued next proof work. The right move was to encode the next four proof slices and document the broader order without adding product code or more tests.

## Files Edited

- `automation/queue/slices.json`
- `docs/workflows/ui-testing-hygiene.md`
- `docs/workflows/roadmap-status.md`
- `SecondBrain/INDEX.md`
- `SecondBrain/sessions/2026-05-07/173252-owlory-ui-proof-roadmap-queue.md`

## Outcome

- Queued `owlory-ui-test-continue-source-coverage-triage`.
- Queued `owlory-ui-test-continue-source-smoke-batch`.
- Queued `owlory-ui-test-continue-routing-matrix-triage`.
- Queued `owlory-ui-test-continue-routing-smoke-batch`.
- Documented that screenshot, device, TestFlight, and broad regression proof lanes are deferred until source and routing coverage are clearer.
- Preserved the current proof boundary: selected high-value Today Continue paths are XCUITest-backed; exhaustive UI behavior is not claimed.

## Validation

Passed:

- `python3 -m json.tool automation/queue/slices.json`
- `python3 automation/supervisor/run_next.py --dry-run`
- `make architecture`
- `make automation-check`
- `git diff --check`

## Proof And Risk

Proof level: `doc/tooling-tested`.

This creates an executable UI proof roadmap. It does not implement new UI tests, screenshot proof, device proof, TestFlight proof, or full UI regression coverage.
