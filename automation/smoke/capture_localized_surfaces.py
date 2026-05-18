#!/usr/bin/env python3
"""Capture named localized HIG surfaces for one or more locales using idb.

Companion to automation/smoke/capture_locale_screenshots.py, which is launch-only.
This harness extends the proof model to a catalog of named scoped surfaces that
the all-locale HIG completion plan requires (Build Info, Today, each root tab,
primary empty states/actions, high-risk date/count/plural).

Usage modes:

    python3 automation/smoke/capture_localized_surfaces.py --check-dependencies
    python3 automation/smoke/capture_localized_surfaces.py --list-surfaces
    python3 automation/smoke/capture_localized_surfaces.py --dry-run \
        --locales en de --surfaces today build-info
    python3 automation/smoke/capture_localized_surfaces.py --capture \
        --udid <udid> --locales en --surfaces today build-info

The harness is honest about its current scope:

- It does not claim translation quality.
- It does not claim full layout correctness.
- It does not claim device or TestFlight proof.
- Settled-state assertions rely on accessibility labels. Locale-specific labels
  must be provided via --label-overrides FILE.json or English fallbacks listed
  in the surface catalog. Captures whose settled assertion fails are recorded
  as blocked, not silently treated as proof.
"""
from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
import tempfile
import time
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from automation.smoke.capture_locale_screenshots import (
    KNOWN_NOTIFICATION_PROMPT_LABELS,
    CommandResult,
    build_dependency_report,
    command_summary,
    contains_label,
    describe_ui,
    dismiss_known_prompt,
    find_button,
    idb_command,
    run_command,
    sha256,
)


SUPPORTED_LOCALES = [
    "en", "ar", "nl", "fr", "de", "it", "ja", "ko", "nb",
    "pt", "pt-BR", "ru", "es", "sv", "zh-Hans", "zh-Hant",
    "tr", "uk", "vi",
]

DEFAULT_BUNDLE_ID = "com.raelldottin.owlory"
DEFAULT_OUTPUT_DIR = Path(
    "automation/proofs/app-localization-hig-multisurface-screenshot-harness"
)


@dataclass(frozen=True)
class NavigationStep:
    kind: str
    payload: dict[str, Any] = field(default_factory=dict)


@dataclass(frozen=True)
class Surface:
    id: str
    label: str
    description: str
    settled_assertion_labels: tuple[str, ...]
    navigation: tuple[NavigationStep, ...] = ()
    applicable_to_locales: tuple[str, ...] = ()

    def applies_to(self, locale: str) -> bool:
        if not self.applicable_to_locales:
            return True
        return locale in self.applicable_to_locales


def build_surface_catalog() -> list[Surface]:
    """Default catalog of scoped HIG surfaces the harness can capture.

    Surfaces map to the scoped surface list under
    automation/proofs/app-localization-hig-ui-matrix/manifest.json.
    """
    return [
        Surface(
            id="today",
            label="Today",
            description=(
                "Settled Today launch surface after locale-aware launch and any "
                "system prompt dismissal."
            ),
            settled_assertion_labels=(
                "Today", "Heute", "Aujourd'hui", "Oggi", "Hoy", "Hoje", "Сегодня",
                "今日", "오늘", "今天",
            ),
        ),
        Surface(
            id="root-tab-train",
            label="Train tab",
            description="Train root tab visible and settled.",
            settled_assertion_labels=("Train", "Trainen", "Entraînement", "Allenamento"),
            navigation=(
                NavigationStep(kind="tap_label", payload={"labels": ["Train"]}),
                NavigationStep(kind="wait", payload={"seconds": 1.5}),
            ),
        ),
        Surface(
            id="root-tab-write",
            label="Write tab",
            description="Write root tab visible and settled.",
            settled_assertion_labels=("Write", "Schrijf", "Écrire", "Scrivi"),
            navigation=(
                NavigationStep(kind="tap_label", payload={"labels": ["Write"]}),
                NavigationStep(kind="wait", payload={"seconds": 1.5}),
            ),
        ),
        Surface(
            id="root-tab-career",
            label="Career tab",
            description="Career root tab visible and settled.",
            settled_assertion_labels=("Career", "Carrière", "Karriere", "Carriera"),
            navigation=(
                NavigationStep(kind="tap_label", payload={"labels": ["Career"]}),
                NavigationStep(kind="wait", payload={"seconds": 1.5}),
            ),
        ),
        Surface(
            id="root-tab-home",
            label="Home tab",
            description="Home root tab visible and settled.",
            settled_assertion_labels=("Home", "Zuhause", "Maison", "Casa"),
            navigation=(
                NavigationStep(kind="tap_label", payload={"labels": ["Home"]}),
                NavigationStep(kind="wait", payload={"seconds": 1.5}),
            ),
        ),
        Surface(
            id="build-info",
            label="Build Info",
            description=(
                "Build Info screen with version, build, commit short/full, branch, "
                "and source-clean fields. Required for full HIG localized UI gates."
            ),
            settled_assertion_labels=("Build Info",),
            navigation=(
                NavigationStep(kind="tap_label", payload={"labels": ["Settings", "Einstellungen"]}),
                NavigationStep(kind="wait", payload={"seconds": 1.0}),
                NavigationStep(kind="tap_label", payload={"labels": ["Build Info"]}),
                NavigationStep(kind="wait", payload={"seconds": 1.5}),
            ),
        ),
        Surface(
            id="empty-state-today",
            label="Today empty state",
            description=(
                "Today empty-state copy. Requires a launch argument or fixture that "
                "starts the app with no Focus Three entries."
            ),
            settled_assertion_labels=("Today", "Heute"),
            navigation=(
                NavigationStep(kind="wait", payload={"seconds": 1.5}),
            ),
        ),
        Surface(
            id="date-count-plural-today",
            label="Today date/count/plural sample",
            description=(
                "Today surface with at least one plural-formatted count and one "
                "locale-aware date string visible (e.g., Focus Three count, "
                "Continue subtitle 'X days ago'). Verifies stringsdict + "
                "Date.FormatStyle render correctly."
            ),
            settled_assertion_labels=("Today", "Heute"),
            navigation=(
                NavigationStep(kind="wait", payload={"seconds": 1.5}),
            ),
        ),
    ]


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Capture named localized HIG surfaces using idb. Use "
            "--check-dependencies, --list-surfaces, or --dry-run before "
            "--capture; --capture is the only mode that writes screenshot "
            "artifacts."
        )
    )
    parser.add_argument("--check-dependencies", action="store_true")
    parser.add_argument("--list-surfaces", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--capture", action="store_true")
    parser.add_argument("--udid", default="")
    parser.add_argument("--bundle-id", default=DEFAULT_BUNDLE_ID)
    parser.add_argument(
        "--output-dir",
        default=str(DEFAULT_OUTPUT_DIR),
        help="Proof output directory. Must be empty before capture.",
    )
    parser.add_argument(
        "--locales",
        nargs="*",
        default=SUPPORTED_LOCALES,
    )
    parser.add_argument(
        "--surfaces",
        nargs="*",
        default=[],
        help="Surface ids to capture. Empty list captures the full catalog.",
    )
    parser.add_argument(
        "--label-overrides",
        default="",
        help=(
            "Path to a JSON file mapping surface_id -> additional settled "
            "assertion labels for non-English locales."
        ),
    )
    parser.add_argument("--settle-seconds", type=float, default=4.0)
    parser.add_argument("--min-screenshot-bytes", type=int, default=50_000)
    parser.add_argument("--allow-simctl-screenshot-fallback", action="store_true")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    catalog = build_surface_catalog()

    if args.list_surfaces:
        print_json(surface_catalog_summary(catalog))
        return 0

    dependency_report = build_dependency_report()

    if args.check_dependencies:
        print_json(dependency_report)
        return 0

    selected_surfaces = select_surfaces(catalog, args.surfaces)
    if not selected_surfaces:
        print_json(blocked_result(
            "no-matching-surfaces",
            {"requested": args.surfaces, "available": [s.id for s in catalog]},
        ))
        return 2

    if args.dry_run:
        print_json(build_plan(args, dependency_report, selected_surfaces))
        return 0

    if not args.capture:
        print_json(blocked_result(
            "no-mode-selected",
            {"message": "Pass --check-dependencies, --list-surfaces, --dry-run, or --capture."},
        ))
        return 2

    if dependency_report["status"] != "ready":
        print_json(blocked_result("missing-idb-dependencies", dependency_report))
        return 2
    if not args.udid:
        print_json(blocked_result(
            "missing-udid",
            {"message": "--capture requires --udid because idb commands target a specific simulator/device."},
        ))
        return 2

    label_overrides = load_label_overrides(args.label_overrides)
    result = capture_all(args, selected_surfaces, label_overrides)
    print_json(result)
    return 0 if result["status"] == "passed" else 1


def select_surfaces(catalog: list[Surface], requested: list[str]) -> list[Surface]:
    if not requested:
        return list(catalog)
    by_id = {surface.id: surface for surface in catalog}
    return [by_id[name] for name in requested if name in by_id]


def surface_catalog_summary(catalog: list[Surface]) -> dict[str, Any]:
    return {
        "schema_version": 1,
        "surfaces": [
            {
                "id": surface.id,
                "label": surface.label,
                "description": surface.description,
                "navigation_steps": len(surface.navigation),
                "settled_assertion_labels": list(surface.settled_assertion_labels),
                "applicable_to_locales": list(surface.applicable_to_locales) or None,
            }
            for surface in catalog
        ],
        "count": len(catalog),
    }


def build_plan(
    args: argparse.Namespace,
    dependency_report: dict[str, Any],
    surfaces: list[Surface],
) -> dict[str, Any]:
    matrix = []
    for locale in args.locales:
        for surface in surfaces:
            if not surface.applies_to(locale):
                continue
            matrix.append({
                "locale": locale,
                "surface_id": surface.id,
                "surface_label": surface.label,
                "navigation_steps": len(surface.navigation),
            })
    return {
        "schema_version": 1,
        "status": "planned" if dependency_report["status"] == "ready" else "blocked",
        "dependency_report": dependency_report,
        "target": {
            "udid": args.udid,
            "bundle_id": args.bundle_id,
            "output_dir": args.output_dir,
        },
        "locales": list(args.locales),
        "surfaces": [s.id for s in surfaces],
        "captures_planned": len(matrix),
        "matrix": matrix,
    }


def capture_all(
    args: argparse.Namespace,
    surfaces: list[Surface],
    label_overrides: dict[str, list[str]],
    runner: Callable[[list[str]], CommandResult] | None = None,
) -> dict[str, Any]:
    if runner is None:
        runner = run_command

    output_dir = Path(args.output_dir)
    if output_dir.exists() and any(output_dir.iterdir()):
        return blocked_result(
            "output-dir-not-empty",
            {
                "message": "Multisurface capture writes only to an empty proof directory.",
                "output_dir": str(output_dir),
                "remediation": "Choose an empty --output-dir or deliberately clear the stale proof first.",
            },
        )
    output_dir.parent.mkdir(parents=True, exist_ok=True)

    entries: list[dict[str, Any]] = []
    failures: list[dict[str, Any]] = []
    capture_index = 0
    with tempfile.TemporaryDirectory(prefix="owlory-localized-surfaces-") as temp_dir:
        staging = Path(temp_dir)
        for locale in args.locales:
            launch = launch_locale(args, locale, runner)
            if launch.returncode != 0:
                failures.append({
                    "locale": locale,
                    "surface_id": "*",
                    "status": "blocked",
                    "reason": "launch-failed",
                    "result": command_summary(launch),
                })
                continue
            time.sleep(args.settle_seconds)
            for surface in surfaces:
                if not surface.applies_to(locale):
                    continue
                capture_index += 1
                capture = capture_one_surface(
                    args=args,
                    locale=locale,
                    surface=surface,
                    index=capture_index,
                    staging_dir=staging,
                    label_overrides=label_overrides,
                    runner=runner,
                )
                if capture["status"] == "passed":
                    entries.append(capture)
                else:
                    failures.append(capture)

    git_commit = read_git_commit_short()
    result = {
        "schema_version": 1,
        "slice_id": "app-localization-hig-multisurface-screenshot-harness",
        "timestamp": utc_timestamp(),
        "status": "passed" if not failures else "blocked",
        "proof_level": "screenshot-verified" if not failures else None,
        "git_commit_short": git_commit,
        "target": {"udid": args.udid, "bundle_id": args.bundle_id},
        "captures": entries,
        "failures": failures,
        "non_claims": [
            "translation quality",
            "full layout correctness",
            "device proof",
            "TestFlight proof",
            "hig-ui-reviewed",
        ],
    }
    if not failures and entries:
        output_dir.mkdir(parents=True, exist_ok=True)
        for entry in entries:
            staged = Path(entry["_staged_path"])
            final = output_dir / entry["file"]
            shutil.move(str(staged), final)
            del entry["_staged_path"]
        write_readme(output_dir, args.locales, [s.id for s in surfaces])
        write_manifest(output_dir, result)
    return result


def launch_locale(args: argparse.Namespace, locale: str, runner) -> CommandResult:
    runner(idb_command(args.udid, ["terminate", args.bundle_id]))
    return runner(idb_command(
        args.udid,
        [
            "launch",
            "--foreground-if-running",
            args.bundle_id,
            "--owlory-ui-testing",
            "-AppleLanguages",
            f"({locale})",
            "-AppleLocale",
            locale,
        ],
    ))


def capture_one_surface(
    args: argparse.Namespace,
    locale: str,
    surface: Surface,
    index: int,
    staging_dir: Path,
    label_overrides: dict[str, list[str]],
    runner,
) -> dict[str, Any]:
    filename = f"{index:02d}-locale-{locale}-surface-{surface.id}.png"
    staged_path = staging_dir / filename

    describe = describe_ui(args.udid, runner)
    if describe["status"] != "passed":
        return _blocked(locale, surface, "describe-ui-failed", details=describe.get("result"))
    elements = describe["elements"]

    if contains_label(elements, *KNOWN_NOTIFICATION_PROMPT_LABELS):
        dismiss = dismiss_known_prompt(args.udid, elements, runner)
        if dismiss["status"] != "passed":
            return _blocked(locale, surface, "system-prompt-blocking-navigation", details=dismiss)
        time.sleep(min(args.settle_seconds, 2.0))
        describe = describe_ui(args.udid, runner)
        if describe["status"] != "passed":
            return _blocked(locale, surface, "describe-after-dismiss-failed", details=describe.get("result"))
        elements = describe["elements"]

    for step in surface.navigation:
        step_result = run_navigation_step(args.udid, step, elements, runner)
        if step_result["status"] != "passed":
            return _blocked(locale, surface, "navigation-step-failed", details=step_result)
        if step.kind in {"tap_label", "tap_identifier"}:
            time.sleep(min(args.settle_seconds, 2.0))
            describe = describe_ui(args.udid, runner)
            if describe["status"] != "passed":
                return _blocked(locale, surface, "describe-after-step-failed", details=describe.get("result"))
            elements = describe["elements"]

    assertion_labels = list(surface.settled_assertion_labels)
    assertion_labels.extend(label_overrides.get(surface.id, []))
    if assertion_labels and not contains_label(elements, *assertion_labels):
        return _blocked(
            locale,
            surface,
            "settled-assertion-failed",
            details={
                "expected_any_of": assertion_labels,
                "hint": (
                    "Provide additional locale-specific labels via --label-overrides "
                    "or add an accessibility identifier to the surface."
                ),
            },
        )

    with tempfile.TemporaryDirectory() as inner:
        inner_path = Path(inner) / filename
        screenshot = capture_screenshot(
            args.udid,
            inner_path,
            args.allow_simctl_screenshot_fallback,
            runner,
        )
        if screenshot["status"] != "passed":
            return _blocked(locale, surface, "screenshot-failed", details=screenshot)
        if not inner_path.exists() or inner_path.stat().st_size < args.min_screenshot_bytes:
            return _blocked(
                locale,
                surface,
                "screenshot-below-minimum",
                details={"minimum_bytes": args.min_screenshot_bytes},
            )
        shutil.move(str(inner_path), staged_path)

    return {
        "locale": locale,
        "surface_id": surface.id,
        "surface_label": surface.label,
        "status": "passed",
        "file": staged_path.name,
        "bytes": staged_path.stat().st_size,
        "sha256": sha256(staged_path),
        "navigation_steps_executed": len(surface.navigation),
        "_staged_path": str(staged_path),
    }


def run_navigation_step(
    udid: str,
    step: NavigationStep,
    elements: list[dict[str, Any]],
    runner,
) -> dict[str, Any]:
    if step.kind == "wait":
        seconds = float(step.payload.get("seconds", 1.0))
        time.sleep(seconds)
        return {"status": "passed", "kind": "wait", "seconds": seconds}
    if step.kind == "tap_label":
        labels = set(step.payload.get("labels", []))
        position = find_button(elements, labels)
        if position is None:
            return {"status": "blocked", "kind": "tap_label", "labels": list(labels), "reason": "label-not-found"}
        x, y = position
        result = runner(idb_command(udid, ["ui", "tap", str(round(x)), str(round(y))]))
        if result.returncode != 0:
            return {"status": "blocked", "kind": "tap_label", "result": command_summary(result)}
        return {"status": "passed", "kind": "tap_label", "labels": list(labels), "tap": {"x": x, "y": y}}
    if step.kind == "tap_identifier":
        identifier = step.payload.get("identifier", "")
        position = find_button_by_identifier(elements, identifier)
        if position is None:
            return {"status": "blocked", "kind": "tap_identifier", "identifier": identifier, "reason": "identifier-not-found"}
        x, y = position
        result = runner(idb_command(udid, ["ui", "tap", str(round(x)), str(round(y))]))
        if result.returncode != 0:
            return {"status": "blocked", "kind": "tap_identifier", "result": command_summary(result)}
        return {"status": "passed", "kind": "tap_identifier", "identifier": identifier, "tap": {"x": x, "y": y}}
    return {"status": "blocked", "kind": step.kind, "reason": "unknown-step-kind"}


def find_button_by_identifier(
    elements: list[dict[str, Any]],
    identifier: str,
) -> tuple[float, float] | None:
    needle = identifier.casefold()
    for element in elements:
        for key in ("AXIdentifier", "identifier", "accessibility_identifier"):
            value = element.get(key)
            if isinstance(value, str) and value.casefold() == needle:
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


def capture_screenshot(
    udid: str,
    output_path: Path,
    allow_simctl_fallback: bool,
    runner,
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
            "This idb client did not produce a screenshot with `idb screenshot` "
            "or `idb ui screenshot`. Retry with --allow-simctl-screenshot-fallback "
            "if idb should own UI interaction while simctl captures the final PNG."
        ),
    }


def load_label_overrides(path: str) -> dict[str, list[str]]:
    if not path:
        return {}
    data = json.loads(Path(path).read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ValueError("--label-overrides JSON must be an object: { surface_id: [labels...] }")
    overrides: dict[str, list[str]] = {}
    for key, value in data.items():
        if not isinstance(key, str) or not isinstance(value, list):
            continue
        overrides[key] = [v for v in value if isinstance(v, str)]
    return overrides


def _blocked(
    locale: str,
    surface: Surface,
    reason: str,
    details: Any = None,
) -> dict[str, Any]:
    payload: dict[str, Any] = {
        "locale": locale,
        "surface_id": surface.id,
        "surface_label": surface.label,
        "status": "blocked",
        "reason": reason,
    }
    if details is not None:
        payload["details"] = details
    return payload


def blocked_result(reason: str, details: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": 1,
        "status": "blocked",
        "reason": reason,
        "details": details,
    }


def write_readme(output_dir: Path, locales: list[str], surface_ids: list[str]) -> None:
    output_dir.joinpath("README.md").write_text(
        "# App Localization HIG Multisurface Screenshot Harness\n\n"
        "This directory contains scoped HIG surface screenshots captured by\n"
        "`automation/smoke/capture_localized_surfaces.py` for the locales and\n"
        "surfaces listed below.\n\n"
        "## Locales\n\n"
        f"```text\n{' '.join(locales)}\n```\n\n"
        "## Surfaces\n\n"
        f"```text\n{' '.join(surface_ids)}\n```\n\n"
        "## Claim\n\n"
        "These screenshots prove repo-managed simulator screenshot evidence for the\n"
        "listed (locale, surface) pairs only. They do not prove translation quality,\n"
        "full layout correctness, device behavior, or TestFlight behavior. They do\n"
        "not constitute a `hig-ui-reviewed` claim for any locale by themselves.\n",
        encoding="utf-8",
    )


def write_manifest(output_dir: Path, result: dict[str, Any]) -> None:
    payload = json.dumps(result, indent=2, sort_keys=True) + "\n"
    output_dir.joinpath("manifest.json").write_text(payload, encoding="utf-8")


def read_git_commit_short() -> str:
    try:
        completed = subprocess.run(
            ["git", "rev-parse", "--short", "HEAD"],
            capture_output=True,
            text=True,
            check=False,
        )
        if completed.returncode == 0:
            return completed.stdout.strip()
    except FileNotFoundError:
        pass
    return ""


def print_json(value: dict[str, Any]) -> None:
    print(json.dumps(value, indent=2, sort_keys=True))


def utc_timestamp() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


if __name__ == "__main__":
    sys.exit(main())
