# HIG UI Alignment Fixes

## Metadata

- Date: 2026-04-24
- Local Time: 07:54:01 EDT
- Agent: Codex
- Status: done
- Slug: hig-ui-alignment-fixes

## User Prompt

```text
fix:
widget glanceability/truthfulness
Write row interaction contract
alert wording
build-info chrome
```

## Interpretation

- What the user wants: Implement the concrete HIG-alignment fixes identified in the prior audit instead of leaving them as findings.
- Scope: Widget presentation, Write row interaction behavior, alert titles across edited feature screens, and Today build-info chrome.
- Assumptions: The repo is still in selective-restore state, so the right move is a narrow UI/runtime cleanup, not broader product redesign.

## Plan

- Step 1: Make the widget foreground the represented reminder instead of redundant Owlory branding.
- Step 2: Remove the nested inline stage-advance button from Write rows and move advancement into secondary row actions.
- Step 3: Replace generic alert titles with feature-specific wording and move build info out of primary toolbar chrome.
- Step 4: Update owning docs and run the narrowest relevant validations plus a full Xcode build.

## Changes

- Modified: `docs/product/domains/app-runtime.md`
- Modified: `docs/product/domains/write.md`
- Modified: `owlory_xcode/Owlory/Features/Career/CareerView.swift`
- Modified: `owlory_xcode/Owlory/Features/Home/HomeView.swift`
- Modified: `owlory_xcode/Owlory/Features/Today/TodayView.swift`
- Modified: `owlory_xcode/Owlory/Features/Train/TrainView.swift`
- Modified: `owlory_xcode/Owlory/Features/Write/WriteView.swift`
- Modified: `owlory_xcode/OwloryWidgets/OwloryTodayWidget.swift`
- Modified: `SecondBrain/INDEX.md`
- Created: `SecondBrain/sessions/2026-04-24/075401-hig-ui-alignment-fixes.md`

## Validation

- Commands run: `make test-domain DOMAIN=write`
- Commands run: `make test-domain DOMAIN=runtime`
- Commands run: `xcodebuild -project owlory_xcode/Owlory.xcodeproj -scheme Owlory -destination 'platform=iOS Simulator,name=iPhone 16,OS=26.3.1' -derivedDataPath /tmp/Owlory-hig-fixes-build CODE_SIGNING_ALLOWED=NO build`
- Commands run: `git diff --check`
- Results: All validation commands passed. No `xcuserdata`, `.build`, or `.DS_Store` artifacts were reintroduced into the repo tree.

## Outcome

- Summary: The widget now foregrounds reminder content, Write rows have a single primary tap action, alerts use feature-specific titles, and build info moved out of raw top-bar chrome into a dedicated info affordance.
- Behavior preserved: Widget taps still route through the existing deep-link path, Write note advancement remains available through note detail and row actions, and build diagnostics remain available in `BuildInfoView`.
- Risk remaining: The repo is still intentionally dirty because the broader selective-recovery surface remains uncommitted.
- Follow-up: Classify and commit the recovery surface before stacking additional feature slices.
