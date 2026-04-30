# owlory-running-app-smoke build blocker

## Prompt

Run the supervised `owlory-running-app-smoke` proof slice and prove or block honestly.

## Interpretation

- This is proof infrastructure, not product behavior work.
- Do not fix Home protocol scheduling code inside the smoke slice.
- Claim `running-app-smoke` only if build, install, launch, and screenshot all succeed.

## Result

- Project exists: `owlory_xcode/Owlory.xcodeproj`.
- Scheme exists: `Owlory`.
- Runnable app target exists: `Owlory`.
- Bundle ID resolved: `com.raelldottin.owlory`.
- Simulator resolved and booted: `iPhone 16`, runtime `com.apple.CoreSimulator.SimRuntime.iOS-26-3`, UDID `93831D66-8855-467D-8991-81886B30A57F`.
- Smoke failed at `build-app`.
- `running-app-smoke` proof was not reached.

## Blocker

`xcodebuild build` fails because Home protocol scheduling work is partially present:

- `HomeView.swift` references `ProtocolScheduleRules`.
- `ProtocolScheduleRules.swift` exists in the worktree but is not yet part of a completed, buildable slice.
- `HomeStore.updateProtocol` now requires a `schedule` argument, while at least one call path still uses the old signature.

## Validation

- `python3 automation/context/build_context.py --slice-id owlory-running-app-smoke`
- `python3 automation/smoke/running_app_smoke.py --output /tmp/owlory-running-app-smoke-rerun.json` failed at build stage
- `make architecture`
- `make automation-check`
- `git diff --check`

## Outcome

- Added a failed handoff for the current smoke rerun.
- Marked `owlory-running-app-smoke` as failed in the queue until the build blocker is completed or cleared.
- Recommended `home-protocol-schedule-windows` as the next blocker-clearing slice because it already owns the dirty source files.
