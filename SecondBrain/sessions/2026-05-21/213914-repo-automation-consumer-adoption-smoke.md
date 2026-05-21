# repo-automation-consumer-adoption-smoke

## Prompt

> "start next slice"

Supervisor pick (only open slice): `repo-automation-consumer-adoption-smoke` (pri 85). The dependency `repo-automation-auto-update-gate` was already done.

## What was done

Added a consumer-adoption smoke proof for the reusable repo-automation package, plus documentation of the consumer setup sequence and the failure modes a consumer encounters today.

### Smoke test additions

`RepoAutomationConsumerAdoptionSmokeTests` in `automation/tests/test_repo_automation_sync.py` bootstraps a temp consumer directory from Owlory's real source + `automation/reusable-manifest.json`, then exercises six paths:

1. **Bootstrap subset is correct.** The manifest-owned reusable subset arrives (supervisor, context builder, schemas, prompts, examples, sync tool, harness test, docs, pyrightconfig); Owlory-specific paths (live queue, handoffs, proofs, smoke, SecondBrain, owlory_xcode, localization, product/runtime docs, release tooling, Owlory pre-push hook) do not arrive.
2. **Executable bits preserved.** `automation/supervisor/run_agent.sh` and `Tools/repo-automation-sync.sh` both retain +x in the consumer.
3. **Supervisor fails loudly without a queue file.** `FileNotFoundError` with the missing path is asserted on both `run_next.py` and `build_context.py`.
4. **Supervisor surfaces a git failure outside a Git working tree.** Asserted via `git` token in the failure output.
5. **Supervisor dry-run succeeds against the example queue inside a git-initialized consumer with bootstrap committed.** The handoff path resolves under the consumer directory (not Owlory), which proves `REPO_ROOT` resolution works correctly for adopters.
6. **`--auto-update` round-trips a clean consumer Git target.** Asserts `result: target is current`.

All 15 tests in the file pass (the 9 pre-existing tests plus the 6 new ones).

### Documentation additions

Added a `Consumer Adoption Bootstrap` section to `docs/workflows/repo-automation.md` covering:

- the exact `--sync` → `git init` → commit → seed queue → smoke-verify sequence
- known consumer-side failure modes (raw Python tracebacks for missing queue and non-Git target, friendly stop message for dirty working tree)
- the manual steps that remain for a real consumer (consumer-specific Makefile, AGENTS.md equivalent, optional hooksPath, optional prompt overrides, optional pyright includes, remote setup)
- what the smoke test does NOT prove (no real-repo migration, no Make/hook/prompt portability proof, no CI integration, no friendlier-message endorsement)

Updated the `Next Slice Boundary` section to reflect that consumer adoption proof is complete at the smoke level and to point at the natural follow-up boundaries.

### Approach

- **Real source, temp consumer.** The smoke test uses Owlory's real `Tools/repo-automation-sync.sh` and `automation/reusable-manifest.json` rather than a synthetic fixture, so it catches drift in the manifest the moment a reusable asset stops landing.
- **Assert current failure shape, do not improve it.** The slice's allowed_paths exclude `automation/supervisor/`, `automation/context/`, and other source paths, so improving the raw-traceback failure messages belongs to a follow-up slice. The smoke test asserts the current shape so future changes are caught.
- **Document gaps honestly.** The docs name both what was proven (six smoke paths) and what was not (real-repo migration, prompt/Makefile portability, friendly messages, CI integration).

### Files touched (6 of 8 cap)

1. `automation/tests/test_repo_automation_sync.py` — added `RepoAutomationConsumerAdoptionSmokeTests` (6 tests, ~170 added lines)
2. `docs/workflows/repo-automation.md` — added `Consumer Adoption Bootstrap`, known-failure-modes list, manual-steps section, smoke-test-does-not-prove section; updated `Next Slice Boundary`
3. `automation/queue/slices.json` — marked slice done
4. `automation/handoffs/20260521T213914Z-repo-automation-consumer-adoption-smoke.json` — handoff JSON
5. `SecondBrain/INDEX.md` — new entry
6. `SecondBrain/sessions/2026-05-21/213914-repo-automation-consumer-adoption-smoke.md` — this file

## Validation

- `git fetch origin main` — fetched.
- `python3 automation/context/build_context.py --slice-id repo-automation-consumer-adoption-smoke` — built.
- `python3 automation/supervisor/run_next.py --dry-run` — reports queue empty after this slice closes.
- `python3 -m unittest automation.tests.test_repo_automation_sync` — 15/15 OK.
- `make architecture` — passed.
- `make automation-check` — passed.
- `make pyright` — passed.
- `git diff --check` — clean.

## Lane Boundary

`consumer-smoke-tested`. Test additions + docs + queue/handoff/INDEX. No changes to the reusable supervisor / context builder / sync tool source code. No real-repo migration.

## Not Claimed

- A specific external repository has consumed the reusable package end-to-end.
- The consumer-side error messages are friendly long-term — they are asserted as the current shape, not endorsed as the final shape.
- Make targets, hook fragments, prompt fragments, or CI integration are proven portable to a real consumer.
- The smoke test is exhaustive — it covers six specific paths but does not, for example, simulate adopter customization of prompt fragments or running policy mutations end-to-end.

## Next

Queue is empty after this slice. Natural follow-up boundaries (not queued):

- consumer-side friendlier error messages (would touch supervisor/policy/context source)
- a real third-party repo migration when a target is named explicitly by the user
- prompt-fragment override portability proof
- consumer Makefile / hooks / CI smoke

No follow-up slice is queued by this slice — those should be added explicitly when their scope is named.
