# app-store-public-support-privacy-pages

## Prompt

User asked for two public static pages for App Store submission:

- `/support`
- `/privacy`

The pages must be plain, lightweight, accessible, mobile-friendly, public-safe, and free of analytics, tracking scripts, cookies, third-party embeds, and external fonts. The pages must include Owlory, Raell Dottin as developer, placeholder support contact email if no official address exists, local-first privacy language, optional microphone/speech-recognition wording, and the final App Store Connect URLs.

## Interpretation

This is a static public-page and App Store metadata slice, closest to the App Runtime/release metadata boundary rather than domain product-rule code. No official support email was found in the repo, so the pages use `support@example.com` as an explicit placeholder.

## Supervisor Slice

Added and used `app-store-public-support-privacy-pages` in `automation/queue/slices.json`.

Required pre-coding harness commands:

```bash
python3 automation/context/build_context.py --slice-id app-store-public-support-privacy-pages
python3 automation/supervisor/run_next.py --dry-run
```

Both commands selected the intended slice and confirmed the allowed paths.

## Files Edited

- `.github/workflows/pages.yml`
- `docs/.nojekyll`
- `docs/README.md`
- `docs/app-store-connect-urls.md`
- `docs/support/index.html`
- `docs/privacy/index.html`
- `automation/queue/slices.json`
- `SecondBrain/INDEX.md`
- `SecondBrain/sessions/2026-05-22/141407-app-store-public-support-privacy-pages.md`
- `automation/handoffs/20260522T181508Z-app-store-public-support-privacy-pages.json`

## Implementation Notes

- The GitHub Pages workflow builds a temporary `_site` directory and copies only `docs/support/index.html`, `docs/privacy/index.html`, and `.nojekyll` into the Pages artifact. It intentionally does not publish the rest of the internal docs tree.
- Both HTML pages use semantic elements, viewport metadata, skip links, system fonts only, local CSS only, and no scripts.
- The privacy page states that Owlory is a local-first personal planning, reflection, writing capture, training, and home routine app; it does not require account sign-in; app data is stored locally; microphone and speech recognition are optional for voice note capture/transcription; Owlory does not sell personal data; and Owlory does not use third-party advertising.

## App Store Connect URLs

- Support URL: `https://raelldottin.github.io/owlory/support`
- Privacy Policy URL: `https://raelldottin.github.io/owlory/privacy`

## Validation

- `python3 automation/context/build_context.py --slice-id app-store-public-support-privacy-pages` - passed.
- `python3 automation/supervisor/run_next.py --dry-run` - passed; selected `app-store-public-support-privacy-pages`.
- `python3 -m json.tool automation/queue/slices.json` - passed.
- Static page parser/link/resource check - passed; no scripts or disallowed remote resources, semantic basics present, relative links resolve.
- `python3 -m http.server 8087 --directory docs` with local `curl` checks - passed; `/support/` and `/privacy/` returned `200 text/html`, and `/support` plus `/privacy` returned directory-index redirects.
- `make architecture` - passed.
- `git diff --check` - passed.

## Outcome

Created the public static pages and deployment workflow. The App Store Connect values to paste are:

- Support URL: `https://raelldottin.github.io/owlory/support`
- Privacy Policy URL: `https://raelldottin.github.io/owlory/privacy`

Residual risks:

- GitHub Pages still needs the `Deploy public App Store pages` workflow to run from `main` with repository Pages source set to GitHub Actions.
- `support@example.com` is intentionally a placeholder until an official Owlory support or privacy email is assigned.
