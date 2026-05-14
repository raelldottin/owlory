# app-localization-all-locale-screenshot-proof

## Prompt

idb harness unblocked at `5fe752a`. Run the queued slice: capture 19 settled locale launch screenshots, preserve PNGs + README + manifest + hashes, claim `screenshot-verified` for the launch surface only.

## Files Edited

- `automation/proofs/app-localization-all-locale-screenshot-proof/` — 19 PNGs (one per locale) plus `README.md` and `manifest.json` written by the capture script.
- `automation/queue/slices.json` — slice flipped from `queued` to `done` with completion notes.
- `docs/workflows/localization-translation-quality.md` — all-locale screenshot proof entry changed from `blocked` to `implemented`.
- `docs/workflows/roadmap-status.md` — removed the screenshot proof slice from the parked list; updated the unblocker-chain entry for `localization-screenshot-proof-idb-harness` to record the captured artifact.
- `docs/workflows/validation.md` — documented `--allow-simctl-screenshot-fallback` and recorded the 2026-05-14 capture run.
- `automation/handoffs/20260514T074211Z-app-localization-all-locale-screenshot-proof.json`
- `SecondBrain/INDEX.md`
- `SecondBrain/sessions/2026-05-14/034211-app-localization-all-locale-screenshot-proof.md`

## Capture run

```text
python3 automation/smoke/capture_locale_screenshots.py \
  --udid E6FA3288-2C0E-4CD0-9B6A-441D92B0DCC0 \
  --allow-simctl-screenshot-fallback \
  --json
```

- Target: iPhone 17 simulator (UDID `E6FA3288-2C0E-4CD0-9B6A-441D92B0DCC0`), iOS 26.5.
- App: Owlory built in Debug from this checkout to `/tmp/owlory-locale-screenshot-derived-data`, installed via `xcrun simctl install`.
- Locales (19): `en ar nl fr de it ja ko nb pt pt-BR ru es sv zh-Hans zh-Hant tr uk vi`.
- For each locale: idb terminates Owlory, relaunches with `--owlory-ui-testing -AppleLanguages (<locale>) -AppleLocale <locale>`, waits 4s to settle, runs `idb ui describe-all`, dismisses any notification prompt via `idb ui tap`, asserts the `Today` launch-surface label is present (English placeholder is the rendered text for every locale because non-English locales remain placeholder until the review intake lands), then captures the screenshot.
- `idb screenshot` and `idb ui screenshot` were not available in the installed fb-idb client; the run used `xcrun simctl io <udid> screenshot` via the documented `--allow-simctl-screenshot-fallback`. idb still owned launch, UI describe, and prompt dismissal per the proof harness rule.
- Result: 19/19 captures passed, status `passed`, proof level `screenshot-verified`, timestamp `2026-05-14T07:40:04Z`.

## Validation

- `make architecture` — passed.
- `make localization-check` — passed (19 locales, 282 keys, 11 plural keys).
- `make automation-check` — 57 tests passed.
- `git diff --check` — clean.

## Lane Boundary

This is `screenshot-verified` (Lane 3) for the launch surface only. It is not running-app flow proof for non-Today surfaces, not device proof, not TestFlight proof. The screenshots show simulator pixels rendered at the captured commit; they do not validate translation quality or full layout correctness on every device family/Dynamic Type size.

## Residual Risk

- Non-English locales currently render English placeholder text because non-`en.lproj` Localizable.strings values are still copies of the English source. The screenshots prove launch settling at each locale; they do not prove visible localized strings beyond German values that have been reviewed.
- The `--allow-simctl-screenshot-fallback` path was needed because the installed `fb-idb` client lacks an `idb screenshot` subcommand. Future runs on a machine with a newer idb may drop the fallback flag.
- A re-run targeting the same proof directory will be blocked by the helper (it refuses to mingle fresh screenshots with stale evidence). Future re-runs must clean the output directory first.
- This proof does not claim Dynamic Type, RTL pseudolocalization, on-device renderer behavior, or production App Store builds. Those each remain separate lanes.
