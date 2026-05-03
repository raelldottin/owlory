# today-last-week-insights-actionability-triage (doc-only)

Classification-first triage of whether the Today Last Week digest should remain informational or gain user-actionable affordances. The slice was scoped to derive the answer from existing Today/Patterns/Home/Write contracts and the live digest rendering, then either close the concern as intentional, queue a narrow follow-up implementation slice if a real gap exists, or document an ambiguity. Conclusion: the digest contract was underspecified about per-stat routing; the rule is now explicit; no implementation slice queued automatically.

## 1. What do the existing contracts imply?

- `docs/product/domains/today.md:86` describes digest summaries as count-first and scope-honest, with `Last Week` reserved for the immediately previous calendar week.
- `docs/product/domains/patterns.md:30-58` puts Weekly Digest generation, cadence, persistence, and rule-version honesty under Patterns ownership. Patterns also owns `PatternNudgeRules` and stale-item / domain-balance nudges via `CalibrationRules`.
- Today owns Continue presentation, day-level surfaces (`PreviousDays`), and per-row routing actions on Continue rows. Today does NOT own pattern nudge content; Patterns does.
- The combined effect: digest output is Patterns-derived data rendered in a Today surface, with no explicit rule about which additional affordances are contract-aligned beyond `View all digests`.

## 2. What does the current implementation do?

- `owlory_xcode/Owlory/Features/Today/TodayView.swift:711` (`lastWeekSection`) renders a collapsed row + DisclosureGroup. The expanded body shows Days active, Completed (X/Y), Streak (Nd), Avg readiness, Best Day (`.summary` line), Hardest Day (`.summary` line), and an italic Key Insight, with one `View all digests` NavigationLink at the bottom.
- `WeeklyDigestRules.collapsedCompletionSummary(...)` and `relativeWeekLabel(...)` produce the count-first label. No per-stat routing, no next-week-planning CTA, no embedded pattern prompts.

## 3. Is the observed behavior intentional, ambiguous, or a gap?

**Underspecified, not a gap.** The current rendering is consistent with "count-first, scope-honest" and "Patterns owns nudge content." The contract simply did not say what additional digest affordances are allowed. Closing that ambiguity is what this slice produced.

## 4. Decision and follow-up

The classification of three actionability options:

- **Option 1: per-item/domain routing.** Contract-aligned for the day-level stats (Best Day, Hardest Day) because Previous Days already renders day data; routing introduces no new derived insight, only navigation. Days active is already adjacent to a Browse previous days link, so duplicating it inside the digest adds no signal. Completed (X/Y) and Streak have no existing single-destination Today surface; routing them would require a new list view, which is more than navigation.
- **Option 2: digest-level next-week CTAs.** REJECTED. Carry-forward already lives in `CarryForwardRules`/`DailyPlanningRules` and Focus Suggestions already own next-week planning. A `Carry forward unfinished` or `Plan next week` button in the digest would duplicate or compete with those flows.
- **Option 3: pattern-driven prompts in the digest body.** REJECTED. Patterns owns nudge content via `PatternNudgeRules` and `CalibrationRules`; surfacing additional prompts inside the digest would either re-derive the same nudges from sparse digest data (scope-honesty risk) or duplicate the existing nudge surface.

**Follow-up implementation slice (NOT auto-queued):** `today-last-week-digest-day-routing` would deep-link Best Day and Hardest Day rows to that specific calendar day in Previous Days. Allowed paths would be `TodayView.swift`, `today.md`, Today tests, and the standard automation paths. Proof level: domain-tested. The slice is plausible and small, but the user has been managing queue order deliberately throughout this session, so I am leaving it unqueued for them to decide.

## 5. Proof level

`doc-only`. The deliverable is a documentation rule clarifying an existing surface; no code, persistence, or rule changed. `domain-tested` is in `missing_proof_levels` because no new domain behavior was added; the existing `WeeklyDigestRulesTests` and `WeeklyDigestCadenceRulesTests` continue to encode the count-first / scope-honest invariants this rule depends on.

## Validation

- `python3 automation/context/build_context.py --slice-id today-last-week-insights-actionability-triage`
- `python3 automation/supervisor/run_next.py --dry-run`
- `make architecture`
- `make test-domain DOMAIN=today`
- `make test-domain DOMAIN=patterns`
- `make automation-check`
- `git diff --check`

## Next

If product wants the day-route from Best/Hardest, queue `today-last-week-digest-day-routing` as a separate small implementation slice. Otherwise the digest contract stays at this rule and the queue plays in priority order: `home-protocol-step-revert` is next.
