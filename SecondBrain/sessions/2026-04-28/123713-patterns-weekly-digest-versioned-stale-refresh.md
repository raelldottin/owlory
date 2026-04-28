# Patterns Weekly Digest Versioned Stale Refresh

## Prompt

Implement a Patterns-owned data-integrity slice: make weekly digest persistence honest across rule changes without silently rewriting historical weekly digest rows.

## Interpretation

- Weekly digest calculation rules changed after old rows may already have been persisted.
- The latest digest may be refreshed from source data when stale.
- Older digest rows are user-trust-sensitive history and must not be silently bulk-rewritten.

## Supervisor Slice

- Slice: `patterns-weekly-digest-versioned-stale-refresh`
- Domain: `patterns`
- Required validations: `make architecture`, `make test-domain DOMAIN=patterns`, `git diff --check`
- Supervisor dry-run selected the slice and confirmed the allowed path boundary.

## Files Edited

- `automation/queue/slices.json`
- `automation/handoffs/20260428T123713Z-patterns-weekly-digest-versioned-stale-refresh.json`
- `docs/product/domains/patterns.md`
- `owlory_xcode/Owlory/Core/Application/PatternStore.swift`
- `owlory_xcode/Owlory/Core/Domain/WeeklyDigest.swift`
- `owlory_xcode/Owlory/Core/Domain/WeeklyDigestRules.swift`
- `owlory_xcode/OwloryCoreTests/WeeklyDigestRulesTests.swift`
- `owlory_xcode/OwloryCoreTests/WeeklyDigestCadenceRulesTests.swift`
- `SecondBrain/INDEX.md`
- `SecondBrain/sessions/2026-04-28/123713-patterns-weekly-digest-versioned-stale-refresh.md`

## Outcome

- Added `digestRuleVersion` metadata to `WeeklyDigest`.
- New generated digests record `WeeklyDigestRules.currentDigestRuleVersion`.
- Missing digest rule version decodes as legacy instead of breaking older persisted rows.
- PatternStore refreshes only the latest matching digest when source data or rule version requires it.
- Older non-latest persisted digests remain untouched during normal refresh/load.

## Validation

- `python3 automation/context/build_context.py --slice-id patterns-weekly-digest-versioned-stale-refresh`: passed
- `python3 automation/supervisor/run_next.py --dry-run`: passed
- `make architecture`: passed
- `make test-domain DOMAIN=patterns`: passed
- `git diff --check`: passed

## Remaining Risk

- Historical backfill is intentionally not implemented; older rows remain legacy until a deliberate migration/review slice exists.
- If source data for an already persisted latest digest disappears entirely, PatternStore keeps the prior digest instead of replacing it with an empty artifact.
