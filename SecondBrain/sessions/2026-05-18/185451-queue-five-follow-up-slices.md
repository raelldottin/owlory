# queue-five-follow-up-slices

## Prompt

> "create slices for pending tasks"

In response to my earlier suggestion of possible follow-up directions after the HIG closure + TestFlight-not-required policy clarification.

## What was done

Queue-only slice. Appended 5 new slices to `automation/queue/slices.json` covering the pending follow-up items the user could pick up later. No code, no test, no doc change beyond the queue.

### Queued (3 slices)

| Slice ID | Pri | Depends on | Target proof |
|---|---:|---|---|
| `app-localization-smaller-width-accessibility-regression` | 65 | `app-localization-tab-bar-truncation-fix` | regression-tested |
| `app-localization-voiceover-verification` | 64 | `app-localization-all-locale-hig-ui-closure` | build-tested or doc-only |
| `app-localization-review-drift-check` | 63 | `app-localization-native-review-intake` | build-tested |

### Blocked (2 slices)

Each has an explicit `entry_condition` for `make clean-stop` parity.

| Slice ID | Pri | Entry condition |
|---|---:|---|
| `app-localization-device-verified-locale-proof` | 50 | Physical iPhone with Owlory at known build provenance + tester ready |
| `app-localization-testflight-verified-locale-proof` | 49 | TestFlight build distributed + tester ready, Build Info captured first |

These two are intentionally **blocked** rather than queued because they need external inputs (physical device, TestFlight distribution + tester). Per the 2026-05-18 policy, neither is required for the `hig-ui-reviewed` claim; they extend the proof ladder if and when the project owner wants the next-tier evidence.

### Schema cleanup during this slice

Initial commit referenced session-note IDs (`app-localization-hig-ui-proof-closure`, `app-localization-all-locale-native-review`) in `depends_on` that aren't slice IDs in the queue. `make automation-check` caught it via the queue-integrity test. Fixed to point at the actual slice IDs (`app-localization-all-locale-hig-ui-closure`, `app-localization-native-review-intake`).

## Validation

- `make architecture` — passed.
- `make automation-check` — 71 tests passed (queue integrity covered).
- `python3 -m json.tool automation/queue/slices.json` — valid.
- `python3 automation/supervisor/run_next.py --dry-run` — picks one of the 3 newly queued slices (selected: `app-localization-review-drift-check`).
- `git diff --check` — clean.

## Lane Boundary

`doc-only`. No source, test, or proof artifact changed.

## Not Claimed

- These slices have been run; they're queued.
- The follow-up work is necessary (the HIG closure + policy already covers what's needed for the localization HIG track; these are extensions).

## Next slice

Supervisor's choice. `app-localization-review-drift-check` is the next eligible by selection order; `app-localization-smaller-width-accessibility-regression` (pri 65) and `app-localization-voiceover-verification` (pri 64) are also queued.
