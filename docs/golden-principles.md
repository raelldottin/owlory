# Golden Principles

These are Owlory's drift-control principles. They are short on purpose; operational detail belongs in domain and workflow docs.

## Repository

- The repo is the system of record. Durable knowledge belongs in docs, scripts, tests, or decision records.
- `AGENTS.md` stays short. Add detail to focused docs and link from `docs/README.md`.
- Future agents should be able to cold-start with `make handoff`, `docs/repo-map.md`, and `docs/product/domain-index.md`.

## Architecture

- Product rules belong in named, deterministic domain policies when practical.
- Application code orchestrates rules and runtime dependencies; it should not hide durable product policy.
- UI renders state and invokes stores; it should not own cross-domain rules.
- Framework, persistence, notification, speech, audio, and filesystem coupling stay outside `Core/Domain`.

## Validation

- Run the narrowest honest validation first.
- Every new workflow command should be documented and reachable through `Makefile` or `Tools/validate.sh`.
- Failed checks should explain the rule, why it exists, and how to remediate it.

## Handoff

- Every prompt gets a `SecondBrain` entry.
- Dirty worktrees are normal, but unrelated changes are not yours to revert.
- Use `make drift-report` before cleaning root clutter, generated assets, archived zips, or legacy docs.
- Use `make review-preflight` before reviewing or taking over a broad change set.
