# ML QA

Use this for features that draft text, classify content, transcribe speech, or suggest changes from user data. Pair it with [ML Model Posture](../runtime/ml-model-posture.md) and [ML Privacy And Drafts](../runtime/ml-privacy.md).

## Current Scope

- Current production suggestion and digest behavior is deterministic unless a future slice reintroduces model adapters.
- Speech transcription is the concrete ML-adjacent runtime path and needs both automated fallback coverage and real-device sanity.
- Do not describe old ML drafting, structured-capture, or model-availability placeholders as active.

## Test Principle

Test structure, state transitions, and fallback behavior first. Treat generated prose quality as eval coverage, not brittle exact-match unit tests.

Generated output must never be the source of truth for completion rates, readiness facts, best/hardest day, carry-forward state, domain activity, or persisted user-authored content.

## Layer Responsibilities

- Unit/domain tests: pure value rules, candidate filtering, deterministic ranking/scoring, confidence categories, and fact preservation.
- Application tests: injected fake services, accepted/dismissed draft flows, disabled/unavailable/empty/malformed responses, and persistence through existing store methods only.
- Infrastructure tests: speech/model adapter availability, cancellation, errors, empty output, audio-path preservation, and deterministic fakes for every failure category.
- UI tests: visible suggestion, accept/edit/dismiss, unavailable state, repeated-tap safety, and fallback continuation when UI automation exists.
- Device sanity: microphone permission, on-device speech availability, transcription latency, fallback behavior, small-screen layout, and any concrete model availability/performance claim.

Do not invent snapshot confidence when the repo has no UI snapshot target. Record the gap instead.

## Fake Response Categories

Every ML/speech/generated-output surface should have deterministic fake coverage for the categories it supports:

- `disabled`: feature is off; current deterministic behavior remains.
- `unavailable`: model or speech capability is missing or not ready; fallback path appears.
- `empty`: no usable text or fields; blank drafts are not persisted as valid output.
- `malformed`: wrong shape, incomplete fields, or unparseable output; no crash and no partial canonical write.
- `accepted`: user-confirmed valid output persists only through existing product paths.
- `dismissed`: valid output rejected by the user does not persist.
- `low-confidence`: structurally valid but weak output remains optional draft material.
- `explicit-wrong`: output contradicts known facts; eval marks it wrong even if the shape is valid.

## Eval Fixtures

Keep fixture sets small enough to audit and broad enough to catch regressions.

- Semantic correctness: source facts, domain, intent, dates, metrics, and allowed scope are preserved.
- Explicit wrongness: invented numbers, wrong domain/status, reversed sentiment/outcome, false fallback success, or wrong ownership is rejected.
- Structural validity: required fields, optional fields, state markers, metadata, and nested schema match the expected shape.
- Fallback: disabled, unavailable, empty, malformed, timeout, and cancellation leave deterministic flows usable and preserve user data.

Checklist-oriented drafts must preserve item boundaries. Do not let generated prose flatten user-provided checklists into one blob before review.

## Feature Checks

- Weekly digest: deterministic digest facts remain unchanged; any narrative draft failure must not block the digest screen.
- Voice capture: empty transcription is safe, audio filename handling remains stable, and typed capture results preserve legacy text-plus-file behavior where that contract exists.
- Focus suggestions: deterministic focus logic owns ranking/fallback; dismissal does not persist; accepting a suggestion writes through the existing Focus path and must not mutate carry-forward history.
- Write, Career, Home, and Train assistants: any future generated draft path needs accepted, dismissed, malformed, empty, and manual-edit coverage before it is treated as release-ready.

## Validation

Run the narrowest honest checks:

```bash
make architecture
make test-domain DOMAIN=voice
make review-preflight
```

For non-voice generated-output work, run the affected domain command from [Validation Workflows](validation.md). Use `make verify` when app wiring, project files, or broad runtime behavior changes.

Device sanity is still required for microphone permission, on-device speech availability, transcription latency, fallback behavior, and any concrete model availability/performance claim.
