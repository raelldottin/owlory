# automation-pyright-tighten-severities

## Prompt

> "start next slice" - continue the supervisor-selected Pyright cleanup slice after the previous agent fixed two smoke helper signatures and hit the usage limit.

## What changed

Finished the Pyright cleanup follow-up from `automation-pyright-validation`.

- `pyrightconfig.json` now treats `reportArgumentType`, `reportOptionalSubscript`, and `reportAssignmentType` as errors again.
- `Makefile` now makes `automation-check` depend on `pyright`, so the normal automation validation chain type-checks before running Python automation tests.
- `automation/smoke/capture_locale_screenshots.py` and `automation/smoke/running_app_smoke.py` type optional injected runners as `CommandRunner | None`.
- `automation/tests/test_capture_locale_screenshots.py` and `automation/tests/test_capture_localized_surfaces.py` now use real `argparse.Namespace` fixtures instead of `SimpleNamespace` for argparse API tests.
- `automation/tests/test_running_app_smoke.py` types fake-runner optional constructor inputs honestly and narrows the optional simulator lookup before subscripting.
- `automation/tests/test_harness.py` adds narrow assertion helpers for optional queue lookups so tests keep fixture failure messages while Pyright sees non-optional records.

No broad ignores, excludes, or `typeCheckingMode` changes were introduced.

## Validation

- `make pyright` - passed, 0 errors / 0 warnings.
- `make automation-check` - passed; runs Pyright first, then 71 automation tests.
- `make architecture` - passed.
- `python3 -m json.tool automation/queue/slices.json` - passed.
- `automation/handoffs/20260518T112109Z-automation-pyright-tighten-severities.json` - schema-valid.
- `python3 automation/context/build_context.py --slice-id automation-pyright-tighten-severities` - passed.
- `python3 automation/supervisor/run_next.py --dry-run` - stop: no eligible queued slice found.
- `git diff --check` - passed.

## Lane Boundary

`build-tested` tooling cleanup. No Swift source touched and no runtime behavior changes intended.

## Residual Risk

`make pyright` remains available as a narrow standalone target for quick type-checking, but `make automation-check` now runs it by default.
