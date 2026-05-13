# Validation Workflows

Set `OWLORY_XCODE_DESTINATION` to override the default simulator destination.

```bash
export OWLORY_XCODE_DESTINATION="platform=iOS Simulator,name=iPhone 17,OS=26.5"
```

## Common Commands

- `make architecture` - run structural checks only.
- `make handoff` - print current repo state, read order, dirty paths, and recent SecondBrain entries.
- `make clean-stop` - prove the queue has no open actionable slices, Git is clean/mirrored, and parked slices have entry conditions.
- `make drift-report` - classify root clutter and legacy docs before cleanup.
- `make clean-system-metadata` - remove only obvious OS metadata files listed in the drift-control policy.
- `make verify-app-icons` - prove the shipped app-icon catalog and classify generated icon archives/folders.
- `make localization-check` - verify approved locale folders, matching `Localizable.strings` and `Localizable.stringsdict` keys, and Xcode variant-group packaging.
- `make review-preflight` - infer touched areas, docs, validation, and review risks for current changes.
- `make automation-check` - run the Python tests for the automation supervisor and context builder.
- `make build-provenance` - print and validate current Xcode version/build plus Git rollback identity.
- `make release-preflight` - require clean/mirrored source plus committed build-number provenance before Xcode Archive.
- `make fast` - architecture checks plus a focused core regression slice.
- `make verify` - architecture checks plus the broader Xcode core test suite.
- `make release-check` - run `make release-preflight`, then run the runtime validation slice before release/archive.
- `make test-domain DOMAIN=today` - run tests for one product domain.
- `make test-domain DOMAIN=voice` - run voice transcription routing and fallback tests.
- `make ui-smoke` - run the maintained focused XCUITest smoke path with isolated DerivedData.
- `make ui-regression` - run the regression batch (Lane 2) with its own isolated DerivedData; not invoked by `make ui-smoke`.
- `python3 automation/smoke/running_app_smoke.py` - build, install, launch, and screenshot the simulator app when running-app-smoke proof is needed. Use `--locale <locale>` for localization resource-loading smoke.

Use [PR Hygiene](pr-hygiene.md) before opening or reviewing a branch. Use [UI Testing Hygiene](ui-testing-hygiene.md) before adding UI tests, preserving screenshot proof, or claiming running-app behavior. Use [UI Regression Plan](ui-regression-plan.md) to choose which UI coverage lane a new claim belongs in and which gating commands to run for that lane.

## Contract Status And Proof Levels

Use the status markers in [Product Overview](../product/overview.md) when a product or workflow contract could be mistaken for shipped behavior.

Recommended status block:

```text
Implementation status: Partially implemented
Proof level: domain tests only
Missing/deferred: UI proof for large Dynamic Type Continue rows
```

Proof level should name the strongest evidence currently available using the automation ladder: `doc-only`, `domain-tested`, `build-tested`, `running-app-smoke`, `flow-verified`, `screenshot-verified`, `device-verified`, or `testflight-verified`. Do not call a contract `Implemented` unless its proof level points to live code paths and a repeatable validation command.

Automation handoffs must also preserve review evidence: `contract_status_changes`, `residual_risks`, `repo_clean_status`, and `git_mirror_status`. Treat those fields as the reviewable claim surface for what changed, what remains unproven, and whether the local repo state was clean or mirrored at handoff time.

## Clean Stop

Use `make clean-stop` when deciding whether all currently actionable work is complete. A clean repo alone is not enough; a clean queue alone is not enough.

The command checks three levels:

- queue state: no `queued`, `in_progress`, or future `ready` slices remain
- Git/repo state: `git status --short --untracked-files=all` is empty and `HEAD...@{u}` is `0 0`
- proof/parking-lot state: remaining `blocked` or `deferred` slices have explicit `entry_condition` values

This is a read-only completion gate. If it fails, use its remediation text instead of guessing: finish or park open queue work, commit/push local changes, or add an entry condition to parked work before claiming a clean stop.

Blocked slices are not executable work. When `make clean-stop` reports parked work and no queued slice is eligible, inspect unblockers with:

```bash
python3 automation/supervisor/run_next.py --dry-run --include-blocked
```

Queue or run the smallest unblocker slice rather than converting the blocked target to `queued` before its entry condition is true.

## ML, Speech, And Generated Output

Use [ML QA](ml-qa.md) together with [ML Model Posture](../runtime/ml-model-posture.md) and [ML Privacy And Drafts](../runtime/ml-privacy.md) for any feature that drafts text, classifies content, transcribes speech, or suggests changes from user data.

Minimum validation shape:

- `make architecture`
- the narrowest affected domain command, such as `make test-domain DOMAIN=voice` for speech/transcription routing
- focused tests or fixtures covering disabled, unavailable, empty, malformed, accepted, dismissed, low-confidence, and explicit-wrong outputs where the surface supports those states
- real-device sanity for microphone permission, on-device speech availability, transcription latency, and any concrete model availability/performance claim

Do not use exact generated prose as the primary assertion unless the prose is deterministic fallback copy.

## Runtime Observability And Performance

Use [Runtime Observability](../runtime/observability.md) together with [Performance Observability](performance-observability.md) for telemetry, MetricKit, signpost, Instruments, or performance-sensitive changes.

Minimum validation shape:

- `make architecture`
- `make test-domain DOMAIN=runtime` when `PerformanceTelemetry`, `BuildInfo`, MetricKit ownership, or app-runtime diagnostics change
- the affected domain command when adding signposts to a domain path
- real-device Instruments evidence for launch, latency, thermal, battery, or power claims
- Xcode Organizer or MetricKit evidence only for release/distributed-build trends, not immediate in-session feedback

Do not claim battery or power improvements from simulator-only checks.

## Localization

Owlory uses Apple-native `Localizable.strings` files under `owlory_xcode/Owlory/Resources/<locale>.lproj`. Plural and dynamic count formats use `Localizable.stringsdict` beside the strings file when needed. English (`en.lproj`) is the source key set. Non-English locales may temporarily keep English values as placeholders, but every locale must carry the same keys and the Xcode project must package `Localizable.strings` and `Localizable.stringsdict` through `PBXVariantGroup` resources, not raw `.lproj` folder copies.

Use [Localization String Inventory](localization-string-inventory.md) before translation or broad string extraction work. It classifies which source strings are already covered by SwiftUI literal localization, which can be safely keyed, and which need a separate formatting or code-routing slice.

Use [Localization Dynamic Formatting](localization-dynamic-formatting.md) before changing interpolated copy, counts, dates, display-name adapters, or notification text. Dynamic localization must preserve the boundary that domain returns semantic values, application coordinates runtime-owned messages, and SwiftUI/presentation code owns visible formatting.

Use [Localization Translation Quality](localization-translation-quality.md) before replacing English placeholders in non-English locale files. Parity checks, running-app smoke, and screenshot proof do not prove translation quality by themselves.

Use the generated review packet in `localization/review/` when handing source values to translators or reviewers:

```bash
python3 Tools/localization-review-export.py --output-dir localization/review
```

The export includes English source values, plural entries, current locale values, and status labels. It is review input only; it does not replace translation review.

Minimum validation shape:

- `make localization-check`
- `make architecture` before handoff, because architecture lint also runs localization parity
- an unsigned simulator build when Xcode project resource wiring changes
- the affected domain command when a dynamic formatting implementation changes Today, digest, Home, reminder, or display-name code

When adding copy, add the English key first, mirror it to every locale, and then translate values. Do not add user-visible placeholder warnings to the app UI.

## Automation Harness

Use [Automation Harness](../../automation/README.md) for queue-driven fresh-run continuation.

Minimum validation shape for `automation/` changes:

- `make architecture`
- `make automation-check`
- `python3 automation/supervisor/run_next.py --dry-run` from a clean or scope-matching worktree when queue selection, stop policy, or prompt packaging changes

Keep example JSON payloads in sync with the tracked schemas.

## Running App Smoke

Use the running-app smoke runner before claiming that a UI-affecting slice has been proven in a launched simulator app:

```bash
python3 automation/smoke/running_app_smoke.py
```

The runner emits JSON. A successful run reaches `proof_level: "running-app-smoke"` and records the simulator, bundle ID, scheme, commit/build metadata, and screenshot path. If the checkout cannot satisfy the runnable-app contract, the runner exits non-zero with `status: "blocked"` and a precise `blocked_contract` instead of claiming app behavior was verified.

For localization runtime smoke, run the same proof path with representative locale launch arguments:

```bash
python3 automation/smoke/running_app_smoke.py --locale en --output /tmp/owlory-locale-smoke-en.json
python3 automation/smoke/running_app_smoke.py --locale es --output /tmp/owlory-locale-smoke-es.json
python3 automation/smoke/running_app_smoke.py --locale fr --output /tmp/owlory-locale-smoke-fr.json
python3 automation/smoke/running_app_smoke.py --locale ar --output /tmp/owlory-locale-smoke-ar.json
python3 automation/smoke/running_app_smoke.py --locale zh-Hans --output /tmp/owlory-locale-smoke-zh-Hans.json
```

Locale smoke proves the built app bundle contains the requested locale resources and that the simulator app launches with `-AppleLanguages`/`-AppleLocale` arguments. It does not prove translation quality, layout correctness, screenshot-preserved proof, real-device behavior, or TestFlight behavior.

Repo-managed screenshot proof for the representative locale launch surfaces lives in `automation/proofs/app-localization-locale-screenshot-proof/`. Use that artifact only for launch-surface screenshot evidence; it does not expand the claim to translation quality or full layout review.

## UI Testing Hygiene

Owlory has a maintained minimal XCUITest target, `OwloryUITests`, for deterministic Today smoke coverage. It is not a broad UI regression suite.

Run it with isolated DerivedData:

```bash
make ui-smoke
```

The smoke tests launch the app with `--owlory-ui-testing`, reset app-local Owlory/Trajectory application-support data in Debug builds, skip notification authorization prompts, and verify the Today dashboard surface plus seeded Today Continue rows for one current Focus item, one source-derived active Home task, and one source-derived active Home protocol run through stable accessibility identifiers. They also exercise the existing Focus-backed Continue Done swipe action, assert that the completed row leaves the visible Continue list, tap one Home-task-backed Continue row to prove it routes into Home with the seeded task visible, and tap one Home-protocol-run-backed Continue row to prove it presents the active run sheet.

When adding another UI test or proof runner:

- use a slice-specific DerivedData path under `/tmp`
- seed deterministic data through launch arguments or a documented fixture path
- isolate simulator state when persistence, first-run, locale, or onboarding behavior matters
- add stable accessibility identifiers before writing brittle tests
- classify failures as harness, fixture, accessibility, timing, product regression, or pre-existing expected failure
- preserve durable screenshot proof under `automation/proofs/<slice-id>/` with proof notes and hashes

See [UI Testing Hygiene](ui-testing-hygiene.md) for the full rules.

The supervisor currently replays only a tiny exact-match allowlist of required validations:

- `make architecture`
- `git diff --check`

All other validation commands remain handoff-reported unless the harness grows a new replay path on purpose.

Validation ownership tiers in the harness are:

- `supervisor_replayable`
- `run_report_only`
- `never_supervisor_owned`

Use those tiers to make slice expectations legible. A domain test like `make test-domain DOMAIN=today` is currently `run_report_only`; manual or UI-launch steps should stay outside supervisor ownership.

## Simulator Status Bar For UI Review

Use this when screenshots or manual UI review need a clean, presentation-safe iPhone simulator status bar.

Target review state:

- time: `9:41`
- cellular: enabled with `4` bars
- Wi-Fi: enabled with `3` bars
- battery: `100%`

Checklist:

1. Open or boot the target iPhone simulator profile.
2. Apply the simulator status-bar override.
3. Launch the app and confirm the status bar is visible and unobstructed.
4. Verify there is no app-level status-bar suppression before treating the issue as a product bug.

Standard command:

```bash
xcrun simctl status_bar booted override \
  --time "9:41" \
  --dataNetwork wifi \
  --wifiMode active \
  --wifiBars 3 \
  --cellularMode active \
  --cellularBars 4 \
  --batteryState charged \
  --batteryLevel 100
```

Notes:

- This is simulator-device state, not app state.
- The override may need to be repeated for other simulator devices or runtimes.
- Do not file an Owlory UI bug unless the issue reproduces after simulator status-bar state is correctly configured.

## Direct Scripts

- `./Tools/architecture-lint.sh`
- `./Tools/agent-handoff.sh`
- `python3 Tools/clean-stop-check.py`
- `./Tools/clean-system-metadata.sh --dry-run`
- `./Tools/drift-report.sh`
- `./Tools/verify-app-icons.sh`
- `./Tools/localization-parity.sh`
- `python3 Tools/localization-review-export.py --output-dir localization/review`
- `./Tools/review-preflight.sh`
- `./Tools/verify-build-provenance.sh`
- `./Tools/release-preflight.sh`
- `.githooks/pre-push`
- `./Tools/verify-build-provenance.sh --expected-build <testflight-build> --expected-commit <build-info-git-commit>`
- `python3 automation/context/build_context.py --slice-id <slice_id>`
- `python3 automation/smoke/running_app_smoke.py`
- `python3 automation/supervisor/run_next.py --dry-run`
- `python3 automation/supervisor/run_next.py --dry-run --include-blocked`
- `python3 automation/supervisor/run_next.py --agent-cmd 'your-agent-runner --cwd {repo_root} --prompt-file {prompt_file}'`
- `./Tools/validate.sh architecture`
- `./Tools/validate.sh app-icons`
- `./Tools/validate.sh build-provenance`
- `./Tools/validate.sh clean-stop`
- `./Tools/validate.sh drift-report`
- `./Tools/validate.sh handoff`
- `./Tools/validate.sh localization`
- `./Tools/validate.sh review-preflight`
- `./Tools/validate.sh system-metadata`
- `./Tools/validate.sh fast`
- `./Tools/validate.sh full`
- `./Tools/validate.sh domain home`
- `./Tools/validate.sh domain voice`
- `python3 automation/smoke/running_app_smoke.py`

## Domain Shortcuts

- `today`: TodayStore, daily planning rules, focus suggestion rules, CarryForward, Readiness, Continue source composition, item assembly, pipeline trace diagnostics, candidate rules, and ranking rules.
- `train`: TrainStore, recurrence rules, and recurring rollover planner.
- `write`: WriteStore and writing stage rules.
- `career`: CareerStore.
- `home`: HomeStore, protocol lifecycle rules, protocol schedule rules, recurrence rules, and recurring rollover planner.
- `patterns`: PatternEngine, PatternNudgeRules, readiness-to-outcome rules, Calibration, WeeklyDigest content rules, and WeeklyDigest cadence rules.
- `reminders`: CompletionTimePredictor and reminder scheduling rules/trace.
- `runtime`: BuildInfo and PerformanceTelemetry.
- `voice`: VoiceTranscriptionRoutingRules plus Train reflection fallback persistence coverage.

## Validation Philosophy

Run the narrowest relevant check first. If a change touches shared rules, run the domain tests and `make architecture`. If it touches app wiring, widget behavior, build identity, or release behavior, run an Xcode build/test path rather than relying on Swift package tests alone.

For TestFlight or rollback work, start with `make build-provenance`. Use `--expected-build` and `--expected-commit` when comparing a local checkout against Build Info metadata copied from an installed TestFlight build.

Before any Xcode Archive, run:

```bash
make release-preflight
```

This is the archive-readiness gate. It requires a clean tree, `HEAD...@{u}` equal to `0 0`, a committed `CURRENT_PROJECT_VERSION`, and releaseable Build Info provenance. If it fails, do not archive.

For push-time release provenance enforcement, install the committed hook once:

```bash
git config core.hooksPath .githooks
```

Then run the same check manually when validating hook changes:

```bash
.githooks/pre-push
```

The hook is intentionally not the archive gate. It protects pushes; Xcode Archive still requires the release preflight in [Release And Rollback Workflow](release.md).

For a blocked TestFlight proof retry, use the clean-build prep evidence path before any upload or capture attempt:

```bash
make build-provenance
make release-preflight
make release-check
```

Preserve the local prep result under `automation/proofs/owlory-release-clean-testflight-build-prep/`. This proves only local archive readiness. The TestFlight proof lane stays blocked until an installed TestFlight build passes the Build Info provenance gate.
