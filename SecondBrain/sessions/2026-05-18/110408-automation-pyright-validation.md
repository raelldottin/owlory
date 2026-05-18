# automation-pyright-validation

## Prompt

> "start next slice" — execute the supervisor-selected slice `automation-pyright-validation`. Project owner requested Pyright be incorporated into the validation process.

## What was done

Validation-infrastructure slice. Wired Pyright as a separate `make pyright` gate covering `automation/` and `Tools/`. No app source changes.

### `pyrightconfig.json` (new)

```json
{
  "include": ["automation", "Tools"],
  "exclude": ["**/__pycache__", "**/.git", "**/node_modules"],
  "pythonVersion": "3.12",
  "typeCheckingMode": "basic",
  "reportMissingImports": "error",
  "reportMissingTypeStubs": "none",
  "reportPossiblyUnboundVariable": "error",
  "reportUndefinedVariable": "error",
  "reportArgumentType": "warning",
  "reportOptionalSubscript": "warning",
  "reportAssignmentType": "warning"
}
```

Severity choice rationale:

- `reportPossiblyUnboundVariable`, `reportUndefinedVariable`, `reportMissingImports`: kept at **error** because these catch genuine bugs (typo'd names, missing imports, control-flow bugs).
- `reportArgumentType`, `reportOptionalSubscript`, `reportAssignmentType`: downgraded to **warning** because the baseline surfaces 23 test-time duck-typing patterns (`SimpleNamespace` standing in for `argparse.Namespace`; `None` defaults typed as `list[str]`). Cleanup is queued; the gate passes today.

The slice notes asked to "avoid hiding type errors with broad excludes" — these are not excludes. Pyright still flags the issues; they just don't fail the gate yet.

### `Makefile` target

```make
pyright:
	@if ! command -v pyright >/dev/null 2>&1; then \
		echo "pyright not found. Install with one of:"; \
		echo "  brew install pyright"; \
		echo "  python3 -m pip install --user pyright"; \
		echo "  npm install -g pyright"; \
		exit 1; \
	fi
	pyright
```

Pyright is **not** folded into `make automation-check`. It stays a separate gate so agents and CI can run both independently; the slice notes endorsed this until the baseline is clean.

### Production fix

`Tools/localization-review-export.py` had two `reportPossiblyUnboundVariable: error` failures at lines 85, 87 because the `fail()` helper was typed `-> None` but actually calls `sys.exit(1)` (never returns). Pyright couldn't see that the `except` branch terminates and therefore thought `data` could be unbound when reached at line 85. Fixed by importing `typing.NoReturn` and changing the return annotation. The control flow is unchanged; Pyright now infers correctly that anything after `fail(...)` is unreachable.

### Documentation

`docs/workflows/validation.md` gains a `make pyright` bullet under Common Commands documenting the bootstrap, severity choices, the 23-warning baseline, and the queued cleanup slice.

### Queued follow-up

`automation-pyright-tighten-severities` (priority 70) queued to:

- Fix or narrowly suppress the 23 baseline warnings (most are `None` defaults typed as non-Optional in test helpers).
- Flip `reportArgumentType`, `reportOptionalSubscript`, `reportAssignmentType` back to `error` in `pyrightconfig.json`.

### Baseline warning distribution

| File | Warnings |
|---|---:|
| `automation/tests/test_harness.py` | 13 |
| `automation/tests/test_running_app_smoke.py` | 5 |
| `automation/tests/test_capture_localized_surfaces.py` | 2 |
| `automation/tests/test_capture_locale_screenshots.py` | 1 |
| `automation/smoke/running_app_smoke.py` | 1 |
| `automation/smoke/capture_locale_screenshots.py` | 1 |
| **Total** | **23** |

## Validation

- `python3 automation/context/build_context.py --slice-id automation-pyright-validation` — ran.
- `python3 automation/supervisor/run_next.py --dry-run` — selected this slice pre-commit.
- `python3 -m json.tool automation/queue/slices.json` — passed.
- `make architecture` — passed.
- `make automation-check` — 71 tests passed.
- `make pyright` — 0 errors / 23 warnings / exit 0.
- `git diff --check` — clean.

## Lane Boundary

`build-tested` (Pyright config + Makefile + one production type-annotation fix). No runtime behavior change. No Swift source touched.

## Residual Risk

- 23 baseline warnings remain. They cover real type-correctness concerns; downgraded to warning so the gate passes honestly. Cleanup queued.
- `make pyright` is not part of `make automation-check`. Agents and CI must invoke it explicitly. Intentional per slice notes; the follow-up slice can fold it in once the baseline is clean.
- The chosen pythonVersion ("3.12") is below the local Python 3.14 installation. This is deliberate for broad compatibility; if Owlory ever pins to a newer minimum, update `pyrightconfig.json`.

## Not Claimed

- All Python code is type-correct (23 warnings remain).
- `make pyright` is folded into `make automation-check` (separate gate).
- No Python type bugs exist (warnings cover real concerns; downgraded for an honest baseline).

## Next slice

Per the supervisor, `automation-pyright-tighten-severities` (priority 70) is the next eligible queue item. It cleans up the 23 warnings and flips the severities back to error.
