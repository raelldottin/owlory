# Clean TestFlight Build Prep

- Slice: `owlory-release-clean-testflight-build-prep`
- Generated: `2026-05-13T13:57:01Z`
- Source commit: `ccf167fbe47ed462bf01b790804077cd92fbe578`
- Branch: `main`

## What This Proves

This artifact records that the local repository was ready to create a clean, reproducible TestFlight archive at the source commit above.

Validated local provenance:

- App version/build: `v0.2.0 (20260417081904)`
- Version source: `owlory_xcode/Owlory.xcodeproj/project.pbxproj`
- Build number source: Xcode `CURRENT_PROJECT_VERSION`
- Committed build number: `matches HEAD`
- Git status at validation time: `clean`
- Releaseable: `yes`
- Rollback checkout: `git checkout ccf167fbe47ed462bf01b790804077cd92fbe578`

Commands passed before this artifact was written:

```bash
python3 automation/context/build_context.py --slice-id owlory-release-clean-testflight-build-prep
python3 automation/supervisor/run_next.py --dry-run --include-blocked
make build-provenance
make release-check
```

`make release-check` ran the clean provenance gate and the runtime validation slice. Runtime validation passed `BuildInfoTests` and `PerformanceTelemetryTests` on the configured iOS simulator destination.

## What This Does Not Prove

This artifact does not claim TestFlight proof.

Not performed in this slice:

- Xcode archive
- App Store Connect upload
- TestFlight install
- Build Info capture from a TestFlight binary
- Continue flow capture from TestFlight
- screenshot, device, or TestFlight proof upgrade

The TestFlight proof retry remains blocked until a fresh installed TestFlight build exists and its Build Info provenance gate passes.

## Archive Checklist

Before archiving:

1. Confirm the repo is clean and mirrored.

   ```bash
   git status --short --untracked-files=all
   git rev-list --left-right --count HEAD...@{u}
   ```

2. Confirm local provenance.

   ```bash
   make build-provenance
   make release-check
   ```

3. Confirm the verifier reports:

   ```text
   Committed build number: matches HEAD
   Working tree: clean
   Releaseable: yes
   ```

4. Archive the committed state in Xcode.
5. Upload the archive to TestFlight.

After installing the TestFlight build:

1. Open Build Info in the installed TestFlight app.
2. Record app version, build number, full commit, GitStatus, configuration, and rollback checkout.
3. Compare the installed build against committed source:

   ```bash
   ./Tools/verify-build-provenance.sh --expected-build <testflight-build> --expected-commit <build-info-git-commit>
   ```

4. Only start `owlory-ui-test-testflight-proof-retry` after the Build Info gate passes.

## Gate Expectations

A TestFlight build is acceptable for proof retry only when Build Info shows:

- Release configuration or the expected archive configuration
- clean `GitStatus`
- full Git commit matching the committed source being checked
- build number matching the committed Xcode `CURRENT_PROJECT_VERSION` at that commit
- rollback checkout line pointing at the same committed source

If any of those fail, stop at the gate. Do not capture Continue surfaces and do not mark the TestFlight proof slice as verified.
