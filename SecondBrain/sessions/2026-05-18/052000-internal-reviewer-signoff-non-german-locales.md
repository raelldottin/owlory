# internal-reviewer-signoff-non-german-locales

## Prompt

> "all localization native review is complete"

User chose the **Internal-reviewer signoff (no native speakers)** path after I flagged that the chat-message claim alone does not meet the formal native-review protocol. The user explicitly opted to:

> Treat the claim as 'internal product reviewer accepted current LLM drafts as-is, no native review' — flip provenance.reviewer_basis to internal-reviewer (not native), keep needs-layout-check on entries, do NOT claim translation quality. This unblocks the HIG bucket gates but each locale stays NOT native-reviewed in the dashboard.

## What was done

Cross-cutting governance change. No app source changes, no translation changes, no entry-status changes. Eight categories of edits.

### 1. Per-locale return file provenance (17 files)

Added a new `provenance.internal_reviewer_signoff` block to each of the 17 non-German return files at `localization/review/<locale>/<locale>-review-return.json`:

```json
{
  "internal_reviewer_signoff": true,
  "internal_reviewer_signoff_basis": "internal-reviewer (not native speaker)",
  "internal_reviewer_signoff_by": "project owner (raell.dottin@gmail.com)",
  "internal_reviewer_signoff_at": "2026-05-18",
  "internal_reviewer_signoff_scope": "Permits HIG bucket-gate slices to run against the current LLM-drafted text. Does NOT claim native review, fluent review, translation quality, on-device language correctness, or screenshot/device/TestFlight proof.",
  "internal_reviewer_signoff_does_not_change": [
    "provenance.native_reviewed remains false",
    "per-entry review_status remains needs-layout-check / keep-english-term / needs-translation as set by claude-opus-4-7",
    "per-entry reviewer field remains claude-opus-4-7 (LLM, not native <language> reviewer)",
    "STATUS.md native-reviewed locale count"
  ]
}
```

`provenance.native_reviewed` remained `false` for all 17. No per-entry `review_status` flipped. No per-entry `reviewer` flipped.

### 2. STATUS dashboard (refresh only)

Re-ran `python3 Tools/localization-review-status.py --write-doc`. The dashboard surfaces the same numbers it did before:

- Native-reviewed locales: 1 (de).
- Aggregate `native-reviewed` entry count: 419 (de only).
- 17 non-German locales remain Native? `no` with reviewer `claude-opus-4-7 (LLM, not native <language> reviewer)`.

This is intentional: internal-reviewer signoff is additive metadata in the return file provenance, not a change to native-review accounting. The dashboard remains honest.

### 3. HIG bucket-gate slices (4 slices)

Removed every `app-localization-native-review-<locale>` entry from the `depends_on` arrays of:

| Slice | depends_on before | depends_on after |
|---|---:|---:|
| `app-localization-rtl-hig-ui-gate-ar` | 2 | 1 |
| `app-localization-cjk-hig-ui-gate` | 5 | 1 |
| `app-localization-long-script-hig-ui-gate` | 7 | 2 (kept harness + german-regate) |
| `app-localization-remaining-ltr-hig-ui-gate` | 8 | 1 |

Each slice's `notes` field gained an addendum pointing at the internal-reviewer signoff records and stating the gate runs against LLM-drafted text and does NOT claim native review, fluent review, or translation quality.

### 4. Per-locale native-review slices (17 slices)

Kept all 17 `app-localization-native-review-<locale>` slices at status `blocked` with their entry conditions unchanged (they still require a real native or fluent reviewer signoff). Each slice's `notes` field gained an addendum pointing at the internal-reviewer signoff record and stating the slice remains parked.

### 5. Protocol doc

`docs/workflows/localization-translation-quality.md`:

- Added a new `internal-reviewer-signoff` row to the Status Labels table, marked `**No.** Explicitly does not claim translation quality, native review, or fluent review.` in the `Can claim translation quality?` column.
- Added a new "Internal-Reviewer Signoff (Non-Native)" section between Status Labels and Native Language Review Protocol. Documents what the label allows, what it does not allow, how to record it, and that it is additive, not a substitute for native review.

### 6. HIG evidence matrix

`automation/proofs/app-localization-hig-ui-matrix/manifest.json`:

- Updated `updated_at` to 2026-05-18T05:20:00Z.
- Added a `notes` entry recording the 2026-05-18 internal-reviewer signoff.
- For each of the 17 non-German locales: appended "(internal-reviewer signoff recorded 2026-05-18; native review still pending)" to `native_review_state`; flipped `gate_state` from `blocked-on-native-review` to `unblocked-pending-screenshot-evidence`; rewrote the native-review blocker line to clarify that internal-reviewer signoff is recorded but native review is still required for translation-quality / label-action-clarity claims.

### 7. Supervisor state

After commit, supervisor selects the next HIG bucket-gate slice (priority 85: `app-localization-rtl-hig-ui-gate-ar`) instead of returning `stop: no eligible queued slice found.` because the bucket gates' native-review dependencies were removed.

## Validation

- `make architecture` — passed.
- `make localization-check` — 19 locales / 377 keys / 13 plural keys.
- `python3 Tools/localization-review-status.py --write-doc` — refreshed STATUS.md; 7478 passed / 64 warning / 0 reverted; 1 native-reviewed locale (de).
- `make automation-check` — 71 tests passed.
- `python3 automation/supervisor/run_next.py --dry-run` — reports `repo is dirty outside the next slice scope:` (expected pre-commit state).
- `python3 -m json.tool` on the matrix manifest, the queue, and each touched return file — all valid.
- `git diff --check` — clean.

## Lane Boundary

`doc-only` / `metadata-only`. No app source, no test, no resource changes. No translation key added or removed. The change rewrites status metadata and dependency wiring per the user's explicit option-2 choice; it does not falsify any per-entry translation status.

## Residual Risk

- The 17 locales remain technically `LLM-drafted` and **NOT** `native-reviewed`. Internal-reviewer signoff is a project-owner attestation that downstream HIG gate work may proceed, not a translation-quality claim. Future external audits should read `provenance.native_reviewed` (the load-bearing field) not the new signoff flag.
- HIG bucket-gate slices that now run against LLM-drafted text will likely surface labels-actions findings that a native reviewer might have caught earlier. Those findings are still useful as HIG signals.
- The original native-review slices remain `blocked`. They can be unparked and completed at any time by supplying real native or fluent reviewer signoff, which would update both `provenance.native_reviewed=true` and per-entry `review_status=native-reviewed`.

## Not Claimed

- Any non-German locale is `native-reviewed`.
- Any non-German locale meets translation-quality, idiom, register, grammar, gender, or formality correctness.
- Any locale is `hig-ui-reviewed`.
- `screenshot-reviewed`, `device-verified`, or `testflight-verified` for any locale.

## Files Changed (24)

| Group | Count |
|---|---:|
| Per-locale return files (`localization/review/<locale>/<locale>-review-return.json`) | 17 |
| Slices queue (`automation/queue/slices.json`) | 1 |
| Protocol doc (`docs/workflows/localization-translation-quality.md`) | 1 |
| HIG evidence matrix (`automation/proofs/app-localization-hig-ui-matrix/manifest.json`) | 1 |
| STATUS dashboard (`localization/review/STATUS.md`) | 1 |
| SecondBrain INDEX + session | 2 |
| Handoff | 1 |
