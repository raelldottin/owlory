# app-localization-notification-copy

## Summary

Localized delivered local notification titles and bodies in the reminder application layer without changing reminder timing, suppression, dedupe, Home schedule rules, or Today projection behavior.

## What Changed

- Added `ReminderNotificationCopy` beside `ReminderScheduler` as the runtime-owned notification copy helper.
- Routed prediction reminders, Today prompt notifications as scheduled, and protocol schedule notifications through localized notification copy.
- Added notification title/body keys to all 19 locale resources.
- Added reminder tests for prediction copy, prompt/protocol copy, and scheduled notification specs using runtime-owned copy.
- Updated Reminders and localization docs to record notification-copy ownership.

## Validation

- `python3 automation/context/build_context.py --slice-id app-localization-notification-copy`
- `python3 automation/supervisor/run_next.py --dry-run`
- `make architecture`
- `make localization-check`
- `./Tools/validate.sh localization`
- `make test-domain DOMAIN=reminders`
- `make test-domain DOMAIN=home`
- `make automation-check`
- `xcodebuild build -quiet -project owlory_xcode/Owlory.xcodeproj -scheme Owlory -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/owlory-notification-localization-build CODE_SIGNING_ALLOWED=NO`
- `git diff --check`

The first reminder-domain run caught a Swift `map` closure compile issue after adding local variables; the slice fixed it with explicit returns and reran reminder validation successfully. The unsigned simulator build passed with the pre-existing `TodayView.onChange` deprecation warning unrelated to this slice.

## Residual Risk

- Non-English notification values remain English placeholders.
- No running-app locale smoke, delivered-notification simulator proof, device notification proof, or TestFlight proof was captured.
- Notification preference UI, broader display-name adapters, and translation quality remain deferred.

## Next Slice

Recommended: `app-localization-display-name-adapters`.
