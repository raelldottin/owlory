# app-localization-readiness-rules-helper-copy-routing

## Prompt

Start the supervisor-selected `app-localization-readiness-rules-helper-copy-routing` slice after the Pattern nudge routing slice completed. Preserve readiness scoring and decisions, move helper-generated readiness nudge copy out of `Core/Domain`, update tests to assert semantic values, add localized keys across 19 locales, validate, commit, and push.

## Interpretation

`ReadinessRules` should return semantic nudge kind data plus `suggestedMaxPriorities`. `TodayView` should own visible readiness nudge formatting with localized keys. Tests should verify decision branches by semantic kind rather than English substrings.

## Context

Inspected `docs/README.md`, `docs/repo-map.md`, `docs/product/domain-index.md`, `docs/product/domains/today.md`, `docs/architecture/boundaries.md`, `docs/workflows/validation.md`, `docs/workflows/localization-dynamic-formatting.md`, `docs/workflows/localization-helper-generated-copy-audit.md`, and the supervisor context bundle.

Ran `make handoff`, `python3 automation/context/build_context.py --slice-id app-localization-readiness-rules-helper-copy-routing`, and `python3 automation/supervisor/run_next.py --dry-run`. The supervisor selected this slice from a clean mirrored checkout.

## Plan

1. Adjust stale slice metadata so the explicitly required test updates are in scope.
2. Refactor `ReadinessRules.Nudge` to expose semantic kind plus priority count only.
3. Route Today readiness nudge formatting through localized keys.
4. Add 9 readiness nudge keys across all supported locale resources.
5. Update readiness/calibration tests to assert semantic kind and priorities.
6. Run required validations plus the focused Today domain suite, write handoff JSON, commit, push, and verify clean/mirrored state.

## Files

Intentionally inspected:

- `automation/queue/slices.json`
- `owlory_xcode/Owlory/Core/Domain/ReadinessRules.swift`
- `owlory_xcode/Owlory/Features/Today/TodayView.swift`
- `owlory_xcode/OwloryCoreTests/ReadinessRulesTests.swift`
- `owlory_xcode/OwloryCoreTests/CalibrationRulesTests.swift`
- `owlory_xcode/Owlory/Resources/*/Localizable.strings`

## Results

Implemented.

- `ReadinessRules.Nudge` now carries semantic `Kind` plus `suggestedMaxPriorities`; the domain no longer returns English nudge sentences.
- `TodayView` maps each readiness kind to localized `today.readiness.nudge.*` keys.
- Added 9 readiness nudge keys across all 19 supported `Localizable.strings` files. Non-English values are LLM-drafted, not native-reviewed.
- Updated `ReadinessRulesTests` to assert all semantic branches, including the previously unasserted fallback `decentDay` branch.
- Updated `CalibrationRulesTests` to assert semantic readiness kind and priority behavior instead of English message substrings.
- Corrected the slice queue metadata to include the explicitly required readiness/calibration tests and realistic all-locale resource fan-out.

Validation passed:

- `make architecture`
- `make localization-check`
- `./Tools/validate.sh localization`
- `make automation-check`
- `make test-domain DOMAIN=today`
- `xcodebuild build -quiet -project owlory_xcode/Owlory.xcodeproj -scheme Owlory -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/owlory-helper-followup-build CODE_SIGNING_ALLOWED=NO`
- `git diff --check`

Build warning: existing `TodayView` `onChange(of:perform:)` iOS 17 deprecation warning remains.

Residual risk: no running-app smoke, screenshot proof, device proof, TestFlight proof, or native translation review was performed for the new keys. Train validation was not run because this slice does not touch Train code or Train-owned readiness presentation.
