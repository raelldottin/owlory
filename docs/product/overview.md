# Product Overview

Use this doc for cross-domain product posture and experience principles. Domain-specific contracts still live in the owning docs under `docs/product/domains/`.

## Product Posture

- Owlory is a private, Apple-native, local-first life command center for a single user who wants continuity across days.
- It unifies daily planning, training logging, writing progression, career evidence, and home maintenance in one coherent system instead of scattering those workflows across separate apps.
- It is not a social app, collaboration surface, or generic catch-all to-do list. Explicit state, low-friction execution, and thoughtful reflection matter more than breadth.

## Contract Status Markers

A product contract is not automatically an implementation claim. When a domain doc records a durable rule, mark its current delivery state when that status is not obvious from code and tests.

Use these markers:

- `Implemented` - behavior has live code paths and targeted validation.
- `Partially implemented` - part of the behavior exists, but important flows or destinations remain future work.
- `Contract only` - the doc records product intent or a design commitment, but the app should not claim the behavior is shipped.
- `Needs UI proof` - code may exist, but user-visible motion, layout, discoverability, or accessibility still needs screenshot, device, or usability evidence.
- `Needs automation enforcement` - the contract depends on process discipline today and should not be described as mechanically enforced yet.
- `Deferred` - the contract is intentionally not being implemented in the current slice; record the reason or trigger for revisiting it.

Current contract status lives in [Roadmap Status](../workflows/roadmap-status.md). Domain docs may also place a status block directly under major contract headings.

## Core Surfaces

- `Today` is the daily command center.
- `Train` tracks one training practice per day with readiness and reflection.
- `Write` is the low-friction thinking inbox and capture inbox for unfinished thought, including thoughts that may later become tasks, notes, or protocols.
- `Career` stores wins, impact, stories, and supporting metrics.
- `Home` manages recurring tasks, protocols, and protocol runs.
- `Patterns`, `Reminders`, `Voice Transcription`, and `App Runtime` support those primary surfaces and are documented separately in the maintained product/runtime docs.

## Experience Principles

- Serious, structured, and trustworthy.
- Calm, readable, and information-dense without clutter.
- Native to Apple platform conventions and Human Interface Guidelines.
- Local-first for correctness.
- Clear state ownership: each surface should answer what state the user is in.
- Explicit transitions: unfinished work should not silently disappear.
- Carry-forward honesty: when something shows up today, the user should be able to understand why.
- Capture first, classify later, if ever.
- Write should feel like catching a thought, not managing a note; any stage progression must stay lightweight and visible.
- Write should reduce the chance of losing thought, not ask the user to perform correctness.
- Write is allowed to receive todo-like thoughts because fast capture matters more than initial correctness; cleanup belongs in later promotion, not in capture gating.
- One training session per day remains the product posture unless the Train domain contract changes.
- Small-screen-safe, iPhone-first layouts stay the default.

## Visual Posture

- Brand emphasis uses restrained navy and royal blue.
- Backgrounds and reading surfaces use layered neutrals.
- Success uses muted green, warning/deferred states use muted amber, and destructive actions use system red.
- `owlory_xcode/Owlory/DesignSystem/AppTheme.swift` is the implementation source of truth for layout tokens and semantic color roles.
- See [Design System Tokens](../design-system.md) for resolved brand hex values and the full token inventory.

## Read Next

- Use [Domain Index](domain-index.md) to find the owning product area.
- Use [Today](domains/today.md), [Train](domains/train.md), [Write](domains/write.md), [Career](domains/career.md), and [Home](domains/home.md) for domain-specific contracts.
