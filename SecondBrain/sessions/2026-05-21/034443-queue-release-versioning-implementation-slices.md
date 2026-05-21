# Queue Release Versioning Implementation Slices

Date: 2026-05-21
Type: queue-only
Proof level: automation-tested

## Prompt

After discussing the long-term plan for Owlory's `CFBundleShortVersionString` / Xcode `MARKETING_VERSION`, the user asked to add implementation slices.

## Added Slices

- `release-versioning-policy-doc` at priority 76, with no dependencies.
- `release-marketing-version-provenance-gate` at priority 75, depending on `release-versioning-policy-doc`.
- `release-bump-version-policy-guard` at priority 74, depending on `release-versioning-policy-doc`.

## Boundary

- No app behavior changed.
- No `MARKETING_VERSION` or `CURRENT_PROJECT_VERSION` value changed.
- No release archive, TestFlight, App Store Connect, or MDM proof is claimed.
- The first selectable slice is documentation-only so the policy lands before automation encodes it.

## Rationale

Owlory already has release tooling for `MARKETING_VERSION`, `CURRENT_PROJECT_VERSION`, build provenance, release preflight, and rollback builds. The implementation gap is narrower:

- Make the long-term policy explicit in `docs/workflows/release.md`.
- Prove `MARKETING_VERSION` is committed at `HEAD` under the same release provenance discipline already applied to `CURRENT_PROJECT_VERSION`.
- Add focused tests and minimal guardrails around `Tools/bump-version.sh` so policy and tooling stay aligned.

## Validation

- `python3 -m json.tool automation/queue/slices.json` passed.
- `python3 -m json.tool automation/handoffs/20260521T074443Z-queue-release-versioning-implementation-slices.json` passed.
- `python3 automation/supervisor/run_next.py --dry-run` passed and selected `release-versioning-policy-doc`.
- `make architecture` passed.
- `make automation-check` passed with Pyright 0 errors / 0 warnings and 93 automation tests passing.
- `git diff --check` passed.
