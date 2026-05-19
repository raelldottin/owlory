#!/usr/bin/env python3
"""Check drift between Owlory source strings and per-locale review return files.

Three drift dimensions per locale:

  1. Source keys missing from the return file (needs a review pass).
  2. Return-file entries no longer in source (review entry is stale).
  3. Source english_value changed since the review entry was recorded.

Reads:
  - owlory_xcode/Owlory/Resources/en.lproj/Localizable.strings
  - owlory_xcode/Owlory/Resources/en.lproj/Localizable.stringsdict
  - localization/review/<locale>/<locale>-review-return.json
    (German uses the legacy filename: localization/review/de/german-review-return.json)

Reporting-only by default. With --check, exits non-zero if any locale shows drift.
Use --json to emit a machine-readable report. The tool does NOT modify any review
return file or app resource.
"""
from __future__ import annotations

import argparse
import json
import plistlib
import re
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parent.parent
RESOURCES_DIR = REPO_ROOT / "owlory_xcode" / "Owlory" / "Resources"
REVIEW_DIR = REPO_ROOT / "localization" / "review"

NON_ENGLISH_LOCALES = [
    "ar", "nl", "fr", "de", "it", "ja", "ko", "nb",
    "pt", "pt-BR", "ru", "es", "sv", "zh-Hans", "zh-Hant",
    "tr", "uk", "vi",
]


def return_file_for(locale: str) -> Path:
    if locale == "de":
        return REVIEW_DIR / "de" / "german-review-return.json"
    return REVIEW_DIR / locale / f"{locale}-review-return.json"


def parse_strings_file(path: Path) -> dict[str, str]:
    """Parse a Localizable.strings file into a {key: value} mapping."""
    if not path.exists():
        return {}
    text = path.read_text(encoding="utf-8")
    pairs: dict[str, str] = {}
    pattern = re.compile(
        r'^\s*"((?:[^"\\]|\\.)*)"\s*=\s*"((?:[^"\\]|\\.)*)"\s*;',
        re.MULTILINE,
    )
    for match in pattern.finditer(text):
        key = _unescape(match.group(1))
        value = _unescape(match.group(2))
        pairs[key] = value
    return pairs


def _unescape(s: str) -> str:
    return s.replace('\\"', '"').replace("\\\\", "\\").replace("\\n", "\n")


class StringsdictParseError(RuntimeError):
    """Raised when a .stringsdict file cannot be parsed by any available backend."""


STRINGSDICT_METADATA_KEYS = {
    "NSStringLocalizedFormatKey",
    "NSStringFormatSpecTypeKey",
    "NSStringFormatValueTypeKey",
}


def parse_stringsdict_keys(path: Path) -> set[str]:
    """Return the set of top-level keys defined in a Localizable.stringsdict file.

    Tries Python's standard plistlib first (works for XML and binary plist; no shellout).
    Falls back to macOS plutil for files in the NeXTSTEP strings-dict format that
    plistlib cannot parse. Raises StringsdictParseError if both backends fail, so
    drift reports cannot silently treat unparseable stringsdict files as 'no keys'.
    """
    if not path.exists():
        return set()
    data = _load_plist(path)
    if not isinstance(data, dict):
        raise StringsdictParseError(
            f"{path} parsed but root is not a dict (got {type(data).__name__})."
        )
    return set(data.keys())


def parse_stringsdict_entries(path: Path) -> dict[tuple[str, str, str], str]:
    """Return {(key, plural_variable, plural_category): english_value}.

    Skips NSStringLocalizedFormatKey and NSStringFormat*TypeKey metadata; those are
    not translatable english values per row. Returns an empty mapping when the file
    is missing. Propagates StringsdictParseError if the file exists but cannot be
    parsed by either plistlib or plutil.
    """
    if not path.exists():
        return {}
    data = _load_plist(path)
    if not isinstance(data, dict):
        raise StringsdictParseError(
            f"{path} parsed but root is not a dict (got {type(data).__name__})."
        )
    out: dict[tuple[str, str, str], str] = {}
    for key, value in data.items():
        if not isinstance(key, str) or not isinstance(value, dict):
            continue
        for plural_variable, plural_dict in value.items():
            if not isinstance(plural_variable, str) or plural_variable in STRINGSDICT_METADATA_KEYS:
                continue
            if not isinstance(plural_dict, dict):
                continue
            for plural_category, english in plural_dict.items():
                if not isinstance(plural_category, str):
                    continue
                if plural_category in STRINGSDICT_METADATA_KEYS:
                    continue
                if isinstance(english, str):
                    out[(key, plural_variable, plural_category)] = english
    return out


def _load_plist(path: Path) -> Any:
    # 1. Python plistlib: handles XML and binary plist formats without shellout.
    try:
        with path.open("rb") as handle:
            return plistlib.load(handle)
    except plistlib.InvalidFileException:
        plistlib_error = "plistlib could not parse the file as XML or binary plist"
    except Exception as exc:  # pragma: no cover - defensive
        plistlib_error = f"plistlib raised {type(exc).__name__}: {exc}"

    # 2. macOS plutil: handles the older NeXTSTEP strings-dict format too.
    plutil = shutil.which("plutil")
    if plutil is None:
        raise StringsdictParseError(
            f"{path} could not be parsed: {plistlib_error}, and plutil is not on PATH. "
            "Either convert the file to XML plist format or install macOS plutil."
        )
    result = subprocess.run(
        [plutil, "-convert", "json", "-o", "-", "--", str(path)],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        raise StringsdictParseError(
            f"{path} could not be parsed: {plistlib_error}, and plutil exited "
            f"{result.returncode}: {result.stderr.strip()}"
        )
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        raise StringsdictParseError(
            f"{path} could not be parsed: plutil JSON output was invalid: {exc}"
        ) from exc


def load_return_file(path: Path) -> dict[str, Any] | None:
    if not path.exists():
        return None
    return json.loads(path.read_text(encoding="utf-8"))


def _relative_to_repo(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def analyze_locale(
    locale: str,
    source_strings: dict[str, str],
    source_stringsdict_entries: dict[tuple[str, str, str], str],
) -> dict[str, Any]:
    path = return_file_for(locale)
    data = load_return_file(path)
    if data is None:
        return {
            "locale": locale,
            "return_file": _relative_to_repo(path),
            "status": "missing-return-file",
            "drift_count": -1,
        }

    resources = data.get("resources", [])
    return_strings_keys: set[str] = set()
    return_english_by_key: dict[str, str] = {}
    return_stringsdict_entries: dict[tuple[str, str, str], str] = {}
    for entry in resources:
        if not isinstance(entry, dict):
            continue
        rt = entry.get("resource_type")
        key = entry.get("key")
        if not isinstance(key, str):
            continue
        if rt == "strings":
            return_strings_keys.add(key)
            ev = entry.get("english_value")
            if isinstance(ev, str):
                return_english_by_key[key] = ev
        elif rt == "stringsdict":
            pv = entry.get("plural_variable")
            pc = entry.get("plural_category")
            ev = entry.get("english_value")
            if (
                isinstance(pv, str)
                and isinstance(pc, str)
                and isinstance(ev, str)
            ):
                return_stringsdict_entries[(key, pv, pc)] = ev

    source_strings_keys = set(source_strings.keys())
    source_stringsdict_keys = {key for (key, _, _) in source_stringsdict_entries}
    return_stringsdict_keys = {key for (key, _, _) in return_stringsdict_entries}

    missing_strings = sorted(source_strings_keys - return_strings_keys)
    stale_strings = sorted(return_strings_keys - source_strings_keys)
    missing_stringsdict_keys = sorted(source_stringsdict_keys - return_stringsdict_keys)
    stale_stringsdict_keys = sorted(return_stringsdict_keys - source_stringsdict_keys)

    source_tuples = set(source_stringsdict_entries.keys())
    return_tuples = set(return_stringsdict_entries.keys())
    missing_stringsdict_tuples = sorted(source_tuples - return_tuples)
    stale_stringsdict_tuples = sorted(return_tuples - source_tuples)

    changed_english: list[dict[str, str]] = []
    for key in sorted(source_strings_keys & return_strings_keys):
        src = source_strings.get(key)
        ret = return_english_by_key.get(key)
        if src is not None and ret is not None and src != ret:
            changed_english.append({
                "key": key,
                "source_value": src,
                "return_file_value": ret,
            })

    changed_stringsdict_english: list[dict[str, Any]] = []
    for tuple_key in sorted(source_tuples & return_tuples):
        src = source_stringsdict_entries.get(tuple_key)
        ret = return_stringsdict_entries.get(tuple_key)
        if src is not None and ret is not None and src != ret:
            key, plural_variable, plural_category = tuple_key
            changed_stringsdict_english.append({
                "key": key,
                "plural_variable": plural_variable,
                "plural_category": plural_category,
                "source_value": src,
                "return_file_value": ret,
            })

    drift_count = (
        len(missing_strings)
        + len(stale_strings)
        + len(missing_stringsdict_keys)
        + len(stale_stringsdict_keys)
        + len(missing_stringsdict_tuples)
        + len(stale_stringsdict_tuples)
        + len(changed_english)
        + len(changed_stringsdict_english)
    )

    return {
        "locale": locale,
        "return_file": _relative_to_repo(path),
        "status": "ok" if drift_count == 0 else "drift",
        "drift_count": drift_count,
        "missing_strings_keys": missing_strings,
        "stale_strings_keys": stale_strings,
        "missing_stringsdict_keys": missing_stringsdict_keys,
        "stale_stringsdict_keys": stale_stringsdict_keys,
        "missing_stringsdict_tuples": [list(t) for t in missing_stringsdict_tuples],
        "stale_stringsdict_tuples": [list(t) for t in stale_stringsdict_tuples],
        "changed_english_values": changed_english,
        "changed_stringsdict_english_values": changed_stringsdict_english,
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check",
        action="store_true",
        help="Exit non-zero when any locale shows drift. Default is reporting-only.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit a machine-readable JSON report instead of human text.",
    )
    parser.add_argument(
        "--locales",
        nargs="*",
        default=NON_ENGLISH_LOCALES,
        help="Locales to inspect. Defaults to all 18 non-English locales.",
    )
    args = parser.parse_args(argv)

    en_strings_path = RESOURCES_DIR / "en.lproj" / "Localizable.strings"
    en_stringsdict_path = RESOURCES_DIR / "en.lproj" / "Localizable.stringsdict"
    source_strings = parse_strings_file(en_strings_path)
    source_stringsdict_entries = parse_stringsdict_entries(en_stringsdict_path)

    per_locale = [
        analyze_locale(locale, source_strings, source_stringsdict_entries)
        for locale in args.locales
    ]

    total_drift = sum(r["drift_count"] for r in per_locale if r["drift_count"] > 0)
    locales_with_drift = [r["locale"] for r in per_locale if r["drift_count"] > 0]

    source_stringsdict_keys_count = len({key for (key, _, _) in source_stringsdict_entries})
    report = {
        "schema_version": 1,
        "source": {
            "strings_path": _relative_to_repo(en_strings_path),
            "strings_keys_count": len(source_strings),
            "stringsdict_path": _relative_to_repo(en_stringsdict_path),
            "stringsdict_keys_count": source_stringsdict_keys_count,
            "stringsdict_tuples_count": len(source_stringsdict_entries),
        },
        "locales_inspected": len(per_locale),
        "locales_with_drift": locales_with_drift,
        "total_drift_count": total_drift,
        "per_locale": per_locale,
    }

    if args.json:
        print(json.dumps(report, indent=2, ensure_ascii=False))
    else:
        print_human(report)

    if args.check and total_drift > 0:
        return 1
    return 0


def print_human(report: dict[str, Any]) -> None:
    src = report["source"]
    print(
        f"localization-review-drift-check: {src['strings_keys_count']} strings keys + "
        f"{src['stringsdict_keys_count']} stringsdict keys "
        f"({src.get('stringsdict_tuples_count', 0)} plural tuples) "
        f"in source ({src['strings_path']})"
    )
    print(
        f"  locales inspected: {report['locales_inspected']}; "
        f"locales with drift: {len(report['locales_with_drift'])}; "
        f"total drift count: {report['total_drift_count']}"
    )
    if report["total_drift_count"] == 0:
        print("  result: no drift")
        return
    for locale_report in report["per_locale"]:
        if locale_report["drift_count"] <= 0:
            continue
        print(
            f"  [{locale_report['locale']:<8}] drift={locale_report['drift_count']} "
            f"({locale_report['return_file']})"
        )
        if locale_report.get("missing_strings_keys"):
            print(
                f"    missing strings keys: {len(locale_report['missing_strings_keys'])} "
                f"(example: {locale_report['missing_strings_keys'][:3]})"
            )
        if locale_report.get("stale_strings_keys"):
            print(
                f"    stale strings keys: {len(locale_report['stale_strings_keys'])} "
                f"(example: {locale_report['stale_strings_keys'][:3]})"
            )
        if locale_report.get("missing_stringsdict_keys"):
            print(
                f"    missing stringsdict keys: {len(locale_report['missing_stringsdict_keys'])} "
                f"(example: {locale_report['missing_stringsdict_keys'][:3]})"
            )
        if locale_report.get("stale_stringsdict_keys"):
            print(
                f"    stale stringsdict keys: {len(locale_report['stale_stringsdict_keys'])} "
                f"(example: {locale_report['stale_stringsdict_keys'][:3]})"
            )
        if locale_report.get("missing_stringsdict_tuples"):
            print(
                f"    missing stringsdict plural tuples: {len(locale_report['missing_stringsdict_tuples'])} "
                f"(example: {locale_report['missing_stringsdict_tuples'][:3]})"
            )
        if locale_report.get("stale_stringsdict_tuples"):
            print(
                f"    stale stringsdict plural tuples: {len(locale_report['stale_stringsdict_tuples'])} "
                f"(example: {locale_report['stale_stringsdict_tuples'][:3]})"
            )
        if locale_report.get("changed_english_values"):
            print(
                f"    changed strings english_value: {len(locale_report['changed_english_values'])} "
                f"(example key: {locale_report['changed_english_values'][0]['key']!r})"
            )
        if locale_report.get("changed_stringsdict_english_values"):
            example = locale_report["changed_stringsdict_english_values"][0]
            print(
                f"    changed stringsdict english_value: {len(locale_report['changed_stringsdict_english_values'])} "
                f"(example: ({example['key']!r}, {example['plural_variable']!r}, {example['plural_category']!r}))"
            )


if __name__ == "__main__":
    sys.exit(main())
