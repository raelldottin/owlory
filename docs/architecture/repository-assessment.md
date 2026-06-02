# Repository Assessment

## Current Structure

Owlory is organized around one Xcode project in `owlory_xcode/`, a Swift package over `Owlory/Core`, root release scripts in `Tools/`, historical docs in `owlory_xcode/Docs/`, and a repository-local `SecondBrain/` prompt/change log.

## Current Pain Points

- Root `AGENTS.md` and nested guidance had grown into large specs instead of maps.
- Durable docs were split between root files and `owlory_xcode/Docs/`, with no progressive-disclosure entry point.
- Domain ownership existed in code naming but was not explicit in docs.
- `Core/Application` is doing too much: stores, continuation rules, reminders, telemetry, runtime managers, and legacy placeholders.
- `DomainModels.swift` contains many unrelated product types, which makes ownership harder to scan.
- Product rules are increasingly isolated and tested (`CarryForwardRules`, `ReadinessRules`, `PatternEngine`, `PatternNudgeRules`, `WeeklyDigestRules`, `WeeklyDigestCadenceRules`, `RecurrenceRules`, `ReminderSchedulingRules`), with load-time recurrence orchestration now handled by `RecurringRolloverPlanner`.
- No mechanical architecture lint existed.
- No root `Makefile` existed even though repo instructions referenced make-style validation.

## Likely Domains

- Today: daily entry, planning, readiness check-in, carry-forward, evening reflection, focus suggestions.
- Train: training sessions, recurring session rollover, reflection.
- Write: writing notes, stage progression, dormant/active pipeline visibility.
- Career: wins, impact, stories, metrics, career assets.
- Home: home tasks, recurring task reset, protocols, protocol runs.
- Patterns: pattern detection, calibration, stale items, weekly digest.
- Reminders: completion history, statistical deadlines, local notifications.
- AppRuntime: app wiring, build identity, telemetry, widgets, Live Activities.

## Boundary Problems

- The app has logical layers but not physical Swift modules yet.
- Today UI is a cross-domain orchestration surface, so it needs clear permission to read multiple stores without becoming the owner of their rules.
- A future Live Activity reintroduction would need an explicit boundary exception instead of ad-hoc `ActivityKit` imports in shared domain code.
- Repeated recurrence logic appeared in separate stores before being moved into a domain rule unit.

## Missing Docs

- Root docs map.
- Domain ownership docs.
- Boundary model and shared-code policy.
- Validation workflow guide.
- Runtime observability guide.
- Decision record for the agent-legible repository direction.

## Missing Enforcement

- Import restrictions for `Core/Domain`.
- Required docs structure checks.
- Short-root-AGENTS check.
- Consistent validation commands.

## Missing Workflows

- Architecture lint command.
- Fast validation command.
- Focused domain validation command.
- Full verification command.

## Transformation Plan

Immediate wins:

- Shorten `AGENTS.md` into a map.
- Add root `docs/` structure.
- Add domain ownership docs and validation workflows.
- Add architecture linting.
- Extract recurrence rules into pure domain code.

Medium-term refactors:

- Split `DomainModels.swift` by domain.
- Move Today cross-domain orchestration helpers out of `TodayView`.
- Separate reminders and completion history into a clearer Reminders domain.
- Promote useful legacy `owlory_xcode/Docs/` content into root docs and archive the rest.

Enforcement work:

- Expand `Tools/architecture-lint.sh` with dependency graph checks as folders settle.
- Add placement checks for new domain rule files and tests.
- Add CI wiring once the repo is ready for hosted automation.

Workflow/tooling work:

- Keep `make architecture`, `make fast`, and `make verify` stable.
- Add UI screenshot/harness workflows only after UI test infrastructure exists.
