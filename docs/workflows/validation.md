# Validation Workflows

Set `OWLORY_XCODE_DESTINATION` to override the default simulator destination.

```bash
export OWLORY_XCODE_DESTINATION="platform=iOS Simulator,name=iPhone 16,OS=26.3.1"
```

## Common Commands

- `make architecture` - run structural checks only.
- `make handoff` - print current repo state, read order, dirty paths, and recent SecondBrain entries.
- `make drift-report` - classify root clutter and legacy docs before cleanup.
- `make clean-system-metadata` - remove only obvious OS metadata files listed in the drift-control policy.
- `make verify-app-icons` - prove the shipped app-icon catalog and classify generated icon archives/folders.
- `make review-preflight` - infer touched areas, docs, validation, and review risks for current changes.
- `make automation-check` - run the Python tests for the automation supervisor and context builder.
- `make build-provenance` - print and validate current Xcode version/build plus Git rollback identity.
- `make fast` - architecture checks plus a focused core regression slice.
- `make verify` - architecture checks plus the broader Xcode core test suite.
- `make release-check` - require clean build provenance, then run the runtime validation slice before release/archive.
- `make test-domain DOMAIN=today` - run tests for one product domain.
- `make test-domain DOMAIN=voice` - run voice transcription routing and fallback tests.

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

## Automation Harness

Use [Automation Harness](../../automation/README.md) for queue-driven fresh-run continuation.

Minimum validation shape for `automation/` changes:

- `make architecture`
- `make automation-check`
- `python3 automation/supervisor/run_next.py --dry-run` from a clean or scope-matching worktree when queue selection, stop policy, or prompt packaging changes

Keep example JSON payloads in sync with the tracked schemas.

The supervisor currently replays only a tiny exact-match allowlist of required validations:

- `make architecture`
- `git diff --check`

All other validation commands remain handoff-reported unless the harness grows a new replay path on purpose.

Validation ownership tiers in the harness are:

- `supervisor_replayable`
- `run_report_only`
- `never_supervisor_owned`

Use those tiers to make slice expectations legible. A domain test like `make test-domain DOMAIN=today` is currently `run_report_only`; manual or UI-launch steps should stay outside supervisor ownership.

## Direct Scripts

- `./Tools/architecture-lint.sh`
- `./Tools/agent-handoff.sh`
- `./Tools/clean-system-metadata.sh --dry-run`
- `./Tools/drift-report.sh`
- `./Tools/verify-app-icons.sh`
- `./Tools/review-preflight.sh`
- `./Tools/verify-build-provenance.sh`
- `./Tools/verify-build-provenance.sh --expected-build <testflight-build> --expected-commit <build-info-git-commit>`
- `python3 automation/context/build_context.py --slice-id <slice_id>`
- `python3 automation/supervisor/run_next.py --dry-run`
- `python3 automation/supervisor/run_next.py --agent-cmd 'your-agent-runner --cwd {repo_root} --prompt-file {prompt_file}'`
- `./Tools/validate.sh architecture`
- `./Tools/validate.sh app-icons`
- `./Tools/validate.sh build-provenance`
- `./Tools/validate.sh drift-report`
- `./Tools/validate.sh handoff`
- `./Tools/validate.sh review-preflight`
- `./Tools/validate.sh system-metadata`
- `./Tools/validate.sh fast`
- `./Tools/validate.sh full`
- `./Tools/validate.sh domain home`
- `./Tools/validate.sh domain voice`

## Domain Shortcuts

- `today`: TodayStore, daily planning rules, focus suggestion rules, CarryForward, Readiness, Continue source composition, item assembly, pipeline trace diagnostics, candidate rules, and ranking rules.
- `train`: TrainStore, recurrence rules, and recurring rollover planner.
- `write`: WriteStore and writing stage rules.
- `career`: CareerStore.
- `home`: HomeStore, protocol lifecycle rules, recurrence rules, and recurring rollover planner.
- `patterns`: PatternEngine, PatternNudgeRules, readiness-to-outcome rules, Calibration, WeeklyDigest content rules, and WeeklyDigest cadence rules.
- `reminders`: CompletionTimePredictor and reminder scheduling rules/trace.
- `runtime`: BuildInfo and PerformanceTelemetry.
- `voice`: VoiceTranscriptionRoutingRules plus Train reflection fallback persistence coverage.

## Validation Philosophy

Run the narrowest relevant check first. If a change touches shared rules, run the domain tests and `make architecture`. If it touches app wiring, widget behavior, build identity, or release behavior, run an Xcode build/test path rather than relying on Swift package tests alone.

For TestFlight or rollback work, start with `make build-provenance`. Use `--expected-build` and `--expected-commit` when comparing a local checkout against Build Info metadata copied from an installed TestFlight build.
