# automation-localization-iphone-se-simulator-provisioning

Prompt received 2026-05-20T08:53:44Z.

User asked to start the next slice.

Initial state:
- Repo clean and mirrored before work.
- Supervisor selected `automation-localization-iphone-se-simulator-provisioning`.
- Slice scope: tooling + Makefile + validation docs + queue/handoff only.

Implementation:
- Added `Tools/provision-localization-smallest-width-simulator.py`.
- Added Makefile targets:
  - `make provision-localization-smallest-width-simulator`
  - `make provision-localization-smallest-width-simulator-check`
- The helper selects the latest available compatible iOS runtime and preferred iPhone SE device type, creates a simulator named `iPhone SE` when missing, and reports the matching xcodebuild destination.
- Provisioned this host successfully:
  - simulator: `iPhone SE`
  - UDID: `71883D37-7354-449B-8BEF-BC590FF640B9`
  - runtime: `iOS 26.5`
  - device type: `iPhone SE (3rd generation)`
  - destination: `platform=iOS Simulator,name=iPhone SE,OS=26.5`
- Updated `app-localization-smallest-width-accessibility-regression` from `blocked` to `queued`.
- Updated validation and UI testing docs to reference the provisioning/check targets.

Non-claims:
- Did not add or run the future `DOMAIN=localization-smallest-width` XCUITest target.
- Did not change app UI or XCUITest behavior.

Validation:
- `python3 automation/context/build_context.py --slice-id automation-localization-iphone-se-simulator-provisioning` passed.
- `python3 automation/supervisor/run_next.py --dry-run` passed while this slice was selectable.
- `make architecture` passed.
- `make automation-check` passed.
- `make pyright` passed.
- `make provision-localization-smallest-width-simulator-check` passed.
- `git diff --check` passed.

Next:
- Supervisor should select `app-localization-smallest-width-accessibility-regression`.
