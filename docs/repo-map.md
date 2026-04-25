# Repo Map

Use this when entering Owlory cold or after context compaction. Load only the next document needed for the task.

## What This Repo Is

Owlory is an Apple-native, local-first life command center with Today, Train, Write, Career, Home, Patterns, Reminders, Voice Transcription, and App Runtime areas. The repository is the system of record for product rules, boundaries, validation workflows, and release/rollback operations.

## First Five Minutes

1. Read `AGENTS.md`.
2. Read `docs/README.md`.
3. Run `make handoff` to see current Git identity, dirty workspace state, recent SecondBrain entries, and validation commands.
4. Use `docs/product/domain-index.md` to find the owner for the requested change.
5. Read the owner doc plus `docs/architecture/boundaries.md`, then inspect only nearby code and tests.
6. Read `docs/product/overview.md` only when the task depends on cross-domain product posture or experience principles.

## Root Files

- `AGENTS.md` - short operating map for agents.
- `README.md` - project entrypoint for humans and agents.
- `Makefile` - stable command surface.
- `automation/` - queue-driven agent supervisor, prompts, schemas, examples, and tests.
- `Tools/` - architecture, validation, release, provenance, and handoff scripts.
- `docs/` - progressive-disclosure docs.
- `SecondBrain/` - prompt and change log for handoff continuity.
- `owlory_xcode/` - Xcode project, app source, widgets, and tests.

## Code Areas

- `owlory_xcode/Owlory/Core/Domain/` - pure product rules and deterministic policies.
- `owlory_xcode/Owlory/Core/Application/` - stores, use-case orchestration, telemetry, scheduling, and runtime planners.
- `owlory_xcode/Owlory/Core/Persistence/` - repository protocols and storage adapters.
- `owlory_xcode/Owlory/Core/Infrastructure/` - Apple framework adapters such as speech and audio capture.
- `owlory_xcode/Owlory/Features/` - SwiftUI feature screens.
- `owlory_xcode/Owlory/DesignSystem/` - reusable visual primitives.
- `owlory_xcode/OwloryWidgets/` - widgets and Live Activity presentation.
- `owlory_xcode/OwloryCoreTests/` - focused Xcode unit tests by domain.

## Stable Command Surface

- `make handoff` - print current repo state for a resuming agent.
- `make drift-report` - classify root clutter and legacy docs before cleanup.
- `make clean-system-metadata` - remove only obvious OS metadata files.
- `make verify-app-icons` - prove the shipped app-icon catalog and classify generated icon archives/folders.
- `make review-preflight` - infer touched areas, docs, validation, and risks for a dirty change set.
- `make architecture` - structural guardrails.
- `make automation-check` - focused Python tests for the automation harness.
- `make test-domain DOMAIN=<name>` - focused domain validation.
- `make fast` - common agent loop.
- `make verify` - broader Xcode core test suite.
- `make build-provenance` - release/TestFlight identity check.

## Retrieval Rules

- Do not bulk-read all docs. Start from `docs/README.md`, then load one domain or workflow doc.
- Use `docs/product/overview.md` for cross-domain product posture or UX-principle questions; otherwise go straight to the owning domain doc.
- Use `automation/README.md` when the task is about queue-driven supervision, handoff artifacts, or fresh-run continuation policy.
- Treat root historical markdown through `docs/workflows/historical-docs.md` before moving or deleting it.
- Treat root duplicate test trees and project archives through `docs/workflows/archived-code-artifacts.md` before moving or deleting them.
- Treat `owlory_xcode/Docs/` through `docs/workflows/legacy-xcode-docs.md` before moving or deleting it.
- For ML, speech, or generated-output changes, read `docs/runtime/ml-model-posture.md`, `docs/runtime/ml-privacy.md`, and `docs/workflows/ml-qa.md` before implementation or review.
- For telemetry, MetricKit, signpost, profiling, or performance-claim changes, read `docs/runtime/observability.md` and `docs/workflows/performance-observability.md`.
- For open-slice selection or legacy roadmap cleanup, read `docs/workflows/roadmap-status.md`.
- Ignore root archives, icon zips, and generated assets unless the task is explicitly about assets.
- Prefer `rg` and `rg --files` for discovery.

## When You Are Stuck

- Run `make handoff` to reestablish repo state.
- Use `python3 automation/supervisor/run_next.py --dry-run` to inspect the next eligible queued slice without mutating the queue.
- Run `make drift-report` before touching root clutter, generated assets, archived project zips, or legacy docs.
- Run `make review-preflight` before reviewing or taking over a broad dirty change set.
- Search `SecondBrain/INDEX.md` for the most recent related slice.
- Read `docs/workflows/roadmap-status.md` when choosing the next best slice.
- Run the narrowest validation command before changing scope.
- If a repeated failure mode appears, improve the harness with a doc, script, lint, or focused test instead of leaving another chat-only warning.
