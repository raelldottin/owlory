# app-localization-protocol-schedule-projection

## Summary

Localized Home protocol schedule/status display text without changing schedule behavior. `ProtocolScheduleRules` now returns semantic schedule summaries, and Home presentation code owns row/help text formatting backed by `Localizable.strings`.

## What Changed

- Removed English display text from `ProtocolScheduleRules.Summary` and `ProtocolScheduleRules.ScheduleSummary`.
- Routed Home protocol row labels and schedule help text through a Home presentation formatter.
- Added Home protocol schedule/status localization keys to all 19 locale resources.
- Updated Home and localization docs to record that protocol schedule projection is presentation-owned.
- Updated Home store and domain tests to assert semantic schedule summaries instead of English strings.

## Validation

- `python3 automation/context/build_context.py --slice-id app-localization-protocol-schedule-projection`
- `python3 automation/supervisor/run_next.py --dry-run`
- `make architecture`
- `make localization-check`
- `./Tools/validate.sh localization`
- `make test-domain DOMAIN=home`
- `make automation-check`
- `xcodebuild build -quiet -project owlory_xcode/Owlory.xcodeproj -scheme Owlory -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/owlory-protocol-schedule-localization-build CODE_SIGNING_ALLOWED=NO`
- `git diff --check`

The unsigned simulator build passed with the pre-existing `TodayView.onChange` deprecation warning unrelated to this slice.

## Residual Risk

- Non-English Home protocol schedule values remain English placeholders.
- Notification copy, Today projection copy, recurrence display-name adapters, and translation quality remain deferred.
- No running-app locale smoke, screenshot, device, or TestFlight proof was captured.

## Next Slice

Recommended: `app-localization-notification-copy`.
