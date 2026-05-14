# App Localization All-Locale Smoke Proof

Slice: `app-localization-all-locale-smoke`

This proof records one running-app smoke result for every supported Owlory locale:

```text
en ar nl fr de it ja ko nb pt pt-BR ru es sv zh-Hans zh-Hant tr uk vi
```

Each JSON result was captured from a clean, mirrored `main` checkout before the proof artifacts were copied into the repository. Each locale reached `proof_level: running-app-smoke`, reported `repo.dirty: no`, launched with `-AppleLanguages` and `-AppleLocale`, and found both packaged localization resources:

```text
Localizable.strings
Localizable.stringsdict
```

## What This Proves

- The Debug simulator app builds, installs, and launches under all 19 supported locale launch arguments.
- The built app bundle contains matching `<locale>.lproj/Localizable.strings` resources for each supported locale.
- The built app bundle contains matching `<locale>.lproj/Localizable.stringsdict` resources for each supported locale.
- Full supported-locale launch/resource smoke is now stronger than the earlier representative-only proof set.

## What This Does Not Prove

- Translation quality.
- Native or fluent review.
- Full layout correctness.
- Screenshot-verified proof.
- Physical-device behavior.
- TestFlight behavior.

Non-English values remain English placeholders unless a later reviewed-translation intake slice replaces them with reviewer/status metadata.

## Manifest

`manifest.json` records each JSON proof file, SHA-256 hash, byte size, status, proof level, requested locale, packaged resource names, and temporary screenshot path emitted by the smoke runner.
