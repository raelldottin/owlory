#!/bin/sh
# Verify Owlory's first-class app localization resources.

set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RESOURCES="$ROOT/owlory_xcode/Owlory/Resources"
PROJECT="$ROOT/owlory_xcode/Owlory.xcodeproj/project.pbxproj"

export OWLORY_LOCALIZATION_RESOURCES="$RESOURCES"
export OWLORY_LOCALIZATION_PROJECT="$PROJECT"

python3 - <<'PY'
import json
import os
import re
import subprocess
import sys
from pathlib import Path

locales = [
    "en",
    "ar",
    "nl",
    "fr",
    "de",
    "it",
    "ja",
    "ko",
    "nb",
    "pt",
    "pt-BR",
    "ru",
    "es",
    "sv",
    "zh-Hans",
    "zh-Hant",
    "tr",
    "uk",
    "vi",
]

resources = Path(os.environ["OWLORY_LOCALIZATION_RESOURCES"])
project_path = Path(os.environ["OWLORY_LOCALIZATION_PROJECT"])
failures = []


def fail(message: str) -> None:
    failures.append(message)


def load_plist(path: Path, kind: str) -> dict:
    result = subprocess.run(
        ["plutil", "-convert", "json", "-o", "-", str(path)],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        fail(
            f"{path.relative_to(resources.parent.parent)} is not a valid {kind} file. "
            "Fix the property-list syntax before running localization validation again."
        )
        return {}
    return json.loads(result.stdout)


def load_strings(path: Path) -> dict[str, str]:
    return load_plist(path, ".strings")


def load_stringsdict(path: Path) -> dict:
    return load_plist(path, ".stringsdict")


if len(locales) != len(set(locales)):
    fail("localization locale list contains duplicates. Use one canonical Apple locale folder per language.")

if not resources.exists():
    fail("missing Owlory/Resources. Localized app resources must live beside Assets.xcassets.")

english_path = resources / "en.lproj" / "Localizable.strings"
english = load_strings(english_path) if english_path.exists() else {}
if not english_path.exists():
    fail("missing en.lproj/Localizable.strings. English is the source language for localization keys.")

english_keys = set(english)
if not english_keys and english_path.exists():
    fail("en.lproj/Localizable.strings has no keys. Add visible app-copy keys before adding placeholder locales.")

english_stringsdict_path = resources / "en.lproj" / "Localizable.stringsdict"
english_stringsdict = load_stringsdict(english_stringsdict_path) if english_stringsdict_path.exists() else {}
english_stringsdict_keys = set(english_stringsdict)
if english_stringsdict_path.exists() and not english_stringsdict_keys:
    fail("en.lproj/Localizable.stringsdict has no keys. Remove it or add plural/dynamic format keys.")

for locale in locales:
    locale_dir = resources / f"{locale}.lproj"
    strings_path = locale_dir / "Localizable.strings"
    if not locale_dir.exists():
        fail(
            f"missing {locale}.lproj. Add {locale}.lproj/Localizable.strings under Owlory/Resources "
            "or remove the locale from the approved target list."
        )
        continue
    if not strings_path.exists():
        fail(
            f"missing {locale}.lproj/Localizable.strings. Every approved locale must carry the same keys as en."
        )
        continue
    localized = load_strings(strings_path)
    localized_keys = set(localized)
    missing = sorted(english_keys - localized_keys)
    extra = sorted(localized_keys - english_keys)
    if missing:
        fail(
            f"{locale}.lproj/Localizable.strings is missing {len(missing)} key(s): {', '.join(missing[:5])}. "
            "Copy the English key into this locale, then translate the value when ready."
        )
    if extra:
        fail(
            f"{locale}.lproj/Localizable.strings has {len(extra)} extra key(s): {', '.join(extra[:5])}. "
            "Add the key to en.lproj first or remove the locale-only key."
        )

    stringsdict_path = locale_dir / "Localizable.stringsdict"
    if english_stringsdict_keys:
        if not stringsdict_path.exists():
            fail(
                f"missing {locale}.lproj/Localizable.stringsdict. Every approved locale must carry the same plural keys as en."
            )
            continue
        localized_stringsdict = load_stringsdict(stringsdict_path)
        localized_stringsdict_keys = set(localized_stringsdict)
        missing_plural = sorted(english_stringsdict_keys - localized_stringsdict_keys)
        extra_plural = sorted(localized_stringsdict_keys - english_stringsdict_keys)
        if missing_plural:
            fail(
                f"{locale}.lproj/Localizable.stringsdict is missing {len(missing_plural)} plural key(s): "
                f"{', '.join(missing_plural[:5])}. Copy the English plural key into this locale, then translate values when ready."
            )
        if extra_plural:
            fail(
                f"{locale}.lproj/Localizable.stringsdict has {len(extra_plural)} extra plural key(s): "
                f"{', '.join(extra_plural[:5])}. Add the key to en.lproj first or remove the locale-only key."
            )
    elif stringsdict_path.exists():
        fail(
            f"{locale}.lproj/Localizable.stringsdict exists but en.lproj/Localizable.stringsdict is missing. "
            "Add plural keys to English first or remove the locale-only stringsdict."
        )

present_locale_dirs = sorted(path.name[:-6] for path in resources.glob("*.lproj") if path.is_dir())
unexpected = [locale for locale in present_locale_dirs if locale not in locales]
if unexpected:
    fail(
        "unexpected localization folder(s): "
        + ", ".join(unexpected)
        + ". Use only the approved canonical Apple locale folders for this slice."
    )

if not project_path.exists():
    fail("missing Owlory.xcodeproj/project.pbxproj. Cannot verify localized resources are packaged correctly.")
else:
    project = project_path.read_text(encoding="utf-8")
    if "PBXVariantGroup" not in project or "Localizable.strings" not in project:
        fail(
            "Xcode project does not package Localizable.strings through a PBXVariantGroup. "
            "Add one variant group under Owlory/Resources and include that group in the app Resources phase."
        )
    if english_stringsdict_keys and (
        "Localizable.stringsdict" not in project or "Localizable.stringsdict in Resources" not in project
    ):
        fail(
            "Xcode project does not package Localizable.stringsdict through a PBXVariantGroup. "
            "Add one variant group under Owlory/Resources and include that group in the app Resources phase."
        )
    if re.search(r"/\* [^*]+\.lproj in Resources \*/", project):
        fail(
            "Xcode project copies a raw .lproj folder in Resources. "
            "Remove raw folder build files and package Localizable.strings through PBXVariantGroup instead."
        )
    if re.search(r"/\* (Localization|Resources) in Resources \*/", project):
        fail(
            "Xcode project copies a top-level Localization/Resources folder into the bundle. "
            "Only Assets.xcassets and the Localizable.strings variant group should be in the app Resources phase."
        )
    for locale in locales:
        region_token = f'"{locale}"' if "-" in locale else locale
        if region_token not in project:
            fail(
                f"Xcode knownRegions is missing {locale}. Add the canonical locale to the project knownRegions list."
            )

if failures:
    print("localization-parity: failed", file=sys.stderr)
    for message in failures:
        print(f"- {message}", file=sys.stderr)
    print(
        "\nWhy this exists: localization folders drift easily and Xcode can silently package raw folders "
        "instead of localized variant resources.\n"
        "Approved remediation: keep English as the source key set, mirror every key in every locale, "
        "and wire Localizable.strings through PBXVariantGroup in Owlory.xcodeproj.\n"
        "See docs/workflows/validation.md for the localization validation path.",
        file=sys.stderr,
    )
    sys.exit(1)

plural_suffix = f", {len(english_stringsdict_keys)} plural keys" if english_stringsdict_keys else ""
print(f"localization-parity: passed ({len(locales)} locales, {len(english_keys)} keys{plural_suffix})")
PY
