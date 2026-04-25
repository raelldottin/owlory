# Performance Observability

Use this before adding telemetry, signposts, MetricKit handling, Instruments profiling, performance tests, or performance claims. Use [Runtime Observability](../runtime/observability.md) to see which runtime surfaces are already instrumented.

## Tool Selection

- `PerformanceTelemetry`: Owlory's shared application boundary for OSLog/signpost-style instrumentation. Prefer this over one-off loggers.
- `OSLog` and signposts: local development, Instruments correlation, critical workflow durations, and privacy-aware operational diagnostics.
- `MetricKit`: daily aggregate payloads and diagnostics from real device use. Do not treat it as a real-time dashboard.
- Xcode Organizer: release and TestFlight trends after enough distributed usage exists.
- Instruments: real-device root-cause analysis for launch, CPU, wakeups, disk, network, memory, thermal, SwiftUI churn, and power.
- XCTest performance tests: deterministic lower-layer regression gates for pure or repeatable work.

## Instrumentation Rules

Add instrumentation only when the runtime path is important enough that support, release, or performance work will need to explain it later.

Good signpost targets:

- launch and first data hydration
- Today, Continue, Patterns, digest, reminders, rollover, and repository load/save paths
- voice capture, transcription, and any future generated-output adapter calls
- Home protocol run lifecycle when user-visible latency or state ambiguity appears
- custom compute/model experiments when comparing baseline and accelerated paths

Do not instrument:

- every row render
- every keystroke
- high-cardinality IDs unless redacted or hashed locally
- raw user text, titles, notes, transcripts, prompts, model output, file paths, career details, or household notes

Use stable operation names and low-cardinality status enums. Default interpolated values to private unless they are clearly non-user data.

## MetricKit Rules

- Register MetricKit subscribers from a process-lifetime owner, not a short-lived view.
- Keep unsupported-platform behavior no-op and testable.
- Treat MetricKit payloads as delayed aggregate evidence, not live UI state.
- Store or export only redacted local/internal summaries until a separate opt-in diagnostics decision exists.
- Use MetricKit custom signposts only for critical release metrics whose count/duration should appear in daily payloads.

MetricKit should help explain release trends such as launch, memory, responsiveness, hangs, crashes, disk writes, network transfer, and custom signpost durations. It should not be used to claim exact per-action battery percentage.

## Profiling And Device Sanity

Performance and battery claims need real-device evidence when the behavior depends on hardware, OS scheduling, thermal state, microphone/speech, networking, display, or app lifecycle timing.

Record:

- device model and OS version
- build/version identity
- battery level and Low Power Mode
- thermal state when relevant
- tethered vs untethered state
- scenario name and trace filename
- whether the run is simulator, generic build, physical device, TestFlight, or App Store

Use Time Profiler, Power Profiler, memory tools, SwiftUI tools, Network tools, or Xcode Organizer depending on the claim. Simulator checks can catch correctness regressions, but they do not prove battery, thermal, or release performance.

## Performance Gates

Use performance gates when the work is repeatable and the metric is meaningful.

Good gate candidates:

- pure Continue derivation
- pattern snapshot computation
- weekly digest rule generation
- repository serialization with temporary stores
- prompt/context budgeting if a future model path reintroduces it

Avoid gates that only measure static fixtures or unstable full-app UI flows without a reliable target. When no honest automated gate exists, record the manual/device gap instead.

## Review Checklist

Before approving performance-sensitive changes, confirm:

- new instrumentation uses shared helpers where practical
- no user content, prompts, transcripts, file paths, or high-cardinality IDs are logged
- signpost names and categories are stable
- MetricKit work is app-lifetime-owned and not used as real-time UI state
- simulator-only checks are not presented as battery or thermal proof
- performance claims include before/after evidence or are phrased as unverified
- any custom compute/model acceleration also follows [ML Model Posture](../runtime/ml-model-posture.md)

## Verify

- `make architecture`
- `make test-domain DOMAIN=runtime` for `PerformanceTelemetry`, MetricKit ownership, or app-runtime diagnostics
- the affected domain command when adding signposts to a domain path
- `make review-preflight`
- physical-device Instruments or Organizer evidence for battery, thermal, launch, or release-performance claims
