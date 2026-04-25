# Selective Stash Recovery Validation

## Metadata

- Date: 2026-04-24
- Local Time: 06:48:54 EDT
- Agent: Codex
- Status: done
- Slug: selective-stash-recovery-validation

## User Prompt

```text
continue
```

## Interpretation

- What the user wants: Continue the recovery work after selectively restoring canonical repo files from `stash@{1}`.
- Scope: Validate the restored Xcode/app/docs surface, keep excluded local noise out of the repo, and resolve any contract mismatch exposed by the restore.
- Assumptions: The restored stash content is intended repo canon unless it conflicts with a newer, already-established product rule.

## Plan

- Step 1: Finish the pending `patterns` domain validation after the selective restore.
- Step 2: Fix any test or contract mismatch exposed by the restored canon.
- Step 3: Recheck repo state to confirm no `.build`, `xcuserdata`, or other excluded local noise re-entered the tree.

## Changes

- Modified: `owlory_xcode/OwloryCoreTests/CalibrationRulesTests.swift`
- Created: `SecondBrain/INDEX.md`
- Created: `SecondBrain/sessions/2026-04-24/064854-selective-stash-recovery-validation.md`
- Inspected: `docs/workflows/second-brain.md`, `owlory_xcode/Owlory/Core/Domain/CalibrationRules.swift`, `owlory_xcode/Owlory/Core/Domain/PatternNudgeRules.swift`

## Validation

- Commands run: `make test-domain DOMAIN=patterns`
- Commands run: `git diff --check`
- Commands run: `git status --short`
- Commands run: `find owlory_xcode -path '*/xcuserdata/*' -o -path '*/.build/*' -o -name '.DS_Store'`
- Results: `patterns` validation passed after updating the stale calibration expectation to the Focus-specific generic nudge copy.
- Failures and reruns: Initial `patterns` run failed because `CalibrationRulesTests.testDomainNudgeForNeglectedDomain()` still expected the older "has been quiet" copy. Updating the test to `"Home hasn't shown up in Focus lately."` resolved the mismatch.

## Outcome

- Summary: The selectively restored repo canon now validates against the established Focus-specific domain-balance copy rule.
- Behavior preserved: Generic domain-balance nudges still skip Write, and restored app/docs/project files remain in the working tree without bringing back excluded local noise.
- Risk remaining: The repo is intentionally dirty because the recovered canon is not yet classified into restoration vs. unrelated product-history commits.
- Follow-up: Split the restored canon into a narrow recovery commit before taking additional feature slices.
