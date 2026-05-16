# app-localization-string-interpolation-formatters

## Prompt

> "start app-localization-string-interpolation-formatters" — source-by-source formatter pass for interpolated user-facing copy. Do not regex-wrap. Do not localize debug/service errors. Do not touch unrelated UI copy. Do not claim native review.

## What was done

Inspected every interpolated visible-string site flagged by the prior two audits. Classified into:

| Category | Sites | Action |
|---|---:|---|
| Real product copy with English fragments | 8 | Wire through formatter (this slice) |
| Pure-number / count / value | 5 | Leave as-is |
| Developer field | 1 | Leave as-is (BuildInfoView) |
| TextField placeholder already-routing | 2 | Leave as-is (HomeView "Step 1\nStep 2\nStep 3") |
| Service-layer error string | 2 | Leave as-is (AudioPlayerService inner messages) |

### 8 sites rewritten

| File:Line | Before | After (key) |
|---|---|---|
| `TodayView.swift:523` | `Text("Next: \(next.plannedActivity)")` | `today.preview.next` (`"Next: %@"`) |
| `TodayView.swift:562` | `Text("Next: \(latest.title)")` | `today.preview.next` (reuse) |
| `TodayView.swift:634` | `Text("Active protocol: \(nextRun.protocolTitle)")` | `today.preview.home.activeProtocol` (`"Active protocol: %@"`) |
| `TodayView.swift:639` | `Text("Next task: \(next.title)")` | `today.preview.home.nextTask` (`"Next task: %@"`) |
| `HomeView.swift:378` | `Text("\(run.completedStepCount)/\(run.totalStepCount) completed")` | `home.protocol.run.progress.completed` (`"%1$d/%2$d completed"`) |
| `HomeView.swift:1115` | `Text("\(currentRun.resolvedStepCount) of \(currentRun.totalStepCount)")` | `home.protocol.run.progress.summary` (`"%1$d of %2$d"`) |
| `TrainView.swift:512` (per-button accessibility) | `.accessibilityLabel("\(label) \(level) of 5\(level == value ? ", selected" : "")")` | Reuses existing `today.readiness.scale.accessibility` / `.selected` stringsdict via new private helper `trainingReadinessScaleAccessibilityLabel(level:isSelected:)` |
| `TrainView.swift:516` (container accessibility) | `.accessibilityLabel("\(label), \(value) of 5")` | Same helper. Note: comma is dropped to match the existing stringsdict format (`%@ %d of 5`). |

### 6 new keys added × 19 locales

```
today.preview.next                       = "Next: %@"
today.preview.home.activeProtocol        = "Active protocol: %@"
today.preview.home.nextTask              = "Next task: %@"
home.protocol.run.progress.completed     = "%1$d/%2$d completed"
home.protocol.steps.placeholder          = "Step 1\nStep 2\nStep 3"        [reserved, not yet wired]
home.protocol.run.progress.summary       = "%1$d of %2$d"
```

LLM-drafted translations (claude-opus-4-7), not native-reviewed.

### Sites intentionally not changed

| File:Line | Reason |
|---|---|
| `TodayView.swift:395` `Text("\(staleDayCount)d")` | Compact day suffix, not English copy |
| `TodayView.swift:909` `\(store.recentEntries.count)` | Pure number |
| `TodayView.swift:1304` `Label("\(entry.focusThree.count)", systemImage:)` | Pure number |
| `TrainView.swift:517` `.accessibilityValue("\(value)")` | Pure number (VoiceOver value, not label) |
| `WriteView.swift:195` `Text("\((store.notesByStage[stage] ?? []).count)")` | Pure number |
| `BuildInfoView.swift:102` `"\(label): \(value)"` | Developer field |
| `HomeView.swift:807, 907` `TextField("Step 1\nStep 2\nStep 3", text:..., axis: ...)` | Already-routing through existing literal-key (`"Step 1\nStep 2\nStep 3"` key exists in Localizable.strings) |

### Files Edited

- `owlory_xcode/Owlory/Features/Today/TodayView.swift` — 4 Text sites
- `owlory_xcode/Owlory/Features/Home/HomeView.swift` — 2 Text sites
- `owlory_xcode/Owlory/Features/Train/TrainView.swift` — 2 accessibilityLabel sites + new private helper
- 19 × `Localizable.strings` — 6 new keys appended in each (102 new entries across all locales, after deduplication for keys that were idempotent)
- `automation/queue/slices.json` — slice flipped `queued` → `done`
- `automation/handoffs/20260516T182802Z-app-localization-string-interpolation-formatters.json` — new handoff
- `SecondBrain/INDEX.md` — index entry
- `SecondBrain/sessions/2026-05-16/182802-app-localization-string-interpolation-formatters.md` — this note

## Validation

- `make architecture` — passed.
- `make localization-check` — **19 locales / 330 keys / 13 plural keys** (up from 324; +6 new keys).
- `./Tools/validate.sh localization` — passed.
- `make test-domain DOMAIN=today` — passed.
- `make test-domain DOMAIN=home` — passed.
- `make automation-check` — 57/57.
- `xcodebuild build -quiet -destination 'generic/platform=iOS Simulator'` — exit 0.
- `git diff --check` — clean.

## Lane Boundary

`build-tested`. Compile is clean, parity holds, domain tests pass. No view structural changes — only call-site copy routing. No native-review claim.

## Translation honesty

All 6 new keys are LLM-drafted, not native-reviewed. The Train accessibility helper reuses the existing `today.readiness.scale.accessibility` keys (LLM-drafted too) — those keys are also unreviewed. Native review remains outstanding for every locale. `app-localization-native-review-intake` is still blocked.

## Cross-feature coupling note

TrainView now imports the today.* stringsdict accessibility format keys. If `today.readiness.scale.accessibility` / `.selected` are renamed, both Today's readinessScaleAccessibilityLabel and Train's trainingReadinessScaleAccessibilityLabel break. The cross-feature dependency is intentional to avoid duplicating a stringsdict, but worth noting for future renames.

## RTL/CJK considerations

The new keys use positional `%1$d/%2$d` where two integers appear together (progress strings). This allows per-language reordering of numerals — but Arabic and other RTL languages may still want to verify visual order with on-device VoiceOver. Out of scope; needs native review pass.

## What remains on the NLS roadmap

| Track | Status |
|---|---|
| Section / Label / Button literal routing | ✅ `31fd012` |
| Accessibility var bypasses | ✅ `dde9115` |
| Interpolated copy formatters | ✅ this commit |
| Inner AudioPlayerService error strings | ⏸ deferred (not user-facing UI directly) |
| Compact `d` day suffix on stale counter | ⏸ deferred (minor) |
| Per-locale review return file refresh | ⏸ optional housekeeping |
| Native review for any locale | 🚫 `app-localization-native-review-intake` still blocked |
