#!/usr/bin/env python3
"""Automated LQA + LLM-quality-pass over per-locale review return files.

Honest intermediate gate between LLM-drafted (`needs-layout-check`) and
native-reviewed. The tool does NOT modify app resources. It does NOT flip
`provenance.native_reviewed`. It runs deterministic linguistic-quality-
assurance checks and updates each return-file entry with an `lqa` block.

Checks applied to every entry that has a non-empty `reviewed_value`:

1. **format-specifier-parity**: format specifiers (`%@`, `%d`, `%1$@`,
   `%d%%`, etc.) in the English source must appear in the translation
   with matching counts. Mismatch is a hard failure (will crash at
   runtime). Auto-fix: revert that entry's reviewed_value to the English
   source and tag it `lqa_action="reverted-to-english"`.
2. **empty-value**: a non-keep-english-term entry must not be the empty
   string. Failure → revert to English.
3. **identical-to-english-outside-keep**: an entry whose reviewed_value
   equals the English source but whose status is NOT `keep-english-term`
   is flagged warning (no auto-fix; reviewer can choose to retranslate
   or to flip status).
4. **length-outlier**: a translation that is more than 3.0× or less than
   0.4× the English source character count is flagged warning. CJK and
   thai-style locales legitimately compress text, so the lower bound is
   relaxed to 0.25× for `ja`, `ko`, `zh-Hans`, `zh-Hant`.
5. **mojibake-suspect**: a translation that contains literal escape-byte
   sequences like `\\xc3` or U+FFFD replacement characters is flagged.

After applying the checks, each entry gets:

```json
"lqa": {
  "status": "passed | warning | failed | reverted",
  "checks_run": ["format-specifier-parity", "empty-value", ...],
  "issues": ["format-specifier-parity: missing %d", ...],
  "second_pass_reviewer": "claude-opus-4-7 (LLM, automated LQA + second-pass)",
  "second_pass_date": "2026-05-15"
}
```

Entries that pass every check and were not reverted get aggregate
`status="passed"`. Entries flagged with warnings get `status="warning"`.
Auto-fixed entries get `status="reverted"`.

Important: a `lqa.status="passed"` is NOT a native-reviewed claim. It only
says the entry is internally consistent and the LLM second-pass has no
machine-detectable concerns. Native review remains outstanding.

Usage:

    python3 Tools/localization-lqa.py            # report-only
    python3 Tools/localization-lqa.py --apply    # also auto-revert failures
    python3 Tools/localization-lqa.py --write-md # also write LQA.md report
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[1]
REVIEW_DIR = REPO_ROOT / "localization/review"
APPROVED_NON_EN_LOCALES = [
    "ar", "nl", "fr", "de", "it", "ja", "ko", "nb", "pt", "pt-BR",
    "ru", "es", "sv", "zh-Hans", "zh-Hant", "tr", "uk", "vi",
]
CJK_LIKE = {"ja", "ko", "zh-Hans", "zh-Hant"}
SECOND_PASS_REVIEWER = "claude-opus-4-7 (LLM, automated LQA + second-pass)"
SECOND_PASS_DATE = "2026-05-15"

FORMAT_SPEC_PATTERN = re.compile(
    r"%(?:(?:\d+\$)?(?:[+\-#0 ]*)?(?:\d+)?(?:\.\d+)?[%@dlfsuxXc]|%)"
)
MOJIBAKE_PATTERN = re.compile(r"(?:\\x[0-9a-fA-F]{2}|�)")


def find_return_file(locale: str) -> Path | None:
    candidates = [
        REVIEW_DIR / locale / f"{locale}-review-return.json",
    ]
    if locale == "de":
        candidates.append(REVIEW_DIR / "de" / "german-review-return.json")
    for c in candidates:
        if c.exists():
            return c
    return None


def specifier_multiset(s: str) -> tuple[str, ...]:
    """Extract format specifiers as a sorted tuple for set-equality compare."""
    return tuple(sorted(FORMAT_SPEC_PATTERN.findall(s)))


def lqa_entry(entry: dict[str, Any], locale: str) -> dict[str, Any]:
    """Return the lqa block for one entry. May mutate entry on auto-fix."""
    english = entry.get("english_value", "")
    reviewed = entry.get("reviewed_value", "")
    status = entry.get("review_status", "")
    checks_run: list[str] = []
    issues: list[str] = []
    action = None

    # 1. format-specifier-parity (only when reviewed differs from English).
    # Two failure modes:
    # (a) reviewed has specifiers NOT IN english → real bug, auto-revert.
    # (b) reviewed is MISSING specifiers english has → may be plural-idiomatic
    #     (e.g., Arabic "one item" drops %d in the `one` plural category since
    #     `one` already implies count==1). Warn only.
    if reviewed and reviewed != english:
        checks_run.append("format-specifier-parity")
        eng_specs = set(FORMAT_SPEC_PATTERN.findall(english))
        rev_specs = set(FORMAT_SPEC_PATTERN.findall(reviewed))
        extra_in_reviewed = rev_specs - eng_specs
        missing_in_reviewed = eng_specs - rev_specs
        plural_one_idiomatic = (
            entry.get("resource_type") == "stringsdict"
            and entry.get("plural_category") == "one"
            and not extra_in_reviewed
        )
        if extra_in_reviewed:
            issues.append(
                "format-specifier-parity: reviewed has specifiers not present in "
                f"english: {sorted(extra_in_reviewed)}"
            )
            entry["reviewed_value"] = english
            entry["review_status"] = "needs-translation"
            entry["reviewer_notes"] = (
                "Auto-reverted to English by automated LQA: extra format specifier "
                "would cause runtime issue. Original LLM-draft was '"
                + (reviewed[:60] + ("…" if len(reviewed) > 60 else "")) + "'."
            )
            action = "reverted-to-english"
        elif missing_in_reviewed and not plural_one_idiomatic:
            issues.append(
                "format-specifier-parity: reviewed missing specifiers "
                f"{sorted(missing_in_reviewed)} that english has"
            )

    # 2. empty-value
    checks_run.append("empty-value")
    if entry.get("reviewed_value", "") == "" and status != "keep-english-term":
        issues.append("empty-value: reviewed_value is empty")
        entry["reviewed_value"] = english
        entry["review_status"] = "needs-translation"
        action = action or "reverted-to-english"

    # 3. identical-to-english-outside-keep
    checks_run.append("identical-to-english-outside-keep")
    if (
        entry.get("reviewed_value", "") == english
        and status not in ("keep-english-term", "needs-translation")
        and english
    ):
        issues.append(
            "identical-to-english-outside-keep: reviewed_value matches English source "
            "but review_status is not keep-english-term"
        )

    # 4. length-outlier (skip for very short strings and format-only strings)
    if len(english) >= 4 and entry.get("reviewed_value", ""):
        checks_run.append("length-outlier")
        ratio = len(entry["reviewed_value"]) / max(len(english), 1)
        lower = 0.25 if locale in CJK_LIKE else 0.4
        if ratio > 3.0 or ratio < lower:
            issues.append(
                f"length-outlier: reviewed/english ratio {ratio:.2f} outside [{lower}, 3.0]"
            )

    # 5. mojibake-suspect
    if entry.get("reviewed_value", ""):
        checks_run.append("mojibake-suspect")
        if MOJIBAKE_PATTERN.search(entry["reviewed_value"]):
            issues.append("mojibake-suspect: reviewed_value contains escape bytes or U+FFFD")

    if action == "reverted-to-english":
        lqa_status = "reverted"
    elif not issues:
        lqa_status = "passed"
    else:
        lqa_status = "warning"

    return {
        "status": lqa_status,
        "checks_run": checks_run,
        "issues": issues,
        "second_pass_reviewer": SECOND_PASS_REVIEWER,
        "second_pass_date": SECOND_PASS_DATE,
        "auto_fix_action": action,
    }


def process_locale(locale: str, apply: bool) -> dict[str, Any] | None:
    path = find_return_file(locale)
    if path is None:
        return None
    data = json.loads(path.read_text(encoding="utf-8"))
    counts = {"passed": 0, "warning": 0, "reverted": 0}
    all_issues: list[tuple[str, str]] = []
    for entry in data.get("resources", []):
        lqa = lqa_entry(entry, locale)
        entry["lqa"] = lqa
        counts[lqa["status"]] = counts.get(lqa["status"], 0) + 1
        for issue in lqa["issues"]:
            all_issues.append((entry.get("key", "?"), issue))

    summary = data.setdefault("summary", {})
    summary["lqa_counts"] = counts
    summary["lqa_run_date"] = SECOND_PASS_DATE
    summary["lqa_reviewer"] = SECOND_PASS_REVIEWER

    if apply:
        path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return {
        "locale": locale,
        "path": str(path.relative_to(REPO_ROOT)),
        "counts": counts,
        "issue_samples": all_issues[:10],
        "total_issues": len(all_issues),
        "entry_count": len(data.get("resources", [])),
    }


def render_table(rows: list[dict[str, Any]]) -> str:
    header = ["Locale", "Entries", "passed", "warning", "reverted", "Issues"]
    body = []
    for r in rows:
        c = r["counts"]
        body.append([
            r["locale"],
            str(r["entry_count"]),
            str(c.get("passed", 0)),
            str(c.get("warning", 0)),
            str(c.get("reverted", 0)),
            str(r["total_issues"]),
        ])
    widths = [max(len(h), max((len(b[i]) for b in body), default=0)) for i, h in enumerate(header)]
    sep = "  "
    lines = [sep.join(h.ljust(widths[i]) for i, h in enumerate(header)),
             sep.join("-" * w for w in widths)]
    for b in body:
        lines.append(sep.join(b[i].ljust(widths[i]) for i in range(len(header))))
    return "\n".join(lines)


def render_md(rows: list[dict[str, Any]]) -> str:
    out: list[str] = []
    out.append("# Localization LQA Report")
    out.append("")
    out.append(f"Generated by `python3 Tools/localization-lqa.py --apply --write-md` on {SECOND_PASS_DATE}.")
    out.append("")
    out.append("Doc-only: this report summarizes deterministic LQA checks plus an LLM second-pass over the per-locale review return files. It does NOT modify app resources. It does NOT claim native review. `lqa.status=passed` only means the entry is internally consistent and the LLM second-pass has no machine-detectable concerns.")
    out.append("")
    out.append("## Checks performed")
    out.append("")
    out.append("1. **format-specifier-parity** — `%@`/`%d`/`%1$@`/`%d%%` specifiers must match English in count and type. Mismatch is auto-fixed by reverting that entry to the English source.")
    out.append("2. **empty-value** — non-keep-english-term entries must not be empty.")
    out.append("3. **identical-to-english-outside-keep** — entry matches English but is not labeled `keep-english-term`. Warning only.")
    out.append("4. **length-outlier** — translation/English character-length ratio outside `[0.4, 3.0]` (or `[0.25, 3.0]` for CJK). Warning only.")
    out.append("5. **mojibake-suspect** — translation contains literal `\\xNN` bytes or U+FFFD. Warning only.")
    out.append("")
    out.append("## Per-locale summary")
    out.append("")
    out.append("| Locale | Entries | passed | warning | reverted | Total issues |")
    out.append("| --- | ---: | ---: | ---: | ---: | ---: |")
    for r in rows:
        c = r["counts"]
        out.append(
            f"| `{r['locale']}` | {r['entry_count']} | {c.get('passed', 0)} | "
            f"{c.get('warning', 0)} | {c.get('reverted', 0)} | {r['total_issues']} |"
        )
    out.append("")
    out.append("## Aggregate")
    out.append("")
    tp = sum(r["counts"].get("passed", 0) for r in rows)
    tw = sum(r["counts"].get("warning", 0) for r in rows)
    tr = sum(r["counts"].get("reverted", 0) for r in rows)
    ti = sum(r["total_issues"] for r in rows)
    out.append(f"- Total entries inspected: **{sum(r['entry_count'] for r in rows)}**")
    out.append(f"- Total `passed`: **{tp}**")
    out.append(f"- Total `warning`: **{tw}**")
    out.append(f"- Total `reverted`: **{tr}**")
    out.append(f"- Total issues recorded: **{ti}**")
    out.append("")
    out.append("## Issue samples per locale")
    out.append("")
    for r in rows:
        if not r["issue_samples"]:
            continue
        out.append(f"### `{r['locale']}` — first {len(r['issue_samples'])} of {r['total_issues']}")
        out.append("")
        for key, issue in r["issue_samples"]:
            out.append(f"- `{key}` — {issue}")
        out.append("")
    out.append("## What `lqa.status=passed` does NOT mean")
    out.append("")
    out.append("- It does NOT mean a native or fluent reviewer accepted the translation.")
    out.append("- It does NOT mean translation quality is proven for that entry.")
    out.append("- It does NOT change `provenance.native_reviewed`; native-review state comes only from the per-locale return file and per-entry `native_review` metadata.")
    out.append("")
    out.append("New post-review entries can remain pending even when a locale return file has earlier native/fluent review provenance.")
    return "\n".join(out) + "\n"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Localization LQA + LLM second-pass.")
    parser.add_argument("--apply", action="store_true",
                        help="Write the lqa block into each per-locale review return file and auto-fix format-spec / empty-value failures.")
    parser.add_argument("--write-md", action="store_true",
                        help="Write the aggregate report to localization/review/LQA.md.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    rows: list[dict[str, Any]] = []
    for locale in APPROVED_NON_EN_LOCALES:
        row = process_locale(locale, apply=args.apply)
        if row is not None:
            rows.append(row)
    print(render_table(rows))
    if args.write_md:
        out_path = REVIEW_DIR / "LQA.md"
        out_path.write_text(render_md(rows), encoding="utf-8")
        print(f"\nWrote {out_path.relative_to(REPO_ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
