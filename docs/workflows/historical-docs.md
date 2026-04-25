# Historical Root Docs

Use this workflow before moving or deleting root-level markdown that predates the agent-legible `docs/` tree.

## Rule

Do not delete a historical root doc just because it is old. Delete or replace it only when repo evidence proves one of these:

- the still-useful content already lives in maintained docs, or
- the doc is clearly obsolete and no active workflow depends on it.

If useful content is unique, promote it into the focused `docs/` tree first. If the content is partly useful but not yet promoted, keep the root doc and classify it as deferred.

## Current Classifications

| Root doc | Evidence | Classification | Action |
| --- | --- | --- | --- |
| `PROJECT_SPEC.md` | Still-useful product posture now lives in `README.md` and `docs/product/overview.md`; domain behavior and ownership live in `docs/product/`; architecture and persistence conventions live in `docs/architecture/overview.md` and `docs/architecture/boundaries.md`; validation lives in `docs/workflows/validation.md`. Stale implementation inventories, test counts, gap lists, and section-by-section UI descriptions were intentionally omitted because current docs, code, and tests are the source of truth. | Fully promoted and safe to remove. | Removed after promoting the still-authoritative cross-domain product and architecture guidance. |
| `LESSONS_FROM_GYMPHANT.md` | Short principles doc duplicated in legacy `owlory_xcode/Docs/`; active principles now live in `docs/golden-principles.md`, `AGENTS.md`, and validation/review workflow docs. | Fully superseded and safe to remove. | Removed after preserving the principles in maintained docs. |
| `CLAUDE.md` | Former long agent instruction dump with stale workout-specific guidance. Some tooling may still look for this filename. Active operating instructions live in `AGENTS.md` and `docs/`. | Superseded content; root compatibility pointer remains. | Replaced with a short pointer to `AGENTS.md` and `docs/README.md`. |
| `SKILL.md` | Unique OSS-evaluation guidance for dependency/reference assessment. It is not an active Codex skill location, but the guidance is still useful. | Authoritative content promoted into `docs/`. | Promoted to `docs/workflows/oss-evaluation.md`; root copy removed. |

## Verification

After a historical-doc cleanup, run:

```bash
make drift-report
make architecture
./Tools/validate.sh handoff
./Tools/validate.sh review-preflight
git diff --check
```

Use `make review-preflight` when the cleanup also touches workflow scripts.
