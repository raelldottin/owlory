#!/usr/bin/env python3
"""Generate the localization review tracking dashboard.

Reads the per-locale review return files under `localization/review/<locale>/`
and produces a summary of review status per locale. Output:

- stdout: human-readable table.
- `--write-doc`: also writes `localization/review/STATUS.md` so future
  reviewers can see at a glance which locales are native-reviewed, which are
  LLM-drafted, and which still hold English placeholders.

The dashboard is reporting-only:

- It does NOT modify app resources.
- It does NOT modify per-locale return files.
- It does NOT make any translation-quality claim. A `native-reviewed` count
  reported here only reflects what the return files already say.

A locale is considered "native-reviewed" only when its `provenance.native_reviewed`
flag is `true`. The dashboard reports the current return-file state; it does not
infer translation quality from LQA output or generated review packets.

Usage:

    python3 Tools/localization-review-status.py
    python3 Tools/localization-review-status.py --write-doc
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[1]
REVIEW_DIR = REPO_ROOT / "localization/review"
RESOURCES_DIR = REPO_ROOT / "owlory_xcode/Owlory/Resources"
APPROVED_NON_EN_LOCALES = [
    "ar", "nl", "fr", "de", "it", "ja", "ko", "nb", "pt", "pt-BR",
    "ru", "es", "sv", "zh-Hans", "zh-Hant", "tr", "uk", "vi",
]

STATUS_VALUES = [
    "native-reviewed",
    "needs-layout-check",
    "needs-product-decision",
    "keep-english-term",
    "needs-translation",
    "reject",
]


def find_return_file(locale: str) -> Path | None:
    """Resolve the per-locale review return file path.

    The 17 multi-locale return files follow `<locale>/<locale>-review-return.json`.
    German uses the legacy `de/german-review-return.json` filename from the
    first-locale intake slice.
    """
    candidates = [
        REVIEW_DIR / locale / f"{locale}-review-return.json",
        REVIEW_DIR / locale / "german-review-return.json" if locale == "de" else None,
    ]
    for candidate in candidates:
        if candidate is not None and candidate.exists():
            return candidate
    return None


def summarize_locale(locale: str) -> dict[str, Any]:
    return_path = find_return_file(locale)
    if return_path is None:
        return {
            "locale": locale,
            "has_return_file": False,
            "native_reviewed": False,
            "reviewer": None,
            "review_date": None,
            "status_counts": {},
            "lqa_counts": {},
            "entry_count": 0,
        }
    data = json.loads(return_path.read_text(encoding="utf-8"))
    provenance = data.get("provenance", {})
    summary = data.get("summary", {})
    counts = summary.get("status_counts", {})
    lqa_counts = summary.get("lqa_counts", {})
    return {
        "locale": locale,
        "has_return_file": True,
        "return_path": str(return_path.relative_to(REPO_ROOT)),
        "target_language": data.get("target_language", locale),
        "native_reviewed": bool(provenance.get("native_reviewed", False)),
        "reviewer": provenance.get("reviewer"),
        "review_date": provenance.get("review_date"),
        "status_counts": {status: counts.get(status, 0) for status in STATUS_VALUES},
        "lqa_counts": lqa_counts,
        "lqa_run_date": summary.get("lqa_run_date"),
        "entry_count": summary.get("review_entry_count", sum(counts.values())),
    }


def render_table(rows: list[dict[str, Any]]) -> str:
    """Render a fixed-width table for the terminal."""
    header = ["Locale", "Lang", "Entries", "Native?", "LQA passed", "LQA warn", "LQA reverted", "LQA date"]
    body: list[list[str]] = []
    for row in rows:
        if not row["has_return_file"]:
            body.append([row["locale"], "?", "?", "—", "—", "—", "—", "—"])
            continue
        lqa = row.get("lqa_counts", {})
        body.append([
            row["locale"],
            row["target_language"].split(" / ")[0],
            str(row["entry_count"]),
            "yes" if row["native_reviewed"] else "no",
            str(lqa.get("passed", "—")),
            str(lqa.get("warning", "—")),
            str(lqa.get("reverted", "—")),
            row.get("lqa_run_date") or "—",
        ])
    widths = [max(len(c) for c in [header[i], *(r[i] for r in body)]) for i in range(len(header))]
    lines = []
    sep = "  "
    lines.append(sep.join(h.ljust(widths[i]) for i, h in enumerate(header)))
    lines.append(sep.join("-" * widths[i] for i in range(len(header))))
    for row in body:
        lines.append(sep.join(c.ljust(widths[i]) for i, c in enumerate(row)))
    return "\n".join(lines)


def aggregate_totals(rows: list[dict[str, Any]]) -> dict[str, Any]:
    totals = {status: 0 for status in STATUS_VALUES}
    lqa_totals = {"passed": 0, "warning": 0, "reverted": 0}
    locales_with_returns = 0
    native_locales: list[str] = []
    locales_with_lqa: list[str] = []
    for row in rows:
        if not row["has_return_file"]:
            continue
        locales_with_returns += 1
        if row["native_reviewed"]:
            native_locales.append(row["locale"])
        for status in STATUS_VALUES:
            totals[status] += row["status_counts"].get(status, 0)
        lqa = row.get("lqa_counts", {})
        if lqa:
            locales_with_lqa.append(row["locale"])
            for k in lqa_totals:
                lqa_totals[k] += lqa.get(k, 0)
    return {
        "locales_total": len(rows),
        "locales_with_returns": locales_with_returns,
        "native_reviewed_locales": native_locales,
        "locales_with_lqa": locales_with_lqa,
        "totals": totals,
        "lqa_totals": lqa_totals,
    }


def render_doc(rows: list[dict[str, Any]], totals: dict[str, Any]) -> str:
    out: list[str] = []
    out.append("# Localization Review Status")
    out.append("")
    out.append("Generated by `python3 Tools/localization-review-status.py --write-doc`. ")
    out.append("Reporting-only: this file does not modify resources and does not make a translation-quality claim.")
    out.append("")
    out.append("A locale is reported as `native-reviewed` only when its return file's `provenance.native_reviewed` is `true`. ")
    out.append("LLM-drafted return files explicitly set this flag to `false` and the reviewer field to `claude-opus-4-7`. ")
    out.append("Flipping a locale to native-reviewed requires a human review pass that updates the per-locale return file.")
    out.append("")
    out.append("## Summary")
    out.append("")
    out.append(f"- Locales tracked: **{totals['locales_total']}**.")
    out.append(f"- Locales with review return files: **{totals['locales_with_returns']}**.")
    out.append(f"- Native-reviewed locales: **{len(totals['native_reviewed_locales'])}** "
               + (f"({', '.join(totals['native_reviewed_locales'])})" if totals['native_reviewed_locales'] else "(none yet)") + ".")
    out.append("")
    out.append("### Aggregate status counts (across all locale return files)")
    out.append("")
    out.append("| Status | Count |")
    out.append("| --- | ---: |")
    for status in STATUS_VALUES:
        out.append(f"| `{status}` | {totals['totals'].get(status, 0)} |")
    out.append("")
    out.append("### Aggregate LQA counts (entries with `lqa` block written by `Tools/localization-lqa.py`)")
    out.append("")
    out.append(f"- Locales with LQA results: **{len(totals['locales_with_lqa'])}**.")
    out.append("")
    out.append("| LQA status | Count |")
    out.append("| --- | ---: |")
    for k in ("passed", "warning", "reverted"):
        out.append(f"| `{k}` | {totals['lqa_totals'].get(k, 0)} |")
    out.append("")
    out.append("`lqa.status=passed` means deterministic checks plus an LLM second-pass have no machine-detectable issues for that entry. It is NOT a native-review claim.")
    out.append("")
    out.append("## Per-locale status")
    out.append("")
    headers = ["Locale", "Language", "Entries", "Native?", *STATUS_VALUES, "LQA passed", "LQA warn", "LQA reverted", "LQA date", "Reviewer", "Review date"]
    out.append("| " + " | ".join(headers) + " |")
    out.append("| " + " | ".join("---" for _ in headers) + " |")
    for row in rows:
        if not row["has_return_file"]:
            out.append(f"| `{row['locale']}` | ? | — | — | " + " | ".join("—" for _ in STATUS_VALUES) + " | — | — | — | — | (no return file) | — |")
            continue
        lqa = row.get("lqa_counts", {})
        cols = [
            f"`{row['locale']}`",
            row["target_language"],
            str(row["entry_count"]),
            "yes" if row["native_reviewed"] else "no",
            *(str(row["status_counts"].get(s, 0)) for s in STATUS_VALUES),
            str(lqa.get("passed", "—")),
            str(lqa.get("warning", "—")),
            str(lqa.get("reverted", "—")),
            row.get("lqa_run_date") or "—",
            f"`{row['reviewer'] or ''}`" if row["reviewer"] else "—",
            row["review_date"] or "—",
        ]
        out.append("| " + " | ".join(cols) + " |")
    out.append("")
    out.append("## Reading guide")
    out.append("")
    out.append("- `native-reviewed`: native or fluent reviewer accepted the value. Translation-quality claim allowed for that key.")
    out.append("- `needs-layout-check`: candidate value (LLM-drafted or otherwise) needs UI/screenshot review. Not a quality claim.")
    out.append("- `needs-product-decision`: reviewer wants product input before accepting.")
    out.append("- `keep-english-term`: brand, format specifier, or loanword kept identical to English on purpose.")
    out.append("- `needs-translation`: no candidate yet; falls back to English placeholder pending native review.")
    out.append("- `reject`: candidate rejected.")
    out.append("")
    out.append("## Source files")
    out.append("")
    for row in rows:
        if row["has_return_file"]:
            out.append(f"- `{row['return_path']}`")
    out.append("")
    return "\n".join(out) + "\n"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Localization review status dashboard.")
    parser.add_argument("--write-doc", action="store_true",
                        help="Also write the dashboard to localization/review/STATUS.md.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    rows = [summarize_locale(locale) for locale in APPROVED_NON_EN_LOCALES]
    print(render_table(rows))
    totals = aggregate_totals(rows)
    print()
    print(f"Locales tracked: {totals['locales_total']}")
    print(f"Locales with return files: {totals['locales_with_returns']}")
    if totals["native_reviewed_locales"]:
        print(f"Native-reviewed locales ({len(totals['native_reviewed_locales'])}): "
              + ", ".join(totals["native_reviewed_locales"]))
    else:
        print("Native-reviewed locales: 0")
    print()
    print("Aggregate status counts (across all locale return files):")
    for status in STATUS_VALUES:
        print(f"  {status:<25} {totals['totals'].get(status, 0)}")
    print()
    print(f"LQA results (across {len(totals['locales_with_lqa'])} locales with lqa blocks):")
    for k in ("passed", "warning", "reverted"):
        print(f"  {k:<25} {totals['lqa_totals'].get(k, 0)}")
    if args.write_doc:
        doc_path = REVIEW_DIR / "STATUS.md"
        doc_path.write_text(render_doc(rows, totals), encoding="utf-8")
        print(f"\nWrote {doc_path.relative_to(REPO_ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
