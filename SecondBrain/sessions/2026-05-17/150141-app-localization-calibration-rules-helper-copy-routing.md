# app-localization-calibration-rules-helper-copy-routing

## Prompt

Start the supervisor-selected calibration helper-copy routing localization slice. Move `CalibrationRules` writing-pipeline and training-consistency visible copy out of `Core/Domain`, preserve readiness and pattern decisions, add all-locale localized keys, update semantic tests, validate, commit, and push.

## Interpretation

`CalibrationRules` should keep owning the product decisions that determine when a writing nudge or training summary exists, but it should return semantic values and structured data only. Train and Write presentation should format those values with localized resources.

## Context

Ran `make handoff` previously for this continuation context, then ran `python3 automation/context/build_context.py --slice-id app-localization-calibration-rules-helper-copy-routing` and `python3 automation/supervisor/run_next.py --dry-run`. The supervisor selected this slice from a clean checkout.

The initial queue metadata omitted the focused test files and used a 12-file cap even though the slice requires 19 locale files plus tests. Corrected that metadata before implementation and reran the supervisor dry-run.

## Plan

1. Refactor `CalibrationRules` writing/training helper outputs to semantic enums plus counts/rates only.
2. Add UI-adjacent formatting helpers in Train/Write and route visible copy through localized keys.
3. Add four localization keys across all 19 supported locale files.
4. Update calibration/training tests to assert semantic values instead of English substrings.
5. Run required validations plus focused Patterns/Train domain tests.
6. Write handoff JSON, commit, push, and verify clean/mirrored state.

## Files

Intentionally inspected:

- `automation/queue/slices.json`
- `owlory_xcode/Owlory/Core/Domain/CalibrationRules.swift`
- `owlory_xcode/Owlory/Features/Train/TrainView.swift`
- `owlory_xcode/Owlory/Features/Write/WriteView.swift`
- `owlory_xcode/Owlory/Features/Today/TodayView.swift`
- `owlory_xcode/OwloryCoreTests/CalibrationRulesTests.swift`
- `owlory_xcode/OwloryCoreTests/TrainingConsistencyTests.swift`
- `owlory_xcode/Owlory/Resources/*/Localizable.strings`

## Results

Implemented.

- `CalibrationRules.WritingPipelineNudge` now carries semantic `Kind.captureBacklog`, `captureCount`, and `bottleneckStage`; it no longer carries English presentation copy.
- `CalibrationRules.TrainingConsistencySummary` now carries semantic `Band` plus `completionRate` and `completionPercent`; existing thresholds are preserved.
- `TrainView` formats training consistency summaries with localized `train.calibration.consistencySummary.*` keys.
- `WriteView` formats writing pipeline nudges with localized `write.calibration.pipelineNudge.captureBacklog`.
- Added 4 calibration keys across all 19 supported `Localizable.strings` files. Non-English values are LLM-drafted, not native-reviewed.
- Updated `TrainingConsistencyTests` to assert semantic bands, counts, rates, and percentages instead of English substrings.
- Corrected the slice queue metadata to include focused tests and realistic all-locale resource fanout, then marked the slice done.

Validation passed:

- `make architecture`
- `make localization-check`
- `./Tools/validate.sh localization`
- `make automation-check`
- `make test-domain DOMAIN=train`
- `make test-domain DOMAIN=patterns`
- `make test-domain DOMAIN=write`
- `xcodebuild build -quiet -project owlory_xcode/Owlory.xcodeproj -scheme Owlory -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/owlory-helper-followup-build CODE_SIGNING_ALLOWED=NO`
- `git diff --check`

Build warning: existing `TodayView` `onChange(of:perform:)` iOS 17 deprecation warning remains.

Supervisor dry-run after marking the slice done reported `stop: no eligible queued slice found.`

Residual risk: no running-app smoke, screenshot proof, device proof, TestFlight proof, or native translation review was performed for the new keys.
