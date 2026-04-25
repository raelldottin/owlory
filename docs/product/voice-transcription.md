# Voice Transcription Routing

## Owns

- Pure routing from a voice transcription result to an editable field.
- Applicable-field allowlists for voice-enabled contexts.
- Text merge behavior for title fields and paragraph-style fields.
- Fallback behavior when persistence receives an empty field plus a transcription.

## Does Not Own

- Microphone permissions, recording, audio files, or speech recognition.
- SwiftUI presentation or playback controls.
- Store persistence side effects.

## Policy

`Core/Domain/VoiceTranscriptionRoutingRules.swift` owns the routing table:

| Context | Default field | Other supported fields |
| --- | --- | --- |
| Today reflection | reflection | none |
| Today quick note | body | title |
| Today quick career record | details | title |
| Train session reflection | reflection | none |
| Write capture | body | none |
| Career record | details | none |
| Home task | notes | none |

Unsupported field requests resolve to no target and leave existing text unchanged. Paragraph-style fields append trimmed transcription with a newline when the field already has text. Title fields trim transcription and cap routed text at 100 characters.

## Runtime Boundaries

- `VoiceCaptureButton` starts/stops recording and passes `VoiceCaptureResult` to the caller.
- `AudioCaptureService` and `SpeechTranscriptionService` own Apple framework integration.
- Feature views select the appropriate routing context and field.
- Stores persist the resulting text and audio metadata.
- Privacy, permission fallback, and draft-only generated-output expectations live in [ML Privacy And Drafts](../runtime/ml-privacy.md).
- QA fallback categories and real-device speech sanity expectations live in [ML QA](../workflows/ml-qa.md).

## Verify

- `make test-domain DOMAIN=voice`
- `xcodebuild test -project Owlory.xcodeproj -scheme Owlory -destination "$OWLORY_XCODE_DESTINATION" -only-testing:OwloryCoreTests/VoiceTranscriptionRoutingRulesTests`
