# Write Promotion Origin Contract

- Date: 2026-04-29
- Slice: `write-promotion-origin-contract`
- Prompt summary: define the Write Lab promotion origin rule before implementing destination-specific promotion flows.

## Interpretation

- Keep this as a domain-contract slice, not UI or destination implementation.
- Source-note conversion remains the only implemented promotion-like Write flow.
- Future cross-domain promotions need source/origin preservation before they can be described as shipped behavior.

## Files Touched

- `docs/product/domains/write.md`
- `docs/workflows/roadmap-status.md`
- `automation/queue/slices.json`
- `automation/handoffs/20260429T115700Z-write-promotion-origin-contract.json`

## Outcome

- Added a `Promotion Origin Contract` to the Write domain.
- Promotion should create a destination-owned object while preserving the original `WritingNote` unless the user explicitly deletes or archives it.
- Future destination objects must store enough origin metadata to route back to the Write note: origin kind, Write note ID, destination kind, destination ID, and creation timestamp.
- Repeated promotion should be idempotent or require an explicit duplicate choice.
- Protocol promotion must not start an active Home protocol run or leak into Today Continue without Home/Today-owned active work.

## Validation

- `python3 automation/context/build_context.py --slice-id write-promotion-origin-contract` passed.
- `python3 automation/supervisor/run_next.py --dry-run` selected `write-promotion-origin-contract`.
- `make architecture` passed.
- `make test-domain DOMAIN=write` passed.
- `git diff --check` passed.
