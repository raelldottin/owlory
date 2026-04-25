# OSS Evaluation Workflow

Use this when evaluating open-source GitHub projects, libraries, or app references that might help Owlory.

## Purpose

The goal is not to copy another product wholesale. The goal is to decide whether Owlory should responsibly use, study, or ignore a project.

## Fit Criteria

Prefer candidates that help Owlory with:

- day-shaping and follow-through
- continuity across sessions and days
- self-calibration and lower re-deciding
- state clarity, deterministic testing, persistence, navigation, or small focused infrastructure

Avoid candidates that:

- turn Owlory into a generic habit, task, social accountability, journal, or analytics-heavy clone
- import whole app architectures for a narrow problem
- add more complexity than product value
- conflict with Apple-native, local-first behavior

## Decision Buckets

- `Use`: a narrow dependency solves a real problem, fits Owlory boundaries, and reduces implementation risk.
- `Study`: ideas or implementation details are useful, but direct adoption is too heavy or opinionated.
- `Ignore`: the project solves the wrong problem, distorts Owlory's product model, or adds complexity without leverage.

## Recommended Output

When asked to evaluate OSS, report:

- recommendation summary
- `Use` / `Study` / `Ignore` table
- why each project fits or does not fit Owlory
- best direct dependency candidates
- best implementation references
- adoption risks
- single next step

Prefer small infrastructure libraries over full app templates. If no project is a strong fit, say so plainly.
