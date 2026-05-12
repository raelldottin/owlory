# UI Regression Plan

Use this when classifying a new UI proof effort, choosing the right gate before claiming coverage, or deciding which lane a failing test belongs to. It defines what full Owlory UI coverage means as five separate lanes with explicit boundaries; it does not implement any new tests.

See also [UI Testing Hygiene](ui-testing-hygiene.md) for the durable rules (deterministic seeds, accessibility identifiers, failure classification, screenshot artifact shape).

## Why Five Lanes

A single "UI test passed" claim conflates very different forms of evidence: that the app launched, that a flow worked under deterministic seeds, that a surface looked correct, that a physical device behaved correctly, and that the release-channel binary matched committed source. Bundling them produces broken proof — a green smoke run is not a screenshot review, and a screenshot review is not a TestFlight verification. Each lane has its own trigger, scope, gating commands, and artifact location. One lane does not imply another.

The five lanes map directly onto the proof levels recorded in slice handoffs (`docs/workflows/validation.md` and `ui-testing-hygiene.md`): `running-app-smoke`, `flow-verified`, `screenshot-verified`, `device-verified`, `testflight-verified`.

## Lane 1: Smoke Suite

**Trigger.** Local dev loop, agent loop, and any PR that touches UI-affecting code.

**Target.** The hand-picked set of high-value Today surface flows that should stay green on every change. Currently `OwloryUITests/OwloryUITests`, covering source visibility for all six composer-backed Continue sources, one Focus-backed Continue Done action, and four route smokes (Home task, active Home protocol run, in-progress Writing, due-today Training).

**Scope.** Fast (single Xcode invocation), deterministic (debug-only seed launch arguments under `OwloryUITestSupport`), runs locally with isolated DerivedData at `/tmp/owlory-ui-smoke-derived-data`. Single class, single test target, no batching.

**Proves.** That the app builds, launches, and the chosen anchor flows work under the seeded fixtures at the current commit.

**Does not prove.** Full UI coverage, edge cases beyond the seeded fixtures, visual correctness, device behavior, TestFlight identity, or that surfaces not asserted by the smoke remain unbroken.

**Gating commands.**
- `make ui-smoke`
- `make ui-smoke-proof` to refresh the smoke screenshot pack after a flow change.

**Artifact location.** `automation/proofs/owlory-ui-smoke-proof/` (PNGs plus `manifest.json` with sha256 hashes, source commit, capture timestamp).

## Lane 2: Regression Suite

**Trigger.** Pre-release, after a domain refactor, or on demand. Not every PR.

**Target.** Broader per-domain coverage than the smoke set, including edge cases, multiple sources per domain, error paths, and action variants the smoke does not assert. Built as separate XCUITest classes (e.g., `OwloryUIRegressionTests/TodayContinueRegression`) so they do not run on every `make ui-smoke` invocation.

**Scope.** Batched simulator execution is allowed when state isolation is needed. Each test resets state via existing seed paths or new deterministic seeds; no test depends on residue from a prior test. May take longer than the smoke; tolerated because the trigger is rare.

**Proves.** That a domain's primary user surfaces remain functional across the actions and source variations covered by the batch, under deterministic seeds.

**Does not prove.** Visual correctness, device behavior, TestFlight identity, surfaces outside the batch, or behavior under non-seeded real-user data.

**Gating commands.**
- `make ui-regression` runs the regression class with `-only-testing:OwloryUITests/TodayContinueRegression` against `/tmp/owlory-ui-regression-derived-data`. Wired by `owlory-ui-regression-batch-1-today-continue`; the first batch covers Today Continue source visibility, source-derived routing, and Focus row actions.
- `make ui-regression DOMAIN=<domain>` is the intended per-domain narrowing shape; not yet wired (a future batch can introduce it when more than one domain has a regression class).

**Artifact location.** `/tmp/owlory-ui-regression-derived-data` (transient). Preserved failure artifacts go to `automation/proofs/<slice-id>/` only when a slice claims them as durable evidence.

## Lane 3: Screenshot Proof

**Trigger.** After a UI-affecting surface change whose visual claim should be reviewable beyond a green test.

**Target.** Specific named surfaces with a stable visual claim — Today launch, Continue rows in their seeded states, settings sheets, Build Info, and so on. One screenshot pack per slice, not one global gallery.

**Scope.** Curated screenshots captured via `captureScreenshot(named:)` and `XCTAttachment(screenshot:)` with `lifetime = .keepAlways`, extracted from the slice's `.xcresult` bundle and written to a slice-owned proof directory with a manifest.

**Proves.** Visual evidence of the named surface at the named commit, hashed for integrity.

**Does not prove.** Surfaces outside the pack, device renderer differences, TestFlight identity, accessibility behavior, layout under Dynamic Type variants that were not captured, or that any later commit still renders the same way.

**Gating commands.**
- `make ui-smoke-proof` for the maintained smoke pack.
- Slice-specific extraction scripts under `automation/smoke/` for slice-owned packs.

**Artifact location.** `automation/proofs/<slice-id>/` with:
- screenshots named `NN-kebab-case.png`
- a README explaining what each screenshot proves and what it does not
- a `manifest.json` with sha256 hashes, source commit, capture timestamp, and the explicit "does not prove" list

## Lane 4: Device Proof

**Trigger.** Pre-TestFlight or pre-release-candidate; before claiming behavior on real hardware.

**Target.** Selected anchor flows run on a physical iPhone with build provenance stamped into the bundle. The chosen flows must have explicit provenance expectations (which seed paths exist on device, which do not).

**Scope.** Hand-run flows on a connected device with documented commit, build number, and Build Info screen capture. Debug-only seeds may or may not be available depending on the build configuration; the slice records which seeds were live.

**Proves.** Real-device touch input, real renderer, real OS scheduling and animations, build provenance for the installed bundle.

**Does not prove.** TestFlight upload chain, App Store Connect identity, other device models or OS versions, or surfaces not exercised on device.

**Gating commands.**
- `make build-provenance` before install to capture and document the source identity.
- Manual install via Xcode "Run" on the device, then capture screenshots and a Build Info screen.
- `./Tools/verify-build-provenance.sh --expected-build <build> --expected-commit <commit>` after install to confirm the local checkout matches the device Build Info.

**Artifact location.** `automation/proofs/owlory-ui-device-proof/` (or slice-specific) with README, `manifest.json`, device model/OS, Build Info screen capture, and screenshots of the verified flows.

## Lane 5: TestFlight Proof

**Trigger.** Post-archive upload, before public release. Only valid for TestFlight builds whose Build Info reports a clean commit that exists in published GitHub history.

**Target.** TestFlight install on device, with the Build Info screen and the verifier output proving the archived `CFBundleVersion` matches the committed `CURRENT_PROJECT_VERSION` at the stamped commit.

**Scope.** Golden-path flows on the TestFlight build with the Build Info screen captured. Seeds are not assumed available unless the TestFlight build was archived from a configuration that exposes them; in release configuration, no debug seed paths are live.

**Proves.** TestFlight build identity matches committed source, and the golden-path flows render correctly from the release-channel binary on real hardware.

**Does not prove.** Future TestFlight builds, edge cases not exercised, surfaces gated by debug-only seeds, content that depends on TestFlight server state, or other testers' install behavior.

**Gating commands.**
- `make release-check` before archive — now includes the committed-build-number assertion from `verify-build-provenance.sh`.
- `./Tools/verify-build-provenance.sh --expected-build <build> --expected-commit <commit>` against the Build Info captured from the installed TestFlight build.

**Artifact location.** `automation/proofs/owlory-ui-testflight-proof/` (or slice-specific) with README, `manifest.json`, Build Info screen capture, verifier output, and screenshots of the verified flows.

## Promotion Order

A feature should travel up the lanes deliberately. Skipping lanes hides the gap; the higher claim cannot be trusted if the lower lane is missing.

1. **Domain tests.** Behavior is provable in core regression tests before any UI claim.
2. **Smoke (Lane 1).** Source visibility, basic routing, and one anchor action per surface.
3. **Regression (Lane 2).** Broader per-domain coverage; multiple sources, edge cases, action variants.
4. **Screenshot proof (Lane 3).** Stable visual surfaces preserved with manifest and hashes.
5. **Device proof (Lane 4).** Real hardware behavior with stamped build provenance.
6. **TestFlight proof (Lane 5).** Release-channel binary verified against committed source.

If a higher lane needs to ship before a lower lane exists (rare), record the gap explicitly in the slice handoff `missing_proof_levels` and add a follow-up slice. Do not silently upgrade the claim.

## Lane Boundaries

Common confusions to avoid:

- A smoke screenshot attachment is not screenshot proof. It is a smoke artifact. Screenshot proof requires a curated pack with manifest, hashes, and a README.
- A green regression run is not visual proof. Layout changes that XCUITest does not assert can slip through.
- A device-proof slice is not a TestFlight proof. Device proof verifies hardware behavior; TestFlight proof verifies the release-channel binary chain.
- A TestFlight install whose Build Info reports a commit that does not exist in committed history is not testflight-verified. The gate at `Tools/verify-build-provenance.sh --require-clean` blocks the symmetric failure mode at archive time.

## When To Add A New Lane

Do not. If a future need does not fit any of the five lanes, prefer to extend the closest lane's scope rather than introducing a sixth. The number of lanes is part of the contract: more lanes dilute the "this proof level means X" signal that handoffs and `roadmap-status.md` rely on.

## Status

This document is the canonical definition of UI coverage lanes for Owlory. Linked from:

- [UI Testing Hygiene](ui-testing-hygiene.md) for daily-use rules within each lane.
- [Validation Workflows](validation.md) for the command shortcuts.
- [Roadmap Status](roadmap-status.md) for the UI regression / snapshot coverage row.
