# update-public-support-email

## Prompt

User asked to change the public support email from `support@example.com` to `raell.dottin+support@gmail.com`.

## Actions

- Updated `docs/support/index.html` mailto link and visible email.
- Updated `docs/privacy/index.html` privacy contact mailto link and visible email.
- Removed user-facing placeholder wording from both public pages.

## Validation

- `rg -n "support@example\\.com|raell\\.dottin\\+support@gmail\\.com" docs/support/index.html docs/privacy/index.html` - passed; public page sources contain only the new address.
- Static support email parser check - passed; no scripts or remote resources, semantic basics present, and each page has one `mailto:raell.dottin+support@gmail.com` link.
- `git diff --check` - passed.
- `make architecture` - passed.
- Pushed commit `4272f26d96ee494ba65ad05209ca9895b81d5c09`.
- GitHub Pages workflow run `26305560699` completed successfully: `https://github.com/raelldottin/owlory/actions/runs/26305560699`.
- Live checks passed:
  - `https://raelldottin.github.io/owlory/support/?v=4272f26` returned `200` and contained `raell.dottin+support@gmail.com`.
  - `https://raelldottin.github.io/owlory/privacy/?v=4272f26` returned `200` and contained `raell.dottin+support@gmail.com`.

## Outcome

Public page source files and live GitHub Pages output now use `raell.dottin+support@gmail.com` for support and privacy contact.
