# German Device Screenshot Proof

## Scope

Karoline provided chat attachment `[Image #1]` on 2026-05-18 as device evidence that the German Today surface is translated correctly on her device.

The screenshot binary is not committed in this repository because the image was provided through chat without a local workspace file path. This record preserves the observed evidence and its limits.

## Observed Evidence

Observed surface: iPhone device screenshot showing Owlory's Today tab in German.

Observed status/content:

- Status bar time: `5:38`
- Today content date: `Sonntag, 17. Mai 2026`
- Active tab: `Heute`

Observed German strings:

- `Heute`
- `Sonntag, 17. Mai 2026`
- `Was ist heute aktiv?`
- `Stabiler Tag. Vertrauen Sie dem Plan.`
- `Einchecken`
- `Zum Einchecken tippen`
- `Training`
- `Keine Sitzungen heute`
- `Sitzung hinzufügen`
- `Schreiben`
- `Keine aktiven Notizen`
- `Eine Notiz erfassen`
- `Karriere`
- `Noch keine Einträge`
- `Erfolg erfassen`
- Tab labels: `Heute`, `Training`, `Schreiben`, `Karriere`, `Haushalt`

## What This Supports

- German native/human review has device-observed visual evidence for the Today launch/dashboard surface.
- The observed Today surface is rendering German strings instead of English placeholders for the visible content listed above.
- The evidence is consistent with the German native-review intake recorded in commit `370743bf8510fbb2187369541a5920b3f5dd7682`.

## What This Does Not Prove

- TestFlight behavior or release-channel provenance.
- Full German app coverage.
- Full layout correctness across all German screens, font sizes, device sizes, or data states.
- A repo-managed screenshot artifact with hashable PNG provenance.
- Build identity, bundle version, or source cleanliness on Karoline's device.

## Follow-Up For Stronger Proof

To raise this beyond a chat-observed device screenshot, preserve the screenshot PNG in this directory and add a manifest entry with file name, SHA-256, byte size, dimensions, source build, device model, and capture date. For TestFlight proof, include Build Info screenshots that establish the installed build's committed source and build number before claiming `testflight-verified`.
