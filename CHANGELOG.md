# Changelog

Curated release notes for Owlory marketing versions.

This file is user- and support-facing. It summarizes changes that matter for TestFlight, App Store, support, and rollback decisions. Detailed operational history belongs in `SecondBrain/`, `automation/handoffs/`, and `automation/queue/slices.json`.

## [Unreleased]

### Added

### Changed

### Fixed

### Localization

### Release And Validation

## [1.0.1] - 2026-05-27

### Added

- Published external App Store support and privacy pages and linked the App Store listing from the README.

### Changed

### Fixed

- Honored the configured run cadence in protocol schedule helper copy.
- Suppressed missed-window reminders for skipped Train and Home items.
- Closed activity-drift and stale-prediction reminder gaps so terminal-status items stop firing reminders.

### Localization

- Refreshed localization review drift records against the latest source strings.

### Release And Validation

- Required pushed clean-stop completion in the release-gate stack.
- Synced the reusable automation clean-stop policy across release tooling.
- Added Train store rename and delete cancel-hook test coverage.
- Recorded simulator proof of terminal-status reminder cancellation.

## [1.0.0] - 2026-05-22

### Added

- Added localized resources and semantic copy routing across Today, Train, Write, Home, Patterns, reminders, accessibility labels, and helper-generated copy.
- Added repo-managed localization review, all-locale review packets, native/fluent review intake, drift checks, and simulator-based HIG/accessibility proof lanes.
- Added release Build Info and provenance workflows that tie installed app version/build metadata back to committed Git source and clean archive readiness.
- Added a curated release changelog and marketing-version policy for future `MARKETING_VERSION` bumps.

### Changed

- Reworked Today, Continue, readiness, pattern, and domain-nudge presentation so domain logic returns semantic values while UI/application layers own localized copy.
- Expanded UI regression coverage for Continue routing, Home protocols, Train active/history flows, Write capture, localization layout/accessibility, and smallest-width simulator checks.
- Documented content and design direction for component choice, error-message guidance, and quiet daily momentum across core surfaces.

### Fixed

- Canceled pending and delivered reminders when Train, Home, and Today-backed items are completed.
- Fixed localized UI risks around RTL directional symbols, tab-bar truncation coverage, and small-width simulator accessibility checks.
- Removed raw or hard-coded English user-facing error copy from store templates, Write source-note conversion guidance, and audio/voice accessibility error labels.
- Strengthened release provenance gates so uncommitted `CURRENT_PROJECT_VERSION` and `MARKETING_VERSION` changes fail before Archive/push.

### Localization

- Recorded native/fluent review intake across supported non-English locales while preserving separate proof levels for simulator, device, and TestFlight evidence.
- Added all-locale string parity, stringsdict XML portability, and automated drift checks for source strings and review-return files.
- Added Apple HIG localized UI workflow, evidence matrix, simulator screenshot proof, and accessibility regression lanes for supported locales.

### Release And Validation

- Added `make release-preflight`, pre-push provenance checks, build-provenance verification, Pyright validation, automation drift gates, and clean-stop completion checks.
- Added isolated tests for release version bump behavior without changing real `MARKETING_VERSION`, `CURRENT_PROJECT_VERSION`, or App Store Connect state.
- Added `CHANGELOG.md` as the curated release-note source for future marketing-version bumps.
