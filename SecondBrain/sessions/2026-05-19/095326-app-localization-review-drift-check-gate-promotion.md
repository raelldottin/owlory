# app-localization-review-drift-check-gate-promotion

## Prompt

> "start next slice" — execute the supervisor-selected slice `app-localization-review-drift-check-gate-promotion`.

## What was done

Gate-promotion slice. Folded `python3 Tools/localization-review-drift-check.py --check` into the `make automation-check` recipe so any drift between source strings and per-locale review return files now fails the gate. Pre-promotion confirmation: `--check` exits 0 against current main.

### Makefile

```make
automation-check: pyright
	python3 Tools/localization-review-drift-check.py --check
	python3 -m unittest discover -s automation/tests -p 'test_*.py'
```

Order matters: `make`'s dependency resolution runs `pyright` first (via the `pyright` dep), then the recipe runs the drift check, then the unittest discover. First failure short-circuits — broken localization invariants must be resolved before Python tests run.

The standalone `make localization-review-drift-check` target (reporting-only, no `--check`) is preserved unchanged for ad-hoc inspection.

### `docs/workflows/validation.md`

| Bullet | Change |
|---|---|
| `make automation-check` | Now describes the 3-step sequence (pyright → drift-check `--check` → unittest discover) |
| `make localization-review-drift-check` | Added explicit note: **"`make automation-check` invokes the tool with `--check` so drift now fails the gate."** |

## Pre-promotion confirmation

```
$ python3 Tools/localization-review-drift-check.py --check
localization-review-drift-check: 377 strings keys + 13 stringsdict keys (42 plural tuples) in source
  locales inspected: 18; locales with drift: 0; total drift count: 0
  result: no drift
$ echo $?
0
```

`--check` exits 0 against the current main. Promotion is safe; the gate flips from "must run separately" to "blocks `make automation-check` if drift" without flipping the current baseline state.

## Validation

- `python3 automation/context/build_context.py --slice-id app-localization-review-drift-check-gate-promotion` — ran.
- `python3 automation/supervisor/run_next.py --dry-run` — selected this slice pre-commit.
- `make architecture` — passed.
- `make localization-check` — 19 / 377 / 13.
- `make automation-check` — passed (drift check "no drift" + 93 unittests OK).
- `make pyright` — 0 errors / 0 warnings.
- `git diff --check` — clean.

## Lane Boundary

`build-tested`. Makefile + docs. No tool, no source, no test, no proof-artifact change.

## Residual Risk

- A future source-string addition that lands without paired native-review intake will fail `make automation-check` everywhere until the review entry catches up. That's the intended gate semantics; the residual is a friction cost on contributors who add English copy. Document the expectation in `localization-translation-quality.md` if this becomes a regular issue.
- A contributor's branch sitting on stale return files (source-string changes merged in but review behind) will see this gate fail locally even when main is green. That's also intended — surfaces drift early.
- The drift gate intentionally does not track `NSStringFormatSpecTypeKey` / `NSStringFormatValueTypeKey` metadata changes; that integrity concern is separate (would need a different check).

## Not Claimed

- `make automation-check` covers UI regression (`make ui-regression DOMAIN=localization` remains separate).
- The drift gate covers stringsdict format-specifier integrity.
- `make localization-review-drift-check` (reporting-only target) is the gate — it isn't; only `--check` inside `automation-check` fails on drift.

## Closing the drift-check ladder

With this slice landed, the four originally-named drift-check follow-up slices are all complete:

| Slice | Status |
|---|---|
| `app-localization-review-drift-check` | done |
| `app-localization-review-drift-check-stringsdict-coverage` | done |
| `app-localization-review-drift-check-non-macos-portability` | done |
| `app-localization-review-drift-check-gate-promotion` | **done** (this slice) |

Plus one superseded:

| Slice | Status |
|---|---|
| `app-localization-nextstep-plist-parser` | deferred-superseded by `app-localization-stringsdict-xml-conversion` |

## Next slice

Supervisor's choice. Several lower-priority candidates remain queued (`app-localization-voiceover-verification` pri 64, `app-localization-smaller-width-accessibility-regression` pri 65, `app-reminders-cancel-pending-on-item-completion` pri 90, plus the two blocked `device-verified`/`testflight-verified` proof slices). Under Owlory's convention (lower priority number = picked first), the next pick is unlikely to be the highest-numbered slice; the reminders bug fix is queued at pri 90 and would be picked last unless renumbered.
