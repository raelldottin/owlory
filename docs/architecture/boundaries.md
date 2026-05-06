# Boundary Model

Owlory uses folder boundaries until physical Swift modules are introduced.

## Approved Flow

```text
Features / Widgets / App entry
  -> Core/Application
      -> Core/Domain
      -> Core/Persistence
      -> Core/Infrastructure

Core/Persistence -> Core/Domain
Core/Infrastructure -> Core/Domain
DesignSystem -> visual primitives only
```

The arrows point from caller to dependency. Outer layers may call inward. Inner layers must not know about outer layers.

## Layer Ownership

- `Core/Domain`: value types, enums, deterministic product rules, ranking/scoring logic, recurrence math, digest and pattern evaluation. No UI, persistence, filesystem, notification, speech, or app lifecycle code.
- `Core/Application`: observable stores, use-case orchestration, injected clocks/repositories, completion history, reminders, telemetry facade, and app runtime managers.
- `Core/Persistence`: repository protocols and storage implementations. It may know `Foundation` file APIs but not SwiftUI.
- `Core/Infrastructure`: Apple framework adapters such as audio capture, speech recognition, and Foundation Models.
- `Features`: SwiftUI screens and view-local formatting. Features may call stores and domain rules but should not own durable product decisions.
- `DesignSystem`: theme and reusable controls. Keep it small and visual; no product rules.
- `OwloryWidgets`: widget and future Live Activity presentation.

## Forbidden Directions

- `Core/Domain` must not import `SwiftUI`, `UIKit`, `AppKit`, `Combine`, `UserNotifications`, `AVFoundation`, `Speech`, or persistence adapters.
- `Core/Persistence` and `Core/Infrastructure` must not import SwiftUI feature views.
- `Features` must not write files directly, schedule notifications directly, or compute cross-domain product rules that belong in `Core/Domain`.
- Shared code must not become a dumping ground for feature-specific behavior.

## Localization Boundary

- `Core/Domain` returns semantic values such as enums, IDs, counts, dates, windows, and statuses. It must not own localized display copy.
- `Core/Application` may coordinate runtime-owned messages such as notification titles and bodies when it also owns the scheduling side effect.
- `Features` and UI-adjacent presentation helpers own screen-facing localized formatting, including counts, dates, display labels, and accessibility copy.
- Shared formatting helpers are allowed only when they are UI-adjacent, boring, and free of product-rule decisions.

For dynamic localization work, use [Localization Dynamic Formatting](../workflows/localization-dynamic-formatting.md) before moving or extracting copy.

## Known Exception

No framework-import exception is currently allowed in `Core/Domain`.
If a future active-session Live Activity needs shared `ActivityKit` attributes, document that exception explicitly and keep it isolated.

## Shared-Code Rule

Before adding shared code, answer yes to at least one:

- Two domains already duplicate the same rule.
- The rule is a durable product invariant.
- The rule needs deterministic tests independent of UI or persistence.

Otherwise keep the code domain-local.
