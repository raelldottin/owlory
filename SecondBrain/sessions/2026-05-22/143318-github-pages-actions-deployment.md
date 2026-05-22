# github-pages-actions-deployment

## Prompt

User changed the Owlory repository to public and asked to complete the GitHub Pages workflow run with Pages source set to GitHub Actions.

## Actions

- Verified `gh` authentication for `raelldottin` and confirmed `raelldottin/owlory` is public.
- Pushed commit `ffdc1af` (`Add App Store public support and privacy pages`) from local `main` to `origin/main`.
- GitHub Pages API initially returned `404`, meaning Pages was not initialized.
- Created the Pages site with `build_type=workflow`:

```bash
gh api --method POST repos/raelldottin/owlory/pages -f build_type=workflow
```

- Confirmed the workflow `Deploy public App Store pages` was active.
- Confirmed the push-triggered workflow run completed successfully:

```text
Run: 26305259247
URL: https://github.com/raelldottin/owlory/actions/runs/26305259247
Head SHA: ffdc1af948648ef15884611f64daae61465b1882
Conclusion: success
```

## Verification

GitHub Pages API returned:

```json
{"build_type":"workflow","html_url":"https://raelldottin.github.io/owlory/","public":true,"source":{"branch":"main","path":"/"},"status":null}
```

Live URL checks:

```text
support 200 text/html; charset=utf-8 https://raelldottin.github.io/owlory/support/
privacy 200 text/html; charset=utf-8 https://raelldottin.github.io/owlory/privacy/
```

## Outcome

GitHub Pages is configured to use GitHub Actions, the deployment workflow completed successfully, and both App Store Connect URLs are live:

- Support URL: `https://raelldottin.github.io/owlory/support`
- Privacy Policy URL: `https://raelldottin.github.io/owlory/privacy`
