# HIG Home Row Action Separation

## Metadata

- Date: 2026-04-24
- Local Time: 08:08:56 EDT
- Agent: Codex
- Status: done
- Slug: hig-home-row-action-separation

## User Prompt

```text
continue
```

## Interpretation

- What the user wants: Continue the HIG cleanup with the next narrow, concrete interaction fix.
- Scope: Home task rows, where edit/open behavior was still nested around other row controls.
- Assumptions: Fixing the row action contract is more important than chasing smaller polish items because nested actions create ambiguous behavior.

## Plan

- Step 1: Confirm the Home row still nests multiple actions in one interactive region.
- Step 2: Separate edit/open from complete, skip, and audio controls while preserving Home behavior.
- Step 3: Revalidate the Home domain and rebuild the app.

## Changes

- Modified: `docs/product/domains/home.md`
- Modified: `owlory_xcode/Owlory/Features/Home/HomeView.swift`
- Modified: `SecondBrain/INDEX.md`
- Created: `SecondBrain/sessions/2026-04-24/080856-hig-home-row-action-separation.md`

## Validation

- Commands run: `make test-domain DOMAIN=home`
- Commands run: `xcodebuild -project owlory_xcode/Owlory.xcodeproj -scheme Owlory -destination 'platform=iOS Simulator,name=iPhone 16,OS=26.3.1' -derivedDataPath /tmp/Owlory-home-row-contract-build CODE_SIGNING_ALLOWED=NO build`
- Commands run: `git diff --check`
- Results: Home validation and app build passed after separating the row actions.

## Outcome

- Summary: Home task rows no longer wrap complete/skip/audio controls inside a row-level edit button. The task title area now owns edit/open, while complete, skip, and audio remain separate controls.
- Behavior preserved: Users can still edit tasks, toggle completion, skip active tasks, and play task audio.
- Risk remaining: Deprecated `onChange(of:perform:)` warnings still exist in `TodayView.swift` and `TrainView.swift`; this slice did not change them.
- Follow-up: Continue HIG cleanup only if it stays similarly narrow and does not blur into the broader recovery diff.
