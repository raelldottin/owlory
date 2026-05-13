# Release And Rollback Workflow

## Build Provenance Sources

- App version and TestFlight build number live in `owlory_xcode/Owlory.xcodeproj/project.pbxproj` as `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION`.
- `./Tools/bump-version.sh <major|minor|patch>` updates `MARKETING_VERSION`, stamps a new timestamp build number, and updates `CHANGELOG.md`.
- `./Tools/set-build-number.sh --auto` updates `CURRENT_PROJECT_VERSION` for rollback builds without changing the app version.
- Xcode `Stamp Build Info` phases run `./Tools/generate-build-info.sh` during app and widget builds so the bundle records Git commit, branch, tag/describe output, GitStatus, build date, configuration, and build-number source.
- `BuildInfo` reads the stamped bundle metadata at runtime. The Build Info sheet is the user-facing support breadcrumb for TestFlight diagnostics.

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
