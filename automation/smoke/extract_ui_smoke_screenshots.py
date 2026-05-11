#!/usr/bin/env python3
"""Extract XCUITest screenshot attachments into the repo's UI smoke proof pack.

The maintained smoke suite (`make ui-smoke`) captures one named screenshot per
test via `captureScreenshot(named:)` and attaches it with `lifetime = .keepAlways`.
This script walks the resulting `.xcresult` bundle, exports each attachment
matching the proof-pack naming convention (e.g. `01-today-launch`,
`02-focus-continue-item`, …) into `automation/proofs/owlory-ui-smoke-proof/`,
and regenerates `manifest.json` with sha256 hashes.

Run after `make ui-smoke` (or via `make ui-smoke-proof`):

    python3 automation/smoke/extract_ui_smoke_screenshots.py \\
        --xcresult /tmp/owlory-ui-smoke-derived-data/Logs/Test/Test-Owlory-*.xcresult

If `--xcresult` is omitted, the script picks the newest `.xcresult` bundle
under `/tmp/owlory-ui-smoke-derived-data/Logs/Test/`.

The script does not run the tests; it only reads the result bundle. It is
safe to re-run; existing PNGs are overwritten only when the attachment hash
differs, and `manifest.json` is rewritten each invocation.
"""
from __future__ import annotations

import argparse
import glob
import hashlib
import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

PROOF_DIR = Path("automation/proofs/owlory-ui-smoke-proof")
DEFAULT_XCRESULT_GLOB = "/tmp/owlory-ui-smoke-derived-data/Logs/Test/Test-Owlory-*.xcresult"
# XCTAttachment names get a `_<int>_<UUID>.png` suffix when emitted into the
# xcresult bundle (XCUITest disambiguates multiple captures with the same
# attachment name). We only want the proof-pack stem (e.g. `01-today-launch`)
# and treat the suffix as cosmetic.
SCREENSHOT_NAME_PATTERN = re.compile(r"^(\d{2}-[a-z0-9-]+)(?:_\d+_[A-F0-9-]+)?(?:\.png)?$")


def newest_xcresult() -> Path:
    candidates = glob.glob(DEFAULT_XCRESULT_GLOB)
    if not candidates:
        raise SystemExit(
            f"no xcresult bundles found under {DEFAULT_XCRESULT_GLOB}; "
            "run `make ui-smoke` first or pass --xcresult explicitly."
        )
    candidates.sort()
    return Path(candidates[-1])


def list_tests(xcresult: Path) -> list[str]:
    out = subprocess.check_output(
        [
            "xcrun",
            "xcresulttool",
            "get",
            "test-results",
            "tests",
            "--path",
            str(xcresult),
        ]
    )
    data = json.loads(out)

    test_ids: list[str] = []

    def walk(node: dict) -> None:
        if node.get("nodeType") == "Test Case":
            ident = node.get("nodeIdentifier")
            if ident:
                test_ids.append(ident)
        for child in node.get("children", []):
            walk(child)

    for node in data.get("testNodes", []):
        walk(node)

    return test_ids


def extract_screenshots_for_test(
    xcresult: Path, test_id: str
) -> list[tuple[str, Path]]:
    """Return a list of (screenshot-name, exported-path) tuples for a single test."""
    out = subprocess.check_output(
        [
            "xcrun",
            "xcresulttool",
            "get",
            "test-results",
            "activities",
            "--path",
            str(xcresult),
            "--test-id",
            test_id,
        ]
    )
    data = json.loads(out)

    results: list[tuple[str, Path]] = []

    def walk_activity(activity: dict) -> None:
        for attachment in activity.get("attachments", []):
            raw_name = attachment.get("name") or ""
            match = SCREENSHOT_NAME_PATTERN.match(raw_name)
            if not match:
                continue
            stem = match.group(1)
            payload_id = attachment.get("payloadId")
            if not payload_id:
                continue
            output_path = PROOF_DIR / f"{stem}.png"
            subprocess.check_call(
                [
                    "xcrun",
                    "xcresulttool",
                    "export",
                    "object",
                    "--legacy",
                    "--path",
                    str(xcresult),
                    "--id",
                    payload_id,
                    "--type",
                    "file",
                    "--output-path",
                    str(output_path),
                ]
            )
            results.append((stem, output_path))
        for child in activity.get("childActivities", []):
            walk_activity(child)

    for run in data.get("testRuns", []):
        for activity in run.get("activities", []):
            walk_activity(activity)

    return results


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def write_manifest(
    captured: list[tuple[str, Path]], xcresult: Path, source_commit: str
) -> Path:
    entries = sorted(
        [
            {
                "name": name,
                "file": f"{name}.png",
                "sha256": sha256(path),
                "size_bytes": path.stat().st_size,
            }
            for name, path in captured
        ],
        key=lambda e: e["name"],
    )
    manifest = {
        "slice": "owlory-ui-test-screenshot-proof-pack",
        "source_commit": source_commit,
        "captured_at": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "xcresult": xcresult.name,
        "screenshots": entries,
    }
    manifest_path = PROOF_DIR / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
    return manifest_path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--xcresult",
        type=Path,
        help="Path to the .xcresult bundle. Defaults to the newest under /tmp.",
    )
    args = parser.parse_args()

    xcresult = args.xcresult or newest_xcresult()
    if not xcresult.exists():
        raise SystemExit(f"xcresult bundle not found: {xcresult}")

    PROOF_DIR.mkdir(parents=True, exist_ok=True)

    source_commit = (
        subprocess.check_output(["git", "rev-parse", "HEAD"]).decode().strip()
    )

    captured: list[tuple[str, Path]] = []
    for test_id in list_tests(xcresult):
        for name, path in extract_screenshots_for_test(xcresult, test_id):
            captured.append((name, path))

    if not captured:
        raise SystemExit(
            "no proof-pack-named screenshots found in xcresult; "
            "ensure `captureScreenshot(named:)` is wired up in the smoke suite."
        )

    seen_names = [name for name, _ in captured]
    duplicate_names = {n for n in seen_names if seen_names.count(n) > 1}
    if duplicate_names:
        raise SystemExit(
            f"duplicate screenshot names in xcresult: {sorted(duplicate_names)}. "
            "Each captureScreenshot(named:) must use a unique name."
        )

    manifest_path = write_manifest(captured, xcresult, source_commit)
    print(f"exported {len(captured)} screenshots to {PROOF_DIR}")
    print(f"manifest: {manifest_path}")
    for name, path in sorted(captured, key=lambda c: c[0]):
        print(f"  {name}.png  ({path.stat().st_size} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
