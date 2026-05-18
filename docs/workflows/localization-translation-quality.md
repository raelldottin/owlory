# Localization Translation Quality

Use this workflow before replacing English placeholder values in non-English localization files. It separates translation quality from resource readiness, launch stability, and screenshot proof.

## Current Status

Localization is not complete. Treat resource readiness, runtime proof, and translation quality as separate tracks:

- **Infrastructure**: implemented. Owlory has Apple-native `Localizable.strings` and `Localizable.stringsdict` resources for all approved locales.
- **Packaging and parity**: implemented. `make localization-check` verifies locale folders, key parity, plural resources, and Xcode variant-group packaging.
- **Representative runtime proof**: implemented for `en`, `es`, `fr`, `ar`, and `zh-Hans` only. This proves representative resource loading and launch stability, not every locale.
- **Representative screenshot proof**: implemented for `en`, `es`, `fr`, `ar`, and `zh-Hans` launch surfaces only. This does not prove translation quality or full layout correctness.
- **Translation review input**: prepared. The generated review packet exists, and the German-first packet is ready under `localization/review/de/`.
- **All-locale smoke**: implemented. `app-localization-all-locale-smoke` passed for all 19 supported locales and proves launch/resource loading only.
- **All-locale screenshot proof**: implemented. `app-localization-all-locale-screenshot-proof` captured one settled launch-surface screenshot per supported locale (19 PNGs) on 2026-05-14 and preserved them under `automation/proofs/app-localization-all-locale-screenshot-proof/` with README and `manifest.json` (sha256 + bytes). This proves launch-surface visual evidence only, not translation quality, full layout correctness, device behavior, or TestFlight behavior.
- **Localization layout regression**: implemented for representative locales. `owlory-ui-regression-batch-7-localization-layout-shell` (Lane 2) runs four XCUITest cases under `-AppleLanguages` / `-AppleLocale` for `en`, `de`, `ar`, and `zh-Hans` and asserts the Today shell settles plus the root tab bar exposes five hittable buttons. It does not prove translated-text layout correctness.
- **All-locale LLM-drafted ingest**: implemented on 2026-05-15 with caveats. All 18 non-English locales received LLM-drafted values produced by `claude-opus-4-7` (NOT a native speaker of any of them). German was ingested first and then accepted by user-reported native/human German review on 2026-05-18; the remaining 17 locales (`ar`, `nl`, `fr`, `it`, `ja`, `ko`, `nb`, `pt`, `pt-BR`, `ru`, `es`, `sv`, `zh-Hans`, `zh-Hant`, `tr`, `uk`, `vi`) remain LLM-drafted. Per-locale review return files live under `localization/review/<locale>/<locale>-review-return.json` (German uses the legacy `german-review-return.json` filename).
- **Automated LQA + LLM-quality-pass**: implemented on 2026-05-15 and refreshed on 2026-05-18 after return files were brought current with 419 entries per locale. `Tools/localization-lqa.py` runs deterministic checks (format-specifier parity, empty-value, identical-to-English-outside-keep, length-outlier, mojibake-suspect) over each per-locale return-file entry plus an LLM second-pass. Each entry receives an `lqa` block with `status=passed | warning | reverted`. As of 2026-05-18: 7,478 entries pass / 64 warnings / 0 reverts across 18 locales. `lqa.status=passed` is NOT a native-review claim — it only says the entry is internally consistent and the LLM second-pass has no machine-detectable concerns. See `localization/review/LQA.md` for the report and `localization/review/STATUS.md` for the dashboard.
- **Reviewed translations (native)**: complete for German only. `localization/review/de/german-review-return.json` has `provenance.native_reviewed=true` and 419 `native-reviewed` entries based on user-reported native/human German review on 2026-05-18. The other 17 non-English locales remain unreviewed LLM drafts with `provenance.native_reviewed=false`.
- **German device screenshot observation**: recorded on 2026-05-18 from Karoline's chat-provided iPhone screenshot. The visible Today dashboard surface shows German text including `Heute`, `Was ist heute aktiv?`, `Stabiler Tag. Vertrauen Sie dem Plan.`, `Einchecken`, `Sitzung hinzufügen`, `Eine Notiz erfassen`, and the German tab labels. This supports device-observed German rendering for that surface only; the binary screenshot is not committed under `automation/proofs/`, so this is not repo-managed `screenshot-verified`, `device-verified`, or `testflight-verified` proof.
- **German TestFlight Build Info observation**: recorded on 2026-05-18 from Karoline's chat-provided Build Info screenshot, reported as TestFlight evidence. The visible fields show version `0.2.0`, build `20260517151819`, commit `f6325f3c28e9`, full commit `f6325f3c28e9e9263eebbe76a3bbba777ff6e615`, and branch `main`. Local history confirms that commit exists and that its committed Xcode project reports `MARKETING_VERSION = 0.2.0` and `CURRENT_PROJECT_VERSION = 20260517151819`. This is build-info-observed provenance only; without a committed screenshot artifact and complete Build Info gate fields, it is not full `testflight-verified` language-review proof.
- **Apple HIG localized UI review**: required for every future localized UI claim. A locale can be language-reviewed without proving every screen is HIG-clean, but any claim that localized UI is release-ready must pass the HIG gate below for the scoped surfaces.
- **All-locale Apple HIG completion plan**: queued on 2026-05-18 in [Localization HIG UI Completion](localization-hig-ui-completion.md). Completion requires native/fluent review inputs for non-German labels/actions, broader screenshot and accessibility/Dynamic Type evidence, per-bucket HIG gates, remediation slices for findings, and a final closure slice. Do not claim all-locale `hig-ui-reviewed` yet.
- **All-locale HIG evidence matrix**: created on 2026-05-18 under [`automation/proofs/app-localization-hig-ui-matrix/`](../../automation/proofs/app-localization-hig-ui-matrix/). Records per-locale `gate_state`, scoped surface coverage, open and closed findings, and the canonical `HIG-<LOCALE_UPPER>-<NNN>` finding taxonomy. As of 2026-05-18: 7 open findings (`HIG-DE-001` in-progress + `HIG-DE-002`/`HIG-FR-001`/`HIG-NL-001`/`HIG-RU-001`/`HIG-TR-001`/`HIG-UK-001` open from the doc-only bucket gates, all Train/Write tab-bar truncation risks), 0 closed findings, 0 locales `hig-ui-reviewed`.
- **Remaining-LTR HIG gate**: started 2026-05-18 under [`automation/proofs/app-localization-remaining-ltr-hig-ui-gate/`](../../automation/proofs/app-localization-remaining-ltr-hig-ui-gate/) for `fr`, `it`, `nb`, `pt`, `pt-BR`, `es`, `vi`. Result: **fail**. Doc-only gate based on source-trace inspection plus a validated multisurface-harness dry-run; no screenshot evidence preserved. HIG-FR-001 open for French Today tab label `Aujourd'hui` (11 chars vs en `Today` 5 chars) — tab-bar truncation risk on smaller iPhone widths. Six other locales have no source-level HIG findings but cannot pass without screenshot evidence.
- **Long-script HIG gate**: started 2026-05-18 under [`automation/proofs/app-localization-long-script-hig-ui-gate/`](../../automation/proofs/app-localization-long-script-hig-ui-gate/) for `de`, `nl`, `ru`, `sv`, `tr`, `uk`. Result: **fail**. Doc-only gate based on source-trace inspection plus a validated multisurface-harness dry-run; no screenshot evidence preserved. Allocates HIG-DE-002/NL-001/RU-001/TR-001/UK-001 (all open, major, adaptive-layout) for Train/Write tab labels significantly longer than English. Swedish has no source-level HIG risk. German retains the prior HIG-DE-001 from the original German HIG gate. Translation-quality notes (NOT HIG defects) flagged for `ru/uk` Write tab (entry/recording semantics) — need native review.
- **CJK HIG gate**: started 2026-05-18 under [`automation/proofs/app-localization-cjk-hig-ui-gate/`](../../automation/proofs/app-localization-cjk-hig-ui-gate/) for `ja`, `ko`, `zh-Hans`, `zh-Hant`. Result: **fail**. Doc-only gate based on source-trace inspection plus a validated multisurface-harness dry-run; no screenshot evidence preserved. Allocates HIG-JA-001 (open, major, adaptive-layout) for Japanese Train tab katakana label `トレーニング` (6 chars, each glyph ~2x Latin width). Korean / Simplified Chinese / Traditional Chinese tab labels are uniformly compact (1-2 ideographs) and have no source-level HIG risk.
- **Arabic RTL HIG gate**: started 2026-05-18 under [`automation/proofs/app-localization-rtl-hig-ui-gate-ar/`](../../automation/proofs/app-localization-rtl-hig-ui-gate-ar/). Result: **fail**. Allocates 3 open findings: HIG-AR-001 (`chevron.right` in TodayView does not auto-mirror under RTL), HIG-AR-002 (`arrow.right.circle` in WriteView at 2 call sites does not auto-mirror), and HIG-AR-003 (`Career` tab label `المسيرة المهنية` at 15 chars — longest Career label across all 19 locales). HIG-AR-001 and HIG-AR-002 are source-level defects with a deterministic SwiftUI rule (`.right`/`.left` SF Symbols do not auto-mirror; `.forward`/`.backward` do); they should be fixed regardless of screenshot evidence. 8 bucket-gate adaptive-layout findings total now share the tab-bar truncation fix shape (HIG-AR-003, HIG-DE-002, HIG-FR-001, HIG-JA-001, HIG-NL-001, HIG-RU-001, HIG-TR-001, HIG-UK-001).
- **HIG remediation triage**: completed 2026-05-18. All 4 bucket-gate slices plus the German re-gate are done. 11 open findings total (HIG-DE-001 in-progress + 10 new). Triage queued three narrow remediation slices: (a) `app-localization-rtl-sf-symbol-fix` (priority 79; source fix for HIG-AR-001 + HIG-AR-002); (b) `app-localization-hig-multisurface-screenshot-capture` (priority 78; preserves screenshot evidence for HIG-DE-001 rerun + the 8 tab-truncation findings); (c) `app-localization-tab-bar-truncation-fix` (priority 77; conditional on capture confirming truncation; addresses the 8 adaptive-layout findings together). `app-localization-all-locale-hig-ui-closure` remains blocked until all three complete.
- **HIG multisurface screenshot capture**: completed 2026-05-18 (proof_level: screenshot-verified for the today launch surface only). Landed 18 Today-surface screenshots (one per non-English locale) under [`automation/proofs/app-localization-hig-multisurface-screenshot-harness/20260518T103428Z-today-capture/`](../../automation/proofs/app-localization-hig-multisurface-screenshot-harness/20260518T103428Z-today-capture/). Findings outcome: HIG-AR-001 closed-fixed (Arabic chevron auto-mirrors under RTL). The 8 tab-truncation findings (HIG-AR-003 + HIG-DE-002 + HIG-FR-001 + HIG-JA-001 + HIG-NL-001 + HIG-RU-001 + HIG-TR-001 + HIG-UK-001) downgraded from major to minor: iOS auto-shrinks long tab labels at iPhone 17 portrait default Dynamic Type, so literal truncation does not occur. Remaining real risk: smaller iPhone widths, larger Dynamic Type, VoiceOver users seeing reduced text. HIG-AR-002 stays in-progress (WriteView Arabic not captured this run). HIG-DE-001 stays in-progress (evening-reflection state not directly captured; launch-surface English regression confirmed absent).
- **German HIG localized UI gate**: started on 2026-05-18 and failed on HIG-DE-001 (English reflection nudge copy in the German Today surface). Re-gated on 2026-05-18 after `app-localization-evening-reflection-nudge-routing` landed the source fix (commit `1cd9f5e`). HIG-DE-001 is now in state `in-progress` with `source_fix_confirmed=true`; the gate result remains `fail` because no post-fix screenshot has been preserved under `automation/proofs/`, and the scoped UI evidence set is still incomplete. Do not claim German `hig-ui-reviewed` until the post-fix screenshot lands and the remaining scoped HIG surfaces are captured.
- **Translation quality**: proven only for German within the reviewed return-file scope. LLM-drafts are visible to users in the other 17 non-English locales, but wording, idiom, grammar, gender, formality, and argument order have NOT been validated by native speakers there. Subtle errors remain likely outside German.

English (`en`) remains the source language and key source of truth. The approved non-English locales are: `ar`, `nl`, `fr`, `de`, `it`, `ja`, `ko`, `nb`, `pt`, `pt-BR`, `ru`, `es`, `sv`, `zh-Hans`, `zh-Hant`, `tr`, `uk`, and `vi`.

As of 2026-05-18: German (`de`) is native-reviewed for the 419 entries tracked in `localization/review/de/german-review-return.json`. Every other non-English `Localizable.strings` and `Localizable.stringsdict` file under `owlory_xcode/Owlory/Resources/<locale>.lproj/` contains LLM-drafted values produced by `claude-opus-4-7`, recorded with `needs-layout-check`, `keep-english-term`, or `needs-translation` statuses. Users running the app in those other languages will see LLM-drafted text instead of English placeholders, but translation quality must not be claimed for them until native review is supplied.

## Status Labels

Use these labels in handoffs and review notes:

| Label | Meaning | Can claim translation quality? |
| --- | --- | --- |
| `english-source` | English source key/value reviewed as product copy. | Only for `en`. |
| `english-placeholder` | Non-English locale value is intentionally copied from English. | No. |
| `draft-translation` | Candidate translated value exists but has not been reviewed by a native or fluent reviewer. | No. |
| `native-reviewed` | Native or fluent reviewer accepted the locale values for the scoped keys. | Yes, for reviewed keys only. |
| `build-info-observed` | Version/build/commit fields were observed on an installed app, but the screenshot or full provenance bundle is incomplete. | No by itself. |
| `hig-ui-reviewed` | Scoped localized UI surfaces were reviewed against Apple HIG layout, typography, accessibility, labels, and RTL expectations. | Yes, for scoped UI surfaces only. |
| `runtime-smoked` | The locale launched in the simulator after translation replacement. | No by itself. |
| `screenshot-reviewed` | Repo-managed screenshot evidence exists for the translated surface. | No by itself; it proves visual evidence, not language quality. |
| `internal-reviewer-signoff` | Project owner / internal product reviewer (not a native speaker) accepted current LLM-drafted text as the baseline for downstream HIG gating. | **No.** Explicitly does not claim translation quality, native review, or fluent review. |

## Internal-Reviewer Signoff (Non-Native)

This label records the case where the project owner accepts the current LLM-drafted text *as the baseline for downstream HIG bucket-gate work*, without obtaining a native or fluent reviewer signoff. It is honest about what it is and is not.

What an `internal-reviewer-signoff` does allow:

- Running HIG bucket-gate slices against the current localized resources (visible-label checks, layout regression, Dynamic Type, accessibility presence, RTL mirroring, etc.).
- Removing the `app-localization-native-review-<locale>` slices from the `depends_on` lists of those HIG gates so the queue can progress on HIG/UI evidence without waiting on a native speaker.

What an `internal-reviewer-signoff` does **not** allow:

- Claiming the locale is `native-reviewed` or `hig-ui-reviewed` for label/action clarity.
- Flipping `provenance.native_reviewed` to `true` in any per-locale return file.
- Flipping any per-entry `review_status` to `native-reviewed`.
- Claiming translation quality, idiom, register, grammar, gender, or formality correctness.
- Closing the `app-localization-native-review-<locale>` slices. They remain parked with `blocked` status and an entry condition that requires a real native/fluent reviewer.

Recording the signoff:

1. Add a `provenance.internal_reviewer_signoff` block to the per-locale return file at `localization/review/<locale>/<locale>-review-return.json`:
   - `internal_reviewer_signoff: true`
   - `internal_reviewer_signoff_basis: "internal-reviewer (not native speaker)"`
   - `internal_reviewer_signoff_by: "<role or identifier>"`
   - `internal_reviewer_signoff_at: "<YYYY-MM-DD>"`
   - `internal_reviewer_signoff_scope: "<exactly what this permits, with explicit non-claims>"`
   - `internal_reviewer_signoff_does_not_change: ["provenance.native_reviewed remains false", ...]`
2. Update the HIG bucket-gate slices' `depends_on` to drop `app-localization-native-review-<locale>` references and append a note that internal-reviewer signoff is the baseline.
3. Leave the per-locale `app-localization-native-review-<locale>` slice `blocked` with its entry condition unchanged; append a note pointing at the internal-reviewer signoff record.

A future native or fluent reviewer can still complete the original native-review slice and flip `provenance.native_reviewed` to `true`. Internal-reviewer signoff is additive, not a substitute.

## Native Language Review Protocol

Use this protocol before marking any new locale or key as `native-reviewed`. A chat message, a single screenshot, or "looks good" approval is not enough by itself.

1. **Open a scoped review slice**: one locale per slice unless a small language family is explicitly being reviewed by the same qualified reviewer. Record the target locale, expected entry count, review packet paths, and whether the scope is all keys or a named subset.
2. **Freeze the review baseline**: regenerate the packet with `python3 Tools/localization-review-export.py --output-dir localization/review`, then record `git rev-parse HEAD`, `make build-provenance`, app version, build number, and the target return file. Do not accept review against an unknown source state.
3. **Gate TestFlight/device provenance first**: for TestFlight review, the reviewer must capture Build Info before reviewing language surfaces. Required fields are version, build, commit or full commit, branch, and any visible source-clean/releaseability fields. The installed build must match committed source. If the screenshot is chat-only, missing the binary artifact, or missing fields, classify it as `build-info-observed` only.
4. **Send the reviewer packet and glossary**: provide the locale review packet, product terminology list, style notes, and the [native review intake template](../../localization/review/native-review-intake-template.md). Ask the reviewer to mark accepted entries, corrections, terms intentionally kept in English, and any product decisions needed.
5. **Run a device language pass**: the reviewer should set Owlory's per-app language, force-close and reopen the app, then inspect the agreed surfaces. At minimum for full-locale review, capture Build Info, Today, each root tab, empty states, primary actions, and any high-risk plural/count/date screens. RTL and CJK locales require screenshots for layout-sensitive surfaces.
6. **Run the Apple HIG localized UI gate**: every scoped localized UI must satisfy Apple's Human Interface Guidelines for platform consistency, adaptive layout, typography, accessibility, labels, locale-aware formatting, and right-to-left behavior where relevant. Do not claim localized UI readiness if text clips, overlaps, truncates critical meaning, breaks Dynamic Type, exposes nonlocalized accessibility copy, or uses directional controls incorrectly.
7. **Return structured signoff**: the reviewer returns the completed intake template plus corrected values. Personal identity can be an internal reviewer ID, vendor, or role, but the file must state the reviewer basis: native speaker, fluent speaker, vendor, or internal product reviewer.
8. **Intake the review**: update only accepted scoped entries to `native-reviewed`. Keep unresolved keys as `needs-product-decision`, `needs-layout-check`, `keep-english-term`, or `needs-translation`. Preserve corrected values in the locale resources only after validation.
9. **Preserve proof artifacts**: store screenshot files under `automation/proofs/` when available, with a manifest containing file names, SHA-256 hashes, dimensions, locale, device/build info, and capture date. If screenshots arrive only in chat, record the observation honestly and do not claim repo-managed screenshot proof.
10. **Validate and hand off**: run `make architecture`, `make localization-check`, `./Tools/validate.sh localization`, `python3 Tools/localization-review-status.py`, `make automation-check`, and `git diff --check`. The handoff must identify the reviewed locale, entry count, reviewer basis, Build Info result, HIG gate result, proof artifacts, and remaining unreviewed locales.

Proof claims are cumulative:

- `native-reviewed` requires completed reviewer signoff for scoped keys.
- `hig-ui-reviewed` requires a completed Apple HIG localized UI gate for scoped surfaces.
- `screenshot-reviewed` requires committed screenshot artifacts.
- `device-verified` requires device proof with build provenance and preserved artifacts.
- `testflight-verified` requires TestFlight Build Info that matches committed source plus preserved TestFlight evidence for the reviewed surfaces.

## Apple HIG Localized UI Gate

Every localized UI surface must adhere to Apple Human Interface Guidelines before it can be called UI-ready. Use Apple's current HIG as the source of truth:

- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines)
- [Layout](https://developer.apple.com/design/human-interface-guidelines/layout)
- [Typography](https://developer.apple.com/design/human-interface-guidelines/typography)
- [Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility/)
- [Labels](https://developer.apple.com/design/human-interface-guidelines/labels)
- [Right to left](https://developer.apple.com/design/human-interface-guidelines/right-to-left)

The all-locale completion plan and queued proof ladder are maintained in [Localization HIG UI Completion](localization-hig-ui-completion.md).

Minimum localized UI gate:

1. **Platform consistency**: use Apple platform conventions, system controls, safe areas, tab/navigation patterns, and SF Symbols or direction-aware symbols where possible.
2. **Adaptive layout**: localized text must fit at supported device widths and orientations without overlap, clipped controls, hidden actions, or layout jumps. Long localized strings must wrap or reflow deliberately.
3. **Typography and Dynamic Type**: text must remain legible with standard and larger accessibility text sizes. Critical labels, buttons, and values must not lose meaning from truncation.
4. **Accessibility**: localized accessibility labels, hints, values, reading order, contrast, and touch targets must remain understandable in the target locale.
5. **Labels and actions**: visible labels must be concise, idiomatic, and clear about state or action. Buttons and tab labels must remain recognizable after translation.
6. **Locale-aware formatting**: dates, times, counts, plurals, units, and number ordering must use locale-aware formatting rather than string concatenation.
7. **Right-to-left behavior**: RTL locales must mirror layout, alignment, navigation affordances, ordered controls, and directional interface icons as appropriate. Do not reverse digits inside a number. Do not flip artwork or images whose meaning would change.
8. **Evidence**: full-locale UI review needs screenshots or equivalent reviewer evidence for Build Info, Today, root tabs, primary empty states, primary actions, high-risk plural/count/date surfaces, and one accessibility text-size pass. RTL locales also require at least one RTL layout screenshot for each high-risk surface.

Fail the HIG gate and queue a UI/layout fix when any scoped localized surface has unreadable text, clipped or overlapping controls, broken interaction, incorrect reading direction, nonlocalized accessibility copy, ambiguous translated actions, or an Apple-platform pattern regression.

## Review Workflow

1. Pick one locale or one small language family per slice. Do not bulk-replace all locales in one pass.
2. Start from the review packet in `localization/review/`, regenerated from current resources when needed.
3. Translate only existing keys unless the slice is explicitly a source-string extraction slice.
4. Preserve placeholders for keys outside the slice. Do not delete or invent locale-only keys.
5. For `.stringsdict`, review grammar for `one` and `other` forms even when the locale does not use English plural categories naturally.
6. Record the reviewer basis in the handoff: native reviewer, fluent reviewer, vendor, or machine draft awaiting review.
7. Run validation before claiming the locale is accepted.

Machine or AI translation may produce `draft-translation`, but it cannot produce `native-reviewed` without a human reviewer record.

## Review Export Packet

Regenerate the reviewer packet before translation replacement work:

```bash
python3 Tools/localization-review-export.py --output-dir localization/review
```

The export reads `Localizable.strings` and `Localizable.stringsdict` from all approved locales, keeps English as the source row, labels non-English values that still match English as `english-placeholder`, and writes:

- `localization/review/translation-review-export.csv`
- `localization/review/translation-review-export.json`
- `localization/review/README.md`

The packet is reviewer input only. It does not claim translation completeness, native review, launch stability, layout correctness, device behavior, or TestFlight behavior.

## Acceptance Criteria

A future translation replacement slice may claim translation quality only for its scoped locale and keys when all of these are true:

- `make localization-check` passes.
- `./Tools/validate.sh localization` passes.
- `make architecture` passes.
- No approved locale has missing or extra keys.
- No new locale folder is introduced unless the target locale list is deliberately changed.
- The handoff identifies which keys changed and which reviewer accepted them.
- The reviewer returned the native review intake template or an equivalent structured signoff.
- Localized UI claims include a completed Apple HIG localized UI gate for the scoped surfaces.
- Placeholders outside the slice remain explicitly classified as placeholders.
- A locale smoke or screenshot proof is run when the slice changes high-visibility navigation, Today launch surfaces, notification copy, or RTL/CJK text.

## Locale Review Notes

- `ar`: Requires Arabic review and RTL screenshot review for visible surfaces before release-quality claims.
- `zh-Hans` and `zh-Hant`: Review separately. Do not treat Simplified and Traditional Chinese as interchangeable.
- `pt` and `pt-BR`: Review separately. Do not copy one into the other without explicit reviewer acceptance.
- `nb`: Treat as Norwegian Bokmål. Do not replace with generic Norwegian without review.
- `ja` and `ko`: Review typography-sensitive short labels and truncation-prone surfaces with screenshots.
- `de`, `nl`, `sv`, `ru`, `uk`, and `tr`: Watch compound words, grammatical case, and truncation in tab labels, buttons, and notification bodies.

## Terminology To Review Deliberately

These product terms should not be translated casually or inconsistently:

- `Owlory`
- `Today`
- `Train`
- `Write`
- `Career`
- `Home`
- `Continue`
- `Focus Three`
- `Check-in`
- `Protocol`
- `Reminder`
- `Weekly Digest`
- `Reflection`

For each locale, the reviewer may choose translated or retained product terms, but the choice must be consistent across the locale.

## What Not To Do

- Do not change English product copy inside a translation slice unless the slice explicitly owns English source copy.
- Do not localize persisted identifiers, enum raw values, storage paths, telemetry names, route names, SF Symbol names, color asset names, or build diagnostics.
- Do not add user-visible placeholder warnings.
- Do not claim translation completeness from parity checks, simulator launch, or screenshots alone.
- Do not use translation work to fix layout; queue a separate layout slice if translated text exposes a UI issue.
- Do not treat the representative localization-layout regression as translation quality or full layout correctness; it proves launch-shell stability under locale arguments only.

## Validation

Planning-only slices use:

```bash
python3 automation/context/build_context.py --slice-id app-localization-translation-quality-plan
python3 automation/supervisor/run_next.py --dry-run
make architecture
make localization-check
./Tools/validate.sh localization
make automation-check
git diff --check
```

Translation review export slices use:

```bash
python3 Tools/localization-review-export.py --output-dir localization/review
make architecture
make localization-check
./Tools/validate.sh localization
make automation-check
git diff --check
```

Translation replacement slices should add the affected locale smoke command and screenshot proof when the changed keys affect high-visibility launch or navigation surfaces.

## German First Review Packet

The first locale review packet is prepared under:

```text
localization/review/de/
```

It contains:

- `german-review-packet.csv`
- `german-review-packet.json`
- `README.md`

Use this packet to collect reviewed German values and reviewer/status metadata when German resources change again. It is not an app-resource replacement. The accepted German review state is now recorded in `localization/review/de/german-review-return.json`, which was refreshed to 419 entries and marked native-reviewed on 2026-05-18 based on user-reported native/human German review.

## Manual Device Review

For TestFlight or physical-device translation review, testers may switch only Owlory's app language instead of changing the whole phone:

```text
Settings > Apps > Owlory > Language
```

If the Owlory language picker does not appear, add the target language first:

```text
Settings > General > Language & Region > Add Language
```

Keep the current iPhone language as primary unless the slice is explicitly testing full-device language behavior. Then return to Owlory's per-app language setting, select the target language, close Owlory, and reopen it.

For TestFlight review, open Owlory Build Info first and capture version, build, commit or full commit, branch, and any source-clean/releaseability fields before taking language screenshots. If Build Info does not match committed source, stop the TestFlight proof lane and record the mismatch before reviewing language surfaces.

Use this only for manual/TestFlight review. Automated localization smoke should continue using `python3 automation/smoke/running_app_smoke.py --locale <locale>` and launch arguments, not the Settings app.

If German or another target language does not appear in Owlory's per-app language picker, do not classify the locale as translation-failed yet. First run the manual language-setting diagnostic from [Validation Workflows](validation.md#manual-per-app-language-testing): confirm the language is in the iPhone's preferred language list, verify the installed build packages the matching `.lproj` resources, and inspect whether the installed build needs explicit `CFBundleLocalizations` metadata.
