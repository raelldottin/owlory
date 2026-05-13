# PR Hygiene

Use this before opening, reviewing, or merging a branch. It preserves the useful Gymphant lesson for Owlory: a PR is not just a diff, it is a reviewable claim with evidence.

## PR Contract

Every PR should answer:

- What slice does this implement?
- What visible behavior changed, if any?
- What existing behavior was intentionally preserved?
- What proof level was reached?
- What proof levels remain missing?
- What validations were run exactly?
- What files or generated artifacts are intentionally included?
- What risks remain?

Do not use a PR to combine unrelated cleanup, product changes, proof artifacts, and workflow edits unless the supervisor slice explicitly allows that scope.

## Before Opening

1. Run `make handoff`.
2. Run `make review-preflight`.
3. Confirm the branch is clean or the PR explicitly explains any preserved dirty state.
4. Confirm `git diff --check` passes.
5. Run the narrowest relevant validation from [Validation Workflows](validation.md).
6. If UI behavior is claimed, follow [UI Testing Hygiene](ui-testing-hygiene.md).
7. If the PR or handoff prepares a TestFlight/archive candidate, run `make release-preflight` after the build-number bump is committed and pushed.

## PR Body Shape

Use this compact shape:

```text
Slice:
Summary:
Behavior changed:
Behavior preserved:
Proof level:
Missing proof:
Validation:
Artifacts:
Residual risk:
```

For proof artifacts, link the repo-managed directory and state what each artifact proves. Temporary `/tmp` screenshots or logs may support local debugging, but they are not durable PR evidence unless promoted into `automation/proofs/<slice-id>/`.

## Review Standard

Reviewers should reject or request clarification when:

- The PR claims behavior without a matching proof level.
- The PR includes unrelated files outside the slice boundary.
- The PR changes app resources or generated artifacts without a documented regeneration path.
- The PR adds workflow commands that are not discoverable from `docs/workflows/validation.md`.
- The PR includes screenshots without a manifest, README, or explicit proof boundary.
- The PR turns known UI-test failures into silence instead of classifying them.
- The PR prepares release work but does not show `make release-preflight` passing from clean mirrored source.

## Merge Gate

Before merge or handoff, the branch should be clean and mirrored or the handoff must say why it is not:

```bash
git status --short
git rev-list --left-right --count HEAD...@{u}
```

Use `legacy-unknown` or an explicit lower proof level when evidence is missing. Never upgrade a claim from later or adjacent work unless this PR actually ran and recorded that proof.
