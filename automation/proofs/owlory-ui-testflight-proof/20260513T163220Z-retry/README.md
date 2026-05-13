# TestFlight Proof Retry Gate Record

- Attempt: `20260513T163220Z`
- Slice: `owlory-ui-test-testflight-proof-retry`
- Local source commit: `c70ab71f9402ab2b97f0676260c171b868c22ae4`
- Local committed build: `20260417081904`
- Device: `Raell Dottin's iPhone`, iOS `26.4.2`, iPhone 15 Pro Max

## Gate Verdict

Blocked before TestFlight UI proof.

The paired iPhone is reachable and now has a newer installed `com.raelldottin.owlory` app than the prior retry. `xcrun devicectl device info apps` reports bundle version `20260417081912`.

The current clean local `main` and `origin/main` are mirrored at `c70ab71f9402ab2b97f0676260c171b868c22ae4`, whose committed Xcode `CURRENT_PROJECT_VERSION` is still `20260417081904`. No committed `project.pbxproj` state on `main` contains `20260417081912`.

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

## What This Does Not Prove

No TestFlight Build Info screenshot was captured in this retry, and no Continue surface was exercised. `testflight-verified` remains missing.

The likely interpretation is that the newly installed TestFlight build was produced after another build-number bump that is not represented in committed source. The gate is doing its job: it stops TestFlight proof before an unreproducible binary can be used as evidence.

## Next Required Action

Create a new TestFlight build from a committed source state whose `CURRENT_PROJECT_VERSION` matches the uploaded bundle version, then install that build on the paired iPhone and rerun the Build Info gate.
