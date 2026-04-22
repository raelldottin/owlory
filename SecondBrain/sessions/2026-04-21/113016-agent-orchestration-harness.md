# Turn Entry

## Metadata

- Date: 2026-04-21
- Local Time: 11:30:16 EDT
- Agent: OpenAI Codex
- Status: Completed
- Slug: agent-orchestration-harness

## User Prompt

```text
Build a durable automation harness under `automation/` that uses a machine-readable slice queue, machine-readable handoff artifacts, a supervisor that launches a fresh agent run per slice, a bounded context packager, and explicit stop conditions that prevent recursive self-spawning or runaway chaining.
```

## Interpretation

- What the user wants: Add a repo-owned orchestration system that can continue from one completed slice into the next by supervising separate agent runs instead of recursively spawning from inside one run.
- Scope: New tracked automation docs, JSON contracts, Python scripts, examples, and light tests; doc links and stable command-surface updates where helpful.
- Assumptions: The harness should stay generic about the actual agent executable by using a configurable command template, and it should enforce strict stop rules rather than silently continuing.

## Plan

- Step 1: Define the tracked queue, handoff, schema, prompt, and doc contract under `automation/`.
- Step 2: Implement bounded context building plus supervisor selection/validation/policy logic in Python.
- Step 3: Add light tests, expose the harness through maintained docs/commands, and run focused validation.

## Changes

- Created:
  - `SecondBrain/sessions/2026-04-21/113016-agent-orchestration-harness.md`
  - `automation/README.md`
  - `automation/queue/slices.json`
  - `automation/handoffs/.gitkeep`
  - `automation/prompts/base.md`
  - `automation/prompts/slice.md`
  - `automation/prompts/review.md`
  - `automation/context/build_context.py`
  - `automation/supervisor/run_next.py`
  - `automation/supervisor/policy.py`
  - `automation/schemas/handoff.schema.json`
  - `automation/schemas/slice.schema.json`
  - `automation/examples/example-handoff.json`
  - `automation/examples/example-slices.json`
  - `automation/tests/test_harness.py`
- Modified:
  - `SecondBrain/INDEX.md`
  - `README.md`
  - `Makefile`
  - `docs/README.md`
  - `docs/repo-map.md`
  - `docs/workflows/validation.md`
  - `docs/workflows/agent-handoff.md`
- Deleted:
- Inspected:
  - `docs/README.md`
  - `docs/repo-map.md`
  - `docs/architecture/boundaries.md`
  - `docs/workflows/validation.md`
  - `docs/workflows/second-brain.md`
  - `docs/workflows/agent-handoff.md`
  - `README.md`
  - `Makefile`

## Validation

- Commands run:
  - `date +%H%M%S`
  - `make automation-check`
  - `python3 automation/context/build_context.py --slice-id today-copy-followup --queue automation/examples/example-slices.json --handoff-dir automation/examples > /tmp/owlory-automation-context.json && wc -c /tmp/owlory-automation-context.json`
  - `python3 automation/supervisor/run_next.py --dry-run --queue automation/examples/example-slices.json --handoff-dir automation/examples`
  - `make architecture`
  - `git diff --check -- README.md Makefile docs/README.md docs/repo-map.md docs/workflows/validation.md docs/workflows/agent-handoff.md automation/README.md automation/queue/slices.json automation/prompts/base.md automation/prompts/slice.md automation/prompts/review.md automation/context/build_context.py automation/supervisor/run_next.py automation/supervisor/policy.py automation/schemas/handoff.schema.json automation/schemas/slice.schema.json automation/examples/example-handoff.json automation/examples/example-slices.json automation/tests/test_harness.py SecondBrain/sessions/2026-04-21/113016-agent-orchestration-harness.md SecondBrain/INDEX.md`
- Results:
  - Captured a session timestamp for this task.
  - `make automation-check` passed with six unit tests.
  - `build_context.py` produced a bounded example context bundle at `/tmp/owlory-automation-context.json` with a size of 28679 bytes.
  - `run_next.py --dry-run` stopped on dirty paths outside the example slice scope, which is the expected policy behavior in the current dirty workspace.
  - `make architecture` passed.
  - Scoped `git diff --check` returned clean.
- Failures and reruns:
  - Initial Python validation failed because the local interpreter is Python 3.9 and does not provide `datetime.UTC` or PEP 604 union syntax. Updated the harness to use `timezone.utc` and `typing.Optional` / `typing.Union`, then reran the validation loop successfully.

## Outcome

- Summary: Added a repo-owned automation harness with a tracked slice queue, handoff schema and artifacts, bounded context packaging, explicit supervisor stop policy, example payloads, light tests, and linked docs plus a stable `make automation-check` command.
- Behavior preserved: The harness does not change Owlory product/runtime behavior, does not recursively self-spawn from inside a run, and refuses continuation when repo dirt or validation status makes chaining unsafe.
- Risk remaining: Live unattended use still requires a machine-local `policy.agent_command_template` or `--agent-cmd`, and the current repository dirt means real supervisor runs will stop until the worktree is cleaned or the slice scope matches that dirt.
- Follow-up: Populate the live queue with real slices only after the repo is clean enough for the intended allowed-path boundaries, then test one end-to-end fresh-run flow with the local agent command template.
