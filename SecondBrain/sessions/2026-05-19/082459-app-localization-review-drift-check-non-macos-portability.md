# app-localization-review-drift-check-non-macos-portability

## Prompt

> "start next slice" — execute the supervisor-selected slice `app-localization-review-drift-check-non-macos-portability`.

## What was done

Tooling slice. Replaced the silent empty-set fallback in `Tools/localization-review-drift-check.py.parse_stringsdict_keys` with a try-plistlib-first / fall-back-to-plutil / raise-on-both-fail pattern.

### Source change

`Tools/localization-review-drift-check.py`:

- Imported `plistlib` (stdlib XML+binary plist parser) and `shutil`.
- Added `StringsdictParseError` exception class.
- Refactored `parse_stringsdict_keys` to call a new private `_load_plist` helper.
- `_load_plist` tries Python `plistlib.load(path)` first; on `plistlib.InvalidFileException` it falls back to `plutil -convert json` shellout; raises `StringsdictParseError` with diagnostic text (plistlib error + plutil exit code/stderr or PATH miss) if both fail.

### Scope deviation recorded honestly

The slice notes assumed plistlib could parse Owlory's `Localizable.stringsdict`. It cannot — Owlory's file uses the NeXTSTEP strings-dict syntax (`{ "key" = { ... }; }`), not XML or binary plist. `plistlib.load()` raises `InvalidFileException` on it. So the implementation reframed:

- Keep plutil reachable for Owlory's current format.
- Add plistlib as the first attempt so the tool transitions cleanly if `.stringsdict` is ever XML-converted, and so XML-format stringsdict in any subdirectory parses on non-macOS hosts.
- Replace the silent empty fallback with `StringsdictParseError` so a missing plutil on a non-macOS host surfaces explicitly instead of generating phantom "all keys missing" drift.

### Tests

`automation/tests/test_localization_review_drift_check.py`:

5 new tests added under `ParseStringsdictKeysTests`:

- `test_returns_empty_set_when_file_missing` — preserves the existing missing-file contract.
- `test_parses_xml_plist_via_plistlib_without_plutil` — writes a real XML plist via `plistlib.dump`, mocks `shutil.which` to None, asserts plistlib path succeeds without plutil.
- `test_raises_when_plistlib_fails_and_plutil_missing` — non-plist file + no plutil → `StringsdictParseError`.
- `test_falls_back_to_plutil_when_plistlib_rejects_format` — non-plist file + mocked plutil success → returns parsed keys.
- `test_raises_when_plutil_fails` — non-plist file + mocked plutil failure → `StringsdictParseError`.

Test count: 15 in the drift module (10 prior + 5 new). `make automation-check` now runs 86 tests (was 81); all green.

### Behavior summary

| Scenario | Before | After |
|---|---|---|
| XML or binary plist .stringsdict + any host | Required plutil; silent empty if missing | plistlib parses; no shellout needed |
| NeXTSTEP strings-dict + macOS with plutil | plutil parses (worked) | plistlib fails → plutil parses (works) |
| NeXTSTEP strings-dict + no plutil | Silent empty set → phantom drift | **Raises `StringsdictParseError`** with explicit message |
| Malformed .stringsdict + any host | Silent empty set → phantom drift | **Raises `StringsdictParseError`** with plistlib + plutil diagnostic |

## Validation

- `python3 automation/context/build_context.py --slice-id app-localization-review-drift-check-non-macos-portability` — ran.
- `python3 automation/supervisor/run_next.py --dry-run` — selected this slice pre-commit.
- `make architecture` — passed.
- `make localization-review-drift-check` — 0 drift across 18 locales (baseline unchanged).
- `make automation-check` — 86 tests passed (5 new).
- `make pyright` — 0 errors / 0 warnings.
- `git diff --check` — clean.

## Lane Boundary

`build-tested`. New parser path + tests. No CLI surface change, no report format change, no doc change (existing docs still describe the tool accurately; the only user-visible difference is an explicit error message instead of silent zero on parse failure, which already matched the docs' implicit promise of "reporting-only flag of drift").

## Residual Risk

- The tool is portable to XML/binary stringsdict on non-macOS but still requires macOS for the current Owlory strings-dict file. If a Linux contributor needs to run the tool, the next step is either converting the source `.stringsdict` to XML or wiring a NeXTSTEP-plist parser into the fallback chain.
- `make localization-review-drift-check` still depends on `plutil` being on PATH for the strings-dict-format file. No regression for the macOS baseline, but Linux CI would fail with `StringsdictParseError` rather than producing a misleading report.
- The new tests mock `subprocess.run` for the plutil fallback path; real plutil integration is verified implicitly via the live `make localization-review-drift-check` baseline run.

## Not Claimed

- The tool runs end-to-end on Linux (it doesn't; current file requires plutil).
- Owlory's `.stringsdict` is XML plist (it isn't).
- macOS dependency has been removed (it has been narrowed; explicit failure on non-macOS replaces silent broken behavior).

## Next slice

Per the supervisor, `app-localization-review-drift-check-stringsdict-coverage` (pri 60) is now the highest-priority eligible follow-up among the drift-check gap slices.
