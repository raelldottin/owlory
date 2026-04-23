# AGENTS.md

Owlory is an Apple-native, local-first life command center. This repository is the system of record for product rules, architecture boundaries, and validation workflows. Prefer the smallest safe change that preserves shipped behavior, and move durable knowledge into `docs/` when you learn something structural.

Start with [docs/README.md](docs/README.md). It is the map for progressive disclosure: architecture rules, product domains, runtime behavior, workflows, and decisions live there instead of accumulating in this file.

Use the supervisor harness by default for non-trivial implementation slices and continuation work. Before coding a slice, classify it in `automation/queue/slices.json`, build its bounded context with `automation/context/build_context.py`, and run `python3 automation/supervisor/run_next.py --dry-run` to confirm the supervisor-selected scope. If the supervisor cannot launch because of a policy gate such as dirty workspace scope or missing `agent_command_template`, record that blocker and continue manually only inside the selected slice boundary. Do not implement recursive self-spawning from inside an agent run.

Each completed slice must leave the repository clean. Commit or preserve the slice deliberately, then verify `git status --short` returns no output before handoff.

To find the owner for a change, use [docs/product/domain-index.md](docs/product/domain-index.md), then load only that domain's doc and the boundary model in [docs/architecture/boundaries.md](docs/architecture/boundaries.md). Product rules belong in `owlory_xcode/Owlory/Core/Domain/`; state orchestration belongs in `Core/Application/`; persistence and framework adapters stay behind their respective boundaries.

Validate before finishing. Start with `make architecture` for structural checks, then run the narrowest relevant command from [docs/workflows/validation.md](docs/workflows/validation.md). Use `make fast` for the common agent loop and `make verify` before broad handoff.

Keep the Second Brain current for every prompt. The workflow is documented in [docs/workflows/second-brain.md](docs/workflows/second-brain.md).
