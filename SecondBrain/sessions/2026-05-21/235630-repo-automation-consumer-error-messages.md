# repo-automation-consumer-error-messages

## Prompt

> "start next slice"

Queue was empty after the consumer-adoption smoke proof landed. User selected `Friendlier consumer errors` from the offered follow-up boundaries, which became this slice (pri 84).

## What was done

Replaced raw `FileNotFoundError` and `subprocess.CalledProcessError` tracebacks in the reusable supervisor with a single `ConfigError` exception class plus targeted catch-and-rephrase. CLI entry points now print a two-line `stop: <reason>` + `hint: <fix>` message on stderr and exit with code 2 instead of dumping a Python traceback to a consumer.

### Code changes

- `automation/supervisor/policy.py`
  - Added `ConfigError(Exception)` with a docstring naming its intended use at CLI entry points.
  - `load_json`: now catches `FileNotFoundError` (raises `ConfigError("missing file: <path>")`) and `json.JSONDecodeError` (raises `ConfigError("invalid JSON in <path>: <err>")`).
  - `load_queue`: explicit existence check before `load_json` returns a queue-specific message naming `automation/examples/example-slices.json` as the starter file.
  - `git_dirty_paths`: now catches `FileNotFoundError` (git not on PATH) and `subprocess.CalledProcessError` (with an existence check on `.git` so the "not a Git repository" hint only fires when that's actually the cause).

- `automation/supervisor/run_next.py`
  - New `_cli_entry()` wraps `main()` in `try / except policy.ConfigError`. On `ConfigError`, prints `stop: <message>` to stderr and returns 2. `__main__` now invokes `_cli_entry()`.

- `automation/context/build_context.py`
  - Same `_cli_entry()` wrapper around `main()`. Imports `policy` (already present at module top).

### Test changes

- `automation/tests/test_repo_automation_sync.py` — `RepoAutomationConsumerAdoptionSmokeTests`:
  - `test_consumer_supervisor_fails_with_friendly_message_without_queue_file` (renamed from `_fails_loudly_`): asserts no `Traceback` substring, asserts `queue file not found`, the missing path, and the `example-slices.json` hint.
  - `test_consumer_context_builder_fails_with_friendly_message_without_queue_file` (renamed): same shape for the context builder.
  - `test_consumer_supervisor_surfaces_friendly_message_outside_git_repo` (renamed from `_requires_git_repo`): asserts no `Traceback` substring, asserts `not a Git repository` and the `git init -b main` hint.

### Doc changes

- `docs/workflows/repo-automation.md`
  - `Known consumer-side failure modes` rewritten to show the new two-line stop+hint shape with verbatim text and to name `policy.ConfigError` + `_cli_entry` as the implementation seam.
  - `What the smoke test does not prove` no longer carries the bullet about non-friendly tracebacks being acceptable long-term (that gap is closed).
  - `Next Slice Boundary` updated to reflect that consumer adoption proof is complete at the smoke level + friendly-error level, and to point at the remaining boundaries (real-repo migration, prompt portability, CI smoke).

### Manual probe

A scratch consumer was bootstrapped, then exercised three failure paths:

| Path | Output |
| --- | --- |
| No queue file, supervisor `--dry-run` | `stop: queue file not found: <path>\nhint: copy automation/examples/example-slices.json to that path and edit it for this repository's slices.` |
| No queue file, context builder | Same text |
| Has queue file, no `.git` | `stop: not a Git repository: <path>\nhint: run 'git init -b main' in this directory, commit the bootstrap, then re-run.` |

All exit code 2 and no Python traceback in any output.

### Approach

- **One exception class for all consumer-facing config failures.** `ConfigError` keeps the entry-point catch sites simple — one `except` arm covers every missing-file / missing-git / malformed-JSON failure mode without each call site having to know which underlying exception to translate.
- **Smoke tests assert the new shape, not the implementation.** The tests look for substrings like `queue file not found` and `not a Git repository` rather than implementation classes. The implementation seam (`ConfigError`, `_cli_entry`) is named in the docs and the handoff but not asserted by tests, so future refactors that keep the user-facing text stable will not break the tests.
- **No schema or contract changes.** This slice changes only how unhappy paths are reported. The happy paths (slice selection, context building, handoff loading) are unchanged.

### Files touched (9 of 10 cap)

1. `automation/supervisor/policy.py`
2. `automation/supervisor/run_next.py`
3. `automation/context/build_context.py`
4. `automation/tests/test_repo_automation_sync.py`
5. `docs/workflows/repo-automation.md`
6. `automation/queue/slices.json` — slice marked done
7. `automation/handoffs/20260521T235630Z-repo-automation-consumer-error-messages.json`
8. `SecondBrain/INDEX.md`
9. `SecondBrain/sessions/2026-05-21/235630-repo-automation-consumer-error-messages.md`

## Validation

- `git fetch origin main` — fetched.
- `python3 automation/context/build_context.py --slice-id repo-automation-consumer-error-messages` — built.
- `python3 automation/supervisor/run_next.py --dry-run` — reports queue empty.
- `python3 -m unittest automation.tests.test_repo_automation_sync` — 15/15 OK (6 consumer-smoke + 9 sync tests).
- `make architecture` — passed.
- `make automation-check` — 116 tests OK.
- `make pyright` — 0 errors.
- `git diff --check` — clean.
- JSON validity for queue + new handoff — OK.
- Manual probe in a temp consumer directory — friendly two-line messages exactly as expected, no tracebacks.

## Lane Boundary

`consumer-smoke-tested`. Source + tests + docs. No changes to schemas, prompts, examples, or the sync tool. No real-repo migration.

## Not Claimed

- Every failure path in the reusable supervisor now emits a friendly message. Only the three highest-visibility paths (missing queue file, missing git repo, JSON-load wrappers feeding them) were touched and asserted. Schema-invalid queue files surface via the existing `Invalid queue file:` ValueError, which was already friendly.
- The two implemented-but-not-asserted paths (git-not-on-PATH, malformed JSON) have been smoke-tested. They were implemented via the same `ConfigError` mechanism but the proof for those is limited to manual probing.
- A real external repository has consumed the friendly errors. The smoke proof bootstraps temp consumers only.

## Next

Queue is empty after this slice. Natural follow-up boundaries (not queued):

- real third-party repo migration (needs a user-named target)
- prompt-fragment override portability proof
- consumer Makefile / hooks / CI smoke
- smoke coverage for the two not-asserted ConfigError paths (git-not-on-PATH, malformed JSON)
