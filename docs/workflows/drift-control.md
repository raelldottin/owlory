# Drift-Control Cleanup Workflow

Use this workflow to reduce root clutter and legacy-doc drift without deleting useful context by accident.

## Command

```bash
make drift-report
```

This calls `Tools/drift-report.sh`, a read-only classifier for:

- system metadata noise
- generated asset archives
- generated asset folders
- loose root reference images
- historical root docs
- legacy `owlory_xcode/Docs` files
- duplicate or archived code artifacts
- current Git status noise

The report is a triage tool. It does not delete, move, stage, or rewrite files.

## Cleanup Rules

1. Clean one class of drift at a time.
2. Do not remove anything just because the report lists it.
3. Confirm the current source of truth before moving or deleting.
4. Keep product-code changes out of cleanup-only patches.
5. Record the cleanup decision in `SecondBrain`.
6. Run `make architecture` after docs/harness cleanup.
7. Run focused domain validation if a cleanup touches source, tests, assets, or build files.

## Approved Remediation Paths

System metadata:

- Policy: system metadata is never source of truth and should not be committed.
- Covered patterns: `.DS_Store`, `._*`, `.AppleDouble`, `.LSOverride`, `Thumbs.db`, `ehthumbs.db`, and `Desktop.ini`.
- Run `make clean-system-metadata` to remove only obvious metadata files.
- Run `./Tools/clean-system-metadata.sh --dry-run` when you want to inspect what would be removed first.
- Do not combine this cleanup with generated asset, archive, docs, or duplicate-code cleanup.

Generated asset archives and folders:

- Confirm shipped assets live under `owlory_xcode/Owlory/Resources/Assets.xcassets`.
- For app icons, run `./Tools/verify-app-icons.sh` and follow [App Icon Asset Workflow](app-icons.md).
- Keep one documented canonical icon source path and one documented build/export path.
- Treat root app-icon bundles, export folders, and icon zip archives as non-canonical by default.
- Preserve only durable variant notes in maintained docs; do not leave alternate shipping-looking icon sets at the repo root.
- Remove non-canonical icon bundles or archives in a dedicated cleanup patch after verification.

Loose root images:

- For app-icon-related images, treat loose root files as non-canonical unless a maintained doc gives them an active owner and location.
- Preserve only durable design notes; remove loose generated/reference images that are not part of the canonical build path.

Historical root docs:

- Follow [Historical Root Docs](historical-docs.md) before moving or deleting root markdown.
- Promote still-authoritative content into `docs/`.
- Link from `docs/README.md` only when the doc is part of the active retrieval path.
- Archive or remove superseded root docs in a docs-only patch.

Legacy `owlory_xcode/Docs`:

- Follow [Legacy Xcode Docs](legacy-xcode-docs.md) before moving or deleting historical Xcode markdown.
- Treat remaining files as historical unless a root doc points there.
- Promote useful content into root `docs/` before removing the legacy copy.
- Do not use legacy docs as the only source of current architecture or workflow truth.

Duplicate or archived code artifacts:

- Compare against current `owlory_xcode/` sources and tests.
- Confirm no current build, test, or workflow references the artifact.
- Follow [Archived Code Artifacts](archived-code-artifacts.md) before removing anything.
- Remove or archive in a dedicated cleanup patch after documenting the decision.

Executable-looking but inactive artifacts deserve extra caution: they can confuse ownership more easily than obviously historical markdown.

## Failure Recovery

If a cleanup accidentally touches unrelated work, stop and inspect `git status --short`. Do not revert user changes casually. Narrow the cleanup to the intended class and leave unrelated paths alone.
