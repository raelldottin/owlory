# TestFlight Proof Retry Gate Record

- Attempt: `20260513T142117Z`
- Slice: `owlory-ui-test-testflight-proof-retry`
- Local source commit: `d0513a41a3e438a76494f43e5f4094a6983ad75e`
- Local committed build: `20260417081904`
- Device: `Raell Dottin's iPhone`, iOS `26.4.2`, iPhone 15 Pro Max

## Gate Verdict

Blocked before TestFlight UI proof.

The paired iPhone is reachable, but the installed `com.raelldottin.owlory` app still reports bundle version `20260417081911`. The current clean local source reports Xcode `CURRENT_PROJECT_VERSION = 20260417081904` at commit `d0513a41a3e438a76494f43e5f4094a6983ad75e`.

The local comparison fails:

```bash
./Tools/verify-build-provenance.sh --expected-build 20260417081911 --expected-commit d0513a41a3e438a76494f43e5f4094a6983ad75e
```

Result:

```text
error: expected build '20260417081911' but Xcode CURRENT_PROJECT_VERSION is '20260417081904'
```

## What Was Checked

```bash
xcrun devicectl device info apps \
  --device 691FB5B7-A8F2-5AE4-BE95-EC1CABC5872F \
  --bundle-id com.raelldottin.owlory
```

Reported:

```text
Name     Bundle Identifier        Version   Bundle Version
------   ----------------------   -------   --------------
Owlory   com.raelldottin.owlory   0.2.0     20260417081911
```

`make build-provenance` on local clean `main` reported:

```text
Git commit full: d0513a41a3e438a76494f43e5f4094a6983ad75e
Committed build number: matches HEAD
Working tree: clean
Releaseable: yes
Build number: 20260417081904
```

## What This Does Not Prove

No TestFlight Build Info screenshot was captured in this retry, and no Continue surface was exercised. `testflight-verified` remains missing.

The likely interpretation is that a fresh build may exist in TestFlight/App Store Connect, but it is not the installed `com.raelldottin.owlory` binary on the paired iPhone yet, or the installed app still points at the earlier unreproducible build.

## Next Required Action

Install the fresh clean TestFlight build on the paired iPhone, then re-run the Build Info gate. The installed app's bundle version and Build Info build number must match committed source before any Continue proof capture starts.
