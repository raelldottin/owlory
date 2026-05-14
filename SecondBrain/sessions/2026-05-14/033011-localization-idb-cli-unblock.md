# localization-idb-cli-unblock

## Summary

Fixed the current idb blocker for localization screenshot proof. `idb_companion` was already present at `/opt/homebrew/bin/idb_companion`; the missing `idb` CLI was installed with `uv tool install fb-idb`, placing the executable at `/Users/raelldottin/.local/bin/idb`.

## What Changed

- Environment: installed the `fb-idb` CLI outside the repo.
- Repo: fixed the screenshot harness command shape to match the installed idb client. This client accepts `--udid` on subcommands, not as a global option.
- Added tests for subcommand-specific UDID placement.

## Validation

- `which idb`
- `which idb_companion`
- `idb --help`
- `idb list-targets`
- `idb describe --udid E6FA3288-2C0E-4CD0-9B6A-441D92B0DCC0 --json`
- `idb ui describe-all --udid E6FA3288-2C0E-4CD0-9B6A-441D92B0DCC0 --json`
- `idb screenshot --udid E6FA3288-2C0E-4CD0-9B6A-441D92B0DCC0 /tmp/owlory-idb-screenshot.png`
- `make localization-screenshot-idb-check`
- `python3 -m py_compile automation/smoke/capture_locale_screenshots.py`
- `python3 -m unittest automation.tests.test_capture_locale_screenshots`
- `make automation-check`
- `make architecture`
- `git diff --check`

## Result

`make localization-screenshot-idb-check` now reports `status: "ready"` with:

- `idb`: `/Users/raelldottin/.local/bin/idb`
- `idb_companion`: `/opt/homebrew/bin/idb_companion`

Because the dependency blocker is resolved, `app-localization-all-locale-screenshot-proof` is queued as the next supervisor-eligible slice.

## Remaining Risk

Full all-locale screenshot proof has not been captured in this prompt. The next proof slice still needs to run the capture helper against an explicit simulator UDID and preserve one settled launch screenshot per supported locale.
