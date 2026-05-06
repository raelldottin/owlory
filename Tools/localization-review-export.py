#!/usr/bin/env python3
"""Export Owlory localization resources for translation review.

This is intentionally read-only with respect to app resources. It creates
reviewer-facing CSV/JSON packets from the current English source strings,
locale placeholder values, and plural resources.
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import subprocess
import sys
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any


APPROVED_LOCALES = [
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

SOURCE_LOCALE = "en"
PLURAL_CATEGORY_ORDER = ["zero", "one", "two", "few", "many", "other"]
PLIST_META_KEYS = {
    "NSStringLocalizedFormatKey",
    "NSStringFormatSpecTypeKey",
    "NSStringFormatValueTypeKey",
}


def repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def fail(message: str) -> None:
    print("localization-review-export: failed", file=sys.stderr)
    print(f"- {message}", file=sys.stderr)
    print(
        "\nWhy this exists: translation review needs a stable packet that separates "
        "resource readiness from translation quality.\n"
        "Approved remediation: keep English as the source key set, run "
        "`make localization-check`, then regenerate with "
        "`python3 Tools/localization-review-export.py --output-dir localization/review`.\n"
        "See docs/workflows/localization-translation-quality.md.",
        file=sys.stderr,
    )
    sys.exit(1)


def load_plist(path: Path) -> dict[str, Any]:
    result = subprocess.run(
        ["plutil", "-convert", "json", "-o", "-", str(path)],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        fail(f"{path} is not valid plist-backed localization syntax: {result.stderr.strip()}")
    try:
        data = json.loads(result.stdout)
    except json.JSONDecodeError as error:
        fail(f"{path} could not be parsed after plutil conversion: {error}")
    if not isinstance(data, dict):
        fail(f"{path} did not parse to a dictionary.")
    return data


def decode_strings_literal(value: str) -> str:
    try:
        return bytes(value, "utf-8").decode("unicode_escape")
    except UnicodeDecodeError:
        return value


def extract_key_comments(path: Path) -> dict[str, str]:
    """Best-effort extraction of comments immediately preceding .strings keys."""
    if not path.exists():
        return {}

    comments: dict[str, str] = {}
    pending_comment = ""
    block_comment_pattern = re.compile(r"/\*\s*(.*?)\s*\*/", re.DOTALL)
    key_pattern = re.compile(r'"((?:\\.|[^"\\])*)"\s*=')
    buffer = ""

    for line in path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not stripped:
            if not buffer:
                pending_comment = ""
            continue

        if stripped.startswith("/*") or buffer:
            buffer = f"{buffer}\n{line}" if buffer else line
            match = block_comment_pattern.search(buffer)
            if match:
                pending_comment = " ".join(match.group(1).split())
                buffer = ""
            continue

        key_match = key_pattern.search(line)
        if key_match:
            key = decode_strings_literal(key_match.group(1))
            if pending_comment:
                comments[key] = pending_comment
                pending_comment = ""
            continue

        pending_comment = ""

    return comments


def resource_paths(resources: Path, locale: str) -> tuple[Path, Path]:
    locale_dir = resources / f"{locale}.lproj"
    return locale_dir / "Localizable.strings", locale_dir / "Localizable.stringsdict"


def verify_locale_files(resources: Path) -> None:
    missing = []
    for locale in APPROVED_LOCALES:
        strings_path, stringsdict_path = resource_paths(resources, locale)
        if not strings_path.exists():
            missing.append(str(strings_path.relative_to(repo_root())))
        if not stringsdict_path.exists():
            missing.append(str(stringsdict_path.relative_to(repo_root())))
    if missing:
        fail(
            "Missing localization resource(s): "
            + ", ".join(missing[:8])
            + ". Run `make localization-check` for the full parity report."
        )


def status_for(locale: str, current_value: str, english_value: str) -> str:
    if locale == SOURCE_LOCALE:
        return "english-source"
    if current_value == english_value:
        return "english-placeholder"
    return "draft-translation"


def ordered_plural_categories(variable_payload: dict[str, Any]) -> list[str]:
    categories = [
        category
        for category in PLURAL_CATEGORY_ORDER
        if category in variable_payload and isinstance(variable_payload[category], str)
    ]
    extras = sorted(
        key
        for key, value in variable_payload.items()
        if key not in PLIST_META_KEYS and key not in categories and isinstance(value, str)
    )
    return categories + extras


def plural_variables(payload: dict[str, Any]) -> list[str]:
    return sorted(
        key
        for key, value in payload.items()
        if key not in PLIST_META_KEYS and isinstance(value, dict)
    )


def build_records(resources: Path) -> tuple[list[dict[str, Any]], list[dict[str, str]]]:
    verify_locale_files(resources)

    strings_by_locale: dict[str, dict[str, str]] = {}
    stringsdict_by_locale: dict[str, dict[str, Any]] = {}
    comments_by_key = extract_key_comments(resource_paths(resources, SOURCE_LOCALE)[0])

    for locale in APPROVED_LOCALES:
        strings_path, stringsdict_path = resource_paths(resources, locale)
        strings_by_locale[locale] = load_plist(strings_path)
        stringsdict_by_locale[locale] = load_plist(stringsdict_path)

    english_strings = strings_by_locale[SOURCE_LOCALE]
    english_stringsdict = stringsdict_by_locale[SOURCE_LOCALE]

    english_string_keys = set(english_strings)
    english_plural_keys = set(english_stringsdict)
    for locale in APPROVED_LOCALES:
        localized_string_keys = set(strings_by_locale[locale])
        localized_plural_keys = set(stringsdict_by_locale[locale])
        if localized_string_keys != english_string_keys:
            missing = sorted(english_string_keys - localized_string_keys)
            extra = sorted(localized_string_keys - english_string_keys)
            fail(
                f"{locale}.lproj/Localizable.strings does not match English keys. "
                f"Missing: {missing[:5]}; extra: {extra[:5]}."
            )
        if localized_plural_keys != english_plural_keys:
            missing = sorted(english_plural_keys - localized_plural_keys)
            extra = sorted(localized_plural_keys - english_plural_keys)
            fail(
                f"{locale}.lproj/Localizable.stringsdict does not match English plural keys. "
                f"Missing: {missing[:5]}; extra: {extra[:5]}."
            )

    structured_resources: list[dict[str, Any]] = []
    csv_rows: list[dict[str, str]] = []

    for key in sorted(english_strings):
        english_value = english_strings[key]
        locales = {}
        for locale in APPROVED_LOCALES:
            current_value = strings_by_locale[locale][key]
            status = status_for(locale, current_value, english_value)
            locales[locale] = {
                "current_value": current_value,
                "status": status,
            }
            csv_rows.append(
                {
                    "resource_type": "strings",
                    "key": key,
                    "plural_variable": "",
                    "plural_category": "",
                    "comment": comments_by_key.get(key, ""),
                    "english_value": english_value,
                    "locale": locale,
                    "current_value": current_value,
                    "status": status,
                    "reviewer_notes": "",
                }
            )
        structured_resources.append(
            {
                "resource_type": "strings",
                "key": key,
                "comment": comments_by_key.get(key, ""),
                "english_value": english_value,
                "locales": locales,
            }
        )

    for key in sorted(english_stringsdict):
        english_payload = english_stringsdict[key]
        if not isinstance(english_payload, dict):
            fail(f"English stringsdict key {key} is not a dictionary.")
        variables = plural_variables(english_payload)
        if not variables:
            fail(f"English stringsdict key {key} has no plural variable payload.")

        for variable in variables:
            english_variable_payload = english_payload[variable]
            categories = ordered_plural_categories(english_variable_payload)
            if not categories:
                fail(f"English stringsdict key {key}/{variable} has no plural categories.")

            for category in categories:
                english_value = english_variable_payload[category]
                locales = {}
                for locale in APPROVED_LOCALES:
                    localized_payload = stringsdict_by_locale[locale][key]
                    if not isinstance(localized_payload, dict) or variable not in localized_payload:
                        fail(f"{locale}.lproj stringsdict key {key} is missing variable {variable}.")
                    localized_variable_payload = localized_payload[variable]
                    if not isinstance(localized_variable_payload, dict) or category not in localized_variable_payload:
                        fail(f"{locale}.lproj stringsdict key {key}/{variable} is missing category {category}.")
                    current_value = localized_variable_payload[category]
                    if not isinstance(current_value, str):
                        fail(f"{locale}.lproj stringsdict key {key}/{variable}/{category} is not a string.")
                    status = status_for(locale, current_value, english_value)
                    locales[locale] = {
                        "current_value": current_value,
                        "status": status,
                    }
                    csv_rows.append(
                        {
                            "resource_type": "stringsdict",
                            "key": key,
                            "plural_variable": variable,
                            "plural_category": category,
                            "comment": "",
                            "english_value": english_value,
                            "locale": locale,
                            "current_value": current_value,
                            "status": status,
                            "reviewer_notes": "",
                        }
                    )
                structured_resources.append(
                    {
                        "resource_type": "stringsdict",
                        "key": key,
                        "plural_variable": variable,
                        "plural_category": category,
                        "comment": "",
                        "english_value": english_value,
                        "locales": locales,
                    }
                )

    return structured_resources, csv_rows


def status_summary(csv_rows: list[dict[str, str]]) -> dict[str, dict[str, int]]:
    summary: dict[str, Counter[str]] = defaultdict(Counter)
    for row in csv_rows:
        summary[row["locale"]][row["status"]] += 1
    return {locale: dict(summary[locale]) for locale in APPROVED_LOCALES}


def write_csv(path: Path, rows: list[dict[str, str]]) -> None:
    def csv_safe(value: str) -> str:
        return value.replace("\r", "\\r").replace("\n", "\\n")

    columns = [
        "resource_type",
        "key",
        "plural_variable",
        "plural_category",
        "comment",
        "english_value",
        "locale",
        "current_value",
        "status",
        "reviewer_notes",
    ]
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=columns, lineterminator="\n")
        writer.writeheader()
        for row in rows:
            writer.writerow({column: csv_safe(row[column]) for column in columns})


def write_json(path: Path, resources: list[dict[str, Any]], rows: list[dict[str, str]]) -> None:
    strings_count = sum(1 for resource in resources if resource["resource_type"] == "strings")
    plural_entry_count = sum(1 for resource in resources if resource["resource_type"] == "stringsdict")
    packet = {
        "schema_version": 1,
        "generated_by": "Tools/localization-review-export.py",
        "source_locale": SOURCE_LOCALE,
        "approved_locales": APPROVED_LOCALES,
        "status_labels": {
            "english-source": "English source key/value reviewed as product copy.",
            "english-placeholder": "Non-English value intentionally copied from English.",
            "draft-translation": "Candidate translated value exists but has not been native-reviewed.",
        },
        "summary": {
            "locale_count": len(APPROVED_LOCALES),
            "strings_key_count": strings_count,
            "plural_review_entry_count": plural_entry_count,
            "csv_row_count": len(rows),
            "status_by_locale": status_summary(rows),
        },
        "resources": resources,
    }
    path.write_text(json.dumps(packet, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def write_readme(path: Path, csv_path: Path, json_path: Path) -> None:
    path.write_text(
        "\n".join(
            [
                "# Localization Review Export",
                "",
                "This packet exports Owlory's current localization resources for translation review. It is reviewer input, not a translation-quality claim.",
                "",
                "Generated with:",
                "",
                "```bash",
                "python3 Tools/localization-review-export.py --output-dir localization/review",
                "```",
                "",
                "Files:",
                "",
                f"- `{csv_path.name}` - reviewer-friendly flat rows for `Localizable.strings` and `Localizable.stringsdict` values. Newlines are escaped as `\\n` so each review row stays on one CSV line.",
                f"- `{json_path.name}` - structured packet preserving locale values, status labels, and summary counts.",
                "",
                "Status labels:",
                "",
                "- `english-source`: English source value.",
                "- `english-placeholder`: non-English value currently matches English and still needs translation review.",
                "- `draft-translation`: non-English value differs from English but has not been accepted by a native or fluent reviewer.",
                "",
                "Use `docs/workflows/localization-translation-quality.md` before replacing placeholder values. Do not claim native review from this export alone.",
                "",
            ]
        ),
        encoding="utf-8",
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Export Owlory localization resources for translation review.")
    parser.add_argument(
        "--output-dir",
        default="localization/review",
        help="Directory for translation-review-export.csv/json and README.md.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    root = repo_root()
    resources_dir = root / "owlory_xcode" / "Owlory" / "Resources"
    if not resources_dir.exists():
        fail(f"Missing localization resources directory: {resources_dir}")

    output_dir = (root / args.output_dir).resolve()
    try:
        output_dir.relative_to(root)
    except ValueError:
        fail("Output directory must stay inside the repository.")

    output_dir.mkdir(parents=True, exist_ok=True)
    csv_path = output_dir / "translation-review-export.csv"
    json_path = output_dir / "translation-review-export.json"
    readme_path = output_dir / "README.md"

    resources, rows = build_records(resources_dir)
    write_csv(csv_path, rows)
    write_json(json_path, resources, rows)
    write_readme(readme_path, csv_path, json_path)

    summary = status_summary(rows)
    non_english_placeholder_rows = sum(
        counts.get("english-placeholder", 0)
        for locale, counts in summary.items()
        if locale != SOURCE_LOCALE
    )
    print(
        "localization-review-export: wrote "
        f"{len(rows)} CSV rows, {len(resources)} structured review entries, "
        f"{non_english_placeholder_rows} non-English placeholder rows"
    )
    print(f"- {csv_path.relative_to(root)}")
    print(f"- {json_path.relative_to(root)}")
    print(f"- {readme_path.relative_to(root)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
