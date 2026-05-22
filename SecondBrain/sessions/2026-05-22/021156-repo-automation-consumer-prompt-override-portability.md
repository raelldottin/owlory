# repo-automation-consumer-prompt-override-portability

## Prompt

> "start next slice"

Queue was empty after the additional-smoke slice. User selected `Prompt-fragment override portability` from the offered follow-up boundaries.

## What was done

Proved that a consumer can override `automation/prompts/base.md` and `automation/prompts/slice.md` and have the supervisor's `render_prompt` use the customized text. Documented the two consumer-side constraints (commit-required, re-sync-overwrites) so adopters know what they're signing up for.

### Smoke test

`test_consumer_can_override_prompt_fragments` in `RepoAutomationConsumerAdoptionSmokeTests`:

1. Bootstrap consumer, `git init`, seed example queue.
2. Rewrite `automation/prompts/slice.md` with a custom layout that keeps the `__SLICE_ID__` placeholder and appends sentinel marker `CONSUMER-SLICE-PROMPT-OVERRIDE-SENTINEL-91827`.
3. Rewrite `automation/prompts/base.md` with sentinel marker `CONSUMER-BASE-PROMPT-OVERRIDE-SENTINEL-46352`.
4. Commit the overrides (the supervisor's dirty-tree check would reject otherwise).
5. Subprocess-invoke a Python probe that imports `render_prompt`, `policy.load_queue`, `policy.select_next_slice`, and `build_context_bundle` from the consumer's tree, then calls `render_prompt` and prints the rendered text.
6. Assert: both sentinel markers appear in the output, AND Owlory's default `Owlory Supervised Slice Run` base heading does NOT appear (proves the override genuinely replaced the default text rather than being concatenated alongside it).

### Documentation

Added a `Customizing prompt fragments` subsection to `docs/workflows/repo-automation.md` covering:

- What `render_prompt` reads (`automation/prompts/base.md` + `slice.md` from the consumer's `repo_root`).
- Constraint 1: overrides must be committed before running the supervisor.
- Constraint 2: `Tools/repo-automation-sync.sh --sync` overwrites customizations because the manifest entry has `delete_stale: true`. Two workarounds named:
  1. Skip the `automation/prompts/` manifest entry locally on re-sync.
  2. Vendor prompts to a separate non-manifest-owned path (e.g., `automation/prompts.local/`) and point `render_prompt` at it via a wrapper.

The doc explicitly states the entry is shipped as a starter template, not a long-lived consumer override surface.

### Approach

- **Subprocess probe, not unittest in-process.** The probe runs in the consumer directory so `render_prompt`'s `repo_root` resolution lands on the consumer (via `Path.cwd()`). Doing this in-process from the test would mix up Owlory's `sys.modules['automation.supervisor.run_next']` with the consumer's, since the test runs under Owlory's repo root.
- **Two sentinels, not one.** Asserting both `base_marker` and `slice_marker` ensures both files are read from the consumer; if `render_prompt` were ever to fall back to Owlory's tree for either, the test catches it.
- **Negative assertion on Owlory default text.** The positive sentinel assertion would pass even if the override were appended to Owlory's default. The negative assertion (`Owlory Supervised Slice Run` not in output) confirms the override genuinely replaced the default content.
- **No source changes.** This slice is test + docs only. The manifest entry is documented as a known limitation rather than fixed; that's a separate slice if the user wants to make overrides survive re-sync.

### Files touched (6 of 6 cap)

1. `automation/tests/test_repo_automation_sync.py` — added 1 test (~75 added lines including the probe)
2. `docs/workflows/repo-automation.md` — added `Customizing prompt fragments` subsection; cross-linked from the manual-steps list
3. `automation/queue/slices.json` — slice marked done
4. `automation/handoffs/20260522T021156Z-repo-automation-consumer-prompt-override-portability.json` — handoff JSON
5. `SecondBrain/INDEX.md` — new entry
6. `SecondBrain/sessions/2026-05-22/021156-repo-automation-consumer-prompt-override-portability.md` — this file

## Validation

- `git fetch origin main` — fetched.
- `python3 automation/context/build_context.py --slice-id repo-automation-consumer-prompt-override-portability` — built.
- `python3 automation/supervisor/run_next.py --dry-run` — queue empty after this closes.
- `python3 -m unittest automation.tests.test_repo_automation_sync` — 18/18 OK (was 17).
- `make architecture` — passed.
- `make automation-check` — 119 tests OK (was 118).
- `make pyright` — 0 errors.
- `git diff --check` — clean.

## Lane Boundary

`consumer-smoke-tested`. Test + docs. No source changes. The manifest entry is documented as a limitation, not modified.

## Not Claimed

- Consumer overrides survive `--sync` — they don't, by current manifest design. The docs explicitly name this trade-off.
- `render_prompt` has been refactored for configurable prompts paths. No API change.
- `automation/prompts/review.md` has been override-tested. Only `base.md` and `slice.md` are exercised by `render_prompt`; `review.md` is loaded by a separate flow not in scope here.

## Next

Queue is empty. Remaining named boundaries (not queued by this slice):

- Workflow templates in the manifest (promotes the external repo's CI scaffold into Owlory as reusable templates).
- Real third-party repo migration (needs a user-named target).
- Generic `git command failed` smoke assertion (the 5th and final ConfigError emit site).
- Manifest fix for prompts/ override durability (set `delete_stale: false`, or remove the entry post-bootstrap).
