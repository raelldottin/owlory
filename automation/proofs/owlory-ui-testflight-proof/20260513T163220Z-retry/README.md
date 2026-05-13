# TestFlight Proof Retry Gate Record

- Attempt: `20260513T163220Z`
- Slice: `owlory-ui-test-testflight-proof-retry`
- Local source commit: `c70ab71f9402ab2b97f0676260c171b868c22ae4`
- Local committed build: `20260417081904`
- Device: `Raell Dottin's iPhone`, iOS `26.4.2`, iPhone 15 Pro Max

## Gate Verdict

Blocked before TestFlight UI proof.

The paired iPhone is reachable and now has a newer installed `com.raelldottin.owlory` app than the prior retry. `xcrun devicectl device info apps` reports bundle version `20260417081912`, and the preserved Build Info screenshots confirm the same build number.

The current clean local `main` and `origin/main` are mirrored at `c70ab71f9402ab2b97f0676260c171b868c22ae4`, whose committed Xcode `CURRENT_PROJECT_VERSION` is still `20260417081904`. No committed `project.pbxproj` state on `main` contains `20260417081912`.

The Build Info screenshots also show the TestFlight app was stamped from clean commit `d0513a41a3e438a76494f43e5f4094a6983ad75e`, branch `main`, configuration `Release`, bundle `com.raelldottin.owlory`, and build source `Xcode CURRENT_PROJECT_VERSION`. That stamped commit's committed Xcode build is still `20260417081904`, not `20260417081912`.

The local comparison fails:

```bash
./Tools/verify-build-provenance.sh --expected-build 20260417081912 --expected-commit c70ab71f9402ab2b97f0676260c171b868c22ae4
```

Result:

```text
error: expected build '20260417081912' but Xcode CURRENT_PROJECT_VERSION is '20260417081904'
```

## What Was Checked

```bash
git fetch origin main
git rev-list --left-right --count HEAD...@{u}
git log --all --oneline -S20260417081912 -- owlory_xcode/Owlory.xcodeproj/project.pbxproj
git show d0513a41a3e438a76494f43e5f4094a6983ad75e:owlory_xcode/Owlory.xcodeproj/project.pbxproj \
  | rg "CURRENT_PROJECT_VERSION" | sort -u
xcrun devicectl device info apps \
  --device 691FB5B7-A8F2-5AE4-BE95-EC1CABC5872F \
  --bundle-id com.raelldottin.owlory
```

Reported:

```text
Name     Bundle Identifier        Version   Bundle Version
------   ----------------------   -------   --------------
Owlory   com.raelldottin.owlory   0.2.0     20260417081912
```

Local `HEAD` after fetch:

```text
0 0
c70ab71 Record blocked TestFlight proof retry
```

Committed Xcode build at local `HEAD`:

```text
CURRENT_PROJECT_VERSION = 20260417081904;
```

Raw `devicectl` app metadata is preserved in [`device-apps.json`](device-apps.json).

Preserved Build Info screenshots:

- [`01-build-info-top.png`](01-build-info-top.png) - shows Version `0.2.0`, Build `20260417081912`, Commit `d0513a41a3e4`, Full commit `d0513a41a3e438a76494f43e5f4094a6983ad75e`, Branch `main`, Git status `clean`, Tag `d0513a4`, Built `2026-05-13T14:13:54Z`, Configuration `Release`, and Bundle `com.raelldottin.owlory`.
- [`02-build-info-source.png`](02-build-info-source.png) - shows the same source block plus Build source `Xcode CURRENT_PROJECT_VERSION`.

## What This Does Not Prove

No Continue surface was exercised. `testflight-verified` remains missing.

The screenshots make the likely interpretation sharper: the newly installed TestFlight build was stamped from a clean committed source commit, but its bundle version was produced after another build-number bump or rewrite that is not represented in that commit's `project.pbxproj`. The gate is doing its job: it stops TestFlight proof before an unreproducible binary can be used as behavior evidence.

## Next Required Action

Create a new TestFlight build from a committed source state whose `CURRENT_PROJECT_VERSION` matches the uploaded bundle version, then install that build on the paired iPhone and rerun the Build Info gate.
