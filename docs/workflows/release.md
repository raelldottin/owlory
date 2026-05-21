# Release And Rollback Workflow

## Build Provenance Sources

- App version and TestFlight build number live in `owlory_xcode/Owlory.xcodeproj/project.pbxproj` as `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION`.
- `./Tools/bump-version.sh <major|minor|patch>` updates `MARKETING_VERSION`, stamps a new timestamp build number, and updates `CHANGELOG.md`.
- `./Tools/set-build-number.sh --auto` updates `CURRENT_PROJECT_VERSION` for rollback builds without changing the app version.
- Xcode `Stamp Build Info` phases run `./Tools/generate-build-info.sh` during app and widget builds so the bundle records Git commit, branch, tag/describe output, GitStatus, build date, configuration, and build-number source.
- `BuildInfo` reads the stamped bundle metadata at runtime. The Build Info sheet is the user-facing support breadcrumb for TestFlight diagnostics.

## App Version Policy

Apple exposes two related but separate bundle identities:

- `MARKETING_VERSION` becomes [`CFBundleShortVersionString`](https://developer.apple.com/documentation/bundleresources/information-property-list/cfbundleshortversionstring), the user-visible app version.
- `CURRENT_PROJECT_VERSION` becomes [`CFBundleVersion`](https://developer.apple.com/documentation/bundleresources/information-property-list/cfbundleversion), the build string for one concrete build iteration.

App Store Connect associates an uploaded build with an app and version record using the bundle ID and version number in the app bundle, then uses the build string to identify the concrete build.

Owlory treats `MARKETING_VERSION` as a SemVer-shaped public release version in the required `major.minor.patch` form. It is not a counter for every implementation slice. Change it only when preparing a release candidate, creating a new App Store Connect version record, or deliberately changing the external support identity for a distributed build.

While Owlory is pre-1.0, use this policy:

- `0.minor.0`: user-visible capability, workflow, domain, or data-model expansion that changes what testers need to understand.
- `0.minor.patch`: maintenance work inside the same release line, including bug fixes, copy/localization fixes, validation hardening, HIG/UI polish, or release-workflow corrections.
- `1.0.0`: first stable product release after the owner deliberately declares the release posture stable. Do not arrive at `1.0.0` through routine slice accumulation.

After 1.0, keep the same shape:

- `major`: product contract reset, large migration, or support-breaking change.
- `minor`: new user-facing capability or meaningful workflow expansion.
- `patch`: fix, polish, localization, validation, or release-infrastructure correction with no new public capability.

Ordinary implementation, localization, HIG, automation, and documentation slices must not bump `MARKETING_VERSION`. Those changes become part of the next intentional release version when a release slice runs `./Tools/bump-version.sh <major|minor|patch>`, reviews `CHANGELOG.md`, commits the release metadata, tags `vX.Y.Z`, and pushes the tag.

`CURRENT_PROJECT_VERSION` is the build identity. Owlory uses a UTC timestamp build number so each archive can be traced and sorted without needing a separate build counter. Bump it for every TestFlight/App Store archive candidate and every rollback candidate. Multiple builds can share one `MARKETING_VERSION`, but a distributed build number must never be reused for a different source state. Keep the numeric timestamp within App Store Connect's 18-character build-number limit.

Rollback policy:

- TestFlight rollback: check out the known-good source, run `./Tools/set-build-number.sh --auto`, commit and push the new build number, then run the release gates before archiving. Do not change `MARKETING_VERSION` unless the rollback is intentionally marketed as a new release version.
- App Store production issue: Apple does not provide a true "revert to prior version" path for a released version. Ship a new version/build from the appropriate source state and document it in the changelog.

Enterprise-style management treats this as a governance trail, not a local Xcode habit. A support or release reviewer should be able to start from any of these records and recover the rest:

- installed app Build Info: version, build, full commit, branch, GitStatus, and rollback checkout
- GitHub commit/tag: `vX.Y.Z`, changelog entry, and committed Xcode version/build metadata
- App Store Connect/TestFlight: bundle ID, version number, build string, upload status, and selected release build
- MDM or internal rollout note: version/build, deployment cohort, release date, and rollback candidate
- support ticket: screenshot or text copy of the Build Info sheet, not a hand-entered guess

For Owlory, the source of truth remains committed GitHub history plus committed Xcode build settings. Do not accept local-only Xcode edits, unpublished commits, untagged release candidates, or dirty Build Info as release truth.

## Version Control Contract

Implementation status: `Implemented` for local provenance checks, pre-push refusal, and archive-readiness preflight.
Proof level: Local Xcode/Git build provenance is implemented and checked by `make build-provenance`; Archive readiness is checked by `make release-preflight`.
Missing/deferred: A Git hook cannot stop someone from clicking Archive in Xcode. Archive still requires running `make release-preflight` immediately before using Xcode Organizer.

- Owlory release identity is shared across GitHub and Xcode, not split between them.
- GitHub is the durable source of committed history: commits, tags, changelog context, and the exact revision that a shipped build came from.
- Xcode is the durable source of app-facing version metadata: `MARKETING_VERSION`, `CURRENT_PROJECT_VERSION`, and the archived bundle metadata stamped into the app.
- Those records should intentionally mirror each other. A professional release should let a reviewer start from either side and recover the other without guesswork:
  - from a shipped app or TestFlight build, find the exact committed GitHub source
  - from a GitHub release commit or tag, confirm the matching Xcode version/build identity
- Do not ship archives from unpublished commits, dirty trees, or local-only Xcode version edits that are not represented in GitHub history.

Use `make build-provenance` before release or rollback work to print the current version, build number, Git commit, dirty-state warning, and rollback checkout command.

## Release Gate Stack

Use the gates in this order:

```text
pre-push hook          -> protects source history before pushing
make release-preflight -> protects Archive readiness before Xcode Organizer
Build Info gate        -> verifies the installed TestFlight binary
```

Do not substitute one for another. A clean push does not prove Archive readiness, and a Continue screenshot does not prove TestFlight behavior unless Build Info passes first.

## Git Hook Enforcement

Owlory ships a committed pre-push hook at `.githooks/pre-push`. Install it once per checkout:

```bash
git config core.hooksPath .githooks
```

The hook blocks pushes when the working tree is dirty, when `CURRENT_PROJECT_VERSION` differs from the committed `project.pbxproj` at `HEAD`, or when `make build-provenance` fails. Its failure messages explain why the rule exists and the remediation path.

This is a push-time guard only. It cannot stop Xcode Organizer from archiving local uncommitted state, so do not use a successful push as an archive proof. Before every TestFlight archive, still run:

```bash
make release-preflight
```

## Release Preflight

`make release-preflight` is the human-visible "do this before Archive" gate. It runs:

```bash
git status --short --untracked-files=all
git rev-list --left-right --count HEAD...@{u}
./Tools/verify-build-provenance.sh --require-clean
make build-provenance
```

Expected output before Archive:

```text
Working tree: clean
Git mirror: 0 0
Committed build number: matches HEAD
Releaseable: yes
Release preflight passed.
```

If any line fails, do not archive. Commit the build-number bump, push/pull until `HEAD...@{u}` is `0 0`, then rerun `make release-preflight`.

## Data Channel Boundary

Release identity is separate from local data identity.

- GitHub/Xcode mirroring proves that the app binary came from the expected committed source and Xcode version/build metadata.
- It does not prove that two installed app copies share the same local `Application Support/Owlory/...` JSON store.
- TestFlight, Xcode-dev, simulator, and device installs may read different local containers even when their source commits are related.
- Moving user data between channels requires an explicit import/export, backup restore, migration, app-group storage change, or sync feature.

Keep TestFlight and debug data separate by default. Do not point a debug build at real TestFlight user data as a convenience during release work.

## Normal Release

1. Run `./Tools/bump-version.sh <major|minor|patch>`.
2. Review `CHANGELOG.md`.
3. Run `make build-provenance` to confirm the Xcode version/build and current Git identity.
4. Run `make fast` or `make verify`.
5. Commit the version and changelog changes.
6. Push the release candidate commit to GitHub so the archive will point at published source history.
7. Confirm the pre-push hook is installed with `git config core.hooksPath .githooks`.
8. Run `make release-preflight` and confirm `Git mirror: 0 0`.
9. Run `make release-check` for runtime validation.
10. Tag `vX.Y.Z`.
11. Push the tag.
12. Re-run `make release-preflight` immediately before Archive.
13. Archive the committed state in Xcode.

`make release-check` runs `make release-preflight` first, then runs the runtime validation slice. It is intentionally stricter than `make build-provenance`, but `make release-preflight` remains the final required gate immediately before Archive.

The clean-tree gate alone is necessary but not sufficient. `verify-build-provenance.sh --require-clean` also asserts that the on-disk `CURRENT_PROJECT_VERSION` matches the committed value at `HEAD:owlory_xcode/Owlory.xcodeproj/project.pbxproj`. The verifier reports `Committed build number: matches HEAD` on success and exits non-zero with `pbxproj CURRENT_PROJECT_VERSION '...' is not committed at HEAD` when they diverge. This catches the failure mode where `./Tools/set-build-number.sh --auto` is run before archive without committing the bump, producing a TestFlight build whose `CFBundleVersion` is not reproducible from any committed pbxproj state on any branch.

## Clean TestFlight Build Prep

When TestFlight proof is blocked by missing fresh-build provenance, run a preparation slice rather than the blocked proof slice. The current prep artifact lives at `automation/proofs/owlory-release-clean-testflight-build-prep/`.

The prep path is:

```bash
make release-preflight
make release-check
```

The required local gate output is:

```text
Committed build number: matches HEAD
Working tree: clean
Releaseable: yes
```

This only proves the local checkout is ready to archive. It does not prove that an archive was uploaded, that TestFlight installed the same build, or that any TestFlight UI behavior was exercised.

After uploading and installing a fresh TestFlight build, open Build Info and record version, build, full commit, GitStatus, configuration, and rollback checkout. Then compare the installed binary to the local source:

```bash
./Tools/verify-build-provenance.sh --expected-build <testflight-build> --expected-commit <build-info-git-commit>
```

Only unblock TestFlight proof retry after that Build Info gate passes. If GitStatus is dirty or unavailable, or if build/commit provenance does not match committed source, keep the proof slice blocked and do not capture Continue surfaces.

Latest passing TestFlight proof: `automation/proofs/owlory-ui-testflight-proof/20260513T205620Z-provenance-intake/` shows Owlory `0.2.0 (20260513202827)` from clean commit `adb5de52bf90233e64257d5c0aa1dc37f59a6bf2`, with committed `CURRENT_PROJECT_VERSION = 20260513202827`, plus natural-data Today Continue and one Home protocol run route screenshot. Treat that as proof for the captured path only, not broad TestFlight coverage.

## TestFlight Diagnosis

1. Open the Build Info sheet in the TestFlight build being diagnosed.
2. Record the app version, build number, Git commit, Git status, and rollback checkout line.
3. Compare the local checkout with the TestFlight metadata:

```bash
./Tools/verify-build-provenance.sh --expected-build <testflight-build> --expected-commit <build-info-git-commit>
```

4. If the command fails on commit mismatch, check out the rollback line shown by the TestFlight build and rerun the comparison.
5. If the command fails on build mismatch, the local Xcode project is not the build-number state that produced that TestFlight artifact.
6. If the symptom is "different data in TestFlight and Xcode," compare bundle/app identity, device versus simulator, and install channel. Build provenance can explain which binary is running, but not move or merge local user data between app containers.

## TestFlight Rollback

1. Check out the known-good commit.
2. Run `./Tools/set-build-number.sh --auto`.
3. Commit the build-number change on top of the rollback source.
4. Push the rollback candidate commit so the rollback archive will point at published GitHub history.
5. Run `make build-provenance` and confirm the rollback checkout line points at the intended source commit.
6. Run at least `make architecture` and the affected domain tests.
7. Run `make release-preflight`, then `make release-check`, from a clean mirrored tree before archiving.
8. Archive that exact commit in Xcode.

The TestFlight build number comes from Xcode `CURRENT_PROJECT_VERSION`; Git metadata identifies the source revision.
