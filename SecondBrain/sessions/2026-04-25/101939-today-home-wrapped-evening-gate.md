# Today Home Wrapped Evening Gate

## Metadata

- Date: 2026-04-25
- Local Time: 10:19:39 EDT
- Agent: Codex
- Status: done
- Slug: today-home-wrapped-evening-gate

## User Prompt

```text
the product really means "close the day," the rule should gate this nudge to evening instead of firing immediately when Home tasks are completed.
```

## Interpretation

- What the user wants: Make the Today Home-wrapped reflection copy truthful by only asking the user to close the day after the evening window starts.
- Scope: Today prompt helpers, Today tests, and the Today product contract.
- Assumption: The existing 6pm threshold remains the product-owned evening boundary.

## Changes

- Modified: `owlory_xcode/Owlory/Core/Application/TodayStore.swift`
- Modified: `owlory_xcode/OwloryCoreTests/TodayStoreTests.swift`
- Modified: `docs/product/domains/today.md`
- Modified: `SecondBrain/INDEX.md`
- Created: `SecondBrain/sessions/2026-04-25/101939-today-home-wrapped-evening-gate.md`

## Validation

- Commands run: `make test-domain DOMAIN=today`
- Commands run: `git diff --check`
- Results: Today domain validation passed, including before-evening and after-evening Home-wrapped reflection cases.

## Outcome

- Summary: Home completion no longer triggers "Close the day" copy before evening. After 6pm, completed Home tasks still prioritize the Home-wrapped reflection prompt.
- Behavior preserved: Generic evening reflection still schedules for 6pm when reflection is missing.
- Risk remaining: The evening threshold is still hard-coded at 6pm in Today prompt helpers.
