# App Localization Locale Screenshot Proof

## Scope

This proof preserves simulator screenshots for the already running-app-smoked locale launch set:

`en`, `es`, `fr`, `ar`, `zh-Hans`

It raises only the representative locale launch surface to `screenshot-verified`. It does not prove translation quality, full layout correctness, real-device behavior, TestFlight behavior, or native-speaker review.

## Evidence

| File | Locale | Proves | SHA-256 |
| --- | --- | --- | --- |
| `01-locale-en-launch.png` | `en` | English baseline locale launch surface rendered after app launch. | `70d7dcf890c2762b36718c4c086979d7c6046c1489dca0c21fee2a84a41559d2` |
| `02-locale-es-launch.png` | `es` | Spanish locale launch surface rendered after app launch. | `f84140bcede119da1f8c3776d2f47dfe8685fddcf8d13b026f16909690137fcc` |
| `03-locale-fr-launch.png` | `fr` | French locale launch surface rendered after app launch. | `ae4f254508264483ba7c6f47fa63e6a6a9158fbfb4c571be6ddc2cfcaec32612` |
| `04-locale-ar-launch.png` | `ar` | Arabic locale launch surface rendered after app launch with right-to-left locale launch arguments. | `4437481c2d389be6f5fe7c52b11513195cb91907e218e78f9f174341745c48ce` |
| `05-locale-zh-Hans-launch.png` | `zh-Hans` | Simplified Chinese locale launch surface rendered after app launch. | `b2680b3ead55e4a45cda06a2c8512df1a281d2da2a240839faa8386963877b8d` |

All screenshots are `1179 x 2556` pixels. Detailed metadata lives in `manifest.json`.

## Provenance

- Source slice: `app-localization-running-locale-smoke`.
- Source handoff: `automation/handoffs/20260506T204606Z-app-localization-running-locale-smoke.json`.
- Source smoke JSON paths:
  - `/tmp/owlory-locale-smoke-en.json`
  - `/tmp/owlory-locale-smoke-es.json`
  - `/tmp/owlory-locale-smoke-fr.json`
  - `/tmp/owlory-locale-smoke-ar.json`
  - `/tmp/owlory-locale-smoke-zh-Hans.json`
- Source app commit reported by smoke JSON: `775d876f861b`.
- Source smoke JSON files report `repo.dirty = yes` because the smoke run happened before the automation/doc handoff commit. The dirty paths were automation and documentation files, not app source or localization resources.
- The first smoke-run screenshots caught the white launch transition. These preserved screenshots were recaptured from the same installed simulator app after relaunching each locale and waiting for the Today surface to settle.

## What This Proves

- The app launched on simulator for the representative locale set.
- The first stable launch surface rendered without a blank screen or crash screenshot.
- The launch screenshots are now repo-managed and hashable for later review.

## What This Does Not Prove

- Translation quality. Non-English values may still be English placeholders.
- Full layout correctness, truncation behavior, or complete RTL/CJK review.
- Device behavior.
- TestFlight behavior.
- Delivered notification localization.

## Validation

```bash
python3 automation/context/build_context.py --slice-id app-localization-locale-screenshot-proof
python3 automation/supervisor/run_next.py --dry-run
make architecture
make localization-check
./Tools/validate.sh localization
make automation-check
git diff --check
git diff --cached --check
```
