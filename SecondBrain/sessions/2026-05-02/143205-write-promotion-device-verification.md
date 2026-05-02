# write-promotion-device-verification (device-verified)

## Summary

Reran the slice on commit `c35a1d666e76` (worktree branch `claude/frosty-greider-e0a33c`, also published as `origin/main`) after `tools-generate-build-info-worktree-fix` landed. Built Owlory from a clean worktree, installed it on the connected physical iPhone, verified the in-app Build Info screen matched the installed bundle exactly, and completed the Write to Home-task to source-note return flow end-to-end. Six device screenshots are committed under `automation/proofs/write-promotion-device-verification/` as durable proof.

## Build Info Gate

In-app Build Info read on device matched the bundle stamp exactly:

```text
Commit:     c35a1d666e76
Full:       c35a1d666e76b051806704da8a99b462535572dd
Branch:     claude/frosty-greider-e0a33c
Tag:        c35a1d6
Built:      2026-05-02T14:02:48Z
Config:     Debug
Bundle:     com.raelldottin.owlory
GitStatus:  clean
```

This is the gate that the first attempt could not pass — the worktree-aware stamping fix is what made device-verified proof possible.

## Flow

1. Write tab -> create note `device verification probe` (screenshot 02).
2. Note action -> Turn into Task -> task created (returned to Home with the new Standalone Task visible, screenshot 03).
3. Tap the Home task -> Edit Task sheet shows the `View source note` route-back link (screenshot 04).
4. Tap `View source note` -> Edit Note view opens for the original Write note in source-note stage (screenshots 05 and 06).

The route-back contract this slice was scoped to verify is met on a real device with traceable provenance.

## Findings outside the slice contract

- **Today inclusion of Write-origin Standalone Tasks is missing on device.** The route-back works, but the new task did not appear in Today's Continue projection. Whether that is intentional (Today is Focus-and-protocol-scoped) or a real gap is a contract question, not a regression of this slice's contract. Recorded as `today-continue-write-task-projection-triage` for follow-up triage rather than queuing a fix.
- **Operator slip on the source-note Move controls.** During the run, the source note's Move/Stage controls were advanced one extra time. Screenshots 05 and 06 still show Stage=Source Note with `Advance to Permanent Note` available, so the route-back proof is intact, but the slip is noted so the screenshots are not misread as a Stage-transition claim.
- **Cross-checkout install collision.** Mid-run an Xcode UI Run from the unrelated main checkout (which was still on `ba44c58`, behind the pushed commits) replaced the c35a1d666e76 install with a stale ba44c58 build. The in-app Build Info gate caught it before any flow proof was claimed; the worktree-built bundle was then reinstalled and the gate retaken before continuing. Lesson: keep Xcode closed (or at least not running) on the main checkout while a worktree-built bundle is the proof artifact.

## Validation

- `python3 automation/context/build_context.py --slice-id write-promotion-device-verification`
- `python3 automation/supervisor/run_next.py --dry-run`
- `make architecture`
- `make automation-check`
- `git diff --check`
- `xcodebuild build` against `platform=iOS,id=00008130-000A090910C1401C` from a clean worktree at `c35a1d666e76`.
- `xcrun devicectl device install app` of the resulting bundle (final installationURL `41F48822-D7A9-4FC2-AC87-79D3C056A059`).
- `/usr/libexec/PlistBuddy` dump of the installed `Info.plist` confirming the stamped Git/Build values.
- On-device verification of the Build Info screen, then the route-back flow.

## Next

Triage `today-continue-write-task-projection-triage` to decide whether Standalone Tasks promoted from Write should appear in Today's Continue, or whether the existing scoping is intentional. Do not queue a code change before that contract decision.

After the main checkout is pulled past `c35a1d6`, the worktree branch identity (`claude/frosty-greider-e0a33c`) and `origin/main` will agree at the commit-level for this slice's proof artifact.
