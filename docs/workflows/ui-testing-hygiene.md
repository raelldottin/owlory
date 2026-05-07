# UI Testing Hygiene

Use this before adding UI tests, preserving screenshot proof, or claiming running-app behavior. It adapts the durable Gymphant UI-testing lessons to Owlory without pretending Owlory already has a full XCUITest suite.

## Current State

- Owlory has a running-app smoke runner: `python3 automation/smoke/running_app_smoke.py`.
- Owlory has repo-managed screenshot proof directories under `automation/proofs/`.
- Owlory does not currently have a first-class XCUITest target or batched UI regression suite.

Do not claim XCUITest coverage until such a target exists and is wired into validation.

## Proof Lanes

Keep these separate:

- `running-app-smoke`: the app built, installed, launched, and produced a non-empty screenshot or log artifact.
- `flow-verified`: a specific running-app user flow was exercised end to end.
- `screenshot-verified`: screenshots are preserved in the repo with a README or manifest that explains the claim.
- `device-verified`: the flow was repeated on a physical device with build provenance.
- `testflight-verified`: the flow was repeated from the TestFlight build identity being claimed.

One lane does not imply another. A smoke screenshot is not a reviewed screenshot-proof artifact by itself.

## Deterministic UI Test Rules

Future UI tests should:

- Use a fresh, slice-specific DerivedData path under `/tmp`, never a developer's default DerivedData.
- Use deterministic launch arguments or seeded fixtures instead of relying on local user data.
- Reset or isolate simulator state when a test depends on first-run behavior, persistence, or locale.
- Add accessibility identifiers for stable controls before writing brittle coordinate or label-only tests.
- Keep screenshots as attachments or write them to an explicit artifact directory only when the test owns screenshot evidence.
- Terminate or relaunch the app between tests when persisted state can leak.
- Prefer focused batches over one giant UI suite when simulator memory, timing, or state leakage is a known risk.

If a UI test requires manual taps because the environment lacks a driver, record that as residual risk and queue automation follow-up instead of calling the proof repeatable.

## Screenshot Proof Artifacts

Repo-managed screenshot proof must live under:

```text
automation/proofs/<slice-id>/
```

Each proof directory needs:

- screenshots with stable names
- a README explaining what each screenshot proves
- hashes or a manifest when the proof claim depends on image integrity
- a clear list of what the screenshots do not prove

Do not preserve white launch-transition screenshots or stale screenshots just because a file exists. Recapture after the surface settles, or keep the proof level lower.

## Failure Classification

When a UI test or proof run fails, classify the failure before broad fixes:

- app crash or launch failure
- test harness or stale DerivedData
- missing fixture or seed data
- missing accessibility identifier
- timing or scroll/hittability issue
- actual product regression
- pre-existing expected failure

Failure reports should include:

- command run
- destination and OS
- DerivedData path
- artifact/log path
- expected state
- observed state
- smallest next fix slice

Do not bury known failures inside broad PR prose. Put durable classifications in `docs/workflows/` or the slice handoff when they affect future work.

## Minimum Validation Shape

For UI-affecting source changes:

```bash
make architecture
<affected domain validation>
python3 automation/smoke/running_app_smoke.py
git diff --check
```

For proof-only screenshot slices:

```bash
make architecture
make automation-check
git diff --check
```

Add an Xcode UI test command only after Owlory has a maintained UI test target and documented seed path.
