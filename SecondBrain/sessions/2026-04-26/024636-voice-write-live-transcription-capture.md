# Voice Write Live Transcription Capture

## Prompt

- User asked: "Voice Notes: Should auto populate the speech to text content when the person is talking and use the voice note feature."

## Scope

- Supervisor slice: `voice-write-live-transcription-capture`
- Domain: Voice capture feeding Write.
- Goal: Let voice note capture populate the editable Write body while the user is actively speaking, without changing the requirement that the note is only saved when the user taps Save.

## Findings

- Voice capture previously waited until recording stopped before applying transcription to the Write capture body.
- The existing routing rule already knows how to merge a transcript into a Write capture field; the missing behavior was live partial delivery.
- The correct contract is draft-first: live speech may fill the body, but it is still editable and not persisted as a note until Save.

## Changes

- `AudioCaptureService` now records through `AVAudioEngine`, writes the same audio stream to disk, and publishes partial `SFSpeechAudioBufferRecognitionRequest` transcription while recording.
- `VoiceCaptureButton` exposes optional recording-started and live-transcription callbacks while preserving existing capture-result call sites.
- `WriteView` snapshots the pre-recording body, live-updates the body from partial speech text without duplicating partials, and finalizes with the stopped recording transcript.
- Added routing-rule coverage for the stable-base pattern used to avoid repeated live partials stacking in the Write body.
- Product docs now state that Write voice capture should populate draft text while speaking and remain user-saved.

## Validation

- `python3 automation/context/build_context.py --slice-id voice-write-live-transcription-capture`
- `python3 automation/supervisor/run_next.py --dry-run`
- `make architecture`
- `make test-domain DOMAIN=voice`
- `make test-domain DOMAIN=write`
- `git diff --check`

## Result

- Voice notes in Write now use live speech-to-text as a drafting aid instead of staying silent until transcription completes.

## Remaining Risk

- No manual real-device microphone pass was run, so partial-transcript cadence, permissions, and audio-session behavior still need device sanity checking.
