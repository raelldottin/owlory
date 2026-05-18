# app-localization-evening-reflection-nudge-routing

## Prompt

The user said: "start next slice".

## Interpretation

Continue the supervisor-selected slice `app-localization-evening-reflection-nudge-routing`. Fix HIG-DE-001 by removing English visible reflection nudge copy from the Today runtime UI path.

## Context

Supervisor selected `app-localization-evening-reflection-nudge-routing`.

The German HIG localized UI gate failed because Karoline's TestFlight Build Info screenshot showed English Today reflection nudge copy in the German UI:

- `Evening reflection`
- `Close the day with one quick reflection.`

Source trace:

- `TodayStore.eveningReflectionNudge(...)` returned English `title` / `message`.
- `TodayView` rendered those runtime strings verbatim.
- Existing localized keys were already present for `notification.prompt.eveningReflection.*` and `notification.prompt.homeWrappedReflection.*` across all 19 locales.

## Results

Implemented.

- Refactored `TodayStore.EveningReflectionNudge` to carry semantic `Kind` only.
- Updated `TodayStore.eveningReflectionNudge(...)` to return `.eveningReflection` or `.homeWrappedReflection`.
- Updated `TodayView` to format visible reflection nudge title/body through existing localized keys.
- Updated `TodayStoreTests` to assert semantic kind rather than English title/body strings.
- Updated localization quality docs to state the source blocker is fixed but German `hig-ui-reviewed` is still not claimed until scoped UI evidence is preserved.

## Validation

Passed:

- `python3 -m json.tool automation/queue/slices.json`
- `python3 -m json.tool automation/handoffs/20260518T042120Z-app-localization-evening-reflection-nudge-routing.json`
- `python3 -c "import json; from automation.supervisor import policy; doc=json.load(open('automation/handoffs/20260518T042120Z-app-localization-evening-reflection-nudge-routing.json')); schema=json.load(open('automation/schemas/handoff.schema.json')); result=policy.validate_document(doc, schema); print('valid' if result.is_valid else '\n'.join(result.errors)); raise SystemExit(0 if result.is_valid else 1)"`
- `python3 automation/context/build_context.py --slice-id app-localization-evening-reflection-nudge-routing`
- `python3 automation/supervisor/run_next.py --dry-run` (`stop: no eligible queued slice found.` after marking the slice done)
- `make architecture`
- `make localization-check`
- `make test-domain DOMAIN=today`
- `make automation-check`
- `git diff --check`
