# Arabic RTL Apple HIG Localized UI Gate

## Scope

This is the Apple Human Interface Guidelines localized UI gate for Arabic (`ar`), the only RTL locale in Owlory's supported list. It runs RTL-specific checks: mirrored layout, alignment, navigation affordances, ordered controls, directional symbols, date/count formatting, accessibility reading order, and screenshot evidence.

Ran 2026-05-18 under the internal-reviewer signoff baseline recorded in `localization/review/ar/ar-review-return.json` (`provenance.internal_reviewer_signoff`). The signoff is the project owner's attestation, not a native or fluent reviewer signoff.

## Gate Result

Result: **fail**

Reason: source-trace inspection surfaced 2 high-confidence RTL HIG defects in Owlory source code plus 1 adaptive-layout finding:

- **HIG-AR-001**: TodayView uses `chevron.right` (does not auto-mirror in RTL).
- **HIG-AR-002**: WriteView uses `arrow.right.circle` at 2 call sites (does not auto-mirror in RTL).
- **HIG-AR-003**: Arabic `Career` tab label `المسيرة المهنية` (15 chars; longest Career label across all 19 locales) — tab-bar truncation likely.

No preserved screenshot evidence exists for any scoped surface.

## Methodology

1. **Source-trace inspection.** Read Arabic `Localizable.strings` and recorded tab labels, primary actions, and Build Info row label. Compared against all 18 other locales.
2. **App-source RTL audit.** Grepped Owlory feature views for the explicit directional SF Symbols `chevron.right`, `chevron.left`, `arrow.right`, `arrow.left`, plus `flipsForRightToLeft` and `rightToLeft` markers. Found three call sites using the non-mirroring `.right` form.
3. **Multisurface harness dry-run.** Ran `python3 automation/smoke/capture_localized_surfaces.py --dry-run --locales ar --surfaces today root-tab-train root-tab-write root-tab-career root-tab-home build-info date-count-plural-today`. Plan: 7 captures; idb + idb_companion `ready`. Arabic today label `اليوم` is not in the harness default catalog and will require `--label-overrides` for actual capture.

No screenshot binaries are committed in this proof directory, so this remains a doc-only gate.

## Findings

| ID | Severity | Area | State | Summary |
|---|---|---|---|---|
| `HIG-AR-001` | major | right-to-left | open | `chevron.right` in TodayView:566 does not auto-mirror; should be `chevron.forward` |
| `HIG-AR-002` | major | right-to-left | open | `arrow.right.circle` in WriteView:88,181 does not auto-mirror; should be `arrow.forward.circle` |
| `HIG-AR-003` | major | adaptive-layout | open | `Career` tab `المسيرة المهنية` (15 chars); tab-bar truncation risk |

### Why HIG-AR-001 and HIG-AR-002 are source-level findings (not source-trace inferences)

SF Symbols follow a deterministic naming rule for RTL mirroring:

- Names ending in `.right` / `.left` (explicit directional): do NOT auto-mirror. They always point the same way regardless of layout direction.
- Names ending in `.forward` / `.backward` (semantic): DO auto-mirror under RTL. They flip from right-to-left in LTR to left-to-right in RTL.

Apple HIG explicitly recommends `.forward`/`.backward` names for any UI affordance that means "next in reading order" or "advance" — exactly the use cases at TodayView:566 (Continue row chevron) and WriteView:88/181 (Advance action button).

This finding is high-confidence because it's a deterministic SwiftUI rule applied to a deterministic source string; no screenshot is required to flag the defect. A screenshot would only measure the visible impact, not change whether the defect exists.

## Per-Locale Notes (Arabic only)

| Surface | Arabic label | Length | Notes |
|---|---|---|---|
| Today | `اليوم` | 5 chars | Fits typical tab-bar width |
| Train | `تدريب` | 5 chars | Fits |
| Write | `كتابة` | 5 chars | Fits |
| Career | **`المسيرة المهنية`** | **15 chars** | **HIG-AR-003**; longest Career label across all 19 locales |
| Home | `المنزل` | 6 chars | Fits |
| Build Info | `معلومات الإصدار` | 15 chars | Detail row; should accommodate |
| Save | `حفظ` | 3 chars | Fits |
| Cancel | `إلغاء` | 5 chars | Fits |
| Continue | `متابعة` | 6 chars | Fits |

## HIG Areas

| Area | Result | Notes |
|---|---|---|
| Platform consistency | not-reviewed | Needs screenshot evidence under Arabic launch |
| Adaptive layout | fail (HIG-AR-003) | Career tab label truncation risk |
| Typography and Dynamic Type | not-reviewed | No standard/Larger Accessibility Text evidence |
| Accessibility | not-reviewed | VoiceOver/labels not verified under Arabic |
| Labels and actions | source-trace-only | LLM-drafted; not native-reviewed |
| Locale-aware formatting | not-reviewed | Dates/counts/plurals need visual check under Arabic |
| Right-to-left | **fail (HIG-AR-001 + HIG-AR-002)** | Three directional SF Symbol call sites do not auto-mirror |

## Missing Evidence For Pass

To claim Arabic `hig-ui-reviewed`, the following preserved evidence is required:

- Build Info screenshot with complete gate fields.
- Today screenshot under Arabic with no visible app-owned English strings.
- All five root tabs under Arabic.
- Primary empty states.
- Primary actions (especially WriteView advance action — confirm HIG-AR-002 visible impact post-fix).
- High-risk date/count/plural surfaces under Arabic.
- Dynamic Type pass (standard text size + Larger Accessibility Text).
- Accessibility labels/hints/values for the reviewed surfaces under Arabic.
- **RTL-only mirroring evidence**: layout mirrored, alignment, navigation affordances, ordered controls, directional symbols pointing the right way (post-fix), digits inside numbers not reversed, non-direction-bearing artwork not flipped.

Plus native or fluent Arabic reviewer signoff for any `translation-quality` claim.

## Status

Do not claim Arabic `hig-ui-reviewed`. Do not claim `screenshot-reviewed`, `device-verified`, or `testflight-verified` for Arabic. Do not claim RTL mirroring is proven correct until HIG-AR-001 and HIG-AR-002 are fixed and post-fix screenshots are preserved.

## Downstream Recommendations

1. **Fix the RTL SF Symbol defects first.** Queue a narrow Swift slice that swaps:
   - `chevron.right` → `chevron.forward` in `owlory_xcode/Owlory/Features/Today/TodayView.swift:566`
   - `arrow.right.circle` → `arrow.forward.circle` in `owlory_xcode/Owlory/Features/Write/WriteView.swift:88,181`

   This is a small, targeted, RTL-correctness fix. It does not need screenshot evidence to start, since the rule is deterministic. Screenshots are useful post-fix to confirm the visible impact and to preserve RTL evidence.

2. **Capture Arabic screenshots after the icon fix.** Run `automation/smoke/capture_localized_surfaces.py --capture --locales ar --surfaces today root-tab-train root-tab-write root-tab-career root-tab-home build-info date-count-plural-today --label-overrides ar_overrides.json` with `today.ar` set to include `اليوم`.

3. **After capture**, confirm or deny HIG-AR-003 (Career tab truncation) and append findings + the all-locale HIG evidence matrix per_locale_state for ar.

4. **If HIG-AR-003 is confirmed**, the tab-bar UI-tweak slice should bundle Arabic alongside the seven other tab-truncation findings from the previous bucket gates.
