# Write Domain

## Product Role

- Write is Owlory's low-friction thinking inbox and incubation layer.
- Product rule: capture first, classify later, if ever.
- Write should help the user catch unfinished thought before it becomes a task, plan, protocol, decision, or nothing at all.

## Current Posture

- The current implementation stores notes in explicit stages: capture, source, permanent, draft seed, draft, published, archived.
- Those stages are support structure for retrieval, incubation, and optional promotion, not a claim that Write is a full note-taking, research, or publishing system.
- Any future refinement should make Write feel more like catching a thought than managing a note.
- Write has no required daily or weekly note cadence.
- Today should not use generic domain-balance copy to imply Write is quiet. Use the Write pipeline nudge only when capture notes are piling up and not advancing.

## Long-Term Success Criteria

- A new user can open Write and save a thought in seconds.
- A new user does not need to understand stages to succeed.
- Initial capture preserves enough context that nothing important is lost during fast entry.
- Promotion into tasks, plans, protocols, reminders, or other Owlory surfaces remains possible after capture.
- The UI must not imply that every note needs promotion or further structuring.

## Psychological Posture

- Write should reduce the chance of losing a thought, not ask the user to perform correctness.
- The emotional test for the surface is whether it feels safe and forgiving for unfinished thinking.
- When a user opens Write, the default feeling should be "I can catch this before I lose it," not "I need to manage this properly."

## Owns

- Writing notes.
- Fast capture of raw thought, including voice-assisted capture.
- Lightweight writing-stage markers that support incubation and later promotion.
- Capture, source note, permanent note, draft seed, draft, published, archived states.
- User-driven promotion handoff from a note into another Owlory surface.
- Writing pipeline nudges derived from pattern calibration.

## Does Not Own

- Research-vault or source-note knowledge-management workflows.
- Heavy document-editing or publishing workflows.
- Required classification at capture time.
- Task, project, protocol, reminder, or decision ownership after a note is promoted into another domain.
- Cross-note pattern interpretation beyond the signals consumed by `Patterns`.
- Career records.
- Today carry-forward policy.
- ML-generated user-facing content.

## Depends On

- `WritingStageRules` for legal transitions.
- `WriteStore` for state and persistence orchestration.
- `VoiceTranscriptionRoutingRules` for capture-field routing.

## Exposes

- `WritingNote`, `WritingStage`, `WriteStore`.
- Continue-routed Write notes should deep-link into the selected note detail after tab routing when Today provides a concrete note highlight target.

## Change Safely

- Optimize for instant entry and minimal required structure.
- Stage changes must stay explicit and tested, but they must not become a gate that makes capture feel heavy.
- Future capture refinements should prefer forgiving defaults over correctness rituals.
- Do not destroy source content or context during promotion.
- Promotion into the rest of Owlory should remain optional; not every note should become structured work.
- If repeated notes drive resurfacing or pattern interpretation, keep that policy in `Patterns` and keep the promoted object owned by the destination domain.
- Do not ask the user to make notes just to satisfy a balance metric.
- Keep ML helpers out of user-authored content generation.

## Verify

- `make test-domain DOMAIN=write`
- `xcodebuild test -project Owlory.xcodeproj -scheme Owlory -destination "$OWLORY_XCODE_DESTINATION" -only-testing:OwloryCoreTests/WritingStageRulesTests`
