# repo-automation-sync-force-templates-flag

## Prompt

> "start next slice"

Queue was empty after the corrupt-git ConfigError smoke slice. User selected `Sync tool --force-templates flag` from the offered boundaries — the natural companion to the first-time-only-template semantic added two slices ago, giving consumers a controlled way to opt back into upstream content when they want it.

## What was done

Added `--force-templates` to `Tools/repo-automation-sync.sh` so consumers can deliberately re-baseline template entries (prompts/, examples/, pyrightconfig.json) to current Owlory source content. The flag intentionally does NOT remove consumer-added files in template directories; only the source-named template files are overwritten.

### Implementation

1. **Argparse.** New `parser.add_argument("--force-templates", action="store_true", ...)` with help text naming the trade-off (overwrites overrides, preserves added files).

2. **Plumbing through main().** All three sync_entries call sites in main (auto-update sync, auto-update verify, default sync/check) now pass `force_templates=args.force_templates`.

3. **sync_entries signature.** New keyword-only `force_templates: bool = False` parameter.

4. **First-time-only guard, updated.** The check inside the per-file copy loop changes from
   `if entry.template and target.exists(): continue`
   to
   `if entry.template and target.exists() and not force_templates: continue`.
   When force_templates is True, the loop falls through to the existing drift detection and copy paths, which overwrite the destination with source content.

5. **Stale-file removal.** `stale_files()` is unchanged. Template entries continue to return `[]` regardless of the force flag, so consumer-added files in template directories survive. This is intentional and documented.

### Test additions

`RepoAutomationConsumerAdoptionSmokeTests` grows by 2:

- **`test_force_templates_overwrites_consumer_override`** — writes a sentinel into `base.md`, commits, runs `--sync` (asserts override preserved by the existing first-time-only semantic), then runs `--sync --force-templates` and asserts the override is replaced with the Owlory source `base.md` byte-for-byte.

- **`test_force_templates_preserves_consumer_added_files`** — writes a known-content `automation/prompts/consumer-only.md`, commits, runs `--sync --force-templates`, asserts the file and its content both remain.

Test count: file 21 → 23; automation-check 122 → 124.

### Docs

Updated `Customizing prompt fragments` in `docs/workflows/repo-automation.md` to describe `--force-templates`, the exact command, what it overwrites, and the deliberate non-removal of consumer-added files. Cross-linked to the two new tests.

### Approach

- **Minimal flag surface.** Added one argparse argument and one keyword parameter; existing call sites changed only to pass the flag through. No behavior change unless `--force-templates` is explicitly passed.
- **Preserve the "added files survive" guarantee.** Stale-file removal stays disabled for template entries even under `--force-templates`. The flag is for re-baselining named templates, not for wiping a directory. Documented and asserted.
- **Source-byte-equality check.** The override test asserts `rebaseline == owlory_base_text` rather than just checking that the sentinel is gone. That guards against a future change that, e.g., merges instead of overwrites.

### Files touched (7 of 8 cap)

1. `Tools/repo-automation-sync.sh` — added flag, plumbed through sync_entries
2. `automation/tests/test_repo_automation_sync.py` — added 2 tests (~75 added lines)
3. `docs/workflows/repo-automation.md` — added flag description + command + cross-link
4. `automation/queue/slices.json` — slice marked done
5. `automation/handoffs/20260522T060420Z-repo-automation-sync-force-templates-flag.json` — handoff JSON
6. `SecondBrain/INDEX.md` — new entry
7. `SecondBrain/sessions/2026-05-22/060420-repo-automation-sync-force-templates-flag.md` — this file

## Validation

- `git fetch origin main` — fetched.
- `python3 automation/context/build_context.py --slice-id repo-automation-sync-force-templates-flag` — built.
- `python3 automation/supervisor/run_next.py --dry-run` — queue empty after this closes.
- `python3 -m unittest automation.tests.test_repo_automation_sync` — 23/23 OK.
- `make architecture` — passed.
- `make automation-check` — 124 tests OK.
- `make pyright` — 0 errors.
- `git diff --check` — clean.

## Lane Boundary

`consumer-smoke-tested`. Source (sync tool), tests, docs. No manifest change.

## Not Claimed

- Every template-flagged entry has been smoke-tested under `--force-templates`. Smoke focuses on `prompts/`. `examples/` and `pyrightconfig.json` go through the same code path so are presumed safe.
- The flag has been smoke-tested under `--auto-update` and `--check`. Only `--sync` is asserted; the other modes go through the same plumbing.

## Next

Queue empty. Remaining named boundaries (not queued):

- Workflow templates in manifest (promotes external CI scaffold into Owlory as reusable templates).
- Real third-party repo migration (needs a user-named target).
- Template-update-detection notice (proactively warn when an upstream template file has changed even though the local copy is preserved).
