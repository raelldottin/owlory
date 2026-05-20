# queue-robinhood-followup-slices

## Prompt

> "add all optional follow up slices: 1. app-content-standards-integrated-reference — single content+design reference 2. app-error-message-audit — inventory lastError surfaces for vague exception messages 3. app-design-vision-metaphor-adr — name the Today/Continue/Patterns/Train throughline as an ADR"

Follow-up to commit `acd6903` (Robinhood newsroom design research). The research manifest listed these 3 candidates as recommended-not-queued.

## What was done

Queue-only update. Appended 3 follow-up slices to `automation/queue/slices.json`. No source/test/UI/translation changes.

### Queued

| Slice ID | Pri | Domain | Reference |
|---|---:|---|---|
| `app-content-standards-integrated-reference` | 70 | design | Robinhood article #3 |
| `app-error-message-audit` | 75 | design | Robinhood article #3 anti-pattern |
| `app-design-vision-metaphor-adr` | 85 | design | Robinhood article #5 |

### Priority rationale

Lower pri = picked first in Owlory's supervisor selection. The ordering reflects expected value-per-effort:

- **pri 70** — content-standards reference is the most actionable Robinhood finding. CTA capitalization, error phrasing, header punctuation, and component-to-content-type mapping each have a direct payoff: less decision overhead for new surfaces, less translation drift across 19 locales.
- **pri 75** — error-message audit produces a manifest + may queue narrower fix slices. Audit-only, no copy changes in the slice itself.
- **pri 85** — design-vision ADR is the most discretionary. Owlory's throughline (Today / Continue / Patterns / Train) is already implicit; the ADR formalizes it so future surfaces can be measured against it. Project owner may decide the throughline is already obvious and cancel this slice.

### Explicit non-scope (captured in each slice's notes)

- **content-standards reference**: do NOT change copy, do NOT add localization keys, do NOT rewrite localization-translation-quality.md (cross-link instead).
- **error-message audit**: do NOT fix copy in the audit slice; produce a manifest + queue narrow per-store fix slices for the gaps.
- **design-vision ADR**: do NOT prescribe specific UI changes; name the throughline only. Keep ADR under 200 lines.

### Dependencies

All three depend on `app-design-research-robinhood-newsroom-lessons` (done at `acd6903`). Each is independently runnable; no inter-slice dependency among the three.

## Validation

- `python3 -m json.tool automation/queue/slices.json` — valid.
- `make automation-check` — drift `no drift` + 93 unittests OK.
- `python3 automation/supervisor/run_next.py --dry-run` — picks `app-content-standards-integrated-reference` (pri 70, lowest among newly queued).

## Lane Boundary

`doc-only`. Queue records + this session note + INDEX. No code/test/UI/translation change.

## Not Claimed

- The 3 slices will be run automatically (the project owner / supervisor decides).
- Any of these slices, when run, will result in source/UI changes (each is doc-only or audit-only).
- The throughline naming in the design-vision ADR is settled (the slice's own scope says "working hypothesis" and the project owner can override).

## Next

Per Owlory's lower-pri-first selection, `start next slice` will pick `app-content-standards-integrated-reference` (pri 70) next.
