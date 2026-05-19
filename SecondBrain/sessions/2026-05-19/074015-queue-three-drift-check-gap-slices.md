# queue-three-drift-check-gap-slices

## Prompt

> "add slices for the gaps"

Refers to the three honest gaps recorded in the previous slice's handoff (`app-localization-review-drift-check`, commit `3665ffc`):

1. Stringsdict per-plural-category drift not detected (top-level keys only).
2. `english_value` drift only checked for strings rows, not stringsdict rows.
3. `parse_stringsdict_keys` silently empty on non-macOS hosts.
4. Drift check not folded into `make automation-check`.

## What was done

Queue-only update. Appended 3 follow-up slices to `automation/queue/slices.json`. Gaps 1 and 2 are tightly coupled (both stringsdict coverage extensions) and bundled into one slice. No source, test, doc, or proof changes.

### Queued (3 slices)

| Slice ID | Pri | Depends on | Covers gaps |
|---|---:|---|---|
| `app-localization-review-drift-check-stringsdict-coverage` | 60 | `app-localization-review-drift-check` | 1 + 2 |
| `app-localization-review-drift-check-gate-promotion` | 59 | `app-localization-review-drift-check-stringsdict-coverage` | 4 |
| `app-localization-review-drift-check-non-macos-portability` | 40 | `app-localization-review-drift-check` | 3 |

### Sequencing rationale

- **Stringsdict-coverage** lands first because the drift check should detect more drift before the gate promotion gates on it. Promoting a too-narrow check into `automation-check` would mask real drift.
- **Gate promotion** waits on stringsdict-coverage so `make automation-check` blocks on a richer drift signal once it gates.
- **Non-macOS portability** is lower priority because Owlory runs on macOS today; the gap matters when the tool eventually runs in CI containers or contributor Linux hosts. Switching `parse_stringsdict_keys` from `plutil` shellout to `plistlib` keeps the tool macOS-friendly while extending its reach. Raises an explicit error on parse failure instead of silently treating absent keys as drift.

## Validation

- `python3 -m json.tool automation/queue/slices.json` — passed.
- `make automation-check` — 81 tests passed (no new code; existing tests continue to pass).
- `make pyright` — 0 errors / 0 warnings.
- `python3 automation/supervisor/run_next.py --dry-run` — selects an eligible queued slice (one of the new three or the prior smaller-width / VoiceOver slices).

## Lane Boundary

`doc-only`. No source/test/doc/proof change beyond the queue.

## Not Claimed

- Any of these gaps is fixed (they're queued).
- The drift check now detects stringsdict per-plural-category drift (still doesn't; stringsdict-coverage slice will add that).
- The drift check is gated by automation-check (still separate; gate-promotion slice will fold it in).

## Residual Risk

- The new slices' `max_files_changed` budgets (6, 4, 3) are conservative; if the stringsdict-coverage slice grows beyond 6 files during implementation, raise the budget rather than splitting late.
- Gate promotion is conditional on a clean drift baseline at the time it runs. If new source strings land before the promotion slice runs and create drift, the promotion slice should defer until drift is resolved rather than weaken `--check`.

## Next slice

Supervisor's choice among the queued slices. `app-localization-smaller-width-accessibility-regression` (pri 65) remains the highest-priority queued item.
