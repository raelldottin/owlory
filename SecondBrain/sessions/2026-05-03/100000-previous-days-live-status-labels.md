# previous-days-live-status-labels (domain-tested)

Added read-only live-status labels to Previous Days focus and carry-forward rows so historical entries show whether the source item is still active, completed, skipped, archived, or abandoned.

## What changed

### TodayView.swift

- Added `PreviousDayLiveStatus` enum with five cases: active, completed, skipped, archived, abandoned. Each carries a display label and color.
- Added `makeLiveStatusResolver()` to TodayView that captures current store state (TrainStore sessions, HomeStore tasks/runs/protocols, WriteStore notes) and returns a closure mapping `OwloryItemOrigin` to live status. Supports trainingSession, homeTask, homeProtocolRun, writingNote origin kinds. careerRecord returns nil.
- Threaded the resolver closure through `PreviousDaysView` and `PreviousDayDetailView`.
- Focus rows show an inline status label after the domain and focus-status text when origin resolves.
- Carry-forward rows show a trailing status label when origin resolves.
- Items without origin metadata or with deleted sources show no label (silent degradation).

### Design decisions

- **Resolver closure, not store injection**: `PreviousDayDetailView` takes `(OwloryItemOrigin) -> PreviousDayLiveStatus?` instead of direct store references. Keeps the view decoupled from store internals.
- **Snapshot at navigation time**: The resolver captures store arrays when `PreviousDaysView` is constructed, not on every render. This is intentional — previous days are historical, and the status label is informational, not reactive.
- **Home protocol run + archived template**: An active run whose parent template is archived shows "Archived" rather than "Active" — the run is technically active but the template context is gone.

## Not changed

- Domain intentions, evening reflections, energy/mood/sleep: no linkable identity, unchanged.
- DailyEntry data: not mutated, no persistence changes.
- No routing from status labels to source records.
- PreviousDayRow (list-level row) unchanged — labels appear only in detail view.

## Proof level

`domain-tested`. Today domain tests pass. No running-app or screenshot proof captured.

## Validation

- `make architecture` — passed
- `make test-domain DOMAIN=today` — passed
- `make automation-check` — passed (36 tests)
- `git diff --check` — clean

## Next

No queued slices remain. Future follow-up: routing from status labels to source records, and readiness trend visualization on the Previous Days list.
