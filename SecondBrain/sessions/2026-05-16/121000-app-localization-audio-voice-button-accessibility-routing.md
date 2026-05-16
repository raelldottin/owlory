# app-localization-audio-voice-button-accessibility-routing

## Prompt

> "start app-localization-audio-voice-button-accessibility-routing"

The narrow follow-up surfaced by the accessibility-bypass audit. Scope: route `AudioPlaybackButton.accessibilityText` and `VoiceCaptureButton.accessibilityText` switch returns through `Localizable.strings` so VoiceOver users in non-English locales hear their language.

## What was done

Added 8 new keys to `Localizable.strings` across all 19 locales with LLM-drafted translations (claude-opus-4-7, not native-reviewed):

| Key | English source | Has `%@`? |
|---|---|:---:|
| `audio.playback.accessibility.play` | `Play recording` | no |
| `audio.playback.accessibility.stop` | `Stop playback` | no |
| `audio.playback.accessibility.error` | `Playback error: %@` | **yes** |
| `voice.capture.accessibility.start` | `Start voice capture` | no |
| `voice.capture.accessibility.stop` | `Stop recording` | no |
| `voice.capture.accessibility.transcribing` | `Transcribing` | no |
| `voice.capture.accessibility.finished` | `Voice capture complete` | no |
| `voice.capture.accessibility.error` | `Error: %@` | **yes** |

Modified `AudioPlaybackButton.accessibilityText` (3 cases) and `VoiceCaptureButton.accessibilityText` (5 cases) to wrap each switch return in `NSLocalizedString` with a descriptive comment. The two `%@`-bearing cases use `String.localizedStringWithFormat` to substitute the runtime error message.

Approach mirrors the existing `HomeAccessibilityLabels` / `continueAccessibilityHint(for:)` / `writeRowAccessibilityHint(for:)` pattern that the audit confirmed already-safe.

## Files Edited

- `owlory_xcode/Owlory/DesignSystem/AudioPlaybackButton.swift` — switch now returns `NSLocalizedString(...)` and `String.localizedStringWithFormat(NSLocalizedString(...), msg)`.
- `owlory_xcode/Owlory/DesignSystem/VoiceCaptureButton.swift` — same pattern, 5 cases.
- 19 × `Localizable.strings` — 8 new keys appended in each.
- `automation/queue/slices.json` — slice flipped `queued` → `done`.
- `automation/handoffs/20260516T121000Z-app-localization-audio-voice-button-accessibility-routing.json` — new handoff.
- `SecondBrain/INDEX.md` — index entry.
- `SecondBrain/sessions/2026-05-16/121000-app-localization-audio-voice-button-accessibility-routing.md` — this note.

## Validation

- `make architecture` — passed.
- `make localization-check` — 19 locales / **324 keys** / 13 plural keys (up from 316; +8 new keys).
- `./Tools/validate.sh localization` — passed.
- `make automation-check` — 57/57.
- `xcodebuild build -quiet -project owlory_xcode/Owlory.xcodeproj -scheme Owlory -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/owlory-a11y-buttons-build CODE_SIGNING_ALLOWED=NO` — exit 0.
- `git diff --check` — clean.

## Lane Boundary

`build-tested`. The compile is clean, parity holds. No VoiceOver runtime verification per locale — that proof level belongs to a separate slice if/when on-device accessibility testing wants to claim it.

## Translation honesty

All 8 new keys are LLM-drafted by claude-opus-4-7. Status semantically equivalent to `needs-layout-check` (no claim of correctness, just that the translation lookup happens). The per-locale review return files (`localization/review/<locale>/<locale>-review-return.json`) currently snapshot the 356 entries from 2026-05-15; the 8 new keys are NOT reflected there. STATUS.md and LQA.md will report stale counts until those derived artifacts are regenerated — that's a maintenance task, deliberately out of scope here to keep this slice tight.

`app-localization-native-review-intake` remains blocked. The new keys widen the pool of unreviewed translations but do not change the blocked status.

## Inner-message localization gap

The error messages themselves (e.g., AudioPlayerService's `"Recording not found."` / `"Could not play recording."`) are still hardcoded English. Only the surrounding "Playback error: %@" / "Error: %@" wrapper is now localized. A future slice could localize the inner messages too — out of scope of this slice.

## Residual risk

(See handoff JSON `residual_risks` for the full list.)

- VoiceOver output per locale not verified at runtime. Native reviewer should confirm the LLM-drafted accessibility labels read aloud naturally.
- Inner AudioPlayerService error messages remain English.
- Per-locale return files and dashboard reports are stale by 8 keys; regenerate when convenient.
- Native review remains outstanding for every locale.

## What remains in the localization NLS roadmap

| Track | Status |
|---|---|
| Section / Label / Button literal routing | ✅ done (commit `31fd012`) |
| Accessibility var bypasses (DesignSystem audio/voice) | ✅ this slice |
| Accessibility helpers (Home/Today/Write) | ✅ already-safe |
| Interpolated copy formatters (`"Next: %@"`, `"%d of %d"`) | ⏸ queued: `app-localization-string-interpolation-formatters` |
| Native review of any locale | 🚫 blocked: `app-localization-native-review-intake` |
| LQA / dashboard refresh after new keys | ⏸ optional housekeeping |
