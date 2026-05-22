# repo-automation-consumer-error-messages-additional-smoke

## Prompt

> "start next slice"

Queue was empty after the production-ready external CI work. User selected "Smoke coverage for remaining ConfigError paths" from the offered follow-up boundaries.

## What was done

Locked in the two ConfigError code paths that the prior `repo-automation-consumer-error-messages` slice implemented but did not assert. Added two new tests to `RepoAutomationConsumerAdoptionSmokeTests`:

1. **`test_consumer_supervisor_fails_with_friendly_message_when_git_not_on_path`** — bootstraps a consumer, initializes git, seeds the example queue, then constructs an isolated `python-only-bin/` directory containing only a symlink to `python3` and uses it as the supervisor's PATH. Asserts the run exits non-zero with `git executable not found on PATH` and no `Traceback`.

2. **`test_consumer_supervisor_fails_with_friendly_message_on_malformed_queue_json`** — bootstraps a consumer, initializes git, then writes `{invalid json,\n` as the queue file before invoking the supervisor. Asserts the run exits non-zero with `invalid JSON in` + the absolute queue path, and no `Traceback`.

### Test count

| Surface | Before | After |
| --- | --- | --- |
| `RepoAutomationConsumerAdoptionSmokeTests` | 6 | 8 |
| `test_repo_automation_sync.py` total | 15 | 17 |
| `make automation-check` total | 116 | 118 |

### Coverage of ConfigError emit sites

After this slice the smoke tests assert friendly messages for **four of five** ConfigError-emitting paths in `policy.py`:

| Path | Asserted by |
| --- | --- |
| Missing queue file (supervisor + context-builder) | `test_consumer_*_fails_with_friendly_message_without_queue_file` ×2 |
| Not-a-Git-repository | `test_consumer_supervisor_surfaces_friendly_message_outside_git_repo` |
| Git executable not on PATH | `test_consumer_supervisor_fails_with_friendly_message_when_git_not_on_path` (new) |
| Malformed JSON in queue | `test_consumer_supervisor_fails_with_friendly_message_on_malformed_queue_json` (new) |
| Generic `git` command failure (defensive branch) | not asserted — unreachable through normal consumer setup |

### Approach

- **Isolated PATH via symlink.** Stripping PATH entirely breaks `python3` itself. The test instead creates a temp directory containing only `python3` (via `os.symlink(shutil.which("python3"), ...)`) and uses that single directory as PATH for the subprocess. Git is no longer findable but python3 still runs.
- **Skip cleanly when prereqs are missing.** If `shutil.which("python3")` returns `None`, the test calls `self.skipTest(...)` rather than blowing up with a None argument to `os.symlink`. The pyright Optional[str] arrow is satisfied via an explicit `if python_exec is None` guard.
- **Substring assertions, not implementation classes.** The tests check for human-readable substrings (`git executable not found on PATH`, `invalid JSON in`) rather than asserting on Python class names. Editing the message text in `policy.ConfigError` will require updating these substrings — that's intentional, so the test is sensitive to consumer-facing wording but not to internal refactors.

### Files touched (5 of 6 cap)

1. `automation/tests/test_repo_automation_sync.py` — added 2 tests to `RepoAutomationConsumerAdoptionSmokeTests` (~40 added lines)
2. `automation/queue/slices.json` — slice marked done
3. `automation/handoffs/20260522T020350Z-repo-automation-consumer-error-messages-additional-smoke.json` — handoff JSON
4. `SecondBrain/INDEX.md` — new entry
5. `SecondBrain/sessions/2026-05-22/020350-repo-automation-consumer-error-messages-additional-smoke.md` — this file

## Validation

- `git fetch origin main` — fetched.
- `python3 automation/context/build_context.py --slice-id repo-automation-consumer-error-messages-additional-smoke` — built.
- `python3 automation/supervisor/run_next.py --dry-run` — queue empty.
- `python3 -m unittest automation.tests.test_repo_automation_sync` — 17/17 OK.
- `make architecture` — passed.
- `make automation-check` — 118 tests OK.
- `make pyright` — 0 errors.
- `git diff --check` — clean.

## Lane Boundary

`consumer-smoke-tested`. Test-only addition (plus queue/handoff/INDEX/session). No changes to `automation/supervisor/policy.py` or any other source file.

## Not Claimed

- Every ConfigError emit site is now asserted. The fifth (`git command failed` generic branch) remains unasserted because it requires a corrupted Git repo to trigger and isn't a typical consumer failure mode.
- A real external repository has experienced these failure modes — the smoke test bootstraps temp consumers only.

## Next

Queue is empty. Remaining named boundaries (not queued by this slice):

- Workflow templates in the manifest so consumers get a CI scaffold during bootstrap
- Prompt-fragment override portability proof
- Real third-party repo migration when a target is named explicitly by the user
