# owlory-running-app-smoke

## Prompt

Add a running-app smoke proof runner that can build, install, launch, and screenshot Owlory on a simulator, while failing closed when the current Xcode project does not satisfy a runnable app contract.

## Interpretation

- This is proof infrastructure, not a product behavior slice.
- The runner must distinguish "blocked before app proof" from "running-app-smoke reached".
- The app source and Xcode project should remain unchanged.

## Plan

1. Register the supervisor slice and dry-run scope.
2. Inspect automation harness patterns and Xcode validation helpers.
3. Add a small smoke runner with deterministic blocked/pass result JSON.
4. Add automation tests for runnable-contract checks, blocked output, and command planning.
5. Update validation docs and handoff evidence.

## Validation

- `python3 automation/context/build_context.py --slice-id owlory-running-app-smoke`
- `python3 automation/supervisor/run_next.py --dry-run`
- `python3 -m py_compile automation/smoke/running_app_smoke.py automation/tests/test_running_app_smoke.py`
- `python3 -m unittest automation.tests.test_running_app_smoke`
- `python3 automation/smoke/running_app_smoke.py --output /tmp/owlory-running-app-smoke-result.json`
- `make architecture`
- `make automation-check`
- `git diff --check`

## Outcome

- Added `automation/smoke/running_app_smoke.py`.
- The runner checks the Xcode project, scheme, runnable app target, bundle identifier, app bundle path, and simulator destination before building.
- Passing smoke builds, installs, launches, and captures a non-empty screenshot artifact.
- Blocked and failed results use JSON fields that avoid claiming `running-app-smoke` when the app contract is unavailable or the screenshot path fails.
- Real smoke result: `status=passed`, `proof_level=running-app-smoke`, simulator `iPhone 16`, bundle ID `com.raelldottin.owlory`, screenshot `/tmp/owlory-running-app-smoke/artifacts/20260430T131805Z/owlory-running-app-smoke.png`.
- Preserved the queued proof-infrastructure follow-ups captured in `091605-proof-infrastructure-queue.md`.
- Out-of-scope Home protocol scheduling edits were present and left unstaged: `HomeStore.swift`, `DomainModels.swift`, `ProtocolScheduleRules.swift`, `HomeView.swift`, `HomeStoreTests.swift`, and `ProtocolScheduleRulesTests.swift`.
