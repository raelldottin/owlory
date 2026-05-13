# TestFlight Proof Retry Gate Record

- Attempt: `20260513T173000Z`
- Slice: `owlory-ui-test-testflight-proof-retry`
- Current local source commit when recorded: `c6e8875ab239b30d844c93b1b3c1220deb33e30c`
- Current committed build when recorded: `20260513172951`

## Gate Verdict

Blocked before TestFlight UI proof.

The TestFlight install reports Owlory `0.2.0 (20260513172951)`, which matches the current committed Xcode build number. However, the Build Info screenshots show the installed app was stamped from a dirty source state:

```text
Commit:       de320a7dd2c3-dirty
Full commit:  de320a7dd2c38878df3343ae3f945df9ffb8f815-dirty
Branch:       main
Git status:   dirty
Tag:          de320a7-dirty
Built:        2026-05-13T17:30:34Z
Configuration: Release
Bundle:       com.raelldottin.owlory
Build source: Xcode CURRENT_PROJECT_VERSION
```

The stamped base commit's committed Xcode build was inspected directly:

```bash
git show de320a7dd2c38878df3343ae3f945df9ffb8f815:owlory_xcode/Owlory.xcodeproj/project.pbxproj \
  | rg "CURRENT_PROJECT_VERSION" | sort -u
```

Result:

```text
CURRENT_PROJECT_VERSION = 20260417081904;
```

That means the archive was produced from uncommitted local state: the binary reports build `20260513172951`, but the stamped commit's committed source reports build `20260417081904` and Build Info correctly says `Git status: dirty`.

## Preserved Screenshots

- [`01-build-info-top.png`](01-build-info-top.png) - shows version/build, dirty commit stamp, Git status `dirty`, not-releaseable banner, build time, and Release configuration.
- [`02-build-info-source.png`](02-build-info-source.png) - shows the dirty source block, bundle identifier, and `Build source: Xcode CURRENT_PROJECT_VERSION`.
- [`03-testflight-launch.png`](03-testflight-launch.png) - shows TestFlight listing Owlory `0.2.0 (20260513172951)`.
- [`04-continue-surface.png`](04-continue-surface.png) - shows the Today Continue surface with natural TestFlight data.

## What This Does Not Prove

The Continue surface screenshot is preserved as context, but it is not a valid TestFlight behavior proof because the mandatory Build Info provenance gate failed first. `testflight-verified` remains missing.

Do not use this retry to claim natural-data Continue proof, launch proof, screenshot proof, device proof, or release-channel behavior. The correct claim is narrower: the TestFlight app was installed and screenshots were captured, but Build Info reports a dirty archive, so the proof lane stops at the gate.

## Next Required Action

Create/upload/install a TestFlight build whose Build Info shows:

```text
Git status: clean
Full commit: a committed source state on main
Build: the same CURRENT_PROJECT_VERSION committed at that source state
Configuration: Release
```

Only after that gate passes should the TestFlight Continue surface be captured as proof.
