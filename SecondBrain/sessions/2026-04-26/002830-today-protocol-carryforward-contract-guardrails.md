# Today Protocol Carry-Forward Contract Guardrails

## Prompt

- User asked: "Can you make sure the implementation of protocolos in today adhere to the contractual rules?"

## Scope

- Supervisor slice: `today-protocol-carryforward-contract-guardrails`
- Domain: Today, with Home protocol lifecycle contract as an input.
- Goal: Ensure Home protocols do not appear as Today carried-forward work unless there is an active Home protocol run source.

## Findings

- Today already passes `homeStore.protocols` into `TodayContinuationRules.derive`, so title-based template suppression was wired into the live Today view.
- The remaining gap was ID-based: a carried Home focus artifact linked to a `HouseholdProtocol.id` could leak if the protocol template title changed after the artifact was created.
- Existing garbage collection only received protocol run IDs, not reusable protocol template IDs.

## Changes

- `TodayContinueSourceComposer` now treats both Home protocol template IDs and protocol run IDs as protocol records when suppressing carried Home protocol artifacts.
- `RootTabView` now passes both protocol template IDs and run IDs into Today protocol artifact garbage collection.
- `TodayStore.garbageCollectHomeProtocolFocusArtifacts` now accepts the broader protocol record ID set.
- Added regression coverage for a renamed protocol template linked by template ID.
- Expanded TodayStore garbage-collection coverage to remove both protocol-template-linked and protocol-run-linked artifacts.

## Validation

- `python3 automation/context/build_context.py --slice-id today-protocol-carryforward-contract-guardrails`
- `python3 automation/supervisor/run_next.py --dry-run`
- `make architecture`
- `make test-domain DOMAIN=today`
- `git diff --check`

## Result

- Today now adheres more tightly to the protocol contract: protocol templates without active runs are not treated as carried-forward Today work, and active protocol runs remain the only protocol-shaped Continue projection.

## Remaining Risk

- No manual simulator pass was run against a real persisted dataset with old protocol Focus artifacts.
