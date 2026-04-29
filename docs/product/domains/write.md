# Write Domain

## Product Role

- Write is Owlory's low-friction thinking inbox and incubation layer.
- Product rule: capture first, classify later, if ever.
- Write should help the user catch unfinished thought before it becomes a task, plan, protocol, decision, or nothing at all.
- Write Lab is the capture inbox inside that role: the place where raw material lands before Owlory or the user decides whether it should stay a note, become structured work, or disappear.

## Current Posture

- The current implementation stores notes in explicit stages: capture, source, permanent, draft seed, draft, published, archived.
- Those stages are support structure for retrieval, incubation, and optional promotion, not a claim that Write is a full note-taking, research, or publishing system.
- If users treat Write Lab like a quick todo list, read that as product evidence that Write is currently the fastest, lowest-friction place to capture intent.
- Do not fight that behavior by forcing up-front classification or by implying the user is using Write incorrectly.
- Source note creation is a lightweight classification step: open a note, choose `Turn into Source Note`, add only useful source metadata, and save.
- Turning a note into a source note must preserve the original note title and body. It adds source fields and moves the note into the source-note role; it must not become a desktop-style filing ritual.
- Any future refinement should make Write feel more like catching a thought than managing a note.
- Write has no required daily or weekly note cadence.
- Today should not use generic domain-balance copy to imply Write is quiet. Use the Write pipeline nudge only when capture notes are piling up and not advancing.

## Capture Inbox Contract

- Write Lab is not a todo list as a product identity.
- Write Lab is allowed to receive todo-like thoughts because users often need the fastest possible place to capture unfinished intent.
- The app should respond to that behavior with a helpful processing path, not with extra friction at capture time.
- The first step is always: write it down.
- Classification, promotion, and cleanup belong after capture, not before it.

## Promotion Model

- Every Write Lab entry should be eligible for lightweight later promotion into the rest of Owlory.
- The canonical promotion targets are task, Today priority, source note, permanent note, protocol item, archive, and keep as note/draft.
- Promotion should be fast on mobile, ideally one or two taps from the captured entry.
- When a note is promoted, preserve the original writing context or keep an origin link instead of silently discarding the capture.
- Do not require the user to decide upfront whether a captured item is a task, note, source, protocol input, or reflection.
- Lightweight follow-up prompts are appropriate after capture when Owlory has a good signal, such as actionable phrasing, a URL, or repeated carry-forward.
- Pattern-driven prompts should stay suggestive rather than mandatory, for example: turn into task, mark as source note, schedule, archive, or keep as note.

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
- The app should say, in effect, "Capture it here. We'll help you move it later," not "Decide what this is before you can save it."

## Owns

- Writing notes.
- Fast capture of raw thought, including voice-assisted capture.
- Fast capture of intent, including thoughts that are task-like before they have been classified into a destination domain.
- Lightweight writing-stage markers that support incubation and later promotion.
- Capture, source note, permanent note, draft seed, draft, published, archived states.
- User-driven promotion handoff from a note into another Owlory surface.
- Writing pipeline nudges derived from pattern calibration.

## Does Not Own

- Research-vault or source-note knowledge-management workflows.
- Heavy document-editing or publishing workflows.
- Required classification at capture time.
- Long-term ownership of tasks or protocol work just because they were first captured in Write Lab.
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
- Let messy capture exist at first; the product value is helping raw material become useful later.
- Voice-assisted capture should populate the editable body while the user is speaking, but it remains draft text until the user saves the note.
- Stage changes must stay explicit and tested, but they must not become a gate that makes capture feel heavy.
- Staged note rows should have one primary action: open the note. Secondary actions such as stage advancement belong in note detail or row actions, not nested inline buttons.
- Source metadata should stay forgiving: source title, creator, URL, source type, date, citation, and quote fields are optional aids, not required proof before saving.
- Future capture refinements should prefer forgiving defaults over correctness rituals.
- Do not open capture with a chooser that asks the user to classify the item before saving.
- If Write Lab gains promotion actions, keep them as lightweight after-capture actions rather than as mandatory entry steps.
- Do not destroy source content or context during promotion.
- Promotion into the rest of Owlory should remain optional; not every note should become structured work.
- If repeated notes drive resurfacing or pattern interpretation, keep that policy in `Patterns` and keep the promoted object owned by the destination domain.
- Do not ask the user to make notes just to satisfy a balance metric.
- Keep ML helpers out of user-authored content generation.

## Verify

- `make test-domain DOMAIN=write`
- `xcodebuild test -project Owlory.xcodeproj -scheme Owlory -destination "$OWLORY_XCODE_DESTINATION" -only-testing:OwloryCoreTests/WritingStageRulesTests`
