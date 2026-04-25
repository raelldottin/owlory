# ML Privacy And Drafts

Use this for features that draft text, classify content, transcribe speech, or suggest changes from user data.

## Current Posture

- Owlory is local-first by default.
- App data is file-backed in Application Support through existing repositories unless a feature explicitly changes storage.
- Current production suggestion and digest behavior is deterministic. The old ML drafting, structured-capture, and model-availability services are placeholders/deleted and must not be described as active.
- Speech transcription is the concrete ML-adjacent runtime path: `SpeechTranscriptionService` prefers `SpeechAnalyzer`/`SpeechTranscriber` where available, then falls back to on-device `SFSpeechRecognizer`.

## Policy

- Deterministic app facts stay deterministic.
- Generated or transcribed output stays draft-only until the user confirms it through the normal app flow.
- ML or speech output may propose text, categories, tags, explanations, ranking phrasing, or structured draft fields.
- ML or speech output must not overwrite user-authored content, silently persist canonical records, replace domain rules, or change completion/readiness/carry-forward facts.

## Storage And Claims

- Describe on-device processing as local processing, not as a promise that data never exists in memory.
- Audio recordings and transcripts may be file-backed or held in memory while the feature runs.
- Do not claim Secure Enclave storage, fully ephemeral storage, cloud sync absence for future cloud features, or API training behavior unless the shipped implementation and current platform terms support the claim.

## Fallbacks

Every model, transcription, or draft path must handle:

- permissions denied, restricted, or not determined
- model or speech assets unavailable
- empty, malformed, low-confidence, or invalid output
- cancellation or async failure

Fallback should preserve the existing deterministic flow. Examples: keep the deterministic digest, return no suggestion, preserve the audio file with an empty transcript, or leave existing text unchanged.

## Cloud And Custom Models

Cloud inference is not Owlory's default. Any future cloud path must be opt-in, explain what leaves the device, minimize payload size, and keep a local fallback where practical.

Foundation Models can be reintroduced only behind availability checks, injectable adapters, draft-only behavior, and deterministic fallbacks. Do not claim Foundation Models are active unless production code uses them.

MLX or other custom model runtimes require a named workload plus model source, license, model size, storage location, bundled/downloaded status, download consent, unsupported-device fallback, and measured memory/thermal/battery risk on a real device.

Use [ML Model Posture](ml-model-posture.md) for Foundation Models, MLX/custom-model, context-window, and adapter-boundary rules.

## Reviewer Checklist

Before approving ML, speech, or generated-output work, confirm:

- local-first behavior remains true unless a cloud path is explicitly requested and disclosed
- persistence remains file-backed where expected
- generated output requires user confirmation before becoming canonical data
- deterministic rules remain the source of truth
- unavailable and failure states degrade safely
- privacy copy matches implementation exactly

## Verify

- `make architecture`
- `make test-domain DOMAIN=voice` for speech/transcription routing changes
- the narrowest affected domain test for any generated-output consumer
- `make review-preflight` before approving broader ML or speech changes

Use [ML QA](../workflows/ml-qa.md) for fallback categories, eval fixtures, and device sanity expectations.
