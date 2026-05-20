# app-error-message-fix-designsystem-accessibility

## Prompt

> "start next slice" - execute the supervisor-selected DesignSystem accessibility error-label slice.

## Decision

Removed raw diagnostic interpolation from the spoken audio playback and voice capture error labels. The localized accessibility labels now name the failed action and give a retry action instead of reading an implementation error string aloud.

Also made `VoiceCaptureButton` retry from `.error` through the same permission/start path as `.idle`; otherwise the new "Double-tap to try again" label would have promised an action the control did not perform.

## What changed

- `AudioPlaybackButton` now returns `audio.playback.accessibility.error` directly for `.error` instead of formatting `%@`.
- `VoiceCaptureButton` now returns `voice.capture.accessibility.error` directly for `.error` instead of formatting `%@`.
- `VoiceCaptureButton.handleTap()` treats `.idle` and `.error` the same for retry.
- Updated both accessibility error keys across all 19 `Localizable.strings` files.
- Updated all 18 non-English review returns for the two changed source rows, marking them `needs-layout-check` / automated draft pending native/fluent acceptance.

## Validation

- `python3 automation/context/build_context.py --slice-id app-error-message-fix-designsystem-accessibility` - passed.
- `python3 automation/supervisor/run_next.py --dry-run` - passed pre-implementation; selected this slice.
- `make architecture` - passed.
- `make localization-check` - passed (19 locales, 386 keys, 13 plural keys).
- `make automation-check` - passed (pyright 0 errors / 0 warnings; review drift 0; 93 automation tests).
- `git diff --check` - passed.
- `xcodebuild build -project owlory_xcode/Owlory.xcodeproj -scheme Owlory -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -derivedDataPath /tmp/owlory-designsystem-accessibility-build` - passed; one unrelated pre-existing `TodayView` `onChange` deprecation warning remains.

## Not Claimed

- Native/fluent acceptance for the two updated accessibility error rows.
- Running-app VoiceOver smoke proof.
- Changes to historical review packet/export artifacts.
- Changes to audio service diagnostic payloads.

## Next

Supervisor next eligible slice should be `app-design-vision-metaphor-adr`.
