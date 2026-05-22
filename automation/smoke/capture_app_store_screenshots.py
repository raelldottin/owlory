"""Capture the 5 App Store screenshots at 1320x2868 (iPhone 17 Pro Max).

Boots the iPhone 17 Pro Max simulator, builds + installs Owlory in Debug
configuration, launches with --owlory-ui-testing --owlory-ui-seed-marketing
(see OwloryUITestSupport.seedMarketing) so all primary surfaces have rich
realistic content, then captures the five surfaces in the order Apple
expects in the App Store carousel:

    1-today.png    Today / Continue dashboard
    2-write.png    Write / Capture inbox
    3-digest.png   Evening Reflection + Last Week digest + Browse Previous Days
    4-train.png    Train view (today planned + history)
    5-home.png     Home protocols + standalone tasks

Usage:
    python3 automation/smoke/capture_app_store_screenshots.py

Requirements:
    - Xcode + iPhone 17 Pro Max simulator runtime available.
    - idb installed and on PATH (used for tab taps and content scrolls).
    - This file is invoked from the repo root.

The output directory `automation/proofs/app-store-screenshots/` is cleared
before each run, so the captured PNGs are always the freshest set.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import time
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_OUTPUT_SUBDIR = "automation/proofs/app-store-screenshots"
DERIVED_DATA_DIR = Path("/tmp/owlory-app-store-derived")
BUNDLE_ID = "com.raelldottin.owlory"
DEFAULT_DEVICE_NAME = "iPhone 17 Pro Max"
LAUNCH_ARGS = ["--owlory-ui-testing", "--owlory-ui-seed-marketing"]


def tab_coords_for(width: int, height: int) -> dict[str, tuple[int, int]]:
    """Five evenly-spaced tab bar centers, with the y just above the home indicator.

    iPhone 17 Pro Max logical 440x956 -> y=920. iPhone 17 logical 402x874 -> y=842.
    """
    column_width = width / 5
    centers_x = [int(column_width * (i + 0.5)) for i in range(5)]
    tab_y = height - 36  # tab labels sit ~36 points above the home-indicator edge
    return {
        "today": (centers_x[0], tab_y),
        "train": (centers_x[1], tab_y),
        "write": (centers_x[2], tab_y),
        "career": (centers_x[3], tab_y),
        "home": (centers_x[4], tab_y),
    }


# Logical screen sizes per device (Apple-published point dimensions).
DEVICE_LOGICAL_SIZE = {
    "iPhone 17 Pro Max": (440, 956),
    "iPhone 17": (402, 874),
    "iPhone 17 Pro": (402, 874),
}


def run(command: list[str], *, check: bool = True, capture: bool = False) -> subprocess.CompletedProcess[str]:
    print(f"$ {' '.join(command)}")
    return subprocess.run(
        command,
        check=check,
        text=True,
        capture_output=capture,
    )


def find_simulator_udid(device_name: str) -> str:
    result = subprocess.run(
        ["xcrun", "simctl", "list", "devices", device_name, "--json"],
        capture_output=True,
        text=True,
        check=True,
    )
    data = json.loads(result.stdout)
    for runtime, devices in data.get("devices", {}).items():
        if "iOS" not in runtime:
            continue
        for device in devices:
            if device.get("name") == device_name and device.get("isAvailable", False):
                return device["udid"]
    raise SystemExit(f"No available {device_name} simulator. Install one via Xcode -> Settings -> Platforms.")


def ensure_booted(udid: str) -> None:
    state = subprocess.run(
        ["xcrun", "simctl", "list", "devices"],
        capture_output=True, text=True, check=True,
    ).stdout
    for line in state.splitlines():
        if udid in line and "Booted" in line:
            return
    run(["xcrun", "simctl", "boot", udid], check=False)
    run(["xcrun", "simctl", "bootstatus", udid, "-b"])


def build_app(udid: str) -> Path:
    run([
        "xcodebuild",
        "-project", str(REPO_ROOT / "owlory_xcode/Owlory.xcodeproj"),
        "-scheme", "Owlory",
        "-configuration", "Debug",
        "-destination", f"platform=iOS Simulator,id={udid}",
        "-derivedDataPath", str(DERIVED_DATA_DIR),
        "build",
        "-quiet",
    ])
    app = DERIVED_DATA_DIR / "Build/Products/Debug-iphonesimulator/Owlory.app"
    if not app.is_dir():
        raise SystemExit(f"Owlory.app missing at {app}")
    return app


def launch_with_seed(udid: str, app_path: Path) -> None:
    run(["xcrun", "simctl", "terminate", udid, BUNDLE_ID], check=False)
    time.sleep(1)
    run(["xcrun", "simctl", "install", udid, str(app_path)])
    run(["xcrun", "simctl", "launch", udid, BUNDLE_ID, *LAUNCH_ARGS])


def screenshot(udid: str, output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    run([
        "xcrun", "simctl", "io", udid, "screenshot", str(output_path),
    ])


def tab_tap(udid: str, tab: str, coords: dict[str, tuple[int, int]]) -> None:
    x, y = coords[tab]
    run(["idb", "ui", "tap", "--udid", udid, str(x), str(y)])


def swipe_up(udid: str, width: int, height: int, *, times: int = 1) -> None:
    center_x = width // 2
    start_y = int(height * 0.7)
    end_y = int(height * 0.25)
    for _ in range(times):
        run([
            "idb", "ui", "swipe", "--udid", udid,
            str(center_x), str(start_y), str(center_x), str(end_y),
            "--duration", "0.3",
        ])
        time.sleep(0.5)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Capture 5 App Store screenshots for a given iPhone simulator."
    )
    parser.add_argument(
        "--device-name",
        default=DEFAULT_DEVICE_NAME,
        help=f"Simulator device name (default: {DEFAULT_DEVICE_NAME}).",
    )
    parser.add_argument(
        "--output-subdir",
        default=DEFAULT_OUTPUT_SUBDIR,
        help=(
            "Repo-relative output directory for the captured PNGs "
            f"(default: {DEFAULT_OUTPUT_SUBDIR})."
        ),
    )
    return parser.parse_args()


def capture_all(device_name: str, output_subdir: str) -> None:
    output_dir = REPO_ROOT / output_subdir
    if output_dir.exists():
        for stale in output_dir.glob("*.png"):
            stale.unlink()
    output_dir.mkdir(parents=True, exist_ok=True)

    if device_name not in DEVICE_LOGICAL_SIZE:
        raise SystemExit(
            f"Unknown device '{device_name}'. Add its logical size to DEVICE_LOGICAL_SIZE."
        )
    width, height = DEVICE_LOGICAL_SIZE[device_name]
    coords = tab_coords_for(width, height)

    udid = find_simulator_udid(device_name)
    print(f"using {device_name} {udid} ({width}x{height} logical)")
    ensure_booted(udid)
    app_path = build_app(udid)
    launch_with_seed(udid, app_path)
    time.sleep(5)

    print("[1/5] Today / Continue dashboard")
    screenshot(udid, output_dir / "1-today.png")

    print("[2/5] Write / Capture inbox")
    tab_tap(udid, "write", coords)
    time.sleep(2)
    screenshot(udid, output_dir / "2-write.png")

    print("[4/5] Train view (capture early so it stays paged-in)")
    tab_tap(udid, "train", coords)
    time.sleep(2)
    screenshot(udid, output_dir / "4-train.png")

    print("[5/5] Home protocols + standalone tasks")
    tab_tap(udid, "home", coords)
    time.sleep(2)
    screenshot(udid, output_dir / "5-home.png")

    print("[3/5] Weekly Digest / reflection (Today scrolled to digest card)")
    tab_tap(udid, "today", coords)
    time.sleep(2)
    swipe_up(udid, width, height, times=2)
    time.sleep(1)
    screenshot(udid, output_dir / "3-digest.png")

    print()
    print("Captured 5 screenshots:")
    for png in sorted(output_dir.glob("*.png")):
        size = png.stat().st_size
        print(f"  {png.name}  ({size:,} bytes)")


if __name__ == "__main__":
    args = parse_args()
    try:
        capture_all(args.device_name, args.output_subdir)
    except subprocess.CalledProcessError as error:
        print(f"command failed: {error}", file=sys.stderr)
        raise SystemExit(error.returncode)
