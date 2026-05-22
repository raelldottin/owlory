# release-v1.0.0-marketing-version-bump

- Timestamp: 2026-05-22T09:05:42Z
- Scope: release/versioning
- Proof level: build-tested + fast-tested

## Summary

Bumped Owlory's marketing version from `0.2.0` to `1.0.0` using `./Tools/bump-version.sh major`. The release build number is `20260522090312`.

## Release State

- `MARKETING_VERSION`: `1.0.0`
- `CURRENT_PROJECT_VERSION`: `20260522090312`
- Changelog: promoted `[Unreleased]` into `## [1.0.0] - 2026-05-22`
- Tag target: `v1.0.0`

## Validation

- `./Tools/bump-version.sh major`
- `make build-provenance` before commit reported the expected dirty/not-yet-committed release state
- `python3 -m unittest automation.tests.test_bump_version`
- `make architecture`
- `make fast`
- `git diff --check`

## Notes

- Release preflight/check must run after the version bump is committed and pushed, because provenance gates require committed `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` to match `HEAD`.
