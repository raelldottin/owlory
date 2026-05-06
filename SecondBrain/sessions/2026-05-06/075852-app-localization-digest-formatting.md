# app-localization-digest-formatting

## Summary

Localized weekly digest presentation counts and date labels without changing digest product rules. The Today feature now formats digest counts, ratios, compact streaks, relative week labels, and week ranges through a presentation helper backed by `Localizable.strings` and `Localizable.stringsdict`.

## What Changed

- Added `WeeklyDigestPresentationFormatting` in the Today feature layer.
- Routed `TodayView`, `DigestListView`, and `DigestDetailView` away from inline English digest count/date formatting.
- Added digest static-format keys and plural keys to all 19 locale resources.
- Updated localization workflow docs to record that weekly digest count/date labels are implemented while digest insights/highlights remain deferred.

## Validation

- `python3 automation/context/build_context.py --slice-id app-localization-digest-formatting`
- `python3 automation/supervisor/run_next.py --dry-run`
- `make architecture`
- `make localization-check`
- `./Tools/validate.sh localization`
- `make test-domain DOMAIN=today`
- `make automation-check`
- `xcodebuild build -quiet -project owlory_xcode/Owlory.xcodeproj -scheme Owlory -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/owlory-digest-formatting-build CODE_SIGNING_ALLOWED=NO`
- `git diff --check`

`make test-domain DOMAIN=today` first caught an invalid `Date.FormatStyle` calendar modifier. The slice fixed that by using an explicit `DateFormatter` with the digest calendar/time zone, then reran the Today domain validation successfully.

## Residual Risk

- Non-English values remain English placeholders.
- Digest insight/highlight summaries and domain display names are still deferred dynamic localization work.
- No running-app locale smoke, screenshot, device, or TestFlight proof was captured.

## Next Slice

Recommended: `app-localization-protocol-schedule-projection`.
