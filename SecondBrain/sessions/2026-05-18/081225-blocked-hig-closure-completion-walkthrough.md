# blocked-hig-closure-completion-walkthrough

## Prompt

> "walk me through the process to complete the blocked slices"

## Current Blocker

Only one parked slice remains: `app-localization-all-locale-hig-ui-closure`.

Entry condition:

- every locale has native/fluent review where required
- every HIG gate passed
- every remediation slice is done
- proof manifests are preserved

Native/fluent review is complete. The remaining blockers are HIG proof/closure:

- `HIG-DE-001`: German post-fix Today reflection evidence is not preserved.
- `HIG-AR-002`: Arabic WriteView RTL directional-symbol fix needs captured proof.
- Scoped HIG proof must be reflected in `automation/proofs/app-localization-hig-ui-matrix/manifest.json`.

## Process

1. Capture or preserve the missing scoped HIG evidence, especially German Today post-fix and Arabic WriteView RTL.
2. Update the HIG matrix to move `HIG-DE-001` and `HIG-AR-002` to closed states with proof references.
3. Verify every per-locale scoped surface status is either passed, not applicable, or explicitly covered by maintained regression proof.
4. Run required closure validations.
5. Only then mark `app-localization-all-locale-hig-ui-closure` done and update docs to claim all-locale `hig-ui-reviewed`.
