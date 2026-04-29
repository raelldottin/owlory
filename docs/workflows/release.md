# Release And Rollback Workflow

## Build Provenance Sources

- App version and TestFlight build number live in `owlory_xcode/Owlory.xcodeproj/project.pbxproj` as `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION`.
- `./Tools/bump-version.sh <major|minor|patch>` updates `MARKETING_VERSION`, stamps a new timestamp build number, and updates `CHANGELOG.md`.
- `./Tools/set-build-number.sh --auto` updates `CURRENT_PROJECT_VERSION` for rollback builds without changing the app version.
- Xcode `Stamp Build Info` phases run `./Tools/generate-build-info.sh` during app and widget builds so the bundle records Git commit, branch, tag/describe output, dirty status, build date, configuration, and build-number source.
- `BuildInfo` reads the stamped bundle metadata at runtime. The Build Info sheet is the user-facing support breadcrumb for TestFlight diagnostics.

## Version Control Contract

Implementation status: `Partially implemented` and `Needs automation enforcement`.
Proof level: Local Xcode/Git build provenance is implemented and checked by `make build-provenance`.
Missing/deferred: Automatic proof that a release commit/tag has been pushed to GitHub before archive remains future enforcement.

- Owlory release identity is shared across GitHub and Xcode, not split between them.
- GitHub is the durable source of committed history: commits, tags, changelog context, and the exact revision that a shipped build came from.
- Xcode is the durable source of app-facing version metadata: `MARKETING_VERSION`, `CURRENT_PROJECT_VERSION`, and the archived bundle metadata stamped into the app.
- Those records should intentionally mirror each other. A professional release should let a reviewer start from either side and recover the other without guesswork:
  - from a shipped app or TestFlight build, find the exact committed GitHub source
  - from a GitHub release commit or tag, confirm the matching Xcode version/build identity
- Do not ship archives from unpublished commits, dirty trees, or local-only Xcode version edits that are not represented in GitHub history.

Use `make build-provenance` before release or rollback work to print the current version, build number, Git commit, dirty-state warning, and rollback checkout command.

## Normal Release

1. Run `./Tools/bump-version.sh <major|minor|patch>`.
2. Review `CHANGELOG.md`.
3. Run `make build-provenance` to confirm the Xcode version/build and current Git identity.
4. Run `make fast` or `make verify`.
5. Commit the version and changelog changes.
6. Push the release candidate commit to GitHub so the archive will point at published source history.
7. Run `make release-check` from a clean tree before archiving.
8. Tag `vX.Y.Z`.
9. Push the tag.
10. Archive the committed state in Xcode.

`make release-check` requires a clean tree and runs the runtime validation slice. It is intentionally stricter than `make build-provenance`.

## TestFlight Diagnosis

1. Open the Build Info sheet in the TestFlight build being diagnosed.
2. Record the app version, build number, Git commit, dirty status, and rollback checkout line.
3. Compare the local checkout with the TestFlight metadata:

```bash
./Tools/verify-build-provenance.sh --expected-build <testflight-build> --expected-commit <build-info-git-commit>
```

4. If the command fails on commit mismatch, check out the rollback line shown by the TestFlight build and rerun the comparison.
5. If the command fails on build mismatch, the local Xcode project is not the build-number state that produced that TestFlight artifact.

## TestFlight Rollback

1. Check out the known-good commit.
2. Run `./Tools/set-build-number.sh --auto`.
3. Commit the build-number change on top of the rollback source.
4. Push the rollback candidate commit so the rollback archive will point at published GitHub history.
5. Run `make build-provenance` and confirm the rollback checkout line points at the intended source commit.
6. Run at least `make architecture` and the affected domain tests.
7. Run `make release-check` from a clean tree before archiving.
8. Archive that exact commit in Xcode.

The TestFlight build number comes from Xcode `CURRENT_PROJECT_VERSION`; Git metadata identifies the source revision.
