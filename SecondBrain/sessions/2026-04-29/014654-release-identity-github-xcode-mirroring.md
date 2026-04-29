# Release Identity GitHub Xcode Mirroring

- Date: 2026-04-29
- Prompt summary: codify that Owlory should maintain professional version control with GitHub history and Xcode version/build metadata mirroring each other.

## Interpretation

- Treat this as a maintained runtime/release contract update, not an app feature slice.
- Make the GitHub/Xcode mirroring rule explicit in the owning docs because the repo already has build-provenance tooling and runtime stamping.

## Files Touched

- `docs/product/domains/app-runtime.md`
- `docs/workflows/release.md`
- `docs/runtime/observability.md`
- `SecondBrain/INDEX.md`

## Changes

- Added an explicit app-runtime rule that GitHub history and Xcode build metadata are two views of one release identity.
- Clarified in the release workflow that professional releases should come from committed, pushed GitHub history rather than local-only Xcode edits or dirty archives.
- Added an observability note that shipped Xcode version/build metadata should map cleanly back to committed GitHub source and vice versa.

## Validation

- `make architecture`
- `git diff --check -- docs/product/domains/app-runtime.md docs/workflows/release.md docs/runtime/observability.md SecondBrain/sessions/2026-04-29/014654-release-identity-github-xcode-mirroring.md SecondBrain/INDEX.md`

## Outcome

- Maintained docs now state the intended release posture: GitHub and Xcode should mirror one shared Owlory release identity.
