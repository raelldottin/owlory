# repo-automation-template-first-time-only-sync

## Prompt

> "start next slice"

Queue was empty after the prompt-override portability slice (which documented a trade-off: `--sync` overwrote consumer prompt customizations because `delete_stale: true` was set on the manifest entry). User selected `Manifest prompts/ override durability` from the offered follow-up boundaries to close that trade-off.

## What was done

Discovered during inspection that simply flipping `delete_stale: true → false` would NOT preserve customized `base.md` / `slice.md` content, because `Tools/repo-automation-sync.sh:sync_entries` always overwrites source-matched destination files via `shutil.copyfile` regardless of `delete_stale`. The flag only controls extra-file removal. So the correct fix is to give the manifest's existing `template: true` flag a real sync semantic: when an entry is template-managed and the destination already exists, skip both the copy and any stale removal.

### Sync tool change

Two small edits in `Tools/repo-automation-sync.sh`:

1. **Per-file copy guard.** In `sync_entries`, before the existing drift check, added:

   ```python
   if entry.template and target.exists():
       continue
   ```

   This makes template entries first-time-only on a per-file basis. The directory containing the template can still receive new files from the source (any new file Owlory adds is copied because its destination doesn't exist yet), but existing files are left alone.

2. **Stale removal guard.** `stale_files()` now returns `[]` for template entries unconditionally:

   ```python
   if entry.kind != "directory" or not entry.delete_stale or entry.template:
       return []
   ```

   This prevents the cleanup pass from removing consumer-added files in template directories even if `delete_stale: true` is still set on a template entry.

### Manifest changes

Flipped `delete_stale: true → false` on the two directory template entries (`automation/prompts/` and `automation/examples/`) for clarity. Under the new code path the flag is moot for template entries, but the manifest now correctly describes intent: template entries don't manage extra files.

### Test additions

Added to `RepoAutomationConsumerAdoptionSmokeTests`:

- `test_consumer_prompt_override_survives_resync` — writes a sentinel into `automation/prompts/base.md`, commits, runs `--sync`, asserts the sentinel still appears.
- `test_consumer_added_prompt_file_survives_resync` — writes `automation/prompts/consumer-custom.md` with known content, commits, runs `--sync`, asserts the file and its content remain.

File now has 20 tests (was 18). Full automation-check goes from 119 to 121.

### Doc rewrite

The `Customizing prompt fragments` section in `docs/workflows/repo-automation.md` (added by the prior slice) was rewritten:

- The two workaround paths previously documented (skip the manifest entry locally, or vendor prompts to a non-manifest-owned path) are removed.
- Replaced with a clear statement that overrides survive re-sync, and a third bullet documenting the unavoidable trade-off: Owlory updates to template files no longer auto-propagate.

### Approach

- **Investigate before implementing.** Confirmed by reading `sync_entries` that `delete_stale: false` alone doesn't solve override durability — `shutil.copyfile` runs unconditionally. The slice description was based on a misunderstanding of the sync semantics; the implementation pivoted to the correct fix.
- **Reuse the existing `template` flag.** Rather than introducing a new flag, gave the existing documentation-only `template: true` a real sync semantic. This is a tighter change and matches the existing intuition (templates are starter content, not authoritative source).
- **Update three template entries consistently.** The flag affects `automation/prompts/`, `automation/examples/`, and `pyrightconfig.json`. All three now have first-time-only semantics; the smoke test focuses on prompts but the same code path covers all three.
- **Acknowledge the new trade-off.** With overrides preserved, Owlory updates to template files don't reach consumers automatically. The doc names this explicitly.

### Files touched (8 of 10 cap)

1. `Tools/repo-automation-sync.sh` — added template-existence guard in `sync_entries`; added template guard in `stale_files`
2. `automation/reusable-manifest.json` — flipped `delete_stale` to `false` on prompts/ and examples/ entries
3. `automation/tests/test_repo_automation_sync.py` — added 2 override-durability tests (~60 added lines)
4. `docs/workflows/repo-automation.md` — rewrote `Customizing prompt fragments` to describe new semantics
5. `automation/queue/slices.json` — slice marked done
6. `automation/handoffs/20260522T022048Z-repo-automation-template-first-time-only-sync.json` — handoff JSON
7. `SecondBrain/INDEX.md` — new entry
8. `SecondBrain/sessions/2026-05-22/022048-repo-automation-template-first-time-only-sync.md` — this file

## Validation

- `git fetch origin main` — fetched.
- `python3 automation/context/build_context.py --slice-id repo-automation-template-first-time-only-sync` — built.
- `python3 automation/supervisor/run_next.py --dry-run` — queue empty after this closes.
- `python3 -m unittest automation.tests.test_repo_automation_sync` — 20/20 OK (was 18).
- `make architecture` — passed.
- `make automation-check` — 121 tests OK (was 119).
- `make pyright` — 0 errors.
- `git diff --check` — clean.
- JSON validity (queue + handoff) — OK.

## Lane Boundary

`consumer-smoke-tested`. Source change (sync tool), manifest change, tests, docs. Behavior change is opt-in by virtue of the existing `template: true` flag — non-template entries continue to behave exactly as before.

## Not Claimed

- Every template-flagged entry is equally well-protected. Code path covers all three (`prompts/`, `examples/`, `pyrightconfig.json`); the smoke test focuses on `prompts/`. The other two are presumed safe by the same code path but not directly asserted.
- Consumers who had already lost overrides under the old behavior automatically regain them. They need to re-establish their customizations once.
- Owlory updates to template files propagate to existing consumers. They don't — the trade-off is documented and intentional.

## Next

Queue is empty. Remaining named boundaries (not queued by this slice):

- Workflow templates in the manifest (promotes the external repo's CI scaffold into Owlory as reusable templates).
- Real third-party repo migration (needs a user-named target).
- Generic `git command failed` smoke assertion (the 5th and final ConfigError emit site).
