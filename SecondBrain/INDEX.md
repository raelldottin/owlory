# Second Brain Index

## 2026-05-19

- [app-localization-review-drift-check-non-macos-portability (build-tested; plistlib-first / plutil-fallback / explicit StringsdictParseError on both-fail; 5 new tests; baseline unchanged 0 drift)](sessions/2026-05-19/082459-app-localization-review-drift-check-non-macos-portability.md)
- [queue-three-drift-check-gap-slices (queue-only; 3 follow-up slices for the drift-check gaps: stringsdict-coverage pri 60, gate-promotion pri 59, non-macos-portability pri 40)](sessions/2026-05-19/074015-queue-three-drift-check-gap-slices.md)

## 2026-05-18

- [app-localization-review-drift-check (build-tested; Tools/localization-review-drift-check.py + Makefile target + 10 unit tests + docs; baseline 0 drift across 18 locales; 377 strings + 13 stringsdict keys)](sessions/2026-05-18/190130-app-localization-review-drift-check.md)
- [queue-five-follow-up-slices (queue-only; 3 queued + 2 blocked follow-up slices: smaller-width accessibility regression, VoiceOver verification, review drift check, device-verified proof, testflight-verified proof)](sessions/2026-05-18/185451-queue-five-follow-up-slices.md)
- [hig-testflight-not-required-policy (doc-only policy clarification: TestFlight HIG proof is not required for the hig-ui-reviewed claim; automated simulator proof + maintained accessibility regression is the accepted bar; no per-locale state change)](sessions/2026-05-18/173838-hig-testflight-not-required-policy.md)
- [app-localization-hig-ui-proof-closure (complete repo-managed HIG UI proof and evidence matrix closure after native/fluent review is complete)](sessions/2026-05-18/123806-app-localization-hig-ui-proof-closure.md)
- [blocked-hig-closure-completion-walkthrough (process to unblock final all-locale HIG closure: capture missing scoped proof, close HIG-DE-001/HIG-AR-002, update matrix/docs, run validation)](sessions/2026-05-18/081225-blocked-hig-closure-completion-walkthrough.md)
- [localization-hig-compliance-status-check (not complete; native/fluent review done, but HIG matrix has 0 claimed locales, HIG-DE-001/HIG-AR-002 pending proof, final closure parked)](sessions/2026-05-18/081144-localization-hig-compliance-status-check.md)
- [start-next-slice-clean-stop-after-native-review (no eligible queued slice; all native/fluent review intake complete; final HIG closure remains parked on scoped proof conditions)](sessions/2026-05-18/080952-start-next-slice-clean-stop-after-native-review.md)
- [app-localization-all-locale-native-review (doc-only intake; all 18 non-English locale return files now native/fluent-reviewed, 7,542 native-reviewed entries; HIG UI readiness still not claimed)](sessions/2026-05-18/075551-app-localization-all-locale-native-review.md)
- [start-next-slice-clean-stop-repeat-4 (no eligible queued slice after fresh fetch; clean-stop still passed; repo clean/mirrored)](sessions/2026-05-18/074443-start-next-slice-clean-stop-repeat-4.md)
- [start-next-slice-clean-stop-repeat-3 (no eligible queued slice after fresh fetch; clean-stop still passed; parked localization blockers unchanged)](sessions/2026-05-18/073839-start-next-slice-clean-stop-repeat-3.md)
- [start-next-slice-clean-stop-repeat-2 (no eligible queued slice after fresh fetch; clean-stop still passed; 18 parked localization blockers unchanged)](sessions/2026-05-18/073237-start-next-slice-clean-stop-repeat-2.md)
- [start-next-slice-clean-stop-repeat (no eligible queued slice; clean-stop still passed after fresh fetch; repo clean/mirrored)](sessions/2026-05-18/073037-start-next-slice-clean-stop-repeat.md)
- [start-next-slice-clean-stop (no eligible queued slice after Pyright validation chain; clean-stop passed; 18 parked localization review/closure slices retain explicit entry conditions)](sessions/2026-05-18/072930-start-next-slice-clean-stop.md)
- [automation-pyright-tighten-severities (build-tested; fixed the remaining Pyright warnings; reportArgumentType/reportOptionalSubscript/reportAssignmentType restored to error; make automation-check now runs make pyright; standalone make pyright 0 errors / 0 warnings)](sessions/2026-05-18/072259-automation-pyright-tighten-severities.md)
- [automation-pyright-validation (build-tested; pyrightconfig.json + make pyright gate; production fix in Tools/localization-review-export.py (NoReturn); baseline 0 errors / 23 warnings; cleanup queued as automation-pyright-tighten-severities)](sessions/2026-05-18/110408-automation-pyright-validation.md)
- [app-localization-tab-bar-truncation-fix (regression-tested; REFRAMED to maintained-coverage; 7 new AccessibilityXL XCUITest cases for fr/ja/nl/ru/tr/uk/ar; 15-test DOMAIN=localization suite passes in 91.8s; closes 8 tab-truncation findings via closed-maintained-coverage state)](sessions/2026-05-18/105800-app-localization-tab-bar-truncation-fix.md)
- [app-localization-multisurface-capture-final-move-fix (backfilled record; harness final-move ran AFTER temp staging dir was deleted by `with` exit, fixed inline 2026-05-18T10:41 and shipped in commit 028a511; surfaced as a named slice after user asked to record the scope deviation)](sessions/2026-05-18/104143-app-localization-hig-multisurface-screenshot-capture.md)
- [app-localization-hig-multisurface-screenshot-capture (screenshot-verified today surface only; 18 PNGs preserved; HIG-AR-001 closed-fixed; 8 tab-truncation findings downgraded major→minor; iPhone 17 portrait default Dynamic Type; fixed harness bug inline)](sessions/2026-05-18/104143-app-localization-hig-multisurface-screenshot-capture.md)
- [app-localization-rtl-sf-symbol-fix (build-tested; chevron.right→chevron.forward in TodayView:566 + arrow.right.circle→arrow.forward.circle in WriteView:88,181; HIG-AR-001 + HIG-AR-002 moved to in_progress with source_fix_confirmed=true; xcodebuild exit 0)](sessions/2026-05-18/102720-app-localization-rtl-sf-symbol-fix.md)
- [app-localization-hig-remediation-triage (doc-only; 11 open HIG findings triaged into 3 narrow remediation slices: rtl-sf-symbol-fix pri 79, multisurface-screenshot-capture pri 78, tab-bar-truncation-fix pri 77; matrix updated with per-finding remediation pointers)](sessions/2026-05-18/102227-app-localization-hig-remediation-triage.md)
- [app-localization-rtl-hig-ui-gate-ar (doc-only; Arabic RTL HIG gate; result fail; 3 new findings — HIG-AR-001 chevron.right TodayView:566 + HIG-AR-002 arrow.right.circle WriteView:88,181 are source-level RTL defects, HIG-AR-003 Career tab truncation; all 4 bucket gates now complete)](sessions/2026-05-18/101657-app-localization-rtl-hig-ui-gate-ar.md)
- [app-localization-cjk-hig-ui-gate (doc-only; HIG gate for ja/ko/zh-Hans/zh-Hant; result fail; HIG-JA-001 open for Japanese 'トレーニング' Train tab katakana truncation; ko/zh-Hans/zh-Hant clean at source level; 7 tab-truncation findings now total across bucket gates)](sessions/2026-05-18/101119-app-localization-cjk-hig-ui-gate.md)
- [app-localization-long-script-hig-ui-gate (doc-only; HIG gate for de/nl/ru/sv/tr/uk; result fail; 5 new findings HIG-DE-002/NL-001/RU-001/TR-001/UK-001 for Train/Write tab truncation; HIG-DE-001 carried; sv clean at source level; harness dry-run validated for 42 captures)](sessions/2026-05-18/100452-app-localization-long-script-hig-ui-gate.md)
- [app-localization-remaining-ltr-hig-ui-gate (doc-only; HIG gate for fr/it/nb/pt/pt-BR/es/vi under internal-reviewer signoff baseline; result fail because no preserved screenshots; HIG-FR-001 open for French 'Aujourd'hui' tab-bar truncation risk; harness dry-run validated for 49 captures)](sessions/2026-05-18/063437-app-localization-remaining-ltr-hig-ui-gate.md)
- [internal-reviewer-signoff-non-german-locales (doc-only/metadata-only; project-owner internal-reviewer signoff recorded in 17 non-German return files; HIG bucket-gate native-review depends_on removed; native_reviewed flags stay false; entries stay needs-layout-check; 4 bucket gates now unblocked)](sessions/2026-05-18/052000-internal-reviewer-signoff-non-german-locales.md)
- [start-next-slice-clean-stop (no eligible queued slice; 5 HIG bucket-gate/remediation slices queued but all transitively blocked on 17 non-German native-review intake slices)](sessions/2026-05-18/051731-start-next-slice-clean-stop.md)
- [app-localization-german-hig-ui-regate (doc-only; German HIG gate re-run after HIG-DE-001 source fix landed; HIG-DE-001 moved from blocking_findings to in_progress_findings with source_fix_confirmed=true; gate result still fail because no post-fix screenshot preserved)](sessions/2026-05-18/051232-app-localization-german-hig-ui-regate.md)
- [app-localization-hig-dynamic-type-accessibility-harness (regression-tested; LocalizationAccessibilityRegression XCUITest class with 4 tests covers Dynamic Type AccessibilityXL en/de shell settle, root tab non-empty accessibility labels, ≥44pt tab touch targets; ui-regression DOMAIN=localization now runs 8 tests)](sessions/2026-05-18/050515-app-localization-hig-dynamic-type-accessibility-harness.md)
- [app-localization-hig-multisurface-screenshot-harness (build-tested; new automation/smoke/capture_localized_surfaces.py with 8-surface catalog, 4 modes, 14 new tests; Makefile target + proof dir + docs wired; no --capture run landed)](sessions/2026-05-18/045832-app-localization-hig-multisurface-screenshot-harness.md)
- [app-localization-hig-evidence-matrix (doc-only; all-locale HIG evidence matrix + finding taxonomy under automation/proofs/app-localization-hig-ui-matrix/; HIG-DE-001 in-progress, 17 non-German locales blocked-on-native-review, 0 locales claimed hig-ui-reviewed)](sessions/2026-05-18/045000-app-localization-hig-evidence-matrix.md)
- [app-localization-hig-ui-completion-slicing (doc-only; all-locale Apple HIG completion ladder queued; 17 non-German native-review blockers preserved)](sessions/2026-05-18/003534-app-localization-hig-ui-completion-slicing.md)
- [start-next-slice-clean-stop (no eligible queued slice available after evening reflection routing; no product changes)](sessions/2026-05-18/002759-start-next-slice-clean-stop.md)
- [app-localization-evening-reflection-nudge-routing (domain-tested; Today visible reflection nudge now semantic in Store and localized in TodayView; German HIG evidence still pending)](sessions/2026-05-18/042120-app-localization-evening-reflection-nudge-routing.md)
- [app-localization-german-hig-ui-gate-intake (doc-only; German HIG gate started and failed on visible English evening-reflection nudge copy; fix slice queued)](sessions/2026-05-18/022906-app-localization-german-hig-ui-gate-intake.md)
- [app-localization-hig-ui-review-gate (doc-only; every localized UI readiness claim now requires an Apple HIG gate)](sessions/2026-05-18/022159-app-localization-hig-ui-review-gate.md)
- [app-localization-native-review-formal-workflow (doc-only; formal native-review intake protocol + template; Karoline Build Info recorded as build-info-observed, not full TestFlight proof)](sessions/2026-05-18/021206-app-localization-native-review-formal-workflow.md)
- [app-localization-german-device-screenshot-proof-record (doc-only; Karoline's German iPhone Today screenshot observed in chat, binary not repo-managed, no TestFlight/device-verified claim)](sessions/2026-05-18/012138-app-localization-german-device-screenshot-proof-record.md)
- [app-localization-native-review-intake (build-tested; German native/human review accepted 419/419 entries; other 17 locales remain unreviewed)](sessions/2026-05-18/010852-app-localization-native-review-intake.md)

## 2026-05-17

- [start-next-slice-clean-stop (no eligible queued slice; clean-stop passed; native-review intake remains blocked)](sessions/2026-05-17/151649-start-next-slice-clean-stop.md)
- [app-localization-calibration-rules-helper-copy-routing (build-tested + train/write/patterns-tested; CalibrationRules writing/training outputs now semantic; Train/Write format through 4 localized keys × 19 locales)](sessions/2026-05-17/150141-app-localization-calibration-rules-helper-copy-routing.md)
- [app-localization-readiness-rules-helper-copy-routing (build-tested + domain-tested; ReadinessRules.Nudge now semantic Kind + suggestedMaxPriorities; Today formats through 9 today.readiness.nudge.* keys × 19 locales)](sessions/2026-05-17/103206-app-localization-readiness-rules-helper-copy-routing.md)
- [app-localization-pattern-nudge-rules-helper-copy-routing (build-tested + domain-tested; PatternNudgeRules.DomainNudge now semantic LifeDomain only; Today formats through today.domainNudge.focusMissing × 19 locales)](sessions/2026-05-17/095354-app-localization-pattern-nudge-rules-helper-copy-routing.md)
- [app-localization-focus-suggestion-reason-routing (build-tested + domain-tested; FocusSuggestionRules.Reason semantic struct with Completion/Timing/ReadinessContext enums; structural refactor restores Domain/Features boundary; 12 new today.focus.suggestion.* keys × 19 locales)](sessions/2026-05-17/091659-app-localization-focus-suggestion-reason-routing.md)
- [app-localization-continue-row-subtitle-routing (build-tested + domain-tested; ContinueSubtitleKind semantic enum; structural refactor restores Application/Features boundary; 6 new today.continue.subtitle.* keys × 19 locales)](sessions/2026-05-17/090132-app-localization-continue-row-subtitle-routing.md)
- [app-localization-today-header-greeting-routing (build-tested; 6 new today.header.greeting.* keys × 19 locales; headerGreeting 6 branches wrapped in String(localized:))](sessions/2026-05-17/075934-app-localization-today-header-greeting-routing.md)
- [app-localization-readiness-anchors-routing (build-tested; 9 new keys × 19 locales; 6 anchor tuple call sites in Today + Train routed via String(localized:))](sessions/2026-05-17/074138-app-localization-readiness-anchors-routing.md)
- [app-localization-helper-generated-copy-audit (doc-only; 4 TestFlight screenshots → ~30+ helper-built English strings across 6 files; 7 narrow follow-up slices queued)](sessions/2026-05-17/020723-app-localization-helper-generated-copy-audit.md)

## 2026-05-16

- [app-localization-return-files-refresh (doc-only; 18 return files refreshed 356 → 372 entries each; LQA / dashboard / German packet / all-locale export all current)](sessions/2026-05-16/184324-app-localization-return-files-refresh.md)
- [app-localization-string-interpolation-formatters (build-tested; 8 interpolation sites rewired through 6 new format-string keys × 19 locales; TrainView reuses Today readiness stringsdict via new helper)](sessions/2026-05-16/182802-app-localization-string-interpolation-formatters.md)
- [app-localization-audio-voice-button-accessibility-routing (build-tested; 8 new keys × 19 locales; AudioPlaybackButton + VoiceCaptureButton accessibility text now localized)](sessions/2026-05-16/121000-app-localization-audio-voice-button-accessibility-routing.md)
- [app-localization-accessibility-bypass-audit (doc-only; 22 sites scanned, 7 already-safe via helpers, 2 real bypasses in DesignSystem audio/voice buttons; 1 narrow follow-up queued)](sessions/2026-05-16/062009-app-localization-accessibility-bypass-audit.md)
- [app-localization-complete-nls-routing-pass (build-tested; 130 sites routed through L() across 8 files; supersedes 7 surface slices + button-verify)](sessions/2026-05-16/054329-app-localization-complete-nls-routing-pass.md)
- [app-localization-visible-string-bypass-audit (doc-only; 400 candidates, 116 must-fix, 10 follow-up slices queued)](sessions/2026-05-16/013410-app-localization-visible-string-bypass-audit.md)

## 2026-05-15

- [app-localization-automated-lqa-and-llm-quality-pass (doc-only; 6354 passed / 54 warning / 0 reverted across 18 locales; NOT a native-review claim)](sessions/2026-05-15/210004-app-localization-automated-lqa-and-llm-quality-pass.md)
- [app-localization-native-review-tracking-dashboard (doc-only; reports 0 native-reviewed across 18 LLM-drafted locales)](sessions/2026-05-15/190123-app-localization-native-review-tracking-dashboard.md)
- [app-localization-all-locale-llm-draft-intake (17 remaining locales LLM-drafted by claude-opus-4-7, NOT native-reviewed; build-tested)](sessions/2026-05-15/181907-app-localization-all-locale-llm-draft-intake.md)
- [app-localization-first-locale-review-intake (German LLM-drafted by claude-opus-4-7, NOT native-reviewed; build-tested)](sessions/2026-05-15/162026-app-localization-first-locale-review-intake.md)
- [owlory-ui-regression-batch-7-localization-layout-shell (running-app-smoke; en/de/ar/zh-Hans launch-shell only)](sessions/2026-05-15/092224-owlory-ui-regression-batch-7-localization-layout-shell.md)
- [owlory-ui-regression-batch-6-patterns-digest-insight-rendering (domain-tested; XCUITest dropped)](sessions/2026-05-15/050440-owlory-ui-regression-batch-6-patterns-digest-insight-rendering.md)
- [owlory-ui-regression-batch-7-localization-layout-triage](sessions/2026-05-15/005854-owlory-ui-regression-batch-7-localization-layout-triage.md)
- [owlory-ui-regression-batch-6-surface-triage](sessions/2026-05-15/002954-owlory-ui-regression-batch-6-surface-triage.md)
- [owlory-ui-regression-batch-5-home-protocol-run-step-progression](sessions/2026-05-15/000435-owlory-ui-regression-batch-5-home-protocol-run-step-progression.md)

## 2026-05-14

- [owlory-ui-regression-batch-5-surface-triage (Agent A, chose Home step progression)](sessions/2026-05-14/233821-owlory-ui-regression-batch-5-surface-triage.md)
- [owlory-ui-regression-batch-4-home-protocol-archive-restore](sessions/2026-05-14/213117-owlory-ui-regression-batch-4-home-protocol-archive-restore.md)
- [owlory-ui-regression-next-surface-triage (Batch 4 follow-up, Agent B chose Home archive/restore)](sessions/2026-05-14/205219-owlory-ui-regression-next-surface-triage.md)
- [home-protocol-direct-archive-affordance](sessions/2026-05-14/203542-home-protocol-direct-archive-affordance.md)
- [home-protocol-archive-swipe-affordance](sessions/2026-05-14/195828-home-protocol-archive-swipe-affordance.md)
- [app-localization-home-action-accessibility-formatting](sessions/2026-05-14/191848-app-localization-home-action-accessibility-formatting.md)
- [app-localization-accessibility-interpolation-audit](sessions/2026-05-14/174003-app-localization-accessibility-interpolation-audit.md)
- [app-localization-digest-insight-summary-formatting](sessions/2026-05-14/172932-app-localization-digest-insight-summary-formatting.md)
- [app-localization-readiness-summary-formatting](sessions/2026-05-14/095404-app-localization-readiness-summary-formatting.md)
- [app-localization-recurrence-interval-formatting](sessions/2026-05-14/082207-app-localization-recurrence-interval-formatting.md)
- [app-localization-all-locale-screenshot-proof](sessions/2026-05-14/034211-app-localization-all-locale-screenshot-proof.md)
- [localization-idb-cli-unblock](sessions/2026-05-14/033011-localization-idb-cli-unblock.md)
- [localization-screenshot-proof-idb-harness](sessions/2026-05-14/022552-localization-screenshot-proof-idb-harness.md)
- [app-localization-all-locale-smoke](sessions/2026-05-14/010204-app-localization-all-locale-smoke.md)
- [app-localization-completion-status-audit](sessions/2026-05-14/005751-app-localization-completion-status-audit.md)
- [app-localization-german-values-absent](sessions/2026-05-14/005211-app-localization-german-values-absent.md)

## 2026-05-13

- [owlory-ui-regression-batch-3-train-active-history](sessions/2026-05-13/213214-owlory-ui-regression-batch-3-train-active-history.md)
- [owlory-ui-regression-expansion-next-surface](sessions/2026-05-13/235054-owlory-ui-regression-expansion-next-surface.md)
- [owlory-ui-regression-next-surface-triage (Agent A, chose Write)](sessions/2026-05-13/212057-owlory-ui-regression-next-surface-triage.md)
- [owlory-ui-regression-next-surface-triage (Agent B, chose Train)](sessions/2026-05-13/202149-owlory-ui-regression-next-surface-triage.md)
- [app-localization-review-packet-for-first-locale](sessions/2026-05-13/194318-app-localization-review-packet-for-first-locale.md)
- [app-localization-manual-language-setting-diagnostic](sessions/2026-05-13/192736-app-localization-manual-language-setting-diagnostic.md)
- [app-localization-manual-app-language-testing-doc](sessions/2026-05-13/192209-app-localization-manual-app-language-testing-doc.md)
- [owlory-ui-testflight-proof](sessions/2026-05-13/170309-owlory-ui-testflight-proof.md)
- [release-discipline-preflight-and-hooks](sessions/2026-05-13/164212-release-discipline-preflight-and-hooks.md)
- [queue-release-discipline-preflight-and-hooks](sessions/2026-05-13/163413-queue-release-discipline-preflight-and-hooks.md)
- [owlory-ui-test-testflight-proof-retry dirty archive gate](sessions/2026-05-13/162123-owlory-ui-test-testflight-proof-retry.md)
- [release-provenance-git-hooks](sessions/2026-05-13/133531-release-provenance-git-hooks.md)
- [owlory-ui-test-testflight-proof-retry fresh install gate](sessions/2026-05-13/123220-owlory-ui-test-testflight-proof-retry.md)
- [owlory-ui-test-testflight-proof-retry](sessions/2026-05-13/102117-owlory-ui-test-testflight-proof-retry.md)
- [owlory-release-clean-testflight-build-prep](sessions/2026-05-13/095701-owlory-release-clean-testflight-build-prep.md)
- [harness-blocked-slice-unblocker-policy](sessions/2026-05-13/094648-harness-blocked-slice-unblocker-policy.md)
- [clean-stop-completion-check](sessions/2026-05-13/082520-clean-stop-completion-check.md)
- [xcode-default-destination-ios-26-5](sessions/2026-05-13/045127-xcode-default-destination-ios-26-5.md)
- [build-info-display-git-status](sessions/2026-05-13/025224-build-info-display-git-status.md)
- [queue-parked-proof-and-localization-slices](sessions/2026-05-13/023215-queue-parked-proof-and-localization-slices.md)
- [ui-simulator-validation-recovery](sessions/2026-05-13/022554-ui-simulator-validation-recovery.md)

## 2026-05-12

- [owlory-ui-regression-batch-1-today-continue](sessions/2026-05-12/050254-owlory-ui-regression-batch-1-today-continue.md)
- [owlory-ui-regression-suite-plan](sessions/2026-05-12/045409-owlory-ui-regression-suite-plan.md)
- [owlory-release-provenance-stamp-gate-fix](sessions/2026-05-12/044933-owlory-release-provenance-stamp-gate-fix.md)

## 2026-05-11

- [owlory-release-provenance-stamp-audit](sessions/2026-05-11/204422-owlory-release-provenance-stamp-audit.md)
- [owlory-ui-test-testflight-proof (blocked at gate)](sessions/2026-05-11/203215-owlory-ui-test-testflight-proof.md)
- [owlory-ui-test-device-proof](sessions/2026-05-11/201558-owlory-ui-test-device-proof.md)
- [owlory-ui-test-screenshot-proof-pack](sessions/2026-05-11/142834-owlory-ui-test-screenshot-proof-pack.md)
- [owlory-ui-test-continue-routing-deferred-coverage](sessions/2026-05-11/103137-owlory-ui-test-continue-routing-deferred-coverage.md)
- [owlory-ui-test-continue-routing-smoke-batch](sessions/2026-05-11/092313-owlory-ui-test-continue-routing-smoke-batch.md)
- [owlory-ui-test-continue-routing-matrix-triage](sessions/2026-05-11/084545-owlory-ui-test-continue-routing-matrix-triage.md)
- [owlory-ui-test-continue-source-smoke-batch](sessions/2026-05-11/083444-owlory-ui-test-continue-source-smoke-batch.md)

## 2026-05-08

- [owlory-ui-test-continue-source-coverage-triage](sessions/2026-05-08/002231-owlory-ui-test-continue-source-coverage-triage.md)

## 2026-05-07

- [owlory-ui-proof-roadmap-queue](sessions/2026-05-07/173252-owlory-ui-proof-roadmap-queue.md)
- [owlory-ui-test-active-home-protocol-routing-smoke](sessions/2026-05-07/071740-owlory-ui-test-active-home-protocol-routing-smoke.md)
- [owlory-ui-test-continue-home-task-routing-smoke](sessions/2026-05-07/070643-owlory-ui-test-continue-home-task-routing-smoke.md)
- [owlory-ui-test-continue-row-action-smoke](sessions/2026-05-07/065423-owlory-ui-test-continue-row-action-smoke.md)
- [owlory-ui-test-fixture-seeder-batch-3](sessions/2026-05-07/064055-owlory-ui-test-fixture-seeder-batch-3.md)
- [owlory-ui-test-fixture-seeder-batch-2](sessions/2026-05-07/012834-owlory-ui-test-fixture-seeder-batch-2.md)
- [owlory-ui-test-seed-and-xcuitest-harness](sessions/2026-05-07/011347-owlory-ui-test-seed-and-xcuitest-harness.md)
- [harness-pr-ui-testing-hygiene](sessions/2026-05-07/005629-harness-pr-ui-testing-hygiene.md)

## 2026-05-06

- [app-localization-translation-review-export](sessions/2026-05-06/192438-app-localization-translation-review-export.md)
- [app-localization-translation-quality-plan](sessions/2026-05-06/190846-app-localization-translation-quality-plan.md)
- [app-localization-locale-screenshot-proof](sessions/2026-05-06/185838-app-localization-locale-screenshot-proof.md)
- [app-localization-running-locale-smoke](sessions/2026-05-06/165126-app-localization-running-locale-smoke.md)
- [app-localization-display-name-adapters](sessions/2026-05-06/161203-app-localization-display-name-adapters.md)
- [app-localization-notification-copy](sessions/2026-05-06/134516-app-localization-notification-copy.md)
- [app-localization-protocol-schedule-projection](sessions/2026-05-06/082147-app-localization-protocol-schedule-projection.md)
- [app-localization-digest-formatting](sessions/2026-05-06/075852-app-localization-digest-formatting.md)
- [app-localization-today-plurals](sessions/2026-05-06/073047-app-localization-today-plurals.md)
- [app-localization-dynamic-formatting-plan](sessions/2026-05-06/022319-app-localization-dynamic-formatting-plan.md)
- [app-localization-string-extraction-audit](sessions/2026-05-06/021725-app-localization-string-extraction-audit.md)
- [app-localization-foundation](sessions/2026-05-06/015052-app-localization-foundation.md)

## 2026-05-03

- [previous-days-live-status-labels](sessions/2026-05-03/100000-previous-days-live-status-labels.md)
- [home-protocol-step-revert](sessions/2026-05-03/090000-home-protocol-step-revert.md)
- [home-protocol-archive](sessions/2026-05-03/082040-home-protocol-archive.md)
- [home-protocol-schedule-notifications](sessions/2026-05-03/010000-home-protocol-schedule-notifications.md)
- [train-row-status-pill-uniformity](sessions/2026-05-03/020000-train-row-status-pill-uniformity.md)
- [reorderable-list-coverage-triage](sessions/2026-05-03/030000-reorderable-list-coverage-triage.md)

## 2026-05-02

- [today-last-week-insights-actionability-triage](sessions/2026-05-02/000658-today-last-week-insights-actionability-triage.md)
- [home-protocol-schedule-ui-proof](sessions/2026-05-02/233505-home-protocol-schedule-ui-proof.md)
- [home-protocol-schedule-stale-treatment](sessions/2026-05-02/151524-home-protocol-schedule-stale-treatment.md)
- [today-continue-write-task-projection-triage](sessions/2026-05-02/145038-today-continue-write-task-projection-triage.md)
- [write-promotion-device-verification](sessions/2026-05-02/143205-write-promotion-device-verification.md)
- [tools-generate-build-info-worktree-fix](sessions/2026-05-02/094114-tools-generate-build-info-worktree-fix.md)
- [write-promotion-device-verification (blocked)](sessions/2026-05-02/043325-write-promotion-device-verification.md)
- [legacy-handoff-proof-field-backfill-batch-2](sessions/2026-05-02/001733-legacy-handoff-proof-field-backfill-batch-2.md)

## 2026-04-30

- [legacy-handoff-proof-field-backfill](sessions/2026-04-30/205431-legacy-handoff-proof-field-backfill.md)
- [write-promotion-screenshot-proof](sessions/2026-04-30/172128-write-promotion-screenshot-proof.md)
- [write-note-promotion-flow-verification](sessions/2026-04-30/170933-write-note-promotion-flow-verification.md)
- [home-protocol-schedule-windows](sessions/2026-04-30/092700-home-protocol-schedule-windows.md)
- [owlory-running-app-smoke-build-blocker](sessions/2026-04-30/092153-owlory-running-app-smoke-build-blocker.md)
- [proof-infrastructure-queue](sessions/2026-04-30/091605-proof-infrastructure-queue.md)
- [write-promotion-status-affordances](sessions/2026-04-30/085602-write-promotion-status-affordances.md)
- [owlory-running-app-smoke](sessions/2026-04-30/091054-owlory-running-app-smoke.md)
- [write-promote-to-protocol](sessions/2026-04-30/050930-write-promote-to-protocol.md)
- [owlory-handoff-evidence-writer](sessions/2026-04-30/050252-owlory-handoff-evidence-writer.md)
- [harness-proof-level-ladder](sessions/2026-04-30/045152-harness-proof-level-ladder.md)
- [write-note-detail-management-actions](sessions/2026-04-30/044502-write-note-detail-management-actions.md)
- [train-completed-sessions-history](sessions/2026-04-30/044037-train-completed-sessions-history.md)

## 2026-04-29

- [document-local-data-channel-boundaries](sessions/2026-04-29/194250-document-local-data-channel-boundaries.md)
- [home-task-write-origin-route-back](sessions/2026-04-29/183451-home-task-write-origin-route-back.md)
- [write-promote-to-task](sessions/2026-04-29/132300-write-promote-to-task.md)
- [write-promote-to-today](sessions/2026-04-29/020000-write-promote-to-today.md)
- [write-promotion-origin-contract](sessions/2026-04-29/015700-write-promotion-origin-contract.md)
- [contract-implementation-completeness-audit](sessions/2026-04-29/015027-contract-implementation-completeness-audit.md)
- [release-identity-github-xcode-mirroring](sessions/2026-04-29/014654-release-identity-github-xcode-mirroring.md)
- [readme-beta-testflight-link](sessions/2026-04-29/013303-readme-beta-testflight-link.md)

## 2026-04-28

- [write-lab-capture-inbox-promotion](sessions/2026-04-28/164726-write-lab-capture-inbox-promotion.md)
- [patterns-weekly-digest-versioned-stale-refresh](sessions/2026-04-28/123713-patterns-weekly-digest-versioned-stale-refresh.md)
- [today-continue-focus-badge-dynamic-type-legibility](sessions/2026-04-28/122104-today-continue-focus-badge-dynamic-type-legibility.md)
- [today-continue-owns-focus-surface](sessions/2026-04-28/121301-today-continue-owns-focus-surface.md)
- [today-focus-completion-contract-actions](sessions/2026-04-28/075238-today-focus-completion-contract-actions.md)
- [patterns-weekly-digest-count-protocol-step-completions](sessions/2026-04-28/074311-patterns-weekly-digest-count-protocol-step-completions.md)
- [today-weekly-digest-truthful-summary-copy](sessions/2026-04-28/030607-today-weekly-digest-truthful-summary-copy.md)

## 2026-04-26

- [write-lightweight-source-note-conversion](sessions/2026-04-26/034234-write-lightweight-source-note-conversion.md)
- [today-linked-train-carryforward-guard](sessions/2026-04-26/033220-today-linked-train-carryforward-guard.md)
- [voice-write-live-transcription-capture](sessions/2026-04-26/024636-voice-write-live-transcription-capture.md)
- [today-protocol-carryforward-contract-guardrails](sessions/2026-04-26/002830-today-protocol-carryforward-contract-guardrails.md)

## 2026-04-25

- [today-home-wrapped-evening-gate](sessions/2026-04-25/101939-today-home-wrapped-evening-gate.md)

## 2026-04-24

- [device-matrix-hig-audit](sessions/2026-04-24/082842-device-matrix-hig-audit.md)
- [device-hig-compliance-assessment](sessions/2026-04-24/081152-device-hig-compliance-assessment.md)
- [hig-home-row-action-separation](sessions/2026-04-24/080856-hig-home-row-action-separation.md)
- [hig-home-hit-target-followup](sessions/2026-04-24/080033-hig-home-hit-target-followup.md)
- [hig-ui-alignment-fixes](sessions/2026-04-24/075401-hig-ui-alignment-fixes.md)
- [hig-audit-findings](sessions/2026-04-24/073307-hig-audit-findings.md)
- [selective-stash-recovery-validation](sessions/2026-04-24/064854-selective-stash-recovery-validation.md)

## 2026-04-23

- [write-domain-balance-nudge-suppression](sessions/2026-04-23/012834-write-domain-balance-nudge-suppression.md)
- [focus-balance-nudge-copy](sessions/2026-04-23/014151-focus-balance-nudge-copy.md)

## 2026-04-22

- [supervisor-validation-replay](sessions/2026-04-22/050358-supervisor-validation-replay.md)
- [validation-ownership-tiers](sessions/2026-04-22/052024-validation-ownership-tiers.md)

## 2026-04-21

- [agent-orchestration-harness](sessions/2026-04-21/113016-agent-orchestration-harness.md)
- [supervisor-safety-hardening](sessions/2026-04-21/114609-supervisor-safety-hardening.md)
- [harness-prompt-context-hardening](sessions/2026-04-21/160904-harness-prompt-context-hardening.md)
