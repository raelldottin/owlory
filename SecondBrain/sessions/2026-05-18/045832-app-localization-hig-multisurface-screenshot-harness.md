# app-localization-hig-multisurface-screenshot-harness

## Prompt

> "start next slice" — execute the supervisor-selected slice `app-localization-hig-multisurface-screenshot-harness`, which extends the existing idb-first launch-surface helper into a configurable multisurface harness for the scoped HIG surfaces.

## What was done

Automation/proof slice. Added a new idb-first screenshot harness alongside the existing launch-only helper, plus tests, Makefile wiring, and proof-directory + doc wiring. No app source changes.

### New harness

`automation/smoke/capture_localized_surfaces.py` provides a configurable surface catalog and four modes:

- `--check-dependencies`: same idb + idb_companion gate as `capture_locale_screenshots.py`.
- `--list-surfaces`: prints the surface catalog (id, label, description, navigation step count, settled assertion labels) — pure device-free introspection.
- `--dry-run --locales ... --surfaces ...`: prints the (locale × surface) matrix and dependency status without running idb.
- `--capture --udid ... [--locales ...] [--surfaces ...] [--label-overrides path.json]`: terminates and relaunches Owlory per locale with `--owlory-ui-testing` plus locale launch arguments, dismisses known notification prompts, walks the per-surface navigation recipe, verifies a settled-state label, screenshots, hashes, and writes the manifest.

### Default surface catalog

8 scoped HIG surfaces:

| id | label | description |
|---|---|---|
| `today` | Today | Settled Today launch surface |
| `root-tab-train` | Train tab | Train root tab settled |
| `root-tab-write` | Write tab | Write root tab settled |
| `root-tab-career` | Career tab | Career root tab settled |
| `root-tab-home` | Home tab | Home root tab settled |
| `build-info` | Build Info | Build Info screen (version/build/commit/branch) |
| `empty-state-today` | Today empty state | Today empty-state copy (needs fixture seeding) |
| `date-count-plural-today` | Today date/count/plural sample | Today with at least one plural-formatted count and one locale-aware date string |

### Navigation step kinds

- `wait` — `time.sleep` for `seconds`.
- `tap_label` — find the first element whose `AXLabel` matches any label in `labels`, compute center, idb tap.
- `tap_identifier` — same but matches `AXIdentifier` / `identifier` / `accessibility_identifier`.

Captures whose settled assertion fails are recorded as `blocked` with `reason: settled-assertion-failed` and the expected-any-of label set, not silently treated as proof. Locale-specific settled labels are supplied via `--label-overrides path.json` (`{ surface_id: [labels...] }`).

### Manifest contract

Per-capture entries: `locale`, `surface_id`, `surface_label`, `file`, `bytes`, `sha256`, `navigation_steps_executed`. Run-level fields: `git_commit_short`, `target.udid`, `target.bundle_id`, `timestamp`, `proof_level` (`screenshot-verified` when all captures pass), `status`, plus `non_claims` listing translation quality, full layout correctness, device proof, TestFlight proof, and `hig-ui-reviewed`.

### Tests

`automation/tests/test_capture_localized_surfaces.py` adds 14 unit tests:

- Catalog includes the required scoped HIG surfaces; `today` carries representative localized fallback labels.
- Args: `--check-dependencies` only mode; `select_surfaces` default + filter behavior.
- Plan: dry-run plan enumerates locale × surface matrix.
- Navigation: wait/tap_label/tap_identifier dispatch, label-not-found block, unknown-step-kind block, tap-at-button-center.
- Guards: empty output directory required; `--label-overrides` parsing (empty path + locale-specific labels with malformed entries rejected).

`make automation-check` now runs 71 tests (was 57).

### Makefile

New target `localization-multisurface-screenshot-idb-check` mirrors the existing `localization-screenshot-idb-check` pattern and runs `--check-dependencies` for fast preflight.

### Docs

- `docs/workflows/localization-hig-ui-completion.md` — new "Multisurface Screenshot Harness" section after the "Evidence Matrix" section, with usage examples and explicit non-claims.
- `docs/workflows/ui-testing-hygiene.md` — added a current-state bullet plus a "For scoped HIG surfaces beyond the Today launch screenshot" example block.

### Proof directory

`automation/proofs/app-localization-hig-multisurface-screenshot-harness/README.md` documents the expected manifest shape, capture command, and non-claims. The directory is otherwise empty — no `--capture` run has landed, and the harness refuses to mix old and new screenshots, so this directory must stay empty until a real capture run is performed.

## Validation

- `python3 automation/context/build_context.py --slice-id app-localization-hig-multisurface-screenshot-harness` — ran.
- `python3 automation/supervisor/run_next.py --dry-run` — passes (selected this slice before commit).
- `make architecture` — passed.
- `make localization-check` — 19 / 377 / 13.
- `make automation-check` — 71 tests passed (14 new).
- `make localization-screenshot-idb-check` — idb + idb_companion ready.
- `make localization-multisurface-screenshot-idb-check` — idb + idb_companion ready.
- `git diff --check` — clean.

## Lane Boundary

`build-tested` (Python harness + tests). No app source or app-test changes. No screenshot artifacts captured. No proof claim made for any locale or surface.

## Residual Risk

- Default settled-state assertion labels include English and a handful of common locales. For locales without a matching fallback label, `--capture` will block on `settled-assertion-failed` unless `--label-overrides path.json` is supplied. This is intentional honesty over silent overclaiming.
- `empty-state-today` and `date-count-plural-today` rely on natural fixture state. Reliable proof requires fixture seeding via `--owlory-ui-testing` launch arguments or in-app debug fixtures that are not yet implemented at the app level. Capturing those surfaces today may yield content-poor screenshots.
- `build-info` navigation uses English tap labels (`Settings`, `Build Info`); locales with heavily-translated Settings labels will block until per-locale label overrides are recorded.
- No proof artifacts exist in the proof directory yet. Downstream per-bucket HIG gate slices must run `--capture`, store proofs here, and append `proof_references` to the all-locale HIG evidence matrix at `automation/proofs/app-localization-hig-ui-matrix/manifest.json`.
- `tap_identifier` recipes are supported but no Owlory UI currently uses AX identifiers for tab bar items. Future XCUITest harness work should add stable identifiers so navigation no longer depends on translated labels.

## Not Claimed

- Any locale is `hig-ui-reviewed`.
- `screenshot-reviewed` for any new (locale, surface) pair (no `--capture` run has landed).
- `device-verified` for any locale.
- `testflight-verified` for any locale.
- Full localized navigation works for every surface across all 19 locales.

## Next slice in the HIG ladder

Per the queue, the next slice is `app-localization-hig-dynamic-type-accessibility-harness`, which adds Dynamic Type, accessibility label/value/hint, tab reachability, and touch target checks alongside this multisurface harness.
