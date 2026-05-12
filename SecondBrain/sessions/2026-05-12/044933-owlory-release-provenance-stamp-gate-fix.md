# owlory-release-provenance-stamp-gate-fix

## Prompt

Implement the release-workflow gate fix queued by owlory-release-provenance-stamp-audit: extend Tools/verify-build-provenance.sh so make release-check fails when on-disk pbxproj CURRENT_PROJECT_VERSION does not match the committed value at HEAD, add a focused test, and document the strengthened gate in docs/workflows/release.md.

## Interpretation

A repo-tooling slice. Scope is the verifier script, the automation tests, the release workflow doc, plus the standard queue/handoff/SecondBrain bookkeeping. No app code, no UI, no localization. The strengthened gate must fire under --require-clean (as make release-check invokes); informational mode (no flag) must surface the comparison without breaking the dev loop.

## Files Edited

- `SecondBrain/INDEX.md`
- `SecondBrain/sessions/2026-05-12/044933-owlory-release-provenance-stamp-gate-fix.md`
- `Tools/verify-build-provenance.sh`
- `automation/handoffs/20260512T044933Z-owlory-release-provenance-stamp-gate-fix.json`
- `automation/queue/slices.json`
- `automation/tests/test_verify_build_provenance.py`
- `docs/workflows/release.md`

## Outcome

- Tools/verify-build-provenance.sh now reads HEAD:owlory_xcode/Owlory.xcodeproj/project.pbxproj, extracts the committed CURRENT_PROJECT_VERSION, and compares it with the on-disk value.
- Build-provenance output gained a `Committed build number:` line that reports `matches HEAD`, `differs from HEAD (HEAD has <value>)`, or `unverifiable (...)`.
- Under `--require-clean`, both gate failures (dirty working tree and pbxproj-vs-HEAD divergence) are now reported before exiting non-zero, instead of bailing on the first.
- New focused tests in automation/tests/test_verify_build_provenance.py cover three paths: matching value passes under --require-clean, uncommitted bump fails under --require-clean with the new remediation message, and uncommitted bump is advisory (exit 0) without --require-clean.
- docs/workflows/release.md gains a numbered step before Archive in Xcode that re-runs the verifier, plus a paragraph describing the strengthened gate and the failure mode it catches.

## Validation

Passed:

- `python3 automation/context/build_context.py --slice-id owlory-release-provenance-stamp-gate-fix`
- `python3 automation/supervisor/run_next.py --dry-run`
- `make architecture`
- `make build-provenance`
- `make automation-check`
- `git diff --check`

## Proof And Risk

Proof level: `domain-tested`. The new verifier code path is exercised by three unit tests under automation/tests/. The release.md doc change is doc-only and not separately tested.

This does not close the xcodebuild command-line override candidate from the audit; CURRENT_PROJECT_VERSION supplied directly to xcodebuild at archive time still bypasses the on-disk pbxproj entirely and is not caught here. It also does not extend the assertion to MARKETING_VERSION or other pbxproj keys, and does not retroactively recover the TestFlight build that triggered the audit. The BuildInfoView UI gap (no direct GitStatus rendering) remains open and is recorded by the audit slice.
