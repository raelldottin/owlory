#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
import tempfile
import time
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable


SUPPORTED_LOCALES = [
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

DEFAULT_BUNDLE_ID = "com.raelldottin.owlory"
DEFAULT_OUTPUT_DIR = Path("automation/proofs/app-localization-all-locale-screenshot-proof")
KNOWN_NOTIFICATION_PROMPT_LABELS = {
    "“Owlory” Would Like to Send You Notifications",
    '"Owlory" Would Like to Send You Notifications',
}
KNOWN_DISMISS_LABELS = {"Don’t Allow", "Don't Allow", "Not Now"}
SETTLED_SURFACE_LABEL = "Today"


@dataclass
class CommandResult:
    argv: list[str]
    returncode: int
    stdout: str = ""
    stderr: str = ""


CommandRunner = Callable[[list[str]], CommandResult]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Capture localization launch screenshots with an idb-first UI interaction path. "
            "Use --check-dependencies before proof capture."
        )
    )
    parser.add_argument("--check-dependencies", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--udid", default="", help="Simulator/device UDID to target with idb.")
    parser.add_argument("--bundle-id", default=DEFAULT_BUNDLE_ID)
    parser.add_argument("--output-dir", default=str(DEFAULT_OUTPUT_DIR))
    parser.add_argument(
        "--locales",
        nargs="*",
        default=SUPPORTED_LOCALES,
        help="Locales to capture. Defaults to all supported Owlory locales."
    )
    parser.add_argument("--settle-seconds", type=float, default=4.0)
    parser.add_argument("--min-screenshot-bytes", type=int, default=50_000)
    parser.add_argument(
        "--allow-simctl-screenshot-fallback",
        action="store_true",
        help=(
            "Use simctl only for screenshot capture if this idb client lacks a screenshot "
            "command. idb still owns launch, UI describe, and prompt dismissal."
        )
    )
    parser.add_argument("--json", action="store_true", help="Emit machine-readable JSON.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    dependency_report = build_dependency_report()

    if args.check_dependencies:
        print_json(dependency_report)
        return 0

    if args.dry_run:
        print_json(build_plan(args, dependency_report))
        return 0

    if dependency_report["status"] != "ready":
        print_json(blocked_result("missing-idb-dependencies", dependency_report))
        return 2
    if not args.udid:
        print_json(blocked_result(
            "missing-udid",
            {
                "message": "Screenshot capture requires --udid because idb commands target a specific simulator/device."
            }
        ))
        return 2

    result = capture_all(args)
    print_json(result)
    return 0 if result["status"] == "passed" else 1


def build_dependency_report(
    which: Callable[[str], str | None] = shutil.which
) -> dict[str, Any]:
    tools = {
        "idb": which("idb"),
        "idb_companion": which("idb_companion"),
    }
    missing = []
    if not tools["idb"]:
        missing.append({
            "tool": "idb",
            "why": "The Python/CLI client drives targets and issues UI commands.",
            "remediation": [
                "Install the idb client outside the repo, for example: python3 -m pip install --user fb-idb",
                "If you use pipx, install the same client with: pipx install fb-idb",
                "Then verify: idb --help && idb list-targets"
            ]
        })
    if not tools["idb_companion"]:
        missing.append({
            "tool": "idb_companion",
            "why": "The macOS companion services simulator/device commands for the idb client.",
            "remediation": [
                "Install the companion outside the repo, for example: brew tap facebook/fb && brew install idb-companion",
                "Then verify: idb_companion --help"
            ]
        })

    return {
        "schema_version": 1,
        "status": "ready" if not missing else "blocked",
        "tools": tools,
        "missing": missing,
        "rule": (
            "xcodebuild/simctl remain the running-app smoke foundation; idb is the "
            "UI interaction/capture helper for screenshot proof when installed."
        ),
        "references": [
            "https://github.com/facebook/idb",
            "https://fbidb.io/docs/installation/",
            "https://fbidb.io/docs/commands/",
            "https://fbidb.io/docs/accessibility/"
        ]
    }


def build_plan(args: argparse.Namespace, dependency_report: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": 1,
        "status": "planned" if dependency_report["status"] == "ready" else "blocked",
        "dependency_report": dependency_report,
        "target": {
            "udid": args.udid,
            "bundle_id": args.bundle_id,
            "output_dir": args.output_dir,
            "locales": args.locales,
        },
        "steps": [
            "Use idb to terminate and relaunch Owlory with --owlory-ui-testing plus locale launch arguments.",
            "Use idb accessibility describe-all to detect and dismiss known system prompts.",
            "Wait until the Today launch surface is visible and no known system prompt remains.",
            "Capture each screenshot to a temporary file before moving it into the proof directory.",
            "Reject screenshots that are missing, too small, or captured while a known prompt is still visible.",
            "Write README.md and manifest.json with hashes and explicit non-claims."
        ],
    }


def capture_all(args: argparse.Namespace, runner: CommandRunner = None) -> dict[str, Any]:
    if runner is None:
        runner = run_command

    output_dir = Path(args.output_dir)
    if output_dir.exists() and any(output_dir.iterdir()):
        return blocked_result(
            "output-dir-not-empty",
            {
                "message": "Screenshot proof capture writes only to an empty proof directory.",
                "output_dir": str(output_dir),
                "remediation": "Choose an empty --output-dir or deliberately clear the stale proof attempt first.",
            },
        )

    output_dir.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="owlory-locale-screenshots-") as temp_dir:
        staging_dir = Path(temp_dir)
        entries = []
        failures = []
        for index, locale in enumerate(args.locales, start=1):
            capture = capture_one_locale(args, index, locale, staging_dir, runner)
            if capture["status"] == "passed":
                entries.append(capture)
            else:
                failures.append(capture)
                break

        result = {
            "schema_version": 1,
            "slice_id": "app-localization-all-locale-screenshot-proof",
            "timestamp": utc_timestamp(),
            "status": "passed" if not failures else "blocked",
            "proof_level": "screenshot-verified" if not failures else None,
            "captures": entries,
            "failures": failures,
            "non_claims": [
                "translation quality",
                "full layout correctness",
                "device proof",
                "TestFlight proof",
            ],
        }
        if not failures:
            output_dir.mkdir(parents=True, exist_ok=True)
            for staged_file in staging_dir.iterdir():
                shutil.move(str(staged_file), output_dir / staged_file.name)
            write_readme(output_dir, args.locales)
            write_manifest(output_dir, result)
        return result


def capture_one_locale(
    args: argparse.Namespace,
    index: int,
    locale: str,
    output_dir: Path,
    runner: CommandRunner
) -> dict[str, Any]:
    prefix = f"{index:02d}"
    final_path = output_dir / f"{prefix}-locale-{locale}-launch.png"

    runner(idb_command(args.udid, ["terminate", args.bundle_id]))
    launch = runner(idb_command(
        args.udid,
        [
            "launch",
            args.bundle_id,
            "--foreground-if-running",
            "--owlory-ui-testing",
            "-AppleLanguages",
            f"({locale})",
            "-AppleLocale",
            locale,
        ],
    ))
    if launch.returncode != 0:
        return failed_capture(locale, "launch-failed", launch)

    time.sleep(args.settle_seconds)
    describe = describe_ui(args.udid, runner)
    if describe["status"] != "passed":
        return failed_capture(locale, "describe-ui-failed", describe["result"])

    elements = describe["elements"]
    if contains_known_prompt(elements):
        dismiss = dismiss_known_prompt(args.udid, elements, runner)
        if dismiss["status"] != "passed":
            return {
                "locale": locale,
                "status": "blocked",
                "reason": "known system prompt is visible and could not be dismissed with idb",
                "details": dismiss,
            }
        time.sleep(args.settle_seconds)
        describe = describe_ui(args.udid, runner)
        if describe["status"] != "passed":
            return failed_capture(locale, "describe-after-dismiss-failed", describe["result"])
        elements = describe["elements"]

    if contains_known_prompt(elements):
        return {
            "locale": locale,
            "status": "blocked",
            "reason": "known system prompt remained visible after dismissal; screenshot was not preserved",
        }
    if not contains_label(elements, SETTLED_SURFACE_LABEL):
        return {
            "locale": locale,
            "status": "blocked",
            "reason": f"settled launch surface label {SETTLED_SURFACE_LABEL!r} was not found",
        }

    with tempfile.TemporaryDirectory() as temp_dir:
        temp_path = Path(temp_dir) / final_path.name
        screenshot = capture_screenshot(
            args.udid,
            temp_path,
            args.allow_simctl_screenshot_fallback,
            runner,
        )
        if screenshot["status"] != "passed":
            return {
                "locale": locale,
                "status": "blocked",
                "reason": "screenshot capture failed",
                "details": screenshot,
            }
        if not temp_path.exists() or temp_path.stat().st_size < args.min_screenshot_bytes:
            return {
                "locale": locale,
                "status": "blocked",
                "reason": "screenshot was missing or below the minimum byte threshold",
                "minimum_bytes": args.min_screenshot_bytes,
            }
        shutil.move(str(temp_path), final_path)

    return {
        "locale": locale,
        "status": "passed",
        "file": final_path.name,
        "bytes": final_path.stat().st_size,
        "sha256": sha256(final_path),
    }


def idb_command(udid: str, args: list[str]) -> list[str]:
    return ["idb", "--udid", udid, *args]


def describe_ui(udid: str, runner: CommandRunner) -> dict[str, Any]:
    result = runner(idb_command(udid, ["ui", "describe-all"]))
    if result.returncode != 0:
        return {"status": "blocked", "result": command_summary(result)}
    try:
        elements = json.loads(result.stdout)
    except json.JSONDecodeError:
        return {"status": "blocked", "result": command_summary(result)}
    if not isinstance(elements, list):
        return {"status": "blocked", "result": command_summary(result)}
    return {"status": "passed", "elements": elements}


def dismiss_known_prompt(
    udid: str,
    elements: list[dict[str, Any]],
    runner: CommandRunner
) -> dict[str, Any]:
    button = find_button(elements, KNOWN_DISMISS_LABELS)
    if button is None:
        return {"status": "blocked", "reason": "No known dismissal button found."}
    x, y = button
    result = runner(idb_command(udid, ["ui", "tap", str(round(x)), str(round(y))]))
    if result.returncode != 0:
        return {"status": "blocked", "result": command_summary(result)}
    return {"status": "passed", "tap": {"x": x, "y": y}}


def capture_screenshot(
    udid: str,
    output_path: Path,
    allow_simctl_fallback: bool,
    runner: CommandRunner
) -> dict[str, Any]:
    attempts = [
        idb_command(udid, ["screenshot", str(output_path)]),
        idb_command(udid, ["ui", "screenshot", str(output_path)]),
    ]
    for argv in attempts:
        result = runner(argv)
        if result.returncode == 0 and output_path.exists():
            return {"status": "passed", "method": argv[:3]}
    if allow_simctl_fallback:
        result = runner(["xcrun", "simctl", "io", udid, "screenshot", str(output_path)])
        if result.returncode == 0 and output_path.exists():
            return {"status": "passed", "method": ["xcrun", "simctl", "io"]}
        return {"status": "blocked", "result": command_summary(result)}
    return {
        "status": "blocked",
        "reason": (
            "This idb client did not produce a screenshot with either `idb screenshot` "
            "or `idb ui screenshot`. Retry with --allow-simctl-screenshot-fallback if "
            "idb should own UI interaction while simctl captures the final PNG."
        ),
    }


def contains_known_prompt(elements: list[dict[str, Any]]) -> bool:
    return contains_label(elements, *KNOWN_NOTIFICATION_PROMPT_LABELS)


def contains_label(elements: list[dict[str, Any]], *labels: str) -> bool:
    needles = {label.casefold() for label in labels}
    for element in elements:
        for value in element_text_values(element):
            if value.casefold() in needles:
                return True
    return False


def find_button(
    elements: list[dict[str, Any]],
    labels: set[str]
) -> tuple[float, float] | None:
    needles = {label.casefold() for label in labels}
    for element in elements:
        values = {value.casefold() for value in element_text_values(element)}
        if not values.intersection(needles):
            continue
        frame = element.get("frame")
        if not isinstance(frame, dict):
            continue
        try:
            x = float(frame["x"]) + float(frame["width"]) / 2
            y = float(frame["y"]) + float(frame["height"]) / 2
        except (KeyError, TypeError, ValueError):
            continue
        return x, y
    return None


def element_text_values(element: dict[str, Any]) -> list[str]:
    values = []
    for key in ("AXLabel", "title", "AXValue", "role_description"):
        value = element.get(key)
        if isinstance(value, str) and value:
            values.append(value)
    return values


def failed_capture(locale: str, reason: str, result: CommandResult) -> dict[str, Any]:
    return {
        "locale": locale,
        "status": "blocked",
        "reason": reason,
        "result": command_summary(result),
    }


def command_summary(result: CommandResult) -> dict[str, Any]:
    return {
        "argv": result.argv,
        "returncode": result.returncode,
        "stdout_tail": result.stdout[-1000:],
        "stderr_tail": result.stderr[-1000:],
    }


def run_command(argv: list[str]) -> CommandResult:
    completed = subprocess.run(argv, text=True, capture_output=True, check=False)
    return CommandResult(
        argv=argv,
        returncode=completed.returncode,
        stdout=completed.stdout,
        stderr=completed.stderr,
    )


def blocked_result(reason: str, details: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": 1,
        "status": "blocked",
        "reason": reason,
        "details": details,
    }


def write_readme(output_dir: Path, locales: list[str]) -> None:
    output_dir.joinpath("README.md").write_text(
        "# App Localization All-Locale Screenshot Proof\n\n"
        "This directory contains one settled launch-surface screenshot per supported locale.\n\n"
        "## Locales\n\n"
        f"```text\n{' '.join(locales)}\n```\n\n"
        "## Claim\n\n"
        "These screenshots prove simulator launch-surface visual evidence for the listed locales.\n"
        "They do not prove translation quality, full layout correctness, device behavior, or TestFlight behavior.\n",
        encoding="utf-8",
    )


def write_manifest(output_dir: Path, result: dict[str, Any]) -> None:
    output_dir.joinpath("manifest.json").write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def sha256(path: Path) -> str:
    import hashlib

    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def print_json(value: dict[str, Any]) -> None:
    print(json.dumps(value, indent=2, sort_keys=True))


def utc_timestamp() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


if __name__ == "__main__":
    sys.exit(main())
