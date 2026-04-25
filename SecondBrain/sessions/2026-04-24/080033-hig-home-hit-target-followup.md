# HIG Home Hit Target Follow-up

## Metadata

- Date: 2026-04-24
- Local Time: 08:00:33 EDT
- Agent: Codex
- Status: done
- Slug: hig-home-hit-target-followup

## User Prompt

```text
continue
```

## Interpretation

- What the user wants: Continue the HIG alignment work after the first batch of widget, Write, alert, and build-info fixes.
- Scope: Find the next safe, concrete UI issue rather than broadening into speculative redesign.
- Assumptions: The best follow-up is another interaction-contract fix with clear platform benefit and low product risk.

## Plan

- Step 1: Re-scan the edited surfaces for remaining obvious HIG/accessibility drift.
- Step 2: Fix the next narrow issue if it is safe and well-justified.
- Step 3: Validate with the owning domain tests and a full app build.

## Changes

- Modified: `docs/product/domains/home.md`
- Modified: `owlory_xcode/Owlory/Features/Home/HomeView.swift`
- Modified: `owlory_xcode/Owlory/Features/Write/WriteView.swift`
- Modified: `SecondBrain/INDEX.md`
- Created: `SecondBrain/sessions/2026-04-24/080033-hig-home-hit-target-followup.md`

## Validation

- Commands run: `make test-domain DOMAIN=home`
- Commands run: `xcodebuild -project owlory_xcode/Owlory.xcodeproj -scheme Owlory -destination 'platform=iOS Simulator,name=iPhone 16,OS=26.3.1' -derivedDataPath /tmp/Owlory-home-hit-target-build CODE_SIGNING_ALLOWED=NO build`
- Commands run: `git diff --check`
- Results: Home validation and rebuild passed. No `xcuserdata` was reintroduced into the repo tree.
- Failures and reruns: The first rebuild surfaced a new unused-variable warning in `WriteView.swift` from the prior HIG slice; replacing the optional binding with a boolean check removed that warning on the final build.

## Outcome

- Summary: Home task-row and protocol-step icon controls now reserve a 44x44 hit area, making complete/restore/skip actions safer on iPhone without changing Home-owned behavior.
- Behavior preserved: Task completion, restore, step completion, and skip semantics are unchanged.
- Risk remaining: Existing deprecated `onChange(of:perform:)` warnings remain in `TodayView.swift` and `TrainView.swift`; they predate this follow-up and were not changed here.
- Follow-up: Keep future HIG cleanup narrow and avoid mixing it with the still-uncommitted recovery surface.
