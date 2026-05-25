# localization-review-drift-risk-fix

User prompt: "fix remaining risk"

## Interpretation

The remaining risk from the prior clean-stop handoff was Owlory `make automation-check` failing because the per-locale localization review return files were missing the five `voicecontrol.label.*` keys added by `app-accessibility-voice-control-input-labels`.

## Work

- Reproduced the failure with `make automation-check`; `Tools/localization-review-drift-check.py --check` reported 18 locales with five missing `voicecontrol.label.*` rows each.
- Regenerated the localization review export packet and German review packet.
- Ran `Tools/localization-return-files-refresh.py --apply` to append the five Voice Control review-return rows for all 18 non-English locales.
- Refreshed LQA and review status docs.
- Corrected the new post-review rows to use `Codex automated draft (not native/fluent reviewer)`, with `native_review.accepted=false`, because these keys were added after the 2026-05-18 native/fluent review pass.
- Updated `Tools/localization-return-files-refresh.py` so future post-native-review additions use automated-draft reviewer provenance and explicit pending native-review metadata.
- Removed the extra generated blank line at EOF in `localization/review/LQA.md` by tightening `Tools/localization-lqa.py`.
- Reworded stale LQA/status tool text so native-review state is read from return-file metadata instead of implying every locale remains unreviewed.

## Files

- `Tools/localization-return-files-refresh.py`
- `Tools/localization-lqa.py`
- `Tools/localization-review-status.py`
- `localization/review/translation-review-export.*`
- `localization/review/de/german-review-packet.*`
- `localization/review/*/*-review-return.json`
- `localization/review/LQA.md`
- `localization/review/STATUS.md`

## Validation

- `python3 Tools/localization-review-drift-check.py --check` passed with 0 drift.
- `make localization-check` passed.
- `make architecture` passed.
- `make automation-check` passed: Pyright, drift check, and 126 automation tests.
- `python3 Tools/localization-return-files-refresh.py` reported +0 strings / +0 plurals for all 18 locales after the refresh.
- `git diff --check` passed after the LQA EOF fix.

## Outcome

The automation-check localization drift risk is closed. The five Voice Control rows are tracked in all locale return files as pending post-review additions, not as native-reviewed entries.
