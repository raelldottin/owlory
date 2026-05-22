# Second Brain Index

## 2026-05-22

- [app-accessibility-swipe-actions-as-accessibility-actions (build-tested; added .accessibilityActions ViewBuilder alongside 12 .swipeActions sites across Write/Home/Today/Career so Switch Control + VoiceOver users can reach the actions without the swipe gesture; reused existing L() strings — no new localization keys; xcodebuild SUCCEEDED)](sessions/2026-05-22/073841-app-accessibility-swipe-actions-as-accessibility-actions.md)
- [app-accessibility-survey-three-categories (doc-only; inventoried 23 accessibility gaps across 3 unhandled categories — Reduce Motion/Transparency/Contrast/Color, Haptics, Switch/Voice/Rotors; all 3 classified `none` at category level; queued 5 follow-up fix slices pri 76-82)](sessions/2026-05-22/063556-app-accessibility-survey-three-categories.md)
- [repo-automation-sync-force-templates-flag (consumer-smoke-tested; added --force-templates to Tools/repo-automation-sync.sh so consumers can deliberately re-baseline template entries; stale-file removal still skips template entries so consumer-added files survive; 2 new tests + docs; suite grows to 23 + automation-check 124)](sessions/2026-05-22/060420-repo-automation-sync-force-templates-flag.md)
- [repo-automation-consumer-git-command-failed-smoke (consumer-smoke-tested; added test_consumer_supervisor_fails_with_friendly_message_on_corrupt_git_repo asserting the 5th and final ConfigError emit site via garbage-in-.git/HEAD; ConfigError smoke coverage now 5/5; suite grows to 21 + automation-check 122)](sessions/2026-05-22/055844-repo-automation-consumer-git-command-failed-smoke.md)
- [repo-automation-template-first-time-only-sync (consumer-smoke-tested; gave manifest template: true a real sync semantic — first-time-only per file, skip stale removal; flipped delete_stale to false on prompts/ + examples/ entries; consumer overrides AND added files now survive --sync; trade-off documented: Owlory updates to template files no longer auto-propagate; suite grows to 20 + automation-check 121)](sessions/2026-05-22/022048-repo-automation-template-first-time-only-sync.md)
- [repo-automation-consumer-prompt-override-portability (consumer-smoke-tested; added test_consumer_can_override_prompt_fragments asserting render_prompt picks up consumer base.md + slice.md overrides via subprocess probe; documented commit-required and re-sync-overwrites constraints with two workaround paths; suite grows to 18 + automation-check 119)](sessions/2026-05-22/021156-repo-automation-consumer-prompt-override-portability.md)
- [repo-automation-consumer-error-messages-additional-smoke (consumer-smoke-tested; added 2 tests to RepoAutomationConsumerAdoptionSmokeTests covering git-not-on-PATH via isolated symlinked bin and malformed-JSON queue; 4 of 5 ConfigError emit sites now asserted; suite grows to 17 + automation-check 118)](sessions/2026-05-22/020350-repo-automation-consumer-error-messages-additional-smoke.md)

## 2026-05-21

- [repo-automation-consumer-error-messages (consumer-smoke-tested; added policy.ConfigError + targeted catches in load_json/load_queue/git_dirty_paths, wrapped run_next.py + build_context.py CLI entries to print two-line stop+hint messages instead of tracebacks, updated smoke assertions to lock in the friendly shape, refreshed docs)](sessions/2026-05-21/235630-repo-automation-consumer-error-messages.md)
- [repo-automation-consumer-adoption-smoke (consumer-smoke-tested; added 6 RepoAutomationConsumerAdoptionSmokeTests covering bootstrap subset, supervisor + context-builder failure modes, git-required surfacing, example-queue dry-run handoff scoping, and auto-update round-trip; documented consumer setup sequence + manual steps + smoke-test boundaries)](sessions/2026-05-21/213914-repo-automation-consumer-adoption-smoke.md)
- [repo-automation-readme-about-refresh (external-maintenance; added root README, updated GitHub About description/homepage/topics, external HEAD 0735246)](sessions/2026-05-21/172519-repo-automation-readme-about-refresh.md)
- [repo-automation-auto-update-gate (automation-tested + hook-tested; added safe --auto-update mode, Make targets, pre-push manifest-change detection, dirty-target refusal tests, and synced external repo HEAD 7eb3bef)](sessions/2026-05-21/171939-repo-automation-auto-update-gate.md)
- [repo-automation-remote-publication-record (remote-published; configured HTTPS origin for external repo-automation, pushed main to GitHub, and verified external mirror 0 0)](sessions/2026-05-21/171004-repo-automation-remote-publication-record.md)
- [repo-automation-external-repo-bootstrap (external-bootstrap-tested; initialized external repo-automation as its own Git repo, synced 17 manifest-owned files, final external HEAD ed52956, and verified real-target check passes)](sessions/2026-05-21/170029-repo-automation-external-repo-bootstrap.md)
- [repo-automation-sync-tooling (automation-tested; added manifest-driven repo-automation sync/check tool, reusable manifest, temp-target tests, and validation docs without mutating the real external folder)](sessions/2026-05-21/162935-repo-automation-sync-tooling.md)
- [repo-automation-reuse-contract-inventory (doc-only; defined reusable automation target, one-way sync direction, manifest contract, exclusions, automatic update boundary, and consumer repo contract)](sessions/2026-05-21/161422-repo-automation-reuse-contract-inventory.md)
- [queue-repo-automation-reuse-slices (queue-only; created external repo-automation folder and queued contract, sync tooling, bootstrap, automatic-update, and consumer-adoption slices)](sessions/2026-05-21/161224-queue-repo-automation-reuse-slices.md)
- [release-changelog-required-gate (automation-tested; bump-version now refuses to mutate MARKETING_VERSION/CURRENT_PROJECT_VERSION unless CHANGELOG.md exists with ## [Unreleased], with temp-repo regression coverage)](sessions/2026-05-21/071142-release-changelog-required-gate.md)
- [release-changelog-current-cycle-backfill (doc-only; populated CHANGELOG.md [Unreleased] with curated current-cycle release notes for localization, HIG/accessibility proof, reminder cancellation, error-copy cleanup, release provenance, and validation gates)](sessions/2026-05-21/071850-release-changelog-current-cycle-backfill.md)
- [release-changelog-foundation (doc-only + automation-tested; added top-level CHANGELOG.md with [Unreleased] release-note categories, release.md changelog policy, and aligned bump-version fixture)](sessions/2026-05-21/071355-release-changelog-foundation.md)
- [queue-release-changelog-slices (queue-only; added changelog foundation, current-cycle backfill, and required-gate slices so marketing-version release notes become curated repo state)](sessions/2026-05-21/070709-queue-release-changelog-slices.md)
- [release-bump-version-policy-guard (automation-tested; added isolated tests executing real bump-version/set-build-number scripts against temp fixtures for semver bumps, timestamp build numbers, changelog promotion, and invalid-input non-mutation)](sessions/2026-05-21/065050-release-bump-version-policy-guard.md)
- [release-marketing-version-provenance-gate (automation-tested; verify-build-provenance now checks committed MARKETING_VERSION against HEAD, fails --require-clean for app-version drift, and docs/hooks name both app-version and build-number gates)](sessions/2026-05-21/040334-release-marketing-version-provenance-gate.md)
- [release-versioning-policy-doc (doc-only + automation-tested; added long-term MARKETING_VERSION / CURRENT_PROJECT_VERSION policy for pre-1.0, release bumps, rollback builds, tags/changelog, and enterprise traceability; next slice is MARKETING_VERSION provenance gate)](sessions/2026-05-21/035040-release-versioning-policy-doc.md)
- [queue-release-versioning-implementation-slices (queue-only; added 3 release implementation slices: policy doc pri 76, MARKETING_VERSION provenance gate pri 75, bump-version policy guard pri 74)](sessions/2026-05-21/034443-queue-release-versioning-implementation-slices.md)
- [app-history-strip-claude-trailers (build-tested + git-history-rewritten; rewrote pushed main history from old 60576b3..e550c66, removed 84 actual Claude attribution trailers, reworded one grep false-positive commit message, and preserved file tree equivalence)](sessions/2026-05-21/052753-app-history-strip-claude-trailers.md)
- [app-design-vision-metaphor-adr (doc-only; added ADR 0002 naming Owlory's design throughline as quiet daily momentum across Today, Continue, Patterns, and Train)](sessions/2026-05-21/041431-app-design-vision-metaphor-adr.md)

## 2026-05-20

- [app-error-message-fix-designsystem-accessibility (localized-copy + build-tested + automation-tested; removed raw %@ from audio/voice accessibility error speech, added retry guidance across 19 locales, marked two changed source rows pending native/fluent re-acceptance, and made voice error taps retry)](sessions/2026-05-20/145005-app-error-message-fix-designsystem-accessibility.md)
- [app-error-message-fix-patternstore-visibility (refactor + automation-tested; removed dead PatternStore.lastError and kept lifecycle-triggered pattern/digest failures as diagnostic telemetry, with no new user-visible copy)](sessions/2026-05-20/143852-app-error-message-fix-patternstore-visibility.md)
- [app-error-message-fix-writestore-domain-message (localized-copy + automation-tested; WriteStore source-note invalid-stage fallback now uses String(localized:) with valid-stage guidance; key added across 19 locales; 18 return files mark new row as automated draft pending native/fluent review)](sessions/2026-05-20/115616-app-error-message-fix-writestore-domain-message.md)
- [app-error-message-fix-store-templates (localized-copy + automation-tested; 8 store-template lastError bodies now route through String(localized:) keys; 8 keys added across 19 locales; 18 return files mark new rows as automated drafts pending native/fluent review)](sessions/2026-05-20/114754-app-error-message-fix-store-templates.md)
- [app-error-message-audit (doc-only; inventoried 16 error-message surfaces, 13 user-visible; queued 4 focused fix slices for store templates, WriteStore stage guidance, PatternStore visibility, and DesignSystem accessibility error labels)](sessions/2026-05-20/102151-app-error-message-audit.md)
- [app-content-standards-integrated-reference (doc-only; new docs/workflows/content-standards.md pairing visible-component choice with copy shape — CTA capitalization, error-phrasing required shape, header punctuation, component-to-content-type mapping, L() key naming cross-ref; named lastError-template gap for the queued audit slice to inventory and fix)](sessions/2026-05-20/101743-app-content-standards-integrated-reference.md)
- [queue-robinhood-followup-slices (queue-only; appended 3 Robinhood-derived follow-up slices — content-standards-integrated-reference pri 70, error-message-audit pri 75, design-vision-metaphor-adr pri 85)](sessions/2026-05-20/100726-queue-robinhood-followup-slices.md)
- [app-design-research-robinhood-newsroom-lessons (doc-only; read all 5 Robinhood newsroom design articles; mapped lessons to Owlory surfaces with applicability ratings; 3 optional follow-up slices recommended; integrated content standards article is most actionable)](sessions/2026-05-20/095634-app-design-research-robinhood-newsroom-lessons.md)
- [queue-claude-trailer-history-rewrite-slice (queue-only; app-history-strip-claude-trailers queued at pri 96 as destructive git-hygiene cleanup of ~84 trailer-bearing commits since 2026-05-03; force-push-with-lease required; risks captured)](sessions/2026-05-20/092517-queue-claude-trailer-history-rewrite-slice.md)
- [queue-robinhood-design-research-slice (queue-only; app-design-research-robinhood-newsroom-lessons queued at pri 95 to read robinhood.com newsroom design category and map applicable lessons to Owlory surfaces; analysis-only with explicit non-implementation scope)](sessions/2026-05-20/091519-queue-robinhood-design-research-slice.md)
- [app-localization-smallest-width-accessibility-regression (regression-tested; added iPhone SE `DOMAIN=localization-smallest-width` routing for existing localization layout/accessibility XCUITests)](sessions/2026-05-20/085912-app-localization-smallest-width-accessibility-regression.md)
- [automation-localization-iphone-se-simulator-provisioning (build-tested; added idempotent iPhone SE simulator provision/check helper + Makefile targets; provisioned iPhone SE on iOS 26.5; unblocked smallest-width localization regression)](sessions/2026-05-20/085344-automation-localization-iphone-se-simulator-provisioning.md)
- [app-localization-external-proof-blocker-reclassification (build-tested; optional device/TestFlight localization proof slices reclassified from blocked to deferred manual-extension tracks; simulator proof remains accepted HIG UI bar)](sessions/2026-05-20/081705-app-localization-external-proof-blocker-reclassification.md)
- [queue-automate-blocked-slice-unblockers (queue-only; added two queued unblocker slices: external proof blocker reclassification and iPhone SE simulator provisioning; blocked slices now list recommended unblockers)](sessions/2026-05-20/073016-queue-automate-blocked-slice-unblockers.md)
- [start-next-slice-clean-stop (no eligible queued slice after fresh pull; clean-stop passed; repo clean/mirrored; 4 parked blocked/deferred slices retain explicit entry conditions)](sessions/2026-05-20/064404-start-next-slice-clean-stop.md)
- [app-reminders-cancel-pending-home-today (build-tested + domain-tested; Home task, Home protocol-run, and Today source-backed focus Done completions now cancel matching pending/delivered reminders via predictor keys)](sessions/2026-05-20/023205-app-reminders-cancel-pending-home-today.md)
- [queue-home-today-cancel-followup (queue-only; app-reminders-cancel-pending-on-home-and-today-completion queued at pri 30; mirrors TrainStore commit c41863a for HomeStore tasks/runs + TodayStore focus-item Done)](sessions/2026-05-20/062433-queue-home-today-cancel-followup.md)
- [app-reminders-cancel-pending-on-item-completion (build-tested + domain-tested; TrainStore now fires onItemCompleted hook at completion; ReminderScheduler.cancelReminder removes delivered too; OwloryApp wires the cancel; 3 new TrainStoreTests; failing-on-main test confirmed before fix)](sessions/2026-05-20/060618-app-reminders-cancel-pending-on-item-completion.md)
- [queue-smallest-width-slice (queue-only; app-localization-smallest-width-accessibility-regression queued as blocked at pri 67 pending iPhone SE simulator provisioning)](sessions/2026-05-20/055811-queue-smallest-width-slice.md)
- [app-localization-smaller-width-accessibility-regression (regression-tested; new DOMAIN=localization-smaller-width Makefile case running 19 localization regression tests against iPhone 16 simulator; both 17 and 16 paths preserved)](sessions/2026-05-20/023059-app-localization-smaller-width-accessibility-regression.md)

## 2026-05-19

- [app-localization-voiceover-verification (regression-tested; 4 new XCUITest methods asserting non-empty AX labels on root tabs under de/ar/ja/ru; 15 accessibility tests / 19 total / 111.9s; manifest under automation/proofs/app-localization-voiceover-verification/)](sessions/2026-05-19/100507-app-localization-voiceover-verification.md)
- [app-localization-review-drift-check-gate-promotion (build-tested; drift-check --check folded into make automation-check between pyright and unittest discover; baseline preserved 0 drift; drift now fails the gate)](sessions/2026-05-19/095326-app-localization-review-drift-check-gate-promotion.md)
- [app-localization-review-drift-check-stringsdict-coverage (build-tested; new parse_stringsdict_entries + per-plural-category tuple drift + stringsdict english_value drift; 7 new tests / 22 drift tests / 93 automation-check total; baseline 0 drift unchanged)](sessions/2026-05-19/094716-app-localization-review-drift-check-stringsdict-coverage.md)
- [app-localization-stringsdict-xml-conversion (build-tested; 19 stringsdict files converted from NeXTSTEP to XML plist via plutil -convert xml1; plistlib parses every file natively; drift tool verified working without plutil; supersedes app-localization-nextstep-plist-parser)](sessions/2026-05-19/094001-app-localization-stringsdict-xml-conversion.md)
- [queue-notification-stale-completion-slice (queue-only; user-reported bug — completed train item still fires window-passed notification; slice app-reminders-cancel-pending-on-item-completion queued at pri 90)](sessions/2026-05-19/093633-queue-notification-stale-completion-slice.md)
- [queue-two-stringsdict-portability-slices (queue-only; 1 queued + 1 deferred follow-up slices for the Linux-portability gap: XML conversion as preferred path, NeXTSTEP parser as alternative)](sessions/2026-05-19/085434-queue-two-stringsdict-portability-slices.md)
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
