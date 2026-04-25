# 0001: Agent-Legible Repository

## Status

Accepted

## Context

Owlory is being built by coding agents and humans together. The repository needs to teach agents how to find ownership, preserve product rules, and verify changes without relying on chat history.

## Decision

- Keep root `AGENTS.md` short and map-like.
- Put durable knowledge in root `docs/`.
- Treat product domains as ownership units even before physical Swift modules exist.
- Enforce dependency direction mechanically with scripts.
- Prefer pure domain rules and targeted tests for recurrence, carry-forward, digest, readiness, reminders, and continuation behavior.

## Consequences

- New guidance should go into the docs tree, not into `AGENTS.md`.
- Architecture linting becomes part of the normal workflow.
- Large module moves are deferred until the documented boundaries are stable.
