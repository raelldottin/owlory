#!/usr/bin/env python3
"""Regenerate the German-first review packet from current `de.lproj` resources.

Mirrors the schema of the original (hand-built) `localization/review/de/german-
review-packet.{csv,json}` so reviewers see what is actually in the resources
right now, including the LLM-drafted German values ingested on 2026-05-15.

The packet is reviewer INPUT. Empty reviewed_value / review_status fields are
intentional: a real native or fluent German reviewer fills them. The current
values of de.lproj appear under `current_value` with the matching
`current_status` (`english-placeholder` when identical to English; `draft-
translation` when the German value differs from English). The packet does NOT
ingest values back into resources and does NOT claim native review.

Usage:

    python3 Tools/german-review-packet-regenerate.py

Reads from owlory_xcode/Owlory/Resources/{en,de}.lproj/ and writes to
localization/review/de/german-review-packet.{csv,json}.
"""
from __future__ import annotations

import csv
import json
import subprocess
import sys
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[1]
EN_DIR = REPO_ROOT / "owlory_xcode/Owlory/Resources/en.lproj"
DE_DIR = REPO_ROOT / "owlory_xcode/Owlory/Resources/de.lproj"
OUT_DIR = REPO_ROOT / "localization/review/de"
OUT_JSON = OUT_DIR / "german-review-packet.json"
OUT_CSV = OUT_DIR / "german-review-packet.csv"

PLURAL_CATEGORY_ORDER = ["zero", "one", "two", "few", "many", "other"]
PLIST_META_KEYS = {
    "NSStringLocalizedFormatKey",
    "NSStringFormatSpecTypeKey",
    "NSStringFormatValueTypeKey",
}

REVIEW_STATUS_VALUES = {
    "native-reviewed": "Native or fluent reviewer accepts reviewed_de_value for this key.",
    "needs-product-decision": "Reviewer needs product input before accepting a translation.",
    "keep-english-term": "Reviewer intentionally keeps the English source term for German.",
    "needs-layout-check": "Translation may be correct but needs UI screenshot/layout review.",
    "reject": "Reviewer rejects the candidate or current value.",
}


def load_plist(path: Path) -> dict[str, Any]:
    result = subprocess.run(
        ["plutil", "-convert", "json", "-o", "-", str(path)],
        check=True,
        capture_output=True,
        text=True,
    )
    return json.loads(result.stdout)


def status_for(current_value: str, english_value: str) -> str:
    return "english-placeholder" if current_value == english_value else "draft-translation"


def ordered_categories(payload: dict[str, Any]) -> list[str]:
    primary = [c for c in PLURAL_CATEGORY_ORDER if c in payload and isinstance(payload[c], str)]
    extras = sorted(
        k for k, v in payload.items()
        if k not in PLIST_META_KEYS and k not in primary and isinstance(v, str)
    )
    return primary + extras


def plural_variables(payload: dict[str, Any]) -> list[str]:
    return sorted(
        k for k, v in payload.items()
        if k not in PLIST_META_KEYS and isinstance(v, dict)
    )


def build_entries() -> list[dict[str, Any]]:
    en_strings = load_plist(EN_DIR / "Localizable.strings")
    de_strings = load_plist(DE_DIR / "Localizable.strings")
    en_sdict = load_plist(EN_DIR / "Localizable.stringsdict")
    de_sdict = load_plist(DE_DIR / "Localizable.stringsdict")

    if set(en_strings) != set(de_strings):
        raise SystemExit("en/de Localizable.strings key parity mismatch.")
    if set(en_sdict) != set(de_sdict):
        raise SystemExit("en/de Localizable.stringsdict key parity mismatch.")

    entries: list[dict[str, Any]] = []

    for key in sorted(en_strings):
        english = en_strings[key]
        current = de_strings[key]
        entries.append({
            "comment": "",
            "current_status": status_for(current, english),
            "current_value": current,
            "english_value": english,
            "key": key,
            "locale": "de",
            "resource_type": "strings",
            "review_date": "",
            "review_status": "",
            "reviewed_value": "",
            "reviewer": "",
            "reviewer_notes": "",
        })

    for key in sorted(en_sdict):
        en_payload = en_sdict[key]
        if not isinstance(en_payload, dict):
            continue
        for variable in plural_variables(en_payload):
            en_var = en_payload[variable]
            de_var = de_sdict[key][variable]
            for category in ordered_categories(en_var):
                english = en_var[category]
                current = de_var.get(category, english)
                entries.append({
                    "comment": "",
                    "current_status": status_for(current, english),
                    "current_value": current,
                    "english_value": english,
                    "key": key,
                    "locale": "de",
                    "plural_category": category,
                    "plural_variable": variable,
                    "resource_type": "stringsdict",
                    "review_date": "",
                    "review_status": "",
                    "reviewed_value": "",
                    "reviewer": "",
                    "reviewer_notes": "",
                })

    return entries


def write_json(path: Path, entries: list[dict[str, Any]]) -> None:
    strings_count = sum(1 for e in entries if e["resource_type"] == "strings")
    plural_count = sum(1 for e in entries if e["resource_type"] == "stringsdict")
    status_counts: dict[str, int] = {}
    for e in entries:
        status_counts[e["current_status"]] = status_counts.get(e["current_status"], 0) + 1

    packet = {
        "generated_by": "Tools/german-review-packet-regenerate.py",
        "resources": entries,
        "review_status_values": REVIEW_STATUS_VALUES,
        "schema_version": 1,
        "source_locale": "en",
        "source_packet": "localization/review/translation-review-export.json",
        "summary": {
            "current_status_counts": status_counts,
            "plural_entry_count": plural_count,
            "review_entry_count": len(entries),
            "strings_entry_count": strings_count,
        },
        "target_language": "German / Deutsch",
        "target_locale": "de",
    }
    path.write_text(json.dumps(packet, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def write_csv(path: Path, entries: list[dict[str, Any]]) -> None:
    columns = [
        "resource_type",
        "key",
        "plural_variable",
        "plural_category",
        "comment",
        "english_value",
        "locale",
        "current_value",
        "current_status",
        "reviewed_value",
        "review_status",
        "reviewer",
        "review_date",
        "reviewer_notes",
    ]

    def safe(v: str) -> str:
        return v.replace("\r", "\\r").replace("\n", "\\n")

    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=columns, lineterminator="\n")
        writer.writeheader()
        for entry in entries:
            row = {c: "" for c in columns}
            for c in columns:
                if c in entry:
                    row[c] = safe(str(entry[c]))
            writer.writerow(row)


def main() -> int:
    entries = build_entries()
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    write_json(OUT_JSON, entries)
    write_csv(OUT_CSV, entries)
    strings_count = sum(1 for e in entries if e["resource_type"] == "strings")
    plural_count = sum(1 for e in entries if e["resource_type"] == "stringsdict")
    status_counts: dict[str, int] = {}
    for e in entries:
        status_counts[e["current_status"]] = status_counts.get(e["current_status"], 0) + 1
    print(
        f"german-review-packet-regenerate: wrote {len(entries)} entries "
        f"({strings_count} strings, {plural_count} stringsdict) status={status_counts}"
    )
    print(f"- {OUT_JSON.relative_to(REPO_ROOT)}")
    print(f"- {OUT_CSV.relative_to(REPO_ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
