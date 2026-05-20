# app-reminders-cancel-pending-home-today

Prompt received 2026-05-20T06:32:05Z.

User stated TestFlight HIG proof is not needed and automated proof is acceptable, then asked to start the next slice.

Initial state:
- Repo clean and mirrored before work.
- Supervisor selected `app-reminders-cancel-pending-on-home-and-today-completion`.
- Selected scope: replicate the `TrainStore` item-completion cancellation closure pattern into Home task completion, Home protocol-run completion, and Today focus-item Done completion.
- Localization device/TestFlight proof slices remain parked/blocked; this slice stays focused on reminders cancellation.

Plan:
1. Inspect existing TrainStore cancellation wiring and Home/Today completion paths.
2. Add focused domain tests for Home task completion, Home protocol-run completion, and Today focus-item Done completion.
3. Inject `onItemCompleted` closures through HomeStore and TodayStore, wire them from `OwloryApp`, and preserve bulk `reschedule()` behavior.
4. Run required validations, write handoff, commit, push, and leave the repo clean.

Implementation:
- Added HomeStore `onItemCompleted` injection and fired `CompletionTimePredictor` keys when Home tasks complete and when protocol runs reach terminal completion.
- Added TodayStore `onItemCompleted` injection and fired source-specific predictor keys only when a source-backed focus item transitions to `.done`.
- Reused the TrainStore/OwloryApp cancellation pattern for all three stores: `Task { @MainActor in scheduler.cancelReminder(forKey: key) }`.
- Preserved `ReminderScheduler.reschedule()` and did not modify scheduler behavior.

Fail-first proof:
- `make test-domain DOMAIN=home` and `make test-domain DOMAIN=today` failed before implementation because the new tests passed `onItemCompleted` into stores that did not yet accept that dependency.
- The first post-implementation parallel Today rerun hit the shared Xcode build DB lock; rerunning Today alone passed.

Validations:
- `python3 automation/context/build_context.py --slice-id app-reminders-cancel-pending-on-home-and-today-completion` passed.
- `python3 automation/supervisor/run_next.py --dry-run` passed and selected this slice.
- `make architecture` passed.
- `make localization-check` passed: 19 locales, 377 keys, 13 plural keys.
- `make test-domain DOMAIN=home` passed.
- `make test-domain DOMAIN=today` passed.
- `make test-domain DOMAIN=runtime` passed.
- `make automation-check` passed.
- `make pyright` passed: 0 errors, 0 warnings.
- `xcodebuild build -quiet -project owlory_xcode/Owlory.xcodeproj -scheme Owlory -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/owlory-reminders-cancel-home-today-build CODE_SIGNING_ALLOWED=NO` passed with the pre-existing TodayView `onChange(of:perform:)` deprecation warning.
- `git diff --check` passed.

Handoff:
- `automation/handoffs/20260520T063828Z-app-reminders-cancel-pending-on-home-and-today-completion.json`
- Proof level: `build-tested` + domain-tested.
