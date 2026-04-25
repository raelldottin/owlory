# Release And Rollback Workflow

## Build Provenance Sources

- App version and TestFlight build number live in `owlory_xcode/Owlory.xcodeproj/project.pbxproj` as `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION`.
- `./Tools/bump-version.sh <major|minor|patch>` updates `MARKETING_VERSION`, stamps a new timestamp build number, and updates `CHANGELOG.md`.
- `./Tools/set-build-number.sh --auto` updates `CURRENT_PROJECT_VERSION` for rollback builds without changing the app version.
- Xcode `Stamp Build Info` phases run `./Tools/generate-build-info.sh` during app and widget builds so the bundle records Git commit, branch, tag/describe output, dirty status, build date, configuration, and build-number source.
- `BuildInfo` reads the stamped bundle metadata at runtime. The Build Info sheet is the user-facing support breadcrumb for TestFlight diagnostics.

Use `make build-provenance` before release or rollback work to print the current version, build number, Git commit, dirty-state warning, and rollback checkout command.

## Normal Release

1. Run `./Tools/bump-version.sh <major|minor|patch>`.
2. Review `CHANGELOG.md`.
3. Run `make build-provenance` to confirm the Xcode version/build and current Git identity.
4. Run `make fast` or `make verify`.
5. Commit the version and changelog changes.
6. Run `make release-check` from a clean tree before archiving.
7. Tag `vX.Y.Z`.
8. Archive the committed state in Xcode.

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
4. Run `make build-provenance` and confirm the rollback checkout line points at the intended source commit.
5. Run at least `make architecture` and the affected domain tests.
6. Run `make release-check` from a clean tree before archiving.
7. Archive that exact commit in Xcode.

The TestFlight build number comes from Xcode `CURRENT_PROJECT_VERSION`; Git metadata identifies the source revision.
