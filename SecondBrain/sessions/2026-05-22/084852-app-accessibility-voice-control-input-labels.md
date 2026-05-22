# app-accessibility-voice-control-input-labels

## Prompt

> "start next slice" (5th and final accessibility-survey follow-up slice)

Supervisor pick: pri 82. Covers finding S06 from `automation/proofs/app-accessibility-survey/manifest.json`. The largest blast radius of the 5 follow-ups because of the 19-locale fan-out.

## What was done

Added short verb-noun Voice Control aliases for the 5 highest-frequency commands. Introduced a new `voicecontrol.label.*` localization namespace across all 19 supported locales (95 new entries) and applied `.accessibilityInputLabels(...)` at each control site. The existing `accessibilityLabel` sentence labels remain as the fallback; the new short labels become the preferred Voice Control match.

### New keys

5 keys under `voicecontrol.label.*`:

| Key | en | de | fr | ja | zh-Hans |
| --- | --- | --- | --- | --- | --- |
| `voicecontrol.label.complete` | Complete | Erledigen | Terminer | 完了 | 完成 |
| `voicecontrol.label.skip` | Skip | Überspringen | Passer | スキップ | 跳过 |
| `voicecontrol.label.edit` | Edit | Bearbeiten | Modifier | 編集 | 编辑 |
| `voicecontrol.label.addToFocus` | Add to Focus | Zum Fokus hinzufügen | Ajouter au focus | フォーカスに追加 | 添加到专注 |
| `voicecontrol.label.startRecording` | Start recording | Aufnahme starten | Démarrer l'enregistrement | 録音開始 | 开始录音 |

Full translation table for all 19 locales lives in the handoff JSON. Localization-parity passes (19 locales × 391 keys × 13 plural keys).

### Sites with `.accessibilityInputLabels`

| File | Control | Key |
| --- | --- | --- |
| HomeView.swift | TaskRow leading complete/restore button | `voicecontrol.label.complete` |
| HomeView.swift | TaskRow edit-body button | `voicecontrol.label.edit` |
| HomeView.swift | TaskRow trailing skip button | `voicecontrol.label.skip` |
| TodayView.swift | continuePrimarySwipeActions `Add to Focus` button | `voicecontrol.label.addToFocus` |
| VoiceCaptureButton.swift | Voice capture toggle | `voicecontrol.label.startRecording` |

### Design decisions

- **`LocalizedStringKey` form.** `.accessibilityInputLabels([LocalizedStringKey("voicecontrol.label.X")])` so the short verb resolves against the user's locale at runtime. The existing accessibilityLabel + accessibilityHint chain stays intact for VoiceOver speech.
- **Real translations, not English placeholders.** A Spanish speaker saying "Complete" won't match Spanish speech recognition; the Spanish alias must be in Spanish. LLM-drafted short imperatives are reasonable starting points and the handoff explicitly names translation quality as a follow-up for native review.
- **Flat namespace.** `voicecontrol.label.*` (5 keys total) rather than per-domain. The same English verb ("Complete") applies wherever a complete action exists; no need to fork into `home.task.voicecontrol.complete` / `today.continue.voicecontrol.complete`.
- **Bulk-add via Python.** Adding 5 keys to 19 locales by hand is 95 edits; a 50-line Python script appended consistent entries with a `// MARK: - Voice Control input labels` header. Localization-parity then verified.

### Approach

- **One key per command, not arrays.** `.accessibilityInputLabels` accepts an array of aliases (e.g., `["Complete", "Mark complete", "Done"]`), but introducing 5 × N-alias keys × 19 locales would have multiplied translation effort. One key per command — the most common verb — covers the highest-frequency case; future polish can grow each command's alias list.
- **Preserve existing accessibilityLabel.** Voice Control still falls back to the full sentence label ("Mark Wash dishes complete") for users who say the full phrase. The new short alias takes precedence when it matches.

### Files touched (26 of 30 cap)

- 19 `*.lproj/Localizable.strings` files — 5 new entries each
- 3 Swift files (HomeView, TodayView, VoiceCaptureButton)
- 4 slice-metadata files (queue, handoff, INDEX, session)

## Validation

- `git fetch origin main` — fetched.
- `xcodebuild build` — exit 0, no errors.
- `python3 automation/context/build_context.py --slice-id app-accessibility-voice-control-input-labels` — built.
- `make architecture` — passed.
- `make automation-check` — 124 tests OK.
- `make localization-check` — **19 locales, 391 keys, 13 plural keys (parity passes)**.
- `make pyright` — 0 errors.
- `git diff --check` — clean.
- Manual smoke: app launches on iPhone 17 Pro Max sim (PID 66427) — no init-time crash.

## Lane Boundary

`build-tested`. 19 locale string files + 3 Swift files + queue/handoff/INDEX/session. No project-file entries (existing files only).

## Not Claimed

- All 19 locale translations are native-quality. Russian / Korean / Japanese / Vietnamese / Arabic translations are LLM-drafted and should be classified by the existing `Tools/localization-review-status.py` workflow before being marked `native-reviewed`.
- On-device Voice Control matching has been verified. The proof level is `build-tested` + simulator launch.
- Every actionable button in Owlory has a Voice Control alias. Only the 5 highest-frequency commands from S06 are covered.

## Next

**All 5 accessibility-survey follow-up slices are now done:**

| pri | slice | status |
| ---:| --- | --- |
| 76 | app-accessibility-swipe-actions-as-accessibility-actions | done |
| 77 | app-accessibility-reduce-motion-helper | done |
| 78 | app-accessibility-haptic-feedback | done |
| 80 | app-accessibility-reduce-transparency-and-contrast | done |
| 82 | app-accessibility-voice-control-input-labels | done |

Queue is now empty. Natural follow-up boundaries (none queued):

- On-device VoiceOver + Switch Control + Voice Control verification (real-device proof for the rotor entries, haptics, reduce-motion / reduce-transparency / increase-contrast behaviors, and Voice Control short aliases).
- Localization translation-quality classification re-run to label the 95 new entries.
- Extend `.accessibilityInputLabels` to lower-frequency commands (Defer, Drop, Archive, Restore, Abandon, Mark Pending).
- Audit lower-priority M06 sites (decorative .opacity(0.8) tints) if a future review shows they reduce legibility in any locale.
