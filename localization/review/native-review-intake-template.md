# Native Review Intake Template

Copy this template into the locale review folder or the proof bundle for each native-language review. Do not mark a locale `native-reviewed` from chat approval alone.

## Locale And Scope

- Locale:
- Language:
- Review date:
- Reviewer basis: native speaker / fluent speaker / vendor / internal product reviewer
- Reviewer identifier: name, vendor, or internal ID
- Scope: full locale / key subset / surface subset
- Return file:
- Review packet:
- Entry count reviewed:
- Exclusions:

## Source Baseline

- Repository commit:
- App version:
- Build number:
- Branch:
- `make build-provenance` result:
- Source changes after this baseline that affect localized runtime values:

## Installed App / TestFlight Gate

- Channel: local debug / ad hoc / TestFlight / App Store
- Device:
- OS version:
- Build Info screenshot path:
- Version shown:
- Build shown:
- Commit shown:
- Full commit shown:
- Branch shown:
- Git/source status shown:
- Configuration shown:
- Gate result: pass / fail / build-info-observed-only
- Gate notes:

## Packet Review

- Packet reviewed: yes / no
- Terminology reviewed: yes / no
- Plural forms reviewed: yes / no / not applicable
- Placeholder and format specifiers checked: yes / no
- Terms intentionally kept in English:
- Product decisions needed:

## Device Surface Review

List each reviewed surface and attach screenshot paths when available.

| Surface | Result | Screenshot path | Notes |
| --- | --- | --- | --- |
| Build Info |  |  |  |
| Today |  |  |  |
| Training |  |  |  |
| Schreiben / Write |  |  |  |
| Karriere / Career |  |  |  |
| Haushalt / Home |  |  |  |

## Corrections

| Key | Decision | Corrected value | Notes |
| --- | --- | --- | --- |
|  | accepted / corrected / keep English / product decision / reject |  |  |

## Signoff

Use a statement equivalent to:

```text
I reviewed the scoped Owlory <locale> translations against app version <version> build <build> from commit <commit>. I accept the entries marked native-reviewed for this scope, with corrections and unresolved items listed above.
```

Reviewer:

Date:

## Intake Validation

The intake slice must record:

- `python3 Tools/localization-review-status.py`
- `make architecture`
- `make localization-check`
- `./Tools/validate.sh localization`
- `make automation-check`
- `git diff --check`
