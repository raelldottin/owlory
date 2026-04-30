# owlory-handoff-evidence-writer

## Prompt

Add the next automation harness slice so every handoff carries enough evidence for review without rereading the full diff.

## Interpretation

- The proof ladder already exists.
- This slice should require richer handoff evidence: contract status changes, residual risks, repo cleanliness, and git mirror status.
- This is harness/docs/test work only; no app or Xcode changes.

## Plan

1. Register the supervisor slice and run the bounded context/dry-run checks.
2. Expand the handoff schema and generated template.
3. Preserve legacy handoffs as read-only context while requiring richer fields for new handoffs.
4. Update prompts and docs to explain good handoff evidence.
5. Add automation tests for missing evidence and residual-risk preservation.

## Files

- To inspect/edit: automation handoff schema, context builder, supervisor policy, prompts, examples, tests, docs, queue, handoff, and this SecondBrain entry.

## Validation

- `python3 automation/context/build_context.py --slice-id owlory-handoff-evidence-writer`: passed.
- `python3 automation/supervisor/run_next.py --dry-run`: passed; selected `owlory-handoff-evidence-writer`.
- `python3 -m py_compile automation/supervisor/policy.py automation/supervisor/run_next.py automation/context/build_context.py automation/tests/test_harness.py`: passed.
- `make automation-check`: passed.
- `git diff --check`: passed.

## Outcome

- Added richer required handoff fields: `contract_status_changes`, `residual_risks`, `repo_clean_status`, and `git_mirror_status`.
- Migrated generated handoff templates and docs from legacy `risks` to `residual_risks`.
- Kept legacy handoffs readable when they still use `risks`.
- Added automation tests for missing/empty residual risks, missing contract status changes, invalid repo clean status, and richer context summaries.
