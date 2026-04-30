# write-promote-to-protocol

## Prompt

Implement the next Write promotion slice: a Write note can become a Home-owned protocol item/draft while preserving the original note and avoiding active protocol run or Today Continue leakage.

## Interpretation

- Write already promotes to Today and Home tasks with typed origin metadata.
- Protocol promotion should create a Home-owned protocol draft/input only.
- The original `WritingNote` must remain Write-owned source context.
- The promotion must not create an active run or make Today Continue show protocol work unless a run is explicitly started later.

## Plan

1. Register and dry-run the supervisor slice.
2. Inspect existing Write promotion, Home protocol, and Today Continue guardrails.
3. Add protocol draft promotion with typed Write-note origin metadata and duplicate prevention.
4. Expose a narrow Write detail action for the supported destination.
5. Add focused Write/Home/Today tests and update contracts.

## Files

- To inspect/edit: Write/Home stores, domain models, Write UI, Today Continue composer guardrails, Write/Home/Today tests, maintained docs, queue, handoff, and this SecondBrain entry.

## Validation

- `python3 automation/context/build_context.py --slice-id write-promote-to-protocol` passed.
- `python3 automation/supervisor/run_next.py --dry-run` passed and selected `write-promote-to-protocol`.
- `make architecture` passed.
- `make test-domain DOMAIN=write` passed.
- `make test-domain DOMAIN=home` passed.
- `make test-domain DOMAIN=today` passed.
- `make automation-check` passed.
- `git diff --check` passed before final handoff creation.

## Outcome

- Added Write to Home protocol promotion as a destination-owned protocol draft/template with typed Write-note origin metadata.
- Preserved the original `WritingNote` during promotion and rejected duplicate protocol promotion for the same note.
- Added Home source-note routing for promoted protocols, including available and missing source states.
- Added Write detail menu support for `Add to Protocol`.
- Added Today coverage proving promoted protocol templates do not surface in Continue without an active run.
- Updated Write, Home, Today, and roadmap-status docs to classify protocol promotion as implementation-backed at `domain-tested` proof level.
