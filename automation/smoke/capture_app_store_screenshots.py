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

import json
import subprocess
import sys
import time
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
OUTPUT_DIR = REPO_ROOT / "automation/proofs/app-store-screenshots"
DERIVED_DATA_DIR = Path("/tmp/owlory-app-store-derived")
BUNDLE_ID = "com.raelldottin.owlory"
DEVICE_NAME = "iPhone 17 Pro Max"
LAUNCH_ARGS = ["--owlory-ui-testing", "--owlory-ui-seed-marketing"]
# Logical (point) coordinates for the 5 tab bar items on iPhone 17 Pro Max
# (440x956 logical, 5 tabs at 88-pt width).
TAB_COORDS = {
    "today": (44, 920),
    "train": (132, 920),
    "write": (220, 920),
    "career": (308, 920),
    "home": (396, 920),
}


def run(command: list[str], *, check: bool = True, capture: bool = False) -> subprocess.CompletedProcess[str]:
    print(f"$ {' '.join(command)}")
    return subprocess.run(
        command,
        check=check,
        text=True,
        capture_output=capture,
    )


def find_simulator_udid() -> str:
    result = subprocess.run(
        ["xcrun", "simctl", "list", "devices", DEVICE_NAME, "--json"],
        capture_output=True,
        text=True,
        check=True,
    )
    data = json.loads(result.stdout)
    for runtime, devices in data.get("devices", {}).items():
        if "iOS" not in runtime:
            continue
        for device in devices:
            if device.get("name") == DEVICE_NAME and device.get("isAvailable", False):
                return device["udid"]
    raise SystemExit(f"No available {DEVICE_NAME} simulator. Install one via Xcode -> Settings -> Platforms.")


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


def tab_tap(udid: str, tab: str) -> None:
    x, y = TAB_COORDS[tab]
    run(["idb", "ui", "tap", "--udid", udid, str(x), str(y)])


def swipe_up(udid: str, *, times: int = 1) -> None:
    for _ in range(times):
        run([
            "idb", "ui", "swipe", "--udid", udid,
            "220", "700", "220", "250",
            "--duration", "0.3",
        ])
        time.sleep(0.5)


def capture_all() -> None:
    if OUTPUT_DIR.exists():
        for stale in OUTPUT_DIR.glob("*.png"):
            stale.unlink()
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    udid = find_simulator_udid()
    print(f"using {DEVICE_NAME} {udid}")
    ensure_booted(udid)
    app_path = build_app(udid)
    launch_with_seed(udid, app_path)
    time.sleep(5)

    print("[1/5] Today / Continue dashboard")
    screenshot(udid, OUTPUT_DIR / "1-today.png")

    print("[2/5] Write / Capture inbox")
    tab_tap(udid, "write")
    time.sleep(2)
    screenshot(udid, OUTPUT_DIR / "2-write.png")

    print("[4/5] Train view (capture early so it stays paged-in)")
    tab_tap(udid, "train")
    time.sleep(2)
    screenshot(udid, OUTPUT_DIR / "4-train.png")

    print("[5/5] Home protocols + standalone tasks")
    tab_tap(udid, "home")
    time.sleep(2)
    screenshot(udid, OUTPUT_DIR / "5-home.png")

    print("[3/5] Weekly Digest / reflection (Today scrolled to digest card)")
    tab_tap(udid, "today")
    time.sleep(2)
    swipe_up(udid, times=2)
    time.sleep(1)
    screenshot(udid, OUTPUT_DIR / "3-digest.png")

    print()
    print("Captured 5 screenshots:")
    for png in sorted(OUTPUT_DIR.glob("*.png")):
        size = png.stat().st_size
        print(f"  {png.name}  ({size:,} bytes)")


if __name__ == "__main__":
    try:
        capture_all()
    except subprocess.CalledProcessError as error:
        print(f"command failed: {error}", file=sys.stderr)
        raise SystemExit(error.returncode)
