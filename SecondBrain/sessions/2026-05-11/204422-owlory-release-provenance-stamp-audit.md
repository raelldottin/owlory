# owlory-release-provenance-stamp-audit

Pinned the root cause of the TestFlight Build Info gate failure recorded by `owlory-ui-test-testflight-proof`. The release workflow's existing clean-tree gate is necessary but insufficient; the build that shipped to TestFlight had a `CFBundleVersion` that was never committed to pbxproj on any branch or in reflog, while the stamp script correctly reported `GitStatus = clean`. Queued exactly one fix slice (`owlory-release-provenance-stamp-gate-fix`) targeting the right surface: `Tools/verify-build-provenance.sh` + `make release-check`, with `docs/workflows/release.md` updated to record the new gate as a numbered release step.

## Evidence

1. Pickaxe `git log --all --pickaxe-regex -S "20260417081911"` returns only the gate-failure record commit (`7eb7fbb`). Pickaxe with `--reflog` returns the same single match. No source state on any branch ever had the TestFlight build number.
2. Every pbxproj-touching commit between 2026-05-01 and 2026-05-08 (around the `Built: 2026-05-05T23:48:12Z` date) shows `CURRENT_PROJECT_VERSION = 20260417081904`.
3. The build number `20260417081911` decodes as UTC `2026-04-17 08:19:11`, matching `Tools/set-build-number.sh --auto`'s `date -u +"%Y%m%d%H%M%S"` pattern. The TestFlight archive happened 19 days after that timestamp.
4. `Tools/generate-build-info.sh` reads `CFBundleVersion` from the processed Info.plist (line 59) and never writes it back unless empty (lines 72–76). The stamp script does not mutate build numbers.
5. `BuildInfo.isReleaseable` returns false when `gitCommit` or `gitCommitFull` has a `-dirty` suffix. `BuildInfoView` renders a `Not releaseable` banner gated on `isReleaseable`. The TestFlight install's Build Info screenshot shows neither `-dirty` suffixes nor the banner, so `gitCommit` was clean, so `git status --porcelain` returned empty at archive time, so **`GitStatus` was `clean`**.
6. Mechanism shortlist (all three consistent with observations; share one fix surface):
   - α: `xcodebuild archive ... CURRENT_PROJECT_VERSION=20260417081911` override.
   - β: pbxproj committed with the bumped value, archived, commit later rewritten away and reflog GC'd.
   - γ: `git update-index --skip-worktree` (or `--assume-unchanged`) used to hide the bump from git status, archived, then unset.

## Diagnosis

`GitStatus = clean` AND build number is uncommitted in any reachable git state. The stamp script and BuildInfo.swift each behaved correctly given their inputs. The release workflow's "clean tree at archive time" gate is necessary but insufficient — it cannot detect that the current pbxproj on disk holds a value that has never been committed (or that an xcodebuild command-line override is being applied).

The fix surface is the release workflow gate. **Adding a stronger assertion to `Tools/verify-build-provenance.sh`**: at `--require-clean` time (the mode `make release-check` invokes), assert `git show HEAD:owlory_xcode/Owlory.xcodeproj/project.pbxproj | grep CURRENT_PROJECT_VERSION` matches the working tree's value. If the on-disk and HEAD-committed values diverge — even with a clean working tree — fail loudly with an actionable message ("Run `set-build-number.sh` and commit the change before archiving"). The Xcode stamp script and BuildInfo.swift stay untouched; they have no observability gap, only the workflow does.

## Secondary finding (recorded, not queued)

`BuildInfoView` displays Version, Build, Commit, Full commit, Branch, Tag, Checkout, Built, Configuration, Bundle, Build source — but **never `GitStatus`**. The user-facing dirty signal is the `Not releaseable` warning banner, gated on `isReleaseable` (suffix inference), not on `GitStatus` directly. This is a UI gap; closing it would make user-facing dirty signals less reliant on suffix inference, but it is not the root cause of the TestFlight gate failure. Not queued; separate product question if pursued.

## Queued follow-up

`owlory-release-provenance-stamp-gate-fix` (priority 155, `depends_on: [owlory-release-provenance-stamp-audit]`):

- Extend `Tools/verify-build-provenance.sh` to assert pbxproj equivalence (working tree vs `git show HEAD`).
- Update `docs/workflows/release.md` to record the new gate as a numbered step.
- Add a focused test under `automation/tests/` simulating the failure mode (modified pbxproj + clean HEAD should fail the verifier).
- Out of scope: surfacing `GitStatus` in `BuildInfoView`, App Store Connect history audit, retroactive replacement of the failing TestFlight build.

## Out of audit scope

- Surfacing `GitStatus` in `BuildInfoView` (UI gap; separate product question).
- App Store Connect-side audit of earlier TestFlight builds.
- Retroactive replacement or revocation of the failing TestFlight build currently installed on the operator's iPhone.

## Validation

- `python3 automation/context/build_context.py --slice-id owlory-release-provenance-stamp-audit`
- `python3 automation/supervisor/run_next.py --dry-run`
- `make architecture`
- `make build-provenance`
- `make automation-check`
- `git diff --check`

## Next

`owlory-release-provenance-stamp-gate-fix` is the next eligible slice. After it lands and a corrected TestFlight build is produced, `owlory-ui-test-testflight-proof` can be re-attempted from a passing gate. Until then: TestFlight proof remains blocked; device-verified proof from `owlory-ui-device-proof/` remains the highest claim for Continue surfaces.
