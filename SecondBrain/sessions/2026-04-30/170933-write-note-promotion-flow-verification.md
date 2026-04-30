# write-note-promotion-flow-verification

## Prompt

Use the supervisor harness and prove the running-app Write promotion flow on clean mirrored `main`:

- Write note -> promote to Home task
- see promotion status in Write
- open promoted task
- use View source note
- return to the source Write note

## Interpretation

- This is a proof slice, not a product slice.
- The existing Write/Home promotion contract should remain unchanged unless a small blocking bug appears.
- The slice succeeds only if the real running app completes the flow.

## Plan

1. Confirm the repo is clean and mirrored.
2. Build slice context and confirm supervisor scope.
3. Run baseline `running_app_smoke`.
4. Seed deterministic simulator data for a Write note.
5. Exercise the full Write -> Home -> source-note round trip in the simulator.
6. Capture proof artifacts and record the slice in automation handoff + queue state.

## Files Inspected

- `AGENTS.md`
- `docs/README.md`
- `docs/architecture/boundaries.md`
- `docs/product/domain-index.md`
- `docs/product/domains/write.md`
- `docs/product/domains/home.md`
- `docs/workflows/validation.md`
- `docs/workflows/second-brain.md`
- `automation/README.md`
- `automation/queue/slices.json`
- `owlory_xcode/Owlory/Features/Write/WriteView.swift`
- `owlory_xcode/Owlory/Features/Home/HomeView.swift`
- `owlory_xcode/Owlory/RootTabView.swift`
- `owlory_xcode/Owlory/Core/Application/HomeStore.swift`
- `owlory_xcode/Owlory/Core/Application/WriteStore.swift`
- `owlory_xcode/Owlory/Core/Persistence/ItemListRepository.swift`

## Validation

- `git status --short`
- `git rev-list --left-right --count HEAD...@{u}`
- `python3 automation/context/build_context.py --slice-id write-note-promotion-flow-verification`
- `python3 automation/supervisor/run_next.py --dry-run`
- `python3 automation/smoke/running_app_smoke.py --output /tmp/owlory-running-app-smoke-before-write-flow.json`
- `python3 automation/smoke/running_app_smoke.py --output /tmp/owlory-running-app-smoke-after-write-flow.json`
- `make architecture`
- `make test-domain DOMAIN=write`
- `make test-domain DOMAIN=home`
- `make automation-check`
- `git diff --check`

## Outcome

- Reached `flow-verified` proof for the Write-to-Home promotion path on a clean mirrored checkout.
- Seeded one deterministic Write note into the simulator app-support store, promoted it to a Home task from the real Write note UI, then verified the Write Move section showed `Task / Created / Show`.
- Verified that `Show` routes into Home with the promoted task highlighted, the Home task detail shows `View source note`, and `View source note` returns to the original Write note detail.
- Captured baseline smoke artifacts plus flow screenshots:
  - `/tmp/write-flow-before-promotion.png`
  - `/tmp/write-flow-after-promotion-status.png`
  - `/tmp/write-flow-home-task-source.png`
  - `/tmp/write-flow-returned-source-note.png`
- Confirmed the promotion created a Home task with `writingNote` origin metadata in simulator persistence and did not remove the source Write note.

## Notes

- `python3 automation/supervisor/run_next.py --dry-run` reported `stop: no eligible queued slice found`, so the slice stayed manual inside the already selected queue boundary.
- The simulator accessibility tree did not respond to the generic scroll helper inside SwiftUI forms; using the element's `Scroll Down` secondary action was enough to reveal the Write status row and the Home `View source note` row without code changes.
- The existing `Show` route lands on the Home list with the promoted task highlighted, not directly in task detail. This slice treated that as the current supported contract and completed the remaining steps from there.
