# App Localization HIG Multisurface Screenshot Harness

This directory contains scoped HIG surface screenshots captured by
`automation/smoke/capture_localized_surfaces.py` for the locales and
surfaces listed below.

## Locales

```text
en ar nl fr de it ja ko nb pt pt-BR ru es sv zh-Hans zh-Hant tr uk vi
```

## Surfaces

```text
today root-tab-train root-tab-write root-tab-career root-tab-home empty-state-today date-count-plural-today build-info
```

## Claim

These screenshots prove repo-managed simulator screenshot evidence for the
listed (locale, surface) pairs only. The HIG matrix consumes this manifest,
the native/fluent review records, source-level remediation evidence, and the
maintained Dynamic Type/accessibility regression to close the scoped
`hig-ui-reviewed` claim.

This proof was captured from a clean iPhone 17 / iOS 26.5 simulator build at
git commit `a7813a8`. The capture used screenshot-only accessibility fallback
because `idb` returned an application-only AX tree during this run.

Not claimed: translation quality by screenshots alone, physical-device
behavior, TestFlight behavior, or automated AX settled assertions for this
specific screenshot run.
