# owlory-ui-regression-next-surface-triage

## Prompt

Unblock `owlory-ui-regression-expansion-next-surface` by choosing exactly one next UI regression surface and a coverage goal. Doc-only; do not add XCUITest code in this triage slice.

## Candidates Considered

| Surface | Contract status | Existing smoke | Cross-domain blast radius | Verdict |
| --- | --- | --- | --- | --- |
| Write capture inbox | `Partially implemented` (active) | Today-Continue ingress to in-progress Writing note only; the Write surface itself is uncovered | High — promotion flows cross Today / Home tasks / Home protocols | Chosen |
| Home protocols | Stabilized (`don't revisit without a concrete bug`) | Continue -> active run sheet route covered by smoke | Medium | Skipped |
| Train | `Implemented` (stale-session rollover) | Due-today Continue route covered by smoke | Low | Skipped |
| Patterns | `Implemented` (weekly digest) | None needed beyond Continue surface; UI is read-only digest cards | Low | Skipped |
| Localization layout | Gated by `app-localization-first-locale-review-intake` (blocked) | None | N/A | Skipped (premature) |

## Choice

Surface: Write capture inbox.

Rationale:
- Write Lab is the only Partially implemented capture domain currently shipping, so regression risk is highest where the contract is in motion.
- Write's promotion flows fan out into Today (Add to Today), Home tasks (task promotion), and Home protocols (protocol promotion); a regression on the Write surface ripples across the most-touched cross-domain wiring.
- The existing Today Continue smoke covers the ingress to an in-progress Writing note, but the Write surface itself (capture field plus promotion affordances) is not covered by any current XCUITest.
- Home protocols and Train are stabilized; their Continue routes are already smoke-covered. Patterns is a read-only digest surface with low interaction risk. Localization layout is gated on parked first-locale review intake.

## Coverage Goal (for the unblocked target slice)

`proof_level` target: `running-app-smoke`.

The implementation slice (`owlory-ui-regression-expansion-next-surface`) should:

- Open Write from the tab bar via an accessibility identifier.
- Add one deterministic seed launch arg (e.g., `--owlory-ui-seed-write-capture-inbox`) under `OwloryUITestSupport` that resets app-local state and writes a single in-progress `WritingNote`.
- Render and assert one in-progress Writing note row plus the capture field.
- Assert visibility of one promotion affordance (Add to Today) without exercising the cross-domain side effect.
- Add a new XCUITest class (e.g., `OwloryUITests/WriteCaptureRegression`) following the `TodayContinueRegression` pattern, so the smoke loop stays fast.
- Wire either `make ui-regression DOMAIN=<domain>` (the documented future shape) or an additional `-only-testing` filter rather than collapsing Write into the Today regression class.

Out of scope:

- Voice / live transcription paths (microphone-permission environmental constraint).
- Task promotion side effects.
- Protocol promotion side effects.
- Screenshot proof pack, device proof, TestFlight proof.

## Files Edited

- `automation/queue/slices.json`
- `docs/workflows/ui-regression-plan.md`
- `docs/workflows/ui-testing-hygiene.md`
- `docs/workflows/roadmap-status.md`
- `automation/handoffs/20260513T212057Z-owlory-ui-regression-next-surface-triage.json`
- `SecondBrain/INDEX.md`
- `SecondBrain/sessions/2026-05-13/212057-owlory-ui-regression-next-surface-triage.md`

## Outcome

- Triage slice marked done.
- `owlory-ui-regression-expansion-next-surface` flipped from `blocked` to `queued`, retitled to "Add Write capture inbox UI regression batch", with allowed_paths and notes scoped to Write capture inbox coverage.
- Parking lot entry for `owlory-ui-regression-expansion-next-surface` removed from `roadmap-status.md` (the localization parking entry remains).
- Supervisor dry-run now picks the Write batch as the next eligible slice.

## Validation

- `python3 automation/context/build_context.py --slice-id owlory-ui-regression-next-surface-triage`
- `python3 automation/supervisor/run_next.py --dry-run`
- `make architecture`
- `make automation-check`
- `git diff --check`

## Residual Risk

- This triage does not prove the Write regression batch will land at `running-app-smoke`; the implementation slice still has to satisfy `make ui-regression` and the failure-classification rules.
- This triage does not pick the next surface after Write; that decision belongs to a future triage slice once Write coverage is in place.
- Localization layout regression remains gated on the parked first-locale review intake; revisiting it requires unblocking that lane first.
