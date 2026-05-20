# queue-claude-trailer-history-rewrite-slice

## Prompt

> "add slice for rewriting already-pushed history for the prior commits that carry the trailer."

Follow-up to commit `f6ad4f0` which added the repo-level Claude attribution disable + commit-msg hook for future commits. This slice queues the optional cleanup of already-pushed history.

## What was done

Queue-only update. Appended one destructive git-hygiene slice to `automation/queue/slices.json`. No source/test/proof artifact changes; no actual history rewrite (the slice is queued, not executed).

### Queued

| Slice ID | Pri | Status | Domain |
|---|---:|---|---|
| `app-history-strip-claude-trailers` | 96 | queued | git-hygiene |

### Pri 96 = picked last

Under Owlory's lower-pri-first supervisor convention, pri 96 makes this slice the last queued item the supervisor will pick. That's appropriate for a destructive operation: it should not pre-empt active work and should run only when explicitly desired.

### Affected commit range (recorded for the implementor)

- 85 hits from `git log --grep='Co-Authored-By: Claude' --pretty='%h'`. One of those (`f6ad4f0` itself, today's "Disable Claude commit/PR attribution") is a **false positive**: its body describes the trailer in narrative text rather than carrying one. The slice notes instruct the implementor to filter by literal trailer line at start-of-line.
- Earliest affected: `60576b3 2026-05-03 Add protocol schedule notification planning`.
- Latest affected before the hook landed: `0a24e57 2026-05-20 Queue Robinhood design newsroom research slice`.
- Force-push base must be the parent of the earliest affected commit.

### Procedure captured in slice notes

1. **Pre-flight gates:** clean tree, mirrored HEAD, no in-flight rebase, no other agent commits in flight.
2. **Rewrite:** prefer `git filter-repo` over deprecated `git filter-branch`; apply the same sed patterns the commit-msg hook already uses.
3. **Verify locally:** zero hits from the trailer grep, commit count preserved, full validation gate (architecture, localization-check, automation-check, pyright) passes against the new HEAD.
4. **Force-push:** `--force-with-lease` only; bare `--force` forbidden. Pre-push provenance hook must pass.
5. **Document:** handoff JSON records old/new SHA ranges; older session notes and handoff JSONs that reference SHAs by value are NOT rewritten — they remain point-in-time historical records.

### Explicit risks (in the slice notes)

- Hash rewrite cascades through every commit from the rewrite base onward.
- Multi-agent activity: anyone mid-slice would need `git fetch && git reset --hard origin/main`.
- Past handoff/session SHA references will be stale after the rewrite. They remain valid as observations but `git show <old-sha>` will fail for anyone who didn't fetch before the rewrite.
- Pre-push provenance check should pass because file contents are unchanged; verify before pushing.

### Out of scope (also in the slice notes)

- Do NOT rewrite historical handoff/session SHA references — they are point-in-time records.
- Do NOT add a Co-Authored-By trailer in this slice's commit (hook would strip it anyway).
- Do NOT touch GitHub PR descriptions; this is local-history-only.

## Validation

- `python3 -m json.tool automation/queue/slices.json` — valid.
- `make automation-check` — drift `no drift` + 93 unittests OK.

## Lane Boundary

`doc-only`. Queue entry + this session note + INDEX line. No code, test, or proof change. The actual history rewrite is the slice's job, not this commit's.

## Not Claimed

- History has been rewritten (it hasn't; this slice queues the rewrite).
- The trailer-bearing commits will be rewritten automatically (the user must explicitly request the slice be run).

## Next

User's next `start next slice` will pick the lowest-priority-numbered queued slice, which remains `app-reminders-cancel-pending-on-home-and-today-completion` (pri 30). This new slice sits at pri 96 — picked last unless renumbered.
