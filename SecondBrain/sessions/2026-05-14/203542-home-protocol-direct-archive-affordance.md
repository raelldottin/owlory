# home-protocol-direct-archive-affordance

## Prompt

Why did protocol archive disappear when the reported bug was about item-looking swipes inside protocols archiving the whole protocol?

## Assessment

The prior bug fix correctly removed the trailing Archive/Delete swipe from expanded protocol rows because that action belonged to the whole `DisclosureGroup` while visually reading like it might apply to a protocol step. However, keeping archive only inside the Edit Protocol sheet made whole-protocol archive too hidden.

## What Changed

- Restored direct protocol archive as an explicit archive icon in the active protocol header row.
- Kept step rows without archive actions.
- Kept whole-protocol archive/restore/delete management in the Edit Protocol sheet.
- Updated Home docs and roadmap notes to distinguish direct protocol-level archive buttons from forbidden trailing step-looking swipe actions.

## Validation

- `make architecture` — passed.
- `make test-domain DOMAIN=home` — TEST SUCCEEDED.
- `make automation-check` — 57 tests passed.
- `xcodebuild build -quiet -project owlory_xcode/Owlory.xcodeproj -scheme Owlory -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/owlory-home-protocol-direct-archive-build CODE_SIGNING_ALLOWED=NO` — BUILD SUCCEEDED. Existing TodayView `onChange(of:perform:)` deprecation warning remains unrelated.
- `git diff --check` — clean.

## Lane Boundary

This is a presentation affordance correction. It does not add per-step archive state and does not change protocol lifecycle, schedule, run, persistence, or archive rules.

## Residual Risk

Per-step archive remains a separate product/model decision because protocol template steps are plain strings.
