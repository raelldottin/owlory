# Release Versioning Policy Doc

Date: 2026-05-21
Type: documentation
Proof level: doc-only + automation-tested

## Prompt

Start the next supervisor-selected slice after adding release-versioning implementation slices.

Selected slice: `release-versioning-policy-doc`

## Changed

- Added `docs/workflows/release.md#app-version-policy`.
- Defined `MARKETING_VERSION` / `CFBundleShortVersionString` as the intentional user-visible release version.
- Defined `CURRENT_PROJECT_VERSION` / `CFBundleVersion` as the per-build identity.
- Documented pre-1.0 and post-1.0 bump rules.
- Documented that ordinary implementation, localization, HIG, automation, and documentation slices must not bump `MARKETING_VERSION`.
- Documented UTC timestamp build-number policy, TestFlight rollback behavior, App Store production issue behavior, tag/changelog expectations, and enterprise traceability across Build Info, GitHub, App Store Connect/TestFlight, MDM rollout notes, and support tickets.
- Updated `docs/product/domains/app-runtime.md` to point at the policy and name the remaining `MARKETING_VERSION` committed-HEAD enforcement gap.
- Marked `release-versioning-policy-doc` done in the queue.

## Boundary

- No app code changed.
- No release scripts changed.
- No `MARKETING_VERSION` or `CURRENT_PROJECT_VERSION` values changed.
- No release archive, TestFlight, App Store Connect, or MDM proof is claimed.

## External References

- Apple `CFBundleShortVersionString` documentation.
- Apple `CFBundleVersion` documentation.
- App Store Connect Upload builds documentation.
- App Store Connect Create a new version documentation.

## Validation

- `git fetch origin main && git pull --rebase origin main` passed.
- `python3 automation/context/build_context.py --slice-id release-versioning-policy-doc` passed.
- `python3 automation/supervisor/run_next.py --dry-run` passed before edits and selected `release-versioning-policy-doc`.
- `python3 -m json.tool automation/queue/slices.json` passed.
- `make architecture` passed.
- `make automation-check` passed with Pyright 0 errors / 0 warnings and 93 automation tests passing.
- `git diff --check` passed.

## Next

Recommended next slice: `release-marketing-version-provenance-gate`.

Reason: the policy now defines `MARKETING_VERSION` as committed release identity, satisfying the next slice entry condition.
