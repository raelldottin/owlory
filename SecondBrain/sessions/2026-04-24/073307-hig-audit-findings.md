# HIG Audit Findings

## Metadata

- Date: 2026-04-24
- Local Time: 07:33:07 EDT
- Agent: Codex
- Status: done
- Slug: hig-audit-findings

## User Prompt

```text
codebase is out of sync from Apple HIG
```

## Interpretation

- What the user wants: Audit the current UI/runtime surface against Apple Human Interface Guidelines and call out the highest-value mismatches.
- Scope: Main app navigation chrome, Write interactions, widget presentation, and alert patterns.
- Assumptions: This is an assessment slice, not a broad UI rewrite while the repo is still in selective-restore state.

## Plan

- Step 1: Inspect the main app surfaces that most directly express platform conventions.
- Step 2: Compare those surfaces to current Apple HIG guidance on widgets, buttons/touch targets, alerts, and toolbars.
- Step 3: Record the most actionable mismatches instead of making speculative broad claims.

## Changes

- Modified: `SecondBrain/INDEX.md`
- Created: `SecondBrain/sessions/2026-04-24/073307-hig-audit-findings.md`
- Inspected: `owlory_xcode/Owlory/RootTabView.swift`, `owlory_xcode/Owlory/OwloryApp.swift`, `owlory_xcode/Owlory/Features/Today/TodayView.swift`, `owlory_xcode/Owlory/Features/Write/WriteView.swift`, `owlory_xcode/Owlory/Features/Home/HomeView.swift`, `owlory_xcode/OwloryWidgets/OwloryTodayWidget.swift`

## Validation

- Commands run: `git status --short`
- Commands run: `rg -n "alert\\(\"Error\"|widgetURL\\(|Text\\(\"Owlory\"\\)|BuildInfo.current.summary" owlory_xcode/Owlory owlory_xcode/OwloryWidgets`
- Results: No code changes made for the audit; findings captured for follow-up slices.

## Outcome

- Summary: The codebase is not broadly noncompliant, but it has concrete HIG drift in widget presentation, generic error alerts, a nested-button interaction in Write, and debug metadata occupying primary toolbar space.
- Risk remaining: The repo is still in recovery-state and intentionally dirty, so these findings should become narrow follow-up slices rather than an opportunistic UI sweep.
- Follow-up: Tackle widget truthfulness/glanceability first, then the Write row interaction contract, then alert wording/toolbars.
