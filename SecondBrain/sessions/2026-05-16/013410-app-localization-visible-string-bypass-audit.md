# app-localization-visible-string-bypass-audit

## Prompt

User asked for a full NLS/localization bypass audit. Audit-first: catalog visible-string call-site bypasses, classify them, queue narrow follow-up implementation slices. Do not fix strings in this slice. Constraints: no native-review claim, no broad copy rewrite, no domain/persistence changes, no parity weakening, no combined surfaces.

## Method

Wrote `/tmp/owlory_localization_audit.py` — a static scanner that runs ~20 regex patterns across every `*.swift` file under `owlory_xcode/Owlory/` and `owlory_xcode/OwloryWidgets/` and cross-references each captured literal against the 316 keys in `owlory_xcode/Owlory/Resources/en.lproj/Localizable.strings`.

Patterns scanned (literal + variable forms where applicable):

- `Text("...")` / `Text(varString)`
- `Label("...", systemImage:)` / `Label("...", image:)` / `Label(varString, systemImage:)`
- `Button("...")` / `Button(varString)`
- `Section("...")`
- `.navigationTitle("...")` / `.navigationTitle(varString)`
- `.accessibilityLabel/Hint/Value("..." or varString)`
- `TextField("...")`
- `LabeledContent("...")`
- `.alert("...")`
- `.confirmationDialog("...")`
- `Picker/Toggle/Stepper/DisclosureGroup("...")`

Classifier: 9 categories mapped to 3 tiers (`must-fix`, `should-fix`, `low/ok`). Initial `bypass-string-var` was refined into three sub-classes via substring heuristics:

- `ok-user-content` — variables like `note.title`, `task.notes`, `transcription`. Correctly not localized.
- `ok-localized-display-helper` — variables like `stage.localizedDisplayName`, `readinessSummaryLabel`, `nudge.message`. Already localized upstream.
- `bypass-string-var-true` — everything else; visible English may slip through.

Then wrote `/tmp/owlory_make_audit_doc.py` to render the final markdown audit document with per-classification, per-surface, and per-finding tables plus recommended follow-up slices.

## Numbers (2026-05-16)

| Tier | Count |
|---|---:|
| must-fix | 116 |
| should-fix | 37 |
| low/ok | 247 |
| **Total findings** | **400** |

| Classification | Count | Tier |
|---|---:|---|
| `bypass-string-var-true` | (subset of 95 var-cases) | must-fix |
| `bypass-section-literal` | 31 | must-fix |
| `bypass-label-literal` | 60 | must-fix |
| `missing-key` | 17 | must-fix |
| `bypass-button-literal-suspect` | 37 | should-fix |
| `ok-literal-text` | 72 | low/ok |
| `ok-literal-navtitle` | 19 | low/ok |
| `ok-accessibility-literal` | 10 | low/ok |
| `ok-other-literal` | 50 | low/ok |
| `ok-user-content` + `ok-localized-display-helper` | ~95 | low/ok |
| `intentional-english` | 8 | low/ok |
| `debug-internal` | 1 | low/ok |

| Surface | Total | must-fix | should-fix |
|---|---:|---:|---:|
| Today | 145 | 73 | 9 |
| Home | 95 | 54 | 9 |
| Write | 77 | 31 | 12 |
| Train | 45 | 19 | 3 |
| Career | 28 | 13 | 4 |
| Root/Tabs | 5 | 5 | 0 |
| Widgets | 3 | 3 | 0 |
| DesignSystem | 2 | 2 | 0 |

## Files Edited

- `docs/workflows/localization-visible-string-audit.md` — **new file**. The catalog document.
- `docs/workflows/localization-string-inventory.md` — added a 2026-05-16 cross-reference note explaining the difference between key-existence audit and call-site routing audit.
- `docs/workflows/localization-dynamic-formatting.md` — added a 2026-05-16 cross-reference note about the ~12 interpolated-copy sites flagged for `app-localization-string-interpolation-formatters`.
- `docs/workflows/roadmap-status.md` — updated Localization row to include the LQA, dashboard, and audit artifacts plus the queued follow-ups.
- `automation/queue/slices.json` — flipped `app-localization-visible-string-bypass-audit` to `done`; queued 10 follow-up slices.
- `automation/handoffs/20260516T013410Z-app-localization-visible-string-bypass-audit.json` — new handoff.
- `SecondBrain/INDEX.md` — index entry.
- `SecondBrain/sessions/2026-05-16/013410-app-localization-visible-string-bypass-audit.md` — this note.

## Follow-up slices queued

| Priority | Slice | Surface | Must-fix |
|---:|---|---|---:|
| 100 | `app-localization-today-shell-copy-routing` | Today / DigestDetail / DigestList / BuildInfo | 73 |
| 99 | `app-localization-home-shell-copy-routing` | Home | 54 |
| 98 | `app-localization-write-shell-copy-routing` | Write | 31 |
| 97 | `app-localization-train-shell-copy-routing-followup` | Train (remaining beyond 2dfd2d0) | 19 |
| 96 | `app-localization-career-shell-copy-routing` | Career | 13 |
| 95 | `app-localization-root-tab-shell-labels` | RootTabView | 5 |
| 94 | `app-localization-widget-shell-strings` | Widgets | 3 |
| 93 | `app-localization-string-interpolation-formatters` | Cross-cutting interpolation patterns | ~12 |
| 92 | `app-localization-button-literal-verify` | Button literals (audit-then-fix) | 37 suspect |
| 91 | `app-localization-accessibility-bypass-audit` | Accessibility var-bypasses | ~10 |

All depend on this audit slice. Each has narrow `allowed_paths` to its own surface only. No surface is combined with another.

## Validation

- `python3 automation/context/build_context.py --slice-id app-localization-visible-string-bypass-audit` — exit 0.
- `python3 automation/supervisor/run_next.py --dry-run` — selected this slice at start; post-completion picks `app-localization-today-shell-copy-routing` (with expected stop-on-dirty until the audit work commits).
- `make architecture` — passed.
- `make localization-check` — 19 / 316 / 13.
- `./Tools/validate.sh localization` — passed.
- `make automation-check` — 57/57.
- `git diff --check` — clean.

## Lane Boundary

`doc-only`. The audit is a static catalog and a queue. No app resources, view code, return files, dashboard tools, or domain code were modified. No claim about whether translations are correct, native, or screenshot-verified.

## Residual Risk

(See handoff JSON `residual_risks` for the full list.)

- Static heuristic may misclassify some `bypass-label-literal` findings that DO localize on iOS 17. Each per-surface fix slice should verify behavior before mass-converting.
- The `Text("Focus lives in Continue. ...")` Today footer was classified `ok-literal-text` per the audit rules; the user-reported observation that it doesn't translate is unexplained and may indicate a deeper SwiftUI quirk requiring its own investigation slice if reproduced.
- Native review is NOT touched by this work. `app-localization-native-review-intake` remains blocked.

## Multi-agent note

The 10 follow-up slices have non-overlapping `allowed_paths` (each scoped to one Feature directory or one cross-cutting concern). Two agents could parallel-work on Today and Home shell-routing safely, but should serialize on slices.json + Localizable.strings updates if new keys are added.
