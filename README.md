# Owlory

Owlory is a private, Apple-native, local-first life command center for continuity across Today, Train, Write, Career, Home, Patterns, Reminders, Voice Transcription, and App Runtime.

This repository is organized as an agent-first execution environment. Product rules, ownership, validation commands, release/rollback steps, and handoff expectations should live in versioned docs or executable tooling instead of chat memory.

## Download

- App Store: [Owlory on the App Store](https://apps.apple.com/us/app/owlory/id6761827402)
- TestFlight beta: [Owlory Beta Test Link](https://testflight.apple.com/join/RWDqdzVA)

## Start Here

1. Read [AGENTS.md](AGENTS.md) for the short operating contract.
2. Read [docs/README.md](docs/README.md) for progressive-disclosure docs.
3. Run `make handoff` to see current Git state, recent work logs, and validation shortcuts.
4. Use [docs/product/domain-index.md](docs/product/domain-index.md) to find the owner before editing.
5. Use [docs/product/overview.md](docs/product/overview.md) when you need the cross-domain product posture or experience principles.

## Repo Shape

- `automation/` - queue-driven agent supervisor, prompt fragments, schemas, examples, and tests.
- `owlory_xcode/` - Xcode project, app source, widgets, and tests.
- `owlory_xcode/Owlory/Core/Domain/` - pure product rules.
- `owlory_xcode/Owlory/Core/Application/` - stores, orchestration, telemetry, reminders, and runtime services.
- `owlory_xcode/Owlory/Core/Persistence/` - repository and storage adapters.
- `owlory_xcode/Owlory/Core/Infrastructure/` - Apple framework adapters.
- `owlory_xcode/Owlory/Features/` - SwiftUI feature screens.
- `Tools/` - validation, architecture, release, provenance, and handoff scripts.
- `docs/` - architecture, product, runtime, workflow, and decision docs.
- `SecondBrain/` - prompt and change log for durable handoff continuity.

See [docs/repo-map.md](docs/repo-map.md) for a compact cold-start map.

## Common Commands

```bash
make handoff
make architecture
make automation-check
make test-domain DOMAIN=today
make fast
make verify
make build-provenance
```

Use [docs/workflows/validation.md](docs/workflows/validation.md) to choose the narrowest honest validation path.
Use [automation/README.md](automation/README.md) for the supervised slice-chaining harness.

## Product Contract

Owlory protects local-first continuity:

- unfinished work should not silently disappear
- product rules should be named, pure, and testable where possible
- application/runtime code may orchestrate rules but should not hide durable policy
- UI should render state and invoke stores rather than owning cross-domain decisions
- release/TestFlight identity must remain traceable to Xcode build metadata and Git commit

Cross-domain product posture and experience principles live in [docs/product/overview.md](docs/product/overview.md).

## Agent Contract

For every prompt:

1. Create or update a `SecondBrain` entry.
2. Inspect the smallest relevant docs/code/tests.
3. Make the smallest safe change.
4. Run targeted validation first.
5. Report exact checks and remaining risk.

If a repeated failure mode appears, improve the harness with a doc, script, lint, or test instead of leaving another chat-only warning.
