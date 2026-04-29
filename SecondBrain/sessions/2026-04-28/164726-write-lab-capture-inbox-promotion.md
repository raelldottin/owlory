# Write Lab Capture Inbox Promotion

- Date: 2026-04-28
- Prompt summary: promote a product rule for Write Lab that accepts todo-like capture without turning Write into a permanent task dump.

## Interpretation

- Treat user behavior as product evidence: Write is currently the fastest place to capture intent.
- Preserve Write's role as a thinking inbox rather than converting it into a generic todo app.
- Make later classification and promotion explicit, but keep capture itself lightweight and forgiving.

## Files Touched

- `docs/product/domains/write.md`
- `docs/product/overview.md`
- `SecondBrain/INDEX.md`

## Changes

- Added a Write-domain contract that frames Write Lab as the capture inbox inside Write's broader incubation role.
- Documented the rule that Write Lab may receive todo-like thoughts without changing Write's product identity into a todo list.
- Added a promotion model for later conversion into task, Today priority, source note, permanent note, protocol item, archive, or keep-as-note paths.
- Added guardrails against up-front classification prompts and against turning Write into a strict processing queue.

## Validation

- `make architecture`
- `git diff --check -- docs/product/domains/write.md docs/product/overview.md SecondBrain/sessions/2026-04-28/164726-write-lab-capture-inbox-promotion.md SecondBrain/INDEX.md`

## Outcome

- Maintained docs now reflect the product distinction: Write is not a todo list, but it is allowed to receive todo-like thoughts because capture speed comes first.
