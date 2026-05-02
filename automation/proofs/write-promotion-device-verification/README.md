# write-promotion-device-verification (device proof)

Real-device evidence for the Write -> Home task -> View source note return flow on commit `c35a1d666e76` (branch `claude/frosty-greider-e0a33c`, built `2026-05-02T14:02:48Z`, Debug). Captured on Raell Dottin's iPhone (`00008130-000A090910C1401C`, iOS 26.3.1) after the worktree-aware build-info stamping fix landed.

## Files

- `01-build-info.png` — In-app Build Info screen showing `Commit c35a1d666e76`, `Branch claude/frosty-greider-e0a33c`, `Built 2026-05-02T14:02:48Z`, `Tag c35a1d6`, `Configuration Debug`. Required gate: this proves the installed build is traceable to the post-fix commit, not the previous `no-git` artifact.
- `02-write-note-created.png` — Write tab list view with the freshly created note `device verification probe` at the bottom.
- `03-turn-into-task-result.png` — Home tab after Turn into Task: a Standalone Task `device verification probe` appears under Standalone Tasks.
- `04-home-task-detail.png` — Edit Task sheet for the new task. The Source section exposes a `View source note` link, which is the route-back affordance under verification.
- `05-view-source-note.png` — Edit Note view reached by tapping `View source note`, showing Stage `Source Note` and the `Advance to Permanent Note` action.
- `06-returned-write-note.png` — Same Edit Note view captured during the operator's repeat traversal; preserved alongside `05` to keep the flow record continuous.

## Observed gap (separate from this slice's contract)

`03` shows the new Home task in Home, but the device pass also confirmed the task does not surface in Today's Continue. That is recorded as a residual risk in the handoff and is a candidate for a follow-up triage slice — it is not a regression of the route-back contract this slice was scoped to verify.
