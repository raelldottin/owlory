# app-localization-all-locale-smoke

## Summary

Ran the running-app smoke proof for all 19 supported Owlory locales and preserved JSON proof artifacts under `automation/proofs/app-localization-all-locale-smoke/`.

## What Changed

- Preserved one clean-source smoke JSON per supported locale.
- Added a proof README and manifest with SHA-256 hashes.
- Marked `app-localization-all-locale-smoke` done in the queue.
- Updated localization status docs to say all-locale launch/resource smoke is implemented, while reviewed translations and translation quality remain incomplete.

## Proof

All 19 locales passed with `proof_level: running-app-smoke` and `repo.dirty: no`:

```text
en ar nl fr de it ja ko nb pt pt-BR ru es sv zh-Hans zh-Hant tr uk vi
```

Each result found both packaged resources in the built app bundle:

```text
Localizable.strings
Localizable.stringsdict
```

## Validation

- `python3 automation/context/build_context.py --slice-id app-localization-all-locale-smoke`
- `python3 automation/supervisor/run_next.py --dry-run`
- `python3 automation/smoke/running_app_smoke.py --locale <locale> --output /tmp/...` for all 19 locales
- JSON proof verification for status, proof level, clean repo status, locale match, and packaged resources
- `make architecture`
- `make localization-check`
- `./Tools/validate.sh localization`
- `make automation-check`
- `git diff --check`

## Remaining Risk

- Non-English values remain English placeholders unless reviewed and ingested.
- Translation quality remains blocked until reviewed translated values exist with reviewer/status metadata.
- The optional all-locale screenshot proof remains blocked until explicitly requested.
- Device and TestFlight localization proof remain separate lanes.
