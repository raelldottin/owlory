#!/usr/bin/env python3
"""Refresh per-locale review return files to include newly added keys.

Reads each per-locale return file under `localization/review/<locale>/`,
identifies keys present in current `Localizable.strings` / `Localizable.stringsdict`
but missing from the return file, and appends new entries with LLM-drafter
provenance. Existing entries are left untouched so any prior reviewer-supplied
metadata is preserved.

The German file uses the legacy `german-review-return.json` filename; all
others use `<locale>-review-return.json`.

This script does NOT:

- Modify app resources.
- Flip `provenance.native_reviewed`.
- Rewrite existing entries.
- Make any translation-quality claim.

Usage:

    python3 Tools/localization-return-files-refresh.py [--apply]

Without `--apply` the script reports per-locale how many entries it would add.
With `--apply` it writes the changes back.
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
from datetime import date
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
RES = REPO / "owlory_xcode/Owlory/Resources"
REVIEW = REPO / "localization/review"
EN_STRINGS = RES / "en.lproj/Localizable.strings"

LOCALES = [
    "ar", "nl", "fr", "de", "it", "ja", "ko", "nb", "pt", "pt-BR",
    "ru", "es", "sv", "zh-Hans", "zh-Hant", "tr", "uk", "vi",
]

LANGUAGE_NAMES = {
    "ar": "Arabic / العربية",
    "nl": "Dutch / Nederlands",
    "fr": "French / Français",
    "de": "German / Deutsch",
    "it": "Italian / Italiano",
    "ja": "Japanese / 日本語",
    "ko": "Korean / 한국어",
    "nb": "Norwegian Bokmål / Norsk Bokmål",
    "pt": "Portuguese / Português",
    "pt-BR": "Brazilian Portuguese / Português (Brasil)",
    "ru": "Russian / Русский",
    "es": "Spanish / Español",
    "sv": "Swedish / Svenska",
    "zh-Hans": "Simplified Chinese / 简体中文",
    "zh-Hant": "Traditional Chinese / 繁體中文",
    "tr": "Turkish / Türkçe",
    "uk": "Ukrainian / Українська",
    "vi": "Vietnamese / Tiếng Việt",
}

KEEP_ENGLISH_TERM_VALUES = {
    "OK", "URL", "Build", "Podcast", "Video", "Check-in",
    "%@", "%@ / 5", "%d/%d", "%d%%",
}
AUTO_DRAFT_REVIEWER = "Codex automated draft (not native/fluent reviewer)"


def find_return_file(locale: str) -> Path:
    candidates = [REVIEW / locale / f"{locale}-review-return.json"]
    if locale == "de":
        candidates.append(REVIEW / "de" / "german-review-return.json")
    for c in candidates:
        if c.exists():
            return c
    raise SystemExit(f"No return file found for locale {locale}")


def load_strings(path: Path) -> dict[str, str]:
    text = path.read_text(encoding="utf-8")
    pat = re.compile(r'^"((?:[^"\\]|\\.)+)"\s*=\s*"((?:[^"\\]|\\.)*)";\s*$', re.MULTILINE)
    out: dict[str, str] = {}
    for m in pat.finditer(text):
        key = (m.group(1).replace('\\"', '"')
               .replace('\\n', '\n').replace('\\\\', '\\'))
        val = (m.group(2).replace('\\"', '"')
               .replace('\\n', '\n').replace('\\\\', '\\'))
        out[key] = val
    return out


def load_stringsdict_triples(path: Path) -> dict[tuple[str, str, str], str]:
    """Return {(key, var, category): value} mapping from a stringsdict file."""
    result = subprocess.run(
        ["plutil", "-convert", "json", "-o", "-", str(path)],
        check=True, capture_output=True, text=True,
    )
    data = json.loads(result.stdout)
    triples: dict[tuple[str, str, str], str] = {}
    for stringsdict_key, payload in data.items():
        if not isinstance(payload, dict):
            continue
        for var_name, var_payload in payload.items():
            if var_name == "NSStringLocalizedFormatKey" or not isinstance(var_payload, dict):
                continue
            for category, value in var_payload.items():
                if category in ("NSStringFormatSpecTypeKey", "NSStringFormatValueTypeKey"):
                    continue
                if isinstance(value, str):
                    triples[(stringsdict_key, var_name, category)] = value
    return triples


def existing_entry_keys(entries: list[dict]) -> set[tuple]:
    """Build a set of identifying tuples for entries already present."""
    seen: set[tuple] = set()
    for e in entries:
        if e.get("resource_type") == "strings":
            seen.add(("strings", e.get("key")))
        elif e.get("resource_type") == "stringsdict":
            seen.add((
                "stringsdict",
                e.get("key"),
                e.get("plural_variable"),
                e.get("plural_category"),
            ))
    return seen


def refresh_locale(locale: str, apply: bool) -> dict[str, int]:
    return_path = find_return_file(locale)
    data = json.loads(return_path.read_text(encoding="utf-8"))
    existing = data.get("resources", [])
    seen = existing_entry_keys(existing)
    provenance = data.get("provenance", {})
    post_native_review = bool(provenance.get("native_reviewed", False))

    # Load current resources
    en_strings = load_strings(RES / "en.lproj/Localizable.strings")
    locale_strings = load_strings(RES / f"{locale}.lproj/Localizable.strings")
    en_sdict = load_stringsdict_triples(RES / "en.lproj/Localizable.stringsdict")
    locale_sdict = load_stringsdict_triples(RES / f"{locale}.lproj/Localizable.stringsdict")

    reviewer = data.get("provenance", {}).get("reviewer", "claude-opus-4-7 (LLM, not native " + LANGUAGE_NAMES.get(locale, locale) + " reviewer)")
    if post_native_review:
        reviewer = AUTO_DRAFT_REVIEWER
    today = str(date.today())
    native_review_pending = {
        "accepted": False,
        "reviewer": None,
        "review_date": None,
        "basis": (
            "Added after the "
            + str(provenance.get("review_date", "recorded"))
            + " native/fluent review pass recorded in this return file; "
            "no native/fluent acceptance is claimed for this key."
        ),
        "pending_native_review": True,
    }

    new_string_entries = 0
    new_sdict_entries = 0

    # Walk strings
    for key, english in en_strings.items():
        if ("strings", key) in seen:
            continue
        reviewed = locale_strings.get(key, english)
        if english in KEEP_ENGLISH_TERM_VALUES or reviewed == english:
            status = "keep-english-term"
            notes = (
                "Auto-added by Tools/localization-return-files-refresh.py. "
                "Term kept identical to English source (brand/format/loanword); native review still required."
            )
        else:
            status = "needs-layout-check"
            notes = (
                "Auto-added by Tools/localization-return-files-refresh.py. "
                "LLM-drafted value; not native-reviewed. Verify wording, grammar, and on-device layout."
            )
        entry = {
            "key": key,
            "english_value": english,
            "reviewed_value": reviewed,
            "review_status": status,
            "reviewer": reviewer,
            "review_date": today,
            "reviewer_notes": notes,
            "resource_type": "strings",
            "locale": locale,
            "post_packet_addition": True,
        }
        if post_native_review:
            entry["native_review"] = native_review_pending
        existing.append(entry)
        new_string_entries += 1

    # Walk stringsdict triples
    for triple, english in en_sdict.items():
        if ("stringsdict", triple[0], triple[1], triple[2]) in seen:
            continue
        reviewed = locale_sdict.get(triple, english)
        if reviewed == english:
            status = "keep-english-term"
            notes = (
                "Auto-added by Tools/localization-return-files-refresh.py. "
                "Plural value identical to English source; native review still required."
            )
        else:
            status = "needs-layout-check"
            notes = (
                "Auto-added by Tools/localization-return-files-refresh.py. "
                "LLM-drafted plural value; not native-reviewed. Verify grammar and on-device layout."
            )
        entry = {
            "key": triple[0],
            "plural_variable": triple[1],
            "plural_category": triple[2],
            "english_value": english,
            "reviewed_value": reviewed,
            "review_status": status,
            "reviewer": reviewer,
            "review_date": today,
            "reviewer_notes": notes,
            "resource_type": "stringsdict",
            "locale": locale,
            "post_packet_addition": True,
        }
        if post_native_review:
            entry["native_review"] = native_review_pending
        existing.append(entry)
        new_sdict_entries += 1

    # Refresh summary counts
    summary = data.setdefault("summary", {})
    summary["review_entry_count"] = len(existing)
    summary["strings_entry_count"] = sum(1 for e in existing if e.get("resource_type") == "strings")
    summary["plural_entry_count"] = sum(1 for e in existing if e.get("resource_type") == "stringsdict")
    status_counts: dict[str, int] = {}
    for e in existing:
        status_counts[e.get("review_status", "unknown")] = status_counts.get(e.get("review_status", "unknown"), 0) + 1
    summary["status_counts"] = status_counts

    data["resources"] = existing

    if apply and (new_string_entries + new_sdict_entries) > 0:
        return_path.write_text(
            json.dumps(data, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )
    return {
        "new_string_entries": new_string_entries,
        "new_sdict_entries": new_sdict_entries,
        "total_entries_after": len(existing),
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Refresh per-locale return files.")
    parser.add_argument("--apply", action="store_true", help="Write changes back.")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    grand_new = 0
    for locale in LOCALES:
        result = refresh_locale(locale, apply=args.apply)
        grand_new += result["new_string_entries"] + result["new_sdict_entries"]
        print(f"  [{locale:<7}] +{result['new_string_entries']} strings  +{result['new_sdict_entries']} plurals  total={result['total_entries_after']}")
    print(f"Total new entries: {grand_new} (applied={args.apply})")


if __name__ == "__main__":
    main()
