# write-promotion-status-affordances

## Prompt

Implement visible promotion/status affordances for Write note detail now that Write can promote to Today, Home tasks, and Home protocol drafts/templates.

## Interpretation

- The main promotion destinations are implemented at the domain layer.
- Write detail should make destination state legible without pressuring users to process the inbox.
- Duplicate promotion actions should not silently disappear without explanation.
- Route-to-destination should only be added where the current app architecture already supports it safely.

## Plan

1. Register and dry-run the supervisor slice.
2. Inspect existing promotion APIs and route/highlight wiring.
3. Add status affordances for Today, task, and protocol promotions.
4. Keep promotion actions lightweight and capture-first.
5. Add focused tests and update maintained docs.

## Validation

- `python3 automation/context/build_context.py --slice-id write-promotion-status-affordances`
- `python3 automation/supervisor/run_next.py --dry-run`
- `make architecture`
- `make test-domain DOMAIN=write`
- `make test-domain DOMAIN=home`
- `make test-domain DOMAIN=today`
- `make automation-check`
- `git diff --check`

## Outcome

- Write note detail now shows a Move section with Today, Task, and Protocol promotion state.
- Duplicate destinations are legible instead of silently disappearing: existing Today/Task/Protocol promotions show completed status, while only eligible destinations expose creation actions.
- Home task destinations can be opened through the existing Home task highlight route; Today Focus and protocol-template routes remain status-only until those destinations have explicit highlight surfaces.
- Product docs and roadmap status now describe the implemented domain-tested affordances and the remaining proof gap.
