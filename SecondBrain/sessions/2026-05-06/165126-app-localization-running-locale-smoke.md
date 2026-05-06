# app-localization-running-locale-smoke

## Summary

Extended the running-app smoke runner so localization can be proven at launch time for representative locales without claiming translation quality.

## Changed

- Added `--locale` and `--apple-locale` to `automation/smoke/running_app_smoke.py`.
- The runner now passes `-AppleLanguages` and `-AppleLocale` launch arguments when a locale is requested.
- The runner now checks the built `.app` bundle for requested locale resources before install.
- Locale screenshots include the locale in the filename.
- Added automation tests for locale launch arguments, resource checks, and missing-resource failure.
- Documented the locale smoke workflow in automation and validation docs.

## Runtime Proof

- `en` passed running-app smoke: `/tmp/owlory-locale-smoke-en.json`.
- `es` passed running-app smoke: `/tmp/owlory-locale-smoke-es.json`.
- `fr` passed running-app smoke: `/tmp/owlory-locale-smoke-fr.json`.
- `ar` passed running-app smoke: `/tmp/owlory-locale-smoke-ar.json`.
- `zh-Hans` passed running-app smoke: `/tmp/owlory-locale-smoke-zh-Hans.json`.

Temporary screenshots:

- `/tmp/owlory-running-app-smoke/artifacts/20260506T204827Z/owlory-running-app-smoke-en.png`
- `/tmp/owlory-running-app-smoke/artifacts/20260506T204942Z/owlory-running-app-smoke-es.png`
- `/tmp/owlory-running-app-smoke/artifacts/20260506T204954Z/owlory-running-app-smoke-fr.png`
- `/tmp/owlory-running-app-smoke/artifacts/20260506T205012Z/owlory-running-app-smoke-ar.png`
- `/tmp/owlory-running-app-smoke/artifacts/20260506T205027Z/owlory-running-app-smoke-zh-Hans.png`

## Validation

- `python3 automation/context/build_context.py --slice-id app-localization-running-locale-smoke` passed.
- `python3 automation/supervisor/run_next.py --dry-run` passed.
- `make architecture` passed.
- `make localization-check` passed.
- `./Tools/validate.sh localization` passed.
- `make automation-check` passed.
- All five locale smoke commands passed.
- Unsigned simulator build passed.
- `git diff --check` passed.

## Residual Risk

- This proves locale resource loading and launch stability, not translation quality.
- Screenshots are temporary artifacts, not repo-managed screenshot proof.
- Smoke JSON reports `repo.dirty = yes` because proof ran before the final metadata commit.
- Device, TestFlight, delivered-notification, and native-speaker review remain unproven.

## Next

Recommended: `app-localization-locale-screenshot-proof` if reviewable locale screenshots should be preserved.
