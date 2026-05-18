# app-localization-native-review-formal-workflow

## Prompt

The user provided a second Karoline screenshot showing Owlory Build Info and said it was TestFlight proof of app version info. They asked for formal native language review steps instead of the current ad hoc process.

## Interpretation

Formalize the native-language review protocol in the maintained localization workflow. Treat Karoline's Build Info screenshot as build-info-observed provenance for version `0.2.0`, build `20260517151819`, and commit `f6325f3c28e9e9263eebbe76a3bbba777ff6e615`, but do not claim full TestFlight language-review proof because the screenshot binary and full proof bundle are not committed.

## Context

Verified locally:

- `f6325f3c28e9e9263eebbe76a3bbba777ff6e615` exists.
- The commit is `Bump TestFlight build number`.
- The committed Xcode project at that commit reports `MARKETING_VERSION = 0.2.0` and `CURRENT_PROJECT_VERSION = 20260517151819`.

The current `HEAD` is `155e065b802c88608b85ca00731f21a76faffbe4`, with later commits recording German review/proof artifacts.

## Results

Implemented.

- Added a formal native-language review protocol to `docs/workflows/localization-translation-quality.md`.
- Added `localization/review/native-review-intake-template.md`.
- Updated docs map wording to mention formal native-review intake.
- Updated the German screenshot proof README and manifest with the observed TestFlight Build Info fields and the `build-info-observed` classification.
- Added and completed supervisor slice `app-localization-native-review-formal-workflow`.

The new protocol requires baseline commit/build capture, Build Info gate, reviewer packet, device surface pass, structured signoff, proof artifact preservation, validation, and explicit proof-claim boundaries before marking a locale native-reviewed.

## Validation

Passed:

- `python3 automation/context/build_context.py --slice-id app-localization-native-review-formal-workflow`
- `python3 automation/supervisor/run_next.py --dry-run`
- `make architecture`
- `make localization-check`
- `python3 Tools/localization-review-status.py`
- `make automation-check`
- `git diff --check`

Additional checks passed:

- `python3 -m json.tool automation/queue/slices.json`
- `python3 -m json.tool automation/proofs/app-localization-german-device-screenshot-proof/manifest.json`
- `python3 -m json.tool automation/handoffs/20260518T021206Z-app-localization-native-review-formal-workflow.json`
- Handoff schema validation for `automation/handoffs/20260518T021206Z-app-localization-native-review-formal-workflow.json`
