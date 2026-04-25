# Owlory

Owlory is a private, Apple-native life command center focused on continuity across:

- Today
- Train
- Write
- Career
- Home

This repository starts intentionally small.
It incorporates lessons learned from building Gymphant:

- explicit product and state contracts
- local-first persistence
- smallest safe change discipline
- deterministic testing hooks
- small-screen-safe SwiftUI structure
- honest validation and real-device follow-through

## Current contents

- `../AGENTS.md` — root operating contract for agents
- `../docs/README.md` — active progressive docs map
- `../docs/workflows/legacy-xcode-docs.md` — classification for historical docs that still live under `Docs/`
- `Package.swift` — lightweight core package for early testing
- `Owlory.xcodeproj/` — starter Xcode project
- `Owlory/` — app source
- `OwloryCoreTests/` — regression tests around daily state, carry-forward rules, and writing-stage progression

## Starter architecture

- `App/` equivalent lives at the root of `Owlory/` for now
- `Features/Today/`
- `Features/Train/`
- `Features/Write/`
- `Features/Career/`
- `Features/Home/`
- `Core/Domain/`
- `Core/Application/`
- `Core/Infrastructure/`
- `Core/Persistence/`
- `DesignSystem/`

## Initial product contract

The app must clearly distinguish:

- no daily entry exists yet
- daily entry exists but setup is incomplete
- active daily entry for today
- reflection completed for today
- historical review of a prior day

Unfinished work should not silently disappear. Carry-forward decisions must be explicit.

## What this revision adds

- a `TodayEntryRepository` boundary
- a file-backed default repository for the app target
- an in-memory repository for tests
- pure carry-forward rules
- explicit `WritingStageRules` for stage progression
- a `FixedClock` for deterministic testing
- regression tests for carry-forward, store seeding behavior, and writing-stage transitions
- an Xcode test target scaffolded into the project for core-domain regression work

## Suggested next steps

1. Open `Owlory.xcodeproj` in Xcode.
2. Open `Package.swift` in Xcode or run `swift test` on a Mac with Apple toolchains.
3. Expand Today entry editing without introducing duplicate sources of truth.
4. Add write-stage and persistence tests before broadening feature behavior.
5. Keep new behavior behind explicit contracts instead of UI side effects.

## Notes

This is still an early scaffold, not a finished production app.
The goal is to establish the same good habits earlier than they appeared in the prior Gymphant project, without importing its complexity.
