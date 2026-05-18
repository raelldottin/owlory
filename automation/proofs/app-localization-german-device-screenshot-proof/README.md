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

## Observed TestFlight Build Info

Karoline later provided a second chat screenshot on 2026-05-18 as TestFlight Build Info evidence. The screenshot was not available as a committed binary artifact, but the visible fields showed:

- Version: `0.2.0`
- Build: `20260517151819`
- Commit: `f6325f3c28e9`
- Full commit: `f6325f3c28e9e9263eebbe76a3bbba777ff6e615`
- Branch: `main`

Local verification confirms commit `f6325f3c28e9e9263eebbe76a3bbba777ff6e615` exists and that its committed Xcode project reports `MARKETING_VERSION = 0.2.0` and `CURRENT_PROJECT_VERSION = 20260517151819`.

This supports only `build-info-observed` provenance for the reported TestFlight app version. It does not raise this proof to `testflight-verified` because the Build Info screenshot file, hash, dimensions, complete gate fields, and paired TestFlight surface artifacts are not committed.

## What This Does Not Prove

- TestFlight behavior beyond the observed Build Info version/build/commit fields.
- Full German app coverage.
- Full layout correctness across all German screens, font sizes, device sizes, or data states.
- A repo-managed screenshot artifact with hashable PNG provenance.
- Complete Build Info gate provenance, source cleanliness, or releaseability on Karoline's device.

## Follow-Up For Stronger Proof

To raise this beyond a chat-observed device screenshot, preserve the screenshot PNG in this directory and add a manifest entry with file name, SHA-256, byte size, dimensions, source build, device model, and capture date. For TestFlight proof, include Build Info screenshots that establish the installed build's committed source and build number before claiming `testflight-verified`.
