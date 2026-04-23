# Write Domain-Balance Nudge Suppression

## Metadata

- Date: 2026-04-23
- Local Time: 01:28:34 EDT
- Agent: Codex
- Status: done
- Slug: write-domain-balance-nudge-suppression

## User Prompt

```text
use supervisor harness:
suppress generic domain-balance nudges for Write and rely on the existing Write-specific nudge, which only fires when there are more than 10 capture notes waiting.
repo should use supervisor repo by default
repo should be clean after each slice completion
```

## Interpretation

- What the user wants: Stop Today from showing generic "Write has been quiet lately" copy, keep Write nudging tied to the existing capture-pipeline signal, ensure repo-level agent instructions default to the supervisor harness, and leave the repo clean at slice completion.
- Scope: Patterns nudge rule, focused coverage, Patterns/Write docs, supervisor queue/handoff, and AGENTS repo contract.
- Assumptions: The clean repository currently tracks only harness files, so the minimum needed Owlory domain files were restored from the preserved dirty-workspace stash for this slice.

## Plan

- Step 1: Add a narrow queue slice and run the supervisor dry-run to confirm selected scope.
- Step 2: Change `PatternNudgeRules.domainNudge` to skip `.writing` for generic domain-balance nudges.
- Step 3: Add focused tests and docs that clarify Write has no required note cadence.
- Step 4: Validate, write the handoff, commit the slice, and verify a clean repo.

## Changes

- Created: `AGENTS.md`
- Created: `docs/product/domains/patterns.md`
- Created: `docs/product/domains/write.md`
- Created: `owlory_xcode/Owlory/Core/Domain/DomainModels.swift`
- Created: `owlory_xcode/Owlory/Core/Domain/PatternTypes.swift`
- Created: `owlory_xcode/Owlory/Core/Domain/PatternNudgeRules.swift`
- Created: `owlory_xcode/OwloryCoreTests/PatternNudgeRulesTests.swift`
- Created: `automation/handoffs/20260423T052834Z-patterns-suppress-write-domain-balance-nudge.json`
- Created: `SecondBrain/sessions/2026-04-23/012834-write-domain-balance-nudge-suppression.md`
- Modified: `automation/queue/slices.json`
- Deleted: none
- Inspected: `automation/README.md`, `automation/supervisor/run_next.py`, `automation/supervisor/policy.py`, `automation/schemas/slice.schema.json`, `automation/schemas/handoff.schema.json`, preserved stash contents

## Validation

- Commands run: `python3 automation/supervisor/run_next.py --dry-run`
- Commands run: `swiftc -typecheck owlory_xcode/Owlory/Core/Domain/DomainModels.swift owlory_xcode/Owlory/Core/Domain/PatternTypes.swift owlory_xcode/Owlory/Core/Domain/PatternNudgeRules.swift`
- Commands run: `git diff --check`
- Results: All final required slice validations passed.
- Failures and reruns: A broader harness unittest command failed because this clean repo does not track the full docs tree expected by one harness test; standalone typechecking of the XCTest file failed because `swiftc` in this environment cannot import `XCTest` outside package testing. The final validation set was narrowed to commands available in this clean slice.

## Outcome

- Summary: Generic domain-balance nudges now skip Write. Today should no longer say "Write has been quiet lately" from Focus allocation data, while the existing capture-pipeline nudge remains the Write-specific signal.
- Behavior preserved: Other neglected domains still use the generic "quiet lately" domain-balance nudge.
- Risk remaining: The focused XCTest file was updated but not package-run in this minimal tracked checkout.
- Follow-up: When the full Owlory package tree is tracked in repo canon, run the domain package tests for Patterns.
