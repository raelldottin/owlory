# tools-generate-build-info-worktree-fix

## Summary

`Tools/generate-build-info.sh` previously used `[ -d "$GIT_ROOT/.git" ]` to decide whether to read git metadata. That test rejects git worktrees because `.git` in a worktree is a file pointer (`gitdir: /path/to/main/.git/worktrees/<name>`), not a directory. The script then fell through to the no-git fallback and stamped `GitCommit=no-git` / `GitBranch=no-git` / `GitTag=no-git`, which broke source traceability and `BuildInfo.isReleaseable` for any worktree build. Replaced the test with `git -C "$GIT_ROOT" rev-parse --git-dir > /dev/null 2>&1`, which asks git itself to resolve the repository and works for normal checkouts, worktrees, and submodules. Updated the comment block explaining the choice.

## Why `git rev-parse --git-dir` over `[ -e ]`

Both fixes work for the immediate worktree case, but `[ -e ]` only proves something exists at the path. `git rev-parse --git-dir` proves git can actually resolve the repository starting from that path. That's a stronger guarantee — it catches cases where `.git` exists but is malformed (corrupted gitdir pointer, partial clone, broken submodule), and it is the same call git uses internally. Cost is one extra git invocation, which is negligible inside a build phase.

## Verification

Three direct stamp invocations covered the relevant repo shapes:

1. **Worktree** (`/Users/raelldottin/Documents/Personal/Owlory/.claude/worktrees/frosty-greider-e0a33c`): produced `GitCommit=54df0d5cd2dd-dirty`, `GitBranch=claude/frosty-greider-e0a33c`, `GitTag=54df0d5-dirty`. Before the fix this same shape produced `no-git/no-git/no-git`.
2. **Normal checkout** (`/Users/raelldottin/Documents/Personal/Owlory`): produced `GitCommit=ba44c58834e5-dirty`, `GitBranch=main`, `GitStatus=dirty`. Unchanged from prior behavior.
3. **Non-git directory** (`/tmp/not-a-repo`): produced `GitCommit=no-git`, `GitBranch=no-git`, `GitStatus=unknown`. Fallback preserved for truly non-git build contexts.

`make build-provenance` against the worktree now reports:

```text
Git commit: 54df0d5cd2dd
Git commit full: 54df0d5cd2dd73604b5579b5e17ed4f89375279a
Git branch: claude/frosty-greider-e0a33c
Git describe: 54df0d5-dirty
Working tree: dirty
Releaseable: no
```

`Releaseable: no` is correct (the working tree had this slice's unstaged edits at verification time); after this slice's commit lands clean, the same command will return `Releaseable: yes` for that commit.

## Validation

- `python3 automation/context/build_context.py --slice-id tools-generate-build-info-worktree-fix`
- `python3 automation/supervisor/run_next.py --dry-run`
- `make architecture`
- `make build-provenance`
- `make automation-check` (36 tests passed)
- `git diff --check`

## Next

Retry `write-promotion-device-verification` from the post-fix commit. The previously installed device app carries no-git provenance and must be overwritten by a fresh post-fix install before any on-device flow is exercised for proof.
