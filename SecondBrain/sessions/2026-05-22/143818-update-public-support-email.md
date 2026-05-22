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

## Outcome

Public page source files now use `raell.dottin+support@gmail.com` for support and privacy contact. Deployment pending push and GitHub Pages workflow completion.
