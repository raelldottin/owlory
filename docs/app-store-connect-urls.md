# App Store Connect Public URLs

Owlory uses two lightweight static pages for App Store Connect review metadata:

- Support URL: `https://raelldottin.github.io/owlory/support`
- Privacy Policy URL: `https://raelldottin.github.io/owlory/privacy`

The source files are:

- `docs/support/index.html`
- `docs/privacy/index.html`

The GitHub Pages workflow in `.github/workflows/pages.yml` publishes only those two public page directories. It does not publish the rest of the repository docs tree.

If Pages is not already configured for this repository, set the repository Pages source to GitHub Actions, then run the `Deploy public App Store pages` workflow from `main`.
