# Architecture Overview

Owlory is currently a single Xcode app rooted at `owlory_xcode/` with a Swift package target over `Owlory/Core`. The repo is not yet split into physical feature modules, so boundaries are enforced by folder ownership, tests, and architecture linting.

## Current Code Shape

- `owlory_xcode/Owlory/Core/Domain/` owns pure product types and deterministic rules.
- `owlory_xcode/Owlory/Core/Application/` owns stores, orchestration, telemetry facades, reminders, and app-facing services.
- `owlory_xcode/Owlory/Core/Persistence/` owns repositories and durable storage adapters.
- `owlory_xcode/Owlory/Core/Infrastructure/` owns framework-backed adapters such as audio capture and speech transcription.
- `owlory_xcode/Owlory/Features/` owns SwiftUI screens for Today, Train, Write, Career, and Home.
- `owlory_xcode/Owlory/DesignSystem/` owns reusable UI primitives and theme tokens.
- `owlory_xcode/OwloryWidgets/` owns widget and Live Activity presentation.
- `Tools/` owns release, architecture, and validation scripts.

## State And Persistence Conventions

- Owlory is local-first for correctness. Durable state persists in Application Support through repository adapters, not cloud services.
- `OwloryApp` wires repositories and clocks explicitly into application-layer stores and runtime managers.
- Production code uses `SystemClock` plus file-backed repositories; focused tests use `FixedClock` plus in-memory repositories.
- Today uses date-addressed `TodayEntryRepository` and `TodayEntryRangeRepository` abstractions because daily entries are persisted per day.
- Collection-style domains use `ItemListRepository<T>` for list persistence.
- File repositories persist ISO-8601 JSON with pretty-printed, sorted-key encoding.
- `@MainActor` stores in `Core/Application` are the observable state owners; deterministic product policy stays in `Core/Domain`.

## Agent Entry Pattern

1. Run `make handoff` when repo state or prior context is unclear.
2. Use [../repo-map.md](../repo-map.md) for the cold-start path.
3. Identify the product domain in [../product/domain-index.md](../product/domain-index.md).
4. Read that domain doc and [boundaries.md](boundaries.md).
5. Inspect the owning source and nearby tests.
6. Keep product rules in `Core/Domain` when they are deterministic.
7. Keep UI work in `Features` and framework coupling in `Infrastructure` or runtime adapters.
8. Run targeted tests first, then `make architecture`.

## Current Structural Risk

The repo is small enough to move quickly, but several folders are broad:

- `Core/Application` mixes stores, workflow rules, telemetry, reminders, and runtime managers.
- `DomainModels.swift` owns many unrelated model families.
- `Features/Today/TodayView.swift` is an orchestration-heavy screen that touches every domain.
- Root-level generated assets and archived zip files make discovery noisy.

The first transformation phase adds maps, boundary checks, and pure-rule extraction before larger module moves.
