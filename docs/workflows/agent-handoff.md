# Agent Handoff Workflow

Use this workflow whenever an agent resumes a dirty workspace, receives a compacted thread summary, or needs to leave durable state for the next agent.

## Command

```bash
make handoff
```

This calls `Tools/agent-handoff.sh` and prints:

- repository root, branch, and commit
- minimum read order
- validation shortcuts
- dirty workspace path summary
- recent `SecondBrain` entries
- the handoff rule for prompt logging and risk reporting

Use `./Tools/agent-handoff.sh --limit <number>` when the dirty path list is longer than the default output.

When the dirty workspace includes root clutter, generated assets, project archives, or legacy docs, run `make drift-report` before deleting or moving anything.
When taking over or reviewing a broad dirty change set, run `make review-preflight` before choosing validation.

## Before Starting Work

1. Run `make handoff`.
2. Read `AGENTS.md`, `docs/README.md`, and `docs/repo-map.md`.
3. Find the domain owner in `docs/product/domain-index.md`.
4. Open only the owner doc, boundary doc, nearby code, and nearby tests.
5. Create or update a `SecondBrain` entry for the prompt.
6. For non-trivial implementation or continuation work, use the supervisor harness by default: classify or reuse a slice in `automation/queue/slices.json`, run `python3 automation/context/build_context.py --slice-id <slice_id>`, then run `python3 automation/supervisor/run_next.py --dry-run`.
7. If the supervisor dry-run blocks because of dirty workspace scope, missing launch configuration, or another policy gate, record the blocker and proceed manually only inside the selected slice boundary.
8. If the task is to choose the next slice, read [Roadmap Status](roadmap-status.md) after the owner docs.

## Before Final Response

1. Update the `SecondBrain` entry with changed files and validation results.
2. Run the narrowest honest validation path.
3. Report exact commands, failures, reruns, and residual risk.
4. Name the next best slice when useful.

## Guardrail

Handoff output is read-only. It must not mutate source files, stage changes, or claim validation. It exists to reduce rediscovery, not to replace domain-specific tests.

For supervised continuation across fresh agent runs, use [automation/README.md](../../automation/README.md) and `python3 automation/supervisor/run_next.py`. The automation harness is the default for slice continuation. It consumes handoff artifacts; it does not let a running agent recursively launch its own successor.
