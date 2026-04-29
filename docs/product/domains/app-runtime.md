# App Runtime Domain

## Owns

- App composition and dependency wiring.
- Root tab orchestration.
- Build identity.
- Performance telemetry facade.
- Widget and Live Activity runtime behavior.
- Shared runtime mirroring from the app's reminder plan into the widget snapshot.

## Does Not Own

- Product rules for individual domains.
- Persistence formats except through injected repositories.
- UI details inside feature screens.

## Depends On

- Stores from application layer.
- `BuildInfo` and `PerformanceTelemetry`.
- Widget extension files in `OwloryWidgets/`.

## Exposes

- App launch wiring.
- Build diagnostics.
- Build provenance and rollback verification workflow.
- Runtime telemetry events.
- The release-identity contract that ties shipped Xcode build metadata back to committed GitHub history.

## Build Provenance And Runtime Mirroring Contract

Implementation status: `Implemented` for local build provenance; `Partially implemented` and `Needs automation enforcement` for GitHub/Xcode release mirroring.
Proof level: `BuildInfo`, Xcode stamp scripts, `BuildInfoTests`, and `make build-provenance` prove local build identity.
Missing/deferred: A pushed-commit release-readiness gate and dedicated widget/reminder parity proof remain future work.

- A local build should report the Git commit, branch, tag/describe output, dirty status, build date, configuration, and build-number source that produced it.
- A release archive should be traceable to committed GitHub history, not a local-only Xcode state.
- Widget mirroring should stay a narrow runtime projection from the app's reminder plan, not a second source of product rules.

## Change Safely

- Keep dependency construction explicit.
- Do not hide new global state in app entry.
- Preserve build-info stamping and release traceability.
- Treat GitHub and Xcode as two views of one release identity, not independent version records. A professional release should always let someone move from a shipped app build to the exact committed GitHub source and from a GitHub release commit back to the matching Xcode version/build metadata.
- Keep `MARKETING_VERSION`, `CURRENT_PROJECT_VERSION`, stamped `BuildInfo`, Git commit/tag identity, and pushed GitHub history intentionally aligned. Do not rely on local-only Xcode edits, unpublished commits, or dirty archives as release truth.
- Keep app/widget shared state explicit and minimal. The widget should mirror the live reminder plan through a narrow shared snapshot, not by becoming a second source of truth for product rules or persistence.
- Widget presentation should foreground the represented reminder or prompt. Do not spend live widget space repeating Owlory branding when the reminder content itself is the point.
- Widget taps and notification responses should carry a narrow deep-link URL that routes the user to the associated app item when the current stores can still resolve it. If the associated item no longer exists, fall back to the owning domain surface instead of inventing replacement state.
- Reserve Live Activities and Dynamic Island presence for active, user-initiated sessions with a clear start/end lifecycle and up-to-date glanceable status. Do not use them for passive planned work, general Continue items, or ambient app presence.
- Build diagnostics belong in `BuildInfoView` and bug-report flows, not as persistent primary chrome on core user surfaces.
- Use `Tools/verify-build-provenance.sh` for release, rollback, and TestFlight comparison work instead of hand-reading the Xcode project.
- Use `docs/workflows/performance-observability.md` before adding or reviewing telemetry, signposts, MetricKit handling, Instruments profiling claims, or performance gates.

## Verify

- `make test-domain DOMAIN=runtime`
- `make build-provenance`
- `make release-check` before archiving from a clean release or rollback checkout.
- `make architecture`
- Run an Xcode build when changing app or widget runtime wiring.
