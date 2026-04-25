# Archived Code Artifacts

Use this workflow before moving or deleting root code/test trees or project archives that look executable but are not part of the active repo shape.

## Rule

Treat executable-looking but inactive artifacts as higher risk than obviously historical markdown. Before deleting one, prove all three:

- the active build, test, and workflow owners live elsewhere in maintained docs or code,
- no current build/test/review workflow depends on the artifact, and
- any still-useful content has been promoted into maintained locations.

If an artifact is unique but still useful, promote only the durable guidance or coverage idea rather than keeping a second quasi-source tree beside the active repo.

## Current Classifications

| Artifact | Evidence | Classification | Action |
| --- | --- | --- | --- |
| `OwloryCoreTests/` | Root folder contains only `BuildInfoTests.swift`. Current test ownership lives under `owlory_xcode/OwloryCoreTests/`, and package, Xcode, docs, validation commands, and `SecondBrain` references all point there. The root copy is a stale partial duplicate that is missing current release-provenance assertions already covered by the maintained test file. | Dead duplicate of maintained tests. | Removed. |
| `owlory_xcode.zip` | Small archive of the old `trajectory_xcode/` starter project with historical `Docs/PROJECT_SPEC.md` and `Docs/LESSONS_FROM_GYMPHANT.md`, plus early app/test scaffolding. No maintained workflow or recovery path references this archive. Its still-useful doc guidance has already been promoted into maintained docs. | Historical project snapshot fully superseded by maintained docs and live code. | Removed. |
| `owlory_xcode_v2.zip` | Archive of a slightly newer `trajectory_xcode/` snapshot with early package/test scaffolding. No current workflow references it, and its product/test guidance is already represented in maintained docs, live `owlory_xcode/`, and `SecondBrain` history. | Historical project snapshot fully superseded by maintained docs and live code. | Removed. |
| `owlory_xcode_v3.zip` | Large archive of the old `trajectory_xcode/` project plus `.build/` output and compiled-package artifacts. No current workflow references it. Keeping a build-output-laden archive beside the working repo makes inactive code look more canonical than it is. | Historical project snapshot plus generated build artifacts; especially unsafe as floating quasi-source. | Removed. |

## Verification

After an archived-code-artifact cleanup, run:

```bash
make drift-report
make architecture
./Tools/validate.sh handoff
./Tools/validate.sh review-preflight
git diff --check
```

Use `make review-preflight` when the cleanup also touches workflow scripts.
