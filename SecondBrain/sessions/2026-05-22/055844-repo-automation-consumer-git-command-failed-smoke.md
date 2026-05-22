# repo-automation-consumer-git-command-failed-smoke

## Prompt

> "start next slice"

Queue was empty after the template-first-time-only-sync slice. User selected `Generic git-command-failed smoke` from the offered follow-up boundaries — the smallest remaining piece that closes ConfigError smoke coverage to 5/5 emit sites.

## What was done

Added one test that exercises the 5th and final ConfigError emit site in `automation/supervisor/policy.py:git_dirty_paths` — the generic `git command failed in <repo_root>` branch that fires when the `.git/` directory exists but `git diff --name-only --relative` fails for any reason.

### Probe of corruption shape

A scratch git repo with `.git/HEAD` overwritten by `garbage-not-a-valid-ref\n` produces:

- `git diff --name-only --relative` exits 129
- stderr begins `warning: Not a git repository. Use --no-index ...`
- `.git/` directory persists (only `HEAD` was modified)

That hits exactly the code path I needed: `subprocess.CalledProcessError` raised, `(repo_root / ".git").exists()` returns True, so the else-branch fires and emits `ConfigError("git command failed in <path>: ...")` instead of the not-a-Git-repository branch.

### Smoke test

`test_consumer_supervisor_fails_with_friendly_message_on_corrupt_git_repo`:

1. `bootstrap_consumer()` + `init_consumer_git()` + `seed_example_queue()` to get to a working baseline.
2. Overwrite the consumer's `.git/HEAD` with `garbage-not-a-valid-ref\n`.
3. Run `python3 automation/supervisor/run_next.py --dry-run` with `PYTHONDONTWRITEBYTECODE=1`.
4. Assert: non-zero exit; no `Traceback` substring; `git command failed in` substring present; the consumer path appears in the message.

### Coverage status after this slice

| ConfigError emit site | Asserted by |
| --- | --- |
| Missing queue file (supervisor + context-builder) | 2 tests |
| `.git/` missing | 1 test |
| Git not on PATH | 1 test |
| Malformed JSON in queue | 1 test |
| Generic git command failure | **1 test (this slice)** |

ConfigError smoke coverage: **5/5**.

### Approach

- **Verify the corruption shape before writing the test.** Ran a scratch shell probe to confirm garbage-in-HEAD produces the expected exit code while keeping `.git/` present. Many "corrupt git" patterns either delete `.git/` (which would hit the wrong branch) or produce zero exit codes for some operations (which would not reproduce the failure at all).
- **Reuse the existing test fixture setup.** The new test sits next to the other four ConfigError tests inside `RepoAutomationConsumerAdoptionSmokeTests` and follows the same setup → corrupt → invoke → assert pattern. No new helper methods required.
- **Stable substring assertions.** Like the other ConfigError tests, this one asserts on the human-readable substring `git command failed in` and the consumer path. Both are injected by `policy.ConfigError` regardless of git's exact stderr, so the test is resilient to git version drift.

### Files touched (5 of 5 cap)

1. `automation/tests/test_repo_automation_sync.py` — added 1 test (~25 added lines)
2. `automation/queue/slices.json` — slice marked done
3. `automation/handoffs/20260522T055844Z-repo-automation-consumer-git-command-failed-smoke.json` — handoff JSON
4. `SecondBrain/INDEX.md` — new entry
5. `SecondBrain/sessions/2026-05-22/055844-repo-automation-consumer-git-command-failed-smoke.md` — this file

## Validation

- `git fetch origin main` — fetched.
- `python3 automation/context/build_context.py --slice-id repo-automation-consumer-git-command-failed-smoke` — built.
- `python3 automation/supervisor/run_next.py --dry-run` — queue empty after this closes.
- `python3 -m unittest automation.tests.test_repo_automation_sync` — 21/21 OK (was 20).
- `make architecture` — passed.
- `make automation-check` — 122 tests OK (was 121).
- `make pyright` — 0 errors.
- `git diff --check` — clean.

## Lane Boundary

`consumer-smoke-tested`. Test-only addition. No source changes (the ConfigError emit site this asserts already existed; this slice only exercises it from a smoke test).

## Not Claimed

- Every git corruption shape is covered. The smoke test exercises one realistic pattern (bad HEAD); other corruptions (missing `.git/objects`, locked `.git/index`, fsck-discoverable damage) take the same code path so are presumed safe but not directly asserted.
- `policy.git_dirty_paths` handles every subprocess error type. `FileNotFoundError` and `CalledProcessError` are caught; OSError variants like permission denied are not exercised in smoke.

## Next

Queue empty. Remaining named boundaries (not queued):

- Workflow templates in the manifest (promotes the external repo's CI scaffold into Owlory as reusable templates).
- Real third-party repo migration (needs a user-named target).
- Sync tool `--force-templates` flag for deliberate re-baseline after the new first-time-only semantic.
