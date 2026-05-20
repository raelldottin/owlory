# Content Standards

Integrated content + design reference for user-visible copy across Owlory's
surfaces. Pairs visual component choices with the localized copy that should
go in them, so future surfaces have a single place to check.

This is a **reference**, not a copy rewrite. The conventions below describe
observed practice in the shipped English source under
`owlory_xcode/Owlory/Resources/en.lproj/Localizable.strings` and the SwiftUI
component patterns in `owlory_xcode/Owlory/Features/`. Where the convention
is observed but inconsistent, that gap is named — and a separate slice is
the appropriate place to fix copy, not this doc.

Related references (do not duplicate):

- [Localization String Inventory](localization-string-inventory.md) — when a
  literal should be extracted and which component APIs already localize a
  literal automatically.
- [Localization Translation Quality](localization-translation-quality.md) —
  status labels, native-review intake, HIG UI evidence, and locale
  acceptance criteria.
- [Localization Dynamic Formatting](localization-dynamic-formatting.md) —
  layer ownership for counts, dates, statuses, and notification copy.
- [Localization Visible String Audit](localization-visible-string-audit.md) —
  call sites where a key exists but the runtime initializer overload
  bypasses `Localizable.strings`.

## 1. CTA capitalization (buttons and primary actions)

**Convention:** Title Case for button labels. Verb-first when the action is
not the obvious affordance of the surrounding UI.

Observed (English source):

- Single-word system actions: `Done`, `OK`, `Cancel`, `Save`, `Add`, `Delete`,
  `Edit`, `Archive`, `Restore`, `Move`. `OK` stays all-caps; this is the
  Apple HIG convention.
- Verb + noun: `Add Task`, `Add Protocol`, `Plan Session`, `Continue Run`,
  `Start New Run`, `Run Protocol`, `Capture Note`, `Restore Protocol`,
  `Archive Protocol`, `Edit Task`, `Edit Protocol`.
- Verb + article + noun for "add a thing" prompts: `Add a Task`,
  `Add a Protocol`, `Plan a Session`, `Capture a Note`. The article appears
  when the row is invitational rather than transactional.
- Adverbial direction: `Start Today`, `Add to Focus`, `Add another session`.
  Note `another session` is mid-sentence — sentence case applies inside an
  invitational row rather than title case.

**Translation implication:** title case in English does not survive
translation; reviewer-facing copy in non-English locales follows the
locale's own capitalization rules, not the English shape. Native reviewers
have final say. See [Localization Translation Quality](localization-translation-quality.md)
for the per-locale acceptance criteria.

**Do not invent new patterns when an existing CTA matches.** Reuse the
existing key (`Add Task`, `Save`, `OK`, `Cancel`) rather than introducing a
new variant.

## 2. Error message phrasing

**Convention:** every user-visible error message must include specific
resolution guidance. A raw exception message ("Failed to save records:
Optional(Error Domain=NSCocoaErrorDomain Code=4 ...)") is not acceptable
user-visible copy.

The Robinhood newsroom design research (commit `acd6903`, article #3)
flagged vague error messages as an anti-pattern; this rule encodes that
guidance.

**Current remaining gap:** the `app-error-message-fix-store-templates`
slice moved the save/load `lastError: String?` templates in `TrainStore`,
`WriteStore`, `HomeStore`, `CareerStore`, and `TodayStore` to localized,
resolution-guided keys. Remaining audited gaps are tracked separately:
`WriteStore` still has a domain-specific stage-conversion message, and
`PatternStore` still needs a visibility decision before its failure strings
can be handled correctly.

**Required shape when introducing a new user-visible error:**

1. Localized via `L()` or `String(localized:)` — never an English-only
   literal.
2. Names what the user can do next ("Try again", "Check internet
   connection", "Free up storage and retry") in plain language. Avoid
   "Contact support" unless the user genuinely cannot self-recover.
3. Does NOT surface `error.localizedDescription` directly — wrap the raw
   exception in a user-meaningful sentence. The raw description may be
   logged for diagnosis, but is not user-visible.
4. Uses sentence case with a terminal period. Errors are sentences, not
   labels.
5. Key namespace: `<domain>.error.<situation>` — e.g.,
   `train.error.session.save`, `home.error.protocol.save.storage`.

**Do not introduce a new error message** if an existing key fits. Reuse
`Couldn't Update Today`, `Couldn't Update Session`, `Couldn't Update Write`,
`Couldn't Update Career`, `Couldn't Update Home` (already extracted in
`Localizable.strings`) when the situation matches the existing alert
shape.

## 3. Header and section-label punctuation

**Convention:** no terminal punctuation on labels that are not sentences.

Observed:

- Section headers / labels: `Highlights`, `Domain Activity`, `Build Info`,
  `Voice Recording`, `Standalone Tasks`, `Archived Protocols`,
  `Protocol Runs`, `Steps`, `Schedule`, `Window`, `Source Details`,
  `Optional Reference`, `Stage`. No periods, no colons, no em dashes.
- Inline content that IS a sentence: `No weekly digests yet.`,
  `No sessions planned for today.`, `No active tasks.`, `No notes yet.`,
  `No active household protocols.` — sentence case, terminal period.
- Question form when the field is asking for input: `What's the session?`,
  `What did you actually do?`, `How did it go?`. Question mark, sentence
  case.
- Optional markers: parenthetical, lowercase: `Notes (optional)`,
  `Metrics (optional)`, `Readiness notes (optional)`. Do not bold or
  italicize the marker.

**Where the convention is unclear in practice:** the title-cased "Tasks"
section header vs. "Standalone Tasks" — both are correct (the former is a
generic section, the latter is a qualified subset). Pick the qualified form
when ambiguity is possible.

## 4. Component-to-content-type mapping

Pairs the SwiftUI component you should reach for with the copy length and
content category it expects. The component automatically localizes its
direct string literal in the cases noted in
[Localization String Inventory](localization-string-inventory.md), so the
choice of component is also a localization decision.

| Component | Use for | Copy shape | Capitalization | Terminal punctuation |
| --- | --- | --- | --- | --- |
| `Button(L("..."))` | User-initiated action | 1-4 words, verb-first | Title Case | None |
| `Label(L("..."), systemImage: "...")` | Iconic identity / status | 1-3 words | Title Case | None |
| `Section(L("..."))` | Grouping of related rows | 1-4 words | Title Case | None |
| `Text(L("..."))` | Static caption or inline sentence | 1 short sentence or fragment | Sentence case | Period if full sentence, none if fragment |
| `.navigationTitle(L("..."))` | Screen identity | 1-3 words | Title Case | None |
| `TextField(L("...promptKey"), ...)` | Empty-state prompt inside an input | Imperative or interrogative fragment | Sentence case | Question mark if interrogative, none otherwise |
| `.alert(L("..."), ...)` | Recoverable error or destructive confirm | Short title (≤6 words) + body sentence | Title Case (title) / Sentence case (body) | None (title) / Period (body) |
| `.confirmationDialog(L("..."), ...)` | Destructive multi-choice | Short question (≤8 words) | Sentence case | Question mark |
| `.accessibilityLabel(L("..."))` | Spoken identity | 1-5 words | Title Case | None |
| `.accessibilityHint(L("..."))` | Spoken result of action | Short sentence | Sentence case | Period |
| Continue row subtitle (presentation-formatted) | Why the row is in Continue | Short sentence fragment | Sentence case | None |
| Weekly digest insight | Reasoning summary | Full sentence (1-2 clauses) | Sentence case | Period |

**Do not nest content categories.** A `Section` header is not the place
for a sentence; a `Text` caption is not the place for a verb-first action.
If the content shape doesn't match any component above, the right answer is
usually to split it into two components (e.g., `Section` + `Text` row),
not to stretch one component to carry mixed content.

## 5. L() key naming convention (cross-reference)

The canonical L() / `Localizable.strings` key naming convention is described
in [Localization String Inventory](localization-string-inventory.md). In
brief:

- Dot-delimited, lowercase + camelCase tokens.
- `<feature>.<surface>.<element>.<state>` — for example,
  `home.protocol.schedule.custom.passed`,
  `today.readiness.scale.accessibility`,
  `notification.prediction.body.train`.
- Plural keys live in `Localizable.stringsdict`, not `Localizable.strings`.
- Format specifiers (`%@`, `%d`) must match across all locales — the
  localization parity check enforces this.

Direct user-facing literals in components listed under "already localized
by SwiftUI literal behavior" are also acceptable keys — the literal is the
key. See the inventory doc's classification rule for the exact list of
component APIs.

## 6. What this reference does NOT do

- Does not rewrite any existing copy. The conventions are observed, not
  newly imposed; existing copy that follows the conventions stays as-is.
- Does not audit which copy violates the conventions. The
  `app-error-message-audit` queued slice handles the error-message gap;
  separate per-domain audits would be appropriate for other gaps if
  prioritized.
- Does not change `Localizable.strings`, `Localizable.stringsdict`, or any
  per-locale return file.
- Does not prescribe a single visual identity or design throughline. The
  `app-design-vision-metaphor-adr` queued slice (also from the Robinhood
  research follow-up) names the Today / Continue / Patterns / Train
  throughline at the ADR level; this reference is one layer below that.
- Does not replace the localization quality contract. Native-review and
  HIG UI completion remain governed by
  [Localization Translation Quality](localization-translation-quality.md)
  and [Localization HIG UI Completion](localization-hig-ui-completion.md).

## 7. When to update this reference

Update when a new visible component is added to the design system, when an
existing convention is intentionally changed (record the decision in
`docs/decisions/`), or when an audit slice produces evidence that an
observed convention is no longer consistent enough to claim. Do not update
this doc to chase a single inconsistent string — fix the string instead.
