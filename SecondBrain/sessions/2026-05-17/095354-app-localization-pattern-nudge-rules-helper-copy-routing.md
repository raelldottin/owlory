# app-localization-pattern-nudge-rules-helper-copy-routing

## Prompt

Continue the supervisor-selected localization slice after a prior run hit its usage limit. The selected slice is `app-localization-pattern-nudge-rules-helper-copy-routing`; the intended checklist is to refactor `PatternNudgeRules.DomainNudge`, route Today formatting through localized copy, update tests, validate, commit, and push.

## Interpretation

Route the Pattern domain nudge away from domain-owned English copy. `Core/Domain/PatternNudgeRules` should keep semantic domain data only; `Features/Today/TodayView` should format the visible message with `String(localized:)` and the existing `LifeDomain.localizedDisplayName`.

## Context

Inspected `docs/README.md`, `docs/repo-map.md`, `docs/product/domain-index.md`, `docs/product/domains/patterns.md`, `docs/architecture/boundaries.md`, `docs/workflows/validation.md`, `docs/workflows/agent-handoff.md`, `docs/workflows/localization-dynamic-formatting.md`, and `docs/workflows/localization-helper-generated-copy-audit.md`.

Ran `make handoff`, `python3 automation/context/build_context.py --slice-id app-localization-pattern-nudge-rules-helper-copy-routing`, and `python3 automation/supervisor/run_next.py --dry-run`. The supervisor selected the expected slice and allowed paths.

## Plan

1. Remove the English `message` field from `PatternNudgeRules.DomainNudge`.
2. Add Today-localized domain nudge formatting with one format-string key across supported locales.
3. Update pattern/calibration tests to assert semantic domain values instead of English copy.
4. Run the slice validations, write handoff JSON, update queue metadata, commit, push, and verify a clean status.

## Files

Intentionally inspected:

- `automation/queue/slices.json`
- `owlory_xcode/Owlory/Core/Domain/PatternNudgeRules.swift`
- `owlory_xcode/Owlory/Features/Today/TodayView.swift`
- `owlory_xcode/OwloryCoreTests/PatternNudgeRulesTests.swift`
- `owlory_xcode/OwloryCoreTests/CalibrationRulesTests.swift`
- `owlory_xcode/Owlory/Resources/*/Localizable.strings`

## Results

Implemented.

- `PatternNudgeRules.DomainNudge` now carries only `LifeDomain`; `message` and the private English `focusBalanceTitle(for:)` helper were removed.
- `TodayView` now formats domain nudges through `today.domainNudge.focusMissing` and `LifeDomain.localizedDisplayName`.
- Added `today.domainNudge.focusMissing` to all 19 supported `Localizable.strings` files. Non-English values are LLM-drafted, not native-reviewed.
- Updated `PatternNudgeRulesTests` and `CalibrationRulesTests` to assert semantic domain values instead of English message copy.
- Preserved the inherited queue cleanup that removed unsupported completion metadata from the prior `app-localization-focus-suggestion-reason-routing` entry.

Validation passed:

- `make architecture`
- `make localization-check`
- `./Tools/validate.sh localization`
- `make automation-check`
- `make test-domain DOMAIN=patterns`
- `xcodebuild build -quiet -project owlory_xcode/Owlory.xcodeproj -scheme Owlory -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/owlory-helper-followup-build CODE_SIGNING_ALLOWED=NO`
- `git diff --check`

Residual risk: no running-app smoke, screenshot proof, device proof, TestFlight proof, or native translation review was performed for the new key.
