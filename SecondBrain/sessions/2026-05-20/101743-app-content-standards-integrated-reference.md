# app-content-standards-integrated-reference

## Prompt

> "start next slice"

Supervisor pick under lower-pri-first selection: `app-content-standards-integrated-reference` (pri 70) — the most actionable of the 3 Robinhood-derived follow-ups queued at commit `9c9373a`.

## What was done

Wrote a single integrated content + design reference at `docs/workflows/content-standards.md`. Pairs visible-component choice with copy shape, so future surfaces have one place to look.

### Content covered

1. **CTA capitalization** — observed Title Case for buttons + verb-first / verb+article+noun shapes, grounded in shipped `en.lproj/Localizable.strings`.
2. **Error message phrasing** — required shape: localized via `L()`, resolution-guided, sentence case with period, key namespace `<domain>.error.<situation>`. Names the current gap (uniform `"Failed to <verb> <noun>: \(error.localizedDescription)"` template across `TrainStore`, `WriteStore`, `HomeStore`, `CareerStore`, `TodayStore`, `PatternStore`) without fixing it — the queued `app-error-message-audit` slice handles that.
3. **Header / section-label punctuation** — no terminal punctuation on labels; periods only on full sentences; question marks on interrogative prompts; parenthetical "(optional)" markers.
4. **Component-to-content-type mapping** — Button / Label / Section / Text / .navigationTitle / TextField / .alert / .confirmationDialog / .accessibilityLabel / .accessibilityHint / Continue-row-subtitle / weekly-digest-insight. Each row names use case, copy shape, capitalization, and terminal punctuation.
5. **L() key-naming** — cross-linked to `localization-string-inventory.md` rather than duplicating.

### Approach

- **Observed > prescribed.** The doc describes patterns visible in the shipped `en.lproj/Localizable.strings` and SwiftUI usage in `owlory_xcode/Owlory/Features/`. Where a convention is observed-but-inconsistent, the doc names it as a gap and points at the appropriate audit slice rather than imposing a new rule.
- **Cross-link, don't duplicate.** Translation quality, HIG completion, key-naming, dynamic formatting, and visible-string-bypass conventions all live in their own docs already. The new reference links to each.
- **Honest gap call-out.** The current `lastError` templates do not match the documented error-shape requirement. The doc says so explicitly, rather than pretending the convention is already met.

### Files touched (6 of 6 cap)

1. `docs/workflows/content-standards.md` — new reference (~210 lines)
2. `docs/README.md` — added link under localization workflow links
3. `automation/queue/slices.json` — slice marked done
4. `automation/handoffs/20260520T101743Z-app-content-standards-integrated-reference.json` — handoff JSON
5. `SecondBrain/INDEX.md` — new entry
6. `SecondBrain/sessions/2026-05-20/101743-app-content-standards-integrated-reference.md` — this file

## Validation

- `python3 automation/context/build_context.py --slice-id app-content-standards-integrated-reference` — built.
- `python3 automation/supervisor/run_next.py --dry-run` — picks `app-error-message-audit` as next (pri 75).
- `make architecture` — passed.
- `make localization-check` — passed (19 locales, 377 keys, 13 plural keys).
- `make automation-check` — drift no-drift + 93 unittests OK.
- `git diff --check` — clean.

## Lane Boundary

`doc-only`. Reference doc + cross-link + queue/handoff/INDEX. No code, test, copy, or translation change. The `lastError` template gap is **named, not fixed** — the audit slice handles fixes.

## Not Claimed

- Existing copy was rewritten to match the conventions (it wasn't; the doc describes observed practice).
- The error-template gap is fixed (it isn't; the audit slice is queued at pri 75 to handle inventory + fix slices).
- The component-to-content-type mapping is exhaustive (it covers components used in current Owlory views, not every SwiftUI component).
- Non-English locales follow English Title Case (the doc explicitly states locale-specific capitalization rules apply).

## Next

Supervisor's next pick under lower-pri-first selection is `app-error-message-audit` (pri 75) — also a Robinhood follow-up, and the natural complement to this reference (audits the error-template gap this doc named).
