# app-design-research-robinhood-newsroom-lessons

## Prompt

User asked to start the next slice; supervisor selected `app-design-research-robinhood-newsroom-lessons`.

## What was done

Doc-only research slice. Read all 5 articles in Robinhood's newsroom design category, captured lessons per article, and mapped each lesson to Owlory surfaces with explicit applicability ratings.

### Articles inspected

1. **Introducing a New Visual Identity** (Oct 2024) — `a-new-visual-identity`
2. **Creative Spark: The Making of Robinhood's Gold Campaign** (Feb 2024) — `the-making-of-robinhoods-gold-campaign`
3. **Design Smarter, Not Harder: The Power of Integrated Content Standards** (Nov 2023) — `the-power-of-integrated-content-standards`
4. **Winding Career Paths: How You Got to Robinhood** (Sep 2023) — `winding-career-paths-how-you-got-to-robinhood`
5. **Robinhood Retirement through the eyes of Research, Creative and Design** (Jun 2023) — `robinhood-retirement-through-the-eyes-of-research-creative-and-design`

### Method

The Robinhood newsroom index page is JavaScript-rendered, so WebFetch could not extract canonical article hrefs from the raw HTML. Resolved each article URL via WebSearch site queries, then ran WebFetch against each URL with a structured prompt to extract design lessons (not marketing fluff).

### Highest-value lessons for Owlory

- **Article #3 (Integrated Content Standards)** — most directly actionable. Owlory's content-design layer (`L()` + `Localizable.strings`) and visual-design layer (`DesignSystem`) currently live separately. Robinhood's approach of integrating content guidance INTO the design system (CTA capitalization, error-message phrasing, header punctuation, component-to-content-type mapping) would close the gap and reduce translation drift across 19 locales.
- **Article #5 (Robinhood Retirement)** — plug-and-play semantic types for non-linear discovery validate Owlory's existing `ContinueSubtitleKind` + `FocusSuggestionRules.Reason` structural refactors. A user can arrive at a Train session via Today's Continue row, the Train tab, or a focus suggestion — Owlory already handles this via semantic data types, which is the pattern Robinhood describes.
- **Article #1 (Visual Identity)** — "less is more" + "purposeful pops" validate Owlory's existing minimal-Today + `OwloryColor.brandPrimary`-as-accent direction.

### Explicit non-applicable to Owlory

- Fintech-specific framing (broker, retirement product, APY, regulatory disclaimers).
- Marketing/campaign creative (TV, 3D, agency partnerships).
- Field research at scale (campus intercepts, lit reviews).
- Real-money UX patterns.

### Article #4 honest rating

The "Winding Career Paths" article is primarily biographical/recruiting content with minimal concrete design methodology. Rated low/none for Owlory applicability — no follow-up recommended.

### Recommended follow-up slices (in manifest, NOT queued in this slice)

| Candidate slice | Rationale | Estimated size |
|---|---|---|
| `app-content-standards-integrated-reference` | Article #3 most actionable. Single integrated content+design reference covering CTA capitalization, error phrasing, header punctuation, component-to-content-type mapping. | doc-only, 4–6 files |
| `app-error-message-audit` | Article #3 anti-pattern "Error code: 1234." Audit Owlory's `lastError` surfaces across stores for vague exception messages without resolution guidance. | audit-only, may queue per-store fix slices |
| `app-design-vision-metaphor-adr` | Article #5 "perpetual motion machines" as unifying metaphor. Owlory has implicit narratives; an ADR naming the Today/Continue/Patterns/Train throughline would guide future surfaces. Optional. | doc-only, 2 files |

## Validation

- `python3 automation/context/build_context.py --slice-id app-design-research-robinhood-newsroom-lessons` — ran.
- `python3 automation/supervisor/run_next.py --dry-run` — selected this slice pre-commit.
- `make architecture` — passed.
- `make automation-check` — drift no-drift + 93 unittests OK.
- `python3 -m json.tool automation/proofs/app-design-research-robinhood-newsroom-lessons/manifest.json` — valid.
- `git diff --check` — clean.

## Lane Boundary

`doc-only`. Manifest + handoff + session + INDEX. No source, test, UI, translation, or design-system change.

## Residual Risks

- WebFetch returned no canonical hrefs from the JavaScript-rendered index page; URLs resolved via WebSearch site queries. If a future article is added that doesn't surface in Google's site index, this approach would miss it.
- Lessons were extracted via WebFetch's LLM summarization rather than direct reading. Summaries are accurate to article topics but could miss nuance an in-person reader would catch.
- The 3 recommended follow-up slices are not queued — the project owner decides which (if any) to pursue.

## Not Claimed

- Robinhood's design system is directly portable to Owlory.
- Any of the recommended follow-up slices should be implemented.
- All 5 articles are equally instructive (article #4 is biographical with minimal design content).
- Robinhood's specific tooling (Bento, Cinema 4D, Figma component variables) maps to Owlory's toolchain.

## Next

Two slices remain queued: `app-history-strip-claude-trailers` (pri 96, destructive git-hygiene). The 3 recommended follow-ups from this slice are documented in the manifest but not auto-queued.
