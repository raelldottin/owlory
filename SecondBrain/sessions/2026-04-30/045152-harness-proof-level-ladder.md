# harness-proof-level-ladder

## Prompt

Add a proof-level ladder to the automation harness before building running-app verification, so handoffs name what was actually proven and what proof remains missing.

## Interpretation

- This is a harness policy slice, not app or Xcode work.
- The repository needs shared vocabulary for proof levels before agents add simulator or running-app smoke workflows.
- Handoffs should preserve residual risk and reject vague completion claims that omit proof level.

## Plan

1. Register the supervisor slice and build bounded context.
2. Add the proof ladder to the handoff schema, context template, prompts, and automation docs.
3. Update policy/test fixtures so valid, missing, and invalid proof levels are covered.
4. Validate with py_compile, automation checks, and diff hygiene.

## Files

- To inspect/edit: automation schema, policy/context helpers, prompts, examples, tests, automation docs, workflow validation docs, queue, handoff, and this SecondBrain entry.

## Validation

- `python3 automation/context/build_context.py --slice-id harness-proof-level-ladder`: passed.
- `python3 automation/supervisor/run_next.py --dry-run`: passed; selected `harness-proof-level-ladder`.
- `python3 -m py_compile automation/supervisor/policy.py automation/supervisor/run_next.py automation/context/build_context.py automation/tests/test_harness.py`: passed.
- `make automation-check`: passed.
- `git diff --check`: passed.

## Outcome

- Added the proof-level ladder to the handoff schema, automation docs, validation docs, and supervisor prompts.
- Added `proof_level` and `missing_proof_levels` to generated handoff templates.
- Added tests for valid proof levels, missing proof level, invalid proof level, invalid missing proof level, and residual-risk/proof preservation in context summaries.
- Preserved legacy handoffs as read-only context with `legacy-unknown` proof so historical summaries do not disappear while new handoffs are strict.
