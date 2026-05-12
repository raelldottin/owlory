# owlory-ui-regression-suite-plan

## Prompt

Doc-only planning slice. Produce docs/workflows/ui-regression-plan.md that defines five lanes with explicit boundaries: smoke suite, regression suite, screenshot proof, device proof, TestFlight proof. For each lane: trigger, target, scope, what it does prove, what it does not prove, gating commands, and artifact location. Do not implement any new tests. Update ui-testing-hygiene.md to cross-reference the plan.

## Interpretation

The job is a definition, not a build. The plan must be specific enough that the next queued slice (owlory-ui-regression-batch-1-today-continue) can construct the regression batch against it, but it must not invent new commands beyond what the next slice will wire up. It must also clarify boundaries that are routinely conflated: smoke artifact vs screenshot proof, green regression vs visual proof, device proof vs TestFlight proof, TestFlight install vs verified TestFlight build.

## Files Edited

- `SecondBrain/INDEX.md`
- `SecondBrain/sessions/2026-05-12/045409-owlory-ui-regression-suite-plan.md`
- `automation/handoffs/20260512T045409Z-owlory-ui-regression-suite-plan.json`
- `automation/queue/slices.json`
- `docs/workflows/roadmap-status.md`
- `docs/workflows/ui-regression-plan.md` (new)
- `docs/workflows/ui-testing-hygiene.md`
- `docs/workflows/validation.md`

## Outcome

- docs/workflows/ui-regression-plan.md created as the canonical lane definition. Each lane records: trigger, target, scope, proves, does-not-prove, gating commands, artifact location. Promotion order and lane-boundary cautions are explicit. The doc caps the number of lanes at five and directs future extensions to the nearest lane rather than a sixth.
- ui-testing-hygiene.md cross-references the plan in its preamble and in the UI proof roadmap section; hygiene rules (deterministic seeds, accessibility identifiers, failure classification, screenshot artifact shape) remain the durable per-lane mechanics.
- validation.md names the plan alongside PR Hygiene and UI Testing Hygiene as a one-line gate-picking reference.
- roadmap-status.md's UI regression / snapshot row now points at the plan as the authority on what lane each open gap belongs in.
- automation/queue/slices.json marks the slice done. The next queued slice (owlory-ui-regression-batch-1-today-continue) depends on this one and is now unblocked.

## Validation

Passed:

- `python3 automation/context/build_context.py --slice-id owlory-ui-regression-suite-plan`
- `python3 automation/supervisor/run_next.py --dry-run`
- `make architecture`
- `make automation-check`
- `git diff --check`

## Proof And Risk

Proof level: `doc-only`. No new tests, no smoke-suite extension, no product code change. The plan's correctness rests on internal consistency and on whether the next slice (`owlory-ui-regression-batch-1-today-continue`) can build the first regression batch against the Lane 2 definition without ambiguity.

Lane 2 names `make ui-regression` as its gating command, but that target does not exist yet; it is documented intent until the next slice wires it. The plan does not address a separate locale-screenshot lane; localization screenshot evidence is treated as a slice-specific Lane 3 pack rather than a sixth lane.
