# app-error-message-fix-patternstore-visibility

## Prompt

> "start next slice" - execute the supervisor-selected PatternStore error visibility slice.

## Decision

Chose option (c): remove `PatternStore.lastError` as dead UI state and keep PatternStore failures diagnostic-only.

Rationale:

- `PatternStore.refresh()` runs from app appearance and foreground lifecycle, not direct user intent.
- Pattern snapshots and weekly digests are optional insight surfaces.
- An alert would be noisy because it could fire while the app refreshes itself.
- An inline digest-list row would not help when there is no latest digest and the list is not reachable from Today.
- The existing `lastError` was not read by any view, so it made the failure look handled when it was not.

## What changed

`PatternStore.swift`:

- Removed `lastError` from Combine and non-Combine declarations.
- Removed success-path `lastError = nil`.
- Replaced `Failed to compute patterns: ...` assignment with `PerformanceTelemetry.notice("PatternStore refresh failed: ...", category: .patterns)`.
- Replaced `Failed to generate digest: ...` assignment with `PerformanceTelemetry.notice("PatternStore digest generation failed: ...", category: .patterns)`.

No user-visible copy was introduced, so no `Localizable.strings` or review return file updates were needed.

## Validation

- `python3 automation/context/build_context.py --slice-id app-error-message-fix-patternstore-visibility` - passed.
- `python3 automation/supervisor/run_next.py --dry-run` - passed pre-implementation; selected this slice.
- `make architecture` - passed.
- `make localization-check` - passed (19 locales, 386 keys, 13 plural keys).
- `make automation-check` - passed (pyright 0 errors / 0 warnings; localization drift 0; 93 tests).
- `git diff --check` - passed.
- `xcodebuild build -project owlory_xcode/Owlory.xcodeproj -scheme Owlory -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -derivedDataPath /tmp/owlory-patternstore-build` - passed.

## Not Claimed

- Localized user-facing PatternStore error copy.
- Running-app smoke proof.
- A retry affordance for digest generation.
- Changes to PatternEngine or WeeklyDigestRules behavior.

## Next

Supervisor next eligible slice should be `app-error-message-fix-designsystem-accessibility`.
