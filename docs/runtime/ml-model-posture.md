# ML Model Posture

Use this for model-runtime choices, context-window handling, and adapter boundaries. Pair it with [ML Privacy And Drafts](ml-privacy.md) and [ML QA](../workflows/ml-qa.md).

## Current Status

- Current production suggestion and digest behavior is deterministic.
- The old Foundation Models drafting, structured-capture, model-availability, and prompt-budgeting files are placeholders or deleted. Do not describe those adapters as active unless production code is reintroduced.
- Speech transcription is active but separate: `SpeechTranscriptionService` owns Apple speech integration and falls back to on-device `SFSpeechRecognizer` where needed.

## Architecture Rule

Owlory is rules-first and model-assisted:

- `Core/Domain` computes facts, candidates, rankings, and deterministic product rules.
- `Core/Application` owns orchestration through injected protocols and fakeable services.
- `Core/Infrastructure` owns Apple framework or custom model adapters.
- UI presents generated output as a reviewable draft.
- Persistence saves only user-accepted output through existing stores.

Model output must not own canonical state, replace deterministic rules, or write through model tools.

## Foundation Models Posture

If a future slice reintroduces Apple Foundation Models, use them as the default app-product language layer for drafting, summarization, classification, guided structured output, and short feature-scoped assistance when the task fits on-device limits.

Required guardrails:

- Check runtime availability before showing model-powered affordances.
- Keep unavailable, disabled, malformed, empty, timeout, and cancellation paths deterministic.
- Keep model work asynchronous and out of computed properties, synchronous store initializers, and foreground refresh paths that users rely on.
- Use feature-scoped sessions. Do not share one app-wide session, and do not send concurrent requests through a stateful session that cannot support them.
- Prefer structured output types or schema-constrained output over ad hoc JSON parsing.
- Keep generated schemas small, shallow, and reviewable.
- Treat streaming or partial output as display-only until final validated output is accepted.
- Use prewarming only after measuring memory and power cost for the specific surface.

## Context Window Rule

Treat every model context window as a hard product constraint. Instructions, source facts, prompts, and generated output all compete for the same budget.

- Send only the facts needed for the task.
- Summarize or chunk long writing, career, training, or digest histories before model calls.
- Prefer compact typed inputs over raw archives or whole repositories of user text.
- Add prompt-budget helpers near application services if a feature needs repeatable trimming.
- Fall back to deterministic behavior when input cannot fit safely.
- Do not hard-code a numeric context limit in product rules unless the limit was verified against the deployed SDK and documented with the change.

## Tool-Calling Boundary

Model tools must start read-only. A model may request small facts, such as latest pattern summaries or selected item metadata, only through explicit application adapters.

Do not let model tools create, update, delete, schedule, or persist app state. Writes happen only after the user accepts or edits a draft through the existing product path.

## MLX And Custom Local Models

Do not add MLX, BNNS, MPS Graph, or a bundled/downloaded custom model as a general dependency for digest, Continue, voice-to-draft, Career, Home, Train, or Focus Suggestions work.

A custom local model slice must first name the workload and prove why Foundation Models, Speech, Natural Language, Vision, Core ML, or deterministic Swift rules are insufficient.

Before shipping a custom model/runtime path, document:

- model source, license, and version
- model size, package size, and storage location
- whether the model is bundled or downloaded
- download consent and deletion behavior if downloaded
- unsupported-device and failure fallback
- latency, memory, thermal, battery, and launch-impact measurements on real hardware
- signposts or telemetry that compare the custom path with the deterministic fallback

## Review Checklist

Before approving model-runtime work, confirm:

- domain rules remain framework-free and deterministic
- app/runtime code depends on injected protocols, not concrete model adapters
- deterministic fallback remains usable when the model path is unavailable
- generated output remains draft-only until user confirmation
- context-window trimming is explicit and testable when long histories are involved
- privacy and QA docs match the implementation

## Verify

- `make architecture`
- `make review-preflight`
- the narrowest affected domain test
- [ML QA](../workflows/ml-qa.md) fixture/fallback checks for generated-output surfaces
- real-device sanity for concrete model availability, latency, memory, thermal, battery, or speech claims
