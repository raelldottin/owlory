# app-design-vision-metaphor-adr

## Prompt

User asked to start the next slice; supervisor selected `app-design-vision-metaphor-adr`.

## What Changed

Doc-only ADR slice. Added `docs/decisions/0002-design-vision-metaphor.md` to name Owlory's cross-surface design throughline as **quiet daily momentum**.

The ADR frames the throughline as a review lens rather than a UI prescription:

- Today narrows attention to the focus three and readiness band.
- Continue returns the user to work already in motion.
- Patterns turns accumulated behavior into weekly insight.
- Train keeps consistency more important than intensity.

It references the Robinhood Retirement research lesson about using a single coherent metaphor across product surfaces, while explicitly rejecting Robinhood's financial "perpetual motion machines" metaphor as non-portable to Owlory.

## Validation

- `python3 automation/context/build_context.py --slice-id app-design-vision-metaphor-adr` - passed.
- `python3 automation/supervisor/run_next.py --dry-run` - selected this slice pre-implementation.
- `make architecture` - passed.
- `make automation-check` - passed (pyright 0 errors / 0 warnings; review drift 0; 93 automation tests).
- `git diff --check` - passed.

## Not Claimed

- No UI, copy, asset, localization, motion, or app-code changes.
- No specific component redesigns.
- No claim that Robinhood's fintech metaphor applies directly to Owlory.

## Next

Commit, push, and confirm the supervisor clean-stop/next-slice state.
