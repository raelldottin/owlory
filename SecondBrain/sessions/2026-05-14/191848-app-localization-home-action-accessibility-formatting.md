# app-localization-home-action-accessibility-formatting

## Prompt

Audit Group A follow-up. Localize the five interpolated Home-action accessibility labels in HomeView via `%@`-format keys and a small presentation helper.

## Files Edited

- `owlory_xcode/Owlory/Resources/en.lproj/Localizable.strings` — added 7 keys.
- 18 non-English `.lproj/Localizable.strings` files — mirrored with English placeholder values.
- `owlory_xcode/Owlory/Core/Application/HomeAccessibilityLabels.swift` — new helper with `taskEdit`, `taskSkip`, `taskMarkComplete`, `taskMarkIncomplete`, `taskRestore`, `protocolStepComplete`, `protocolStepSkip`. All seven delegate to a private `format(_:_:)` that calls `String.localizedStringWithFormat(NSLocalizedString(...), argument)`.
- `owlory_xcode/Owlory.xcodeproj/project.pbxproj` — registered the helper (PBXBuildFile A082, PBXFileReference A181, group child, Sources build phase).
- `owlory_xcode/Owlory/Features/Home/HomeView.swift` — five call sites swapped to helper calls: line 529 (Edit), line 547 (Skip task), line 577-585 (leadingButtonAccessibilityLabel three branches), line 1123 (Complete protocol step), line 1152 (Skip protocol step).
- `docs/workflows/localization-string-inventory.md` — Group A entry updated from queued→shipped with call-site → helper mapping.
- `docs/workflows/localization-dynamic-formatting.md` — added queue-order entry (#9).
- `automation/queue/slices.json` — slice flipped to `done`.
- `automation/handoffs/20260514T231848Z-app-localization-home-action-accessibility-formatting.json`
- `SecondBrain/INDEX.md`
- `SecondBrain/sessions/2026-05-14/191848-app-localization-home-action-accessibility-formatting.md`

## Key map

| Helper method | Localizable.strings key | English |
| --- | --- | --- |
| `taskEdit(title:)` | `home.task.accessibility.edit` | `Edit %@` |
| `taskSkip(title:)` | `home.task.accessibility.skip` | `Skip %@` |
| `taskMarkComplete(title:)` | `home.task.accessibility.markComplete` | `Mark %@ complete` |
| `taskMarkIncomplete(title:)` | `home.task.accessibility.markIncomplete` | `Mark %@ incomplete` |
| `taskRestore(title:)` | `home.task.accessibility.restore` | `Restore %@` |
| `protocolStepComplete(title:)` | `home.protocol.step.accessibility.complete` | `Complete %@` |
| `protocolStepSkip(title:)` | `home.protocol.step.accessibility.skip` | `Skip %@` |

## Validation

- `python3 automation/context/build_context.py --slice-id app-localization-home-action-accessibility-formatting` — exit 0.
- `python3 automation/supervisor/run_next.py --dry-run` — selected this slice; post-completion returns to clean stop.
- `make architecture` — passed.
- `make localization-check` — passed (19 locales, 314 keys, 13 plural keys; up from 307 keys).
- `make test-domain DOMAIN=home` — TEST SUCCEEDED.
- `make automation-check` — 57 tests passed.
- `xcodebuild build -quiet -project owlory_xcode/Owlory.xcodeproj -scheme Owlory -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/owlory-localization-home-accessibility-build CODE_SIGNING_ALLOWED=NO` — BUILD SUCCEEDED.
- `git diff --check` — clean.

## Lane Boundary

`build-tested`. Swift compiles, key parity preserved, Home domain tests pass. Not running-app smoke; not screenshot/device/TestFlight. A user under a non-English locale still hears English placeholder accessibility labels, by policy.

## Residual Risk

- Non-English locales render English placeholder text for the new keys; this matches the existing translation-quality policy and is gated on the reviewer-intake workflow.
- The `%@`-format strings place the task/step title in different positions across the seven phrases. Some languages may prefer different ordering ("complete %@" in English vs "%@ als erledigt markieren" in German); translators rewrite the format string per-locale without code changes.
- I did not exercise these strings under VoiceOver. The audit and this slice only confirm the strings flow through `NSLocalizedString`; verifying the spoken output matches expectations is a manual or device-proof concern.
- Audit Groups B, C, and D remain documented in `localization-string-inventory.md` but unqueued.

## Notes For Next Slice

The remaining audit groups (B Voice/Audio button state phrases, C Train readiness scale row, D BuildInfoView label:value) are each their own scoped slice. Pick one explicitly before reopening the queue.
