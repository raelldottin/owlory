"""Capture the localized App Store onboarding-tour screenshots (6.9" / 1320x2868).

The App Store listing leads with Owlory's 6-page onboarding tour
(Welcome / Today / Train / Write / Career / Home — see
`Features/Onboarding/OnboardingView.swift`). Every page renders through `L(...)`,
so the tour is fully localized from the `.strings` bundles. This harness boots
the iPhone 17 Pro Max simulator (6.9" display -> 1320x2868 px, the size Apple
reuses for every other iPhone size and every localization), forces light
appearance and the Apple-standard cellular status bar (9:41, LTE, full battery),
then for each supported language relaunches the app in that language and walks
the 6 tour pages, capturing one PNG per page.

The app is launched WITHOUT `--owlory-ui-testing` so the tour is shown, and the
"Get Started"/"Skip" buttons are never tapped, so the onboarding-complete flag
stays unset and the tour re-appears on every relaunch (one fresh install only).

Usage:
    python3 automation/smoke/capture_app_store_onboarding_localized.py
    python3 automation/smoke/capture_app_store_onboarding_localized.py --locales en,de,ja

Requirements:
    - Xcode + an available "iPhone 17 Pro Max" simulator runtime.
    - idb on PATH (used to locate + tap the localized "Next" button).
    - Invoked from the repo root.

Output (cleared per run):
    automation/proofs/app-store-screenshots-localized/<lproj>/{1..6}-<page>.png
"""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
import time
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
OUTPUT_SUBDIR = "automation/proofs/app-store-screenshots-localized"
DERIVED_DATA_DIR = Path("/tmp/owlory-app-store-derived")
BUNDLE_ID = "com.raelldottin.owlory"
DEVICE_NAME = "iPhone 17 Pro Max"

# Onboarding tour pages, in the order OnboardingPage.allPages renders them.
PAGES = ["1-welcome", "2-today", "3-train", "4-write", "5-career", "6-home"]

# (lproj dir, AppleLanguages value, AppleLocale, is_RTL). lproj == app's own
# language identifier; the README maps each to its App Store Connect language.
LOCALES: list[tuple[str, str, str, bool]] = [
    ("en", "en", "en_US", False),
    ("ar", "ar", "ar_SA", True),
    ("nl", "nl", "nl_NL", False),
    ("fr", "fr", "fr_FR", False),
    ("de", "de", "de_DE", False),
    ("it", "it", "it_IT", False),
    ("ja", "ja", "ja_JP", False),
    ("ko", "ko", "ko_KR", False),
    ("nb", "nb", "nb_NO", False),
    ("pt", "pt-PT", "pt_PT", False),
    ("pt-BR", "pt-BR", "pt_BR", False),
    ("ru", "ru", "ru_RU", False),
    ("es", "es", "es_ES", False),
    ("sv", "sv", "sv_SE", False),
    ("zh-Hans", "zh-Hans", "zh_CN", False),
    ("zh-Hant", "zh-Hant", "zh_TW", False),
    ("tr", "tr", "tr_TR", False),
    ("uk", "uk", "uk_UA", False),
    ("vi", "vi", "vi_VN", False),
]


def run(cmd: list[str], *, check: bool = True, capture: bool = False, quiet: bool = False) -> subprocess.CompletedProcess[str]:
    if not quiet:
        print(f"$ {' '.join(cmd)}")
    return subprocess.run(cmd, check=check, text=True, capture_output=capture)


def find_udid() -> str:
    out = run(
        ["xcrun", "simctl", "list", "devices", DEVICE_NAME, "--json"],
        capture=True, quiet=True,
    ).stdout
    data = json.loads(out)
    for runtime, devices in data.get("devices", {}).items():
        if "iOS" not in runtime:
            continue
        for d in devices:
            if d.get("name") == DEVICE_NAME and d.get("isAvailable"):
                return d["udid"]
    raise SystemExit(f"No available {DEVICE_NAME}. Install it via Xcode > Settings > Platforms.")


def ensure_booted(udid: str) -> None:
    state = run(["xcrun", "simctl", "list", "devices"], capture=True, quiet=True).stdout
    if any(udid in line and "Booted" in line for line in state.splitlines()):
        return
    run(["xcrun", "simctl", "boot", udid], check=False)
    run(["xcrun", "simctl", "bootstatus", udid, "-b"])


def configure_chrome(udid: str) -> None:
    """Light appearance + Apple-standard cellular status bar (persists at device level)."""
    run(["xcrun", "simctl", "ui", udid, "appearance", "light"], check=False)
    run([
        "xcrun", "simctl", "status_bar", udid, "override",
        "--time", "9:41",
        "--cellularBars", "4",
        "--cellularMode", "active",
        "--operatorName", "Carrier",
        "--dataNetwork", "hide",  # cellular-only look: no Wi-Fi / data-type glyph
        "--batteryState", "charged",
        "--batteryLevel", "100",
    ], check=False)


def build_if_missing(udid: str) -> Path:
    app = DERIVED_DATA_DIR / "Build/Products/Debug-iphonesimulator/Owlory.app"
    if app.is_dir():
        print(f"reusing prebuilt app at {app}")
        return app
    run([
        "xcodebuild",
        "-project", str(REPO_ROOT / "owlory_xcode/Owlory.xcodeproj"),
        "-scheme", "Owlory",
        "-configuration", "Debug",
        "-destination", f"platform=iOS Simulator,id={udid}",
        "-derivedDataPath", str(DERIVED_DATA_DIR),
        "build", "-quiet",
    ])
    if not app.is_dir():
        raise SystemExit(f"Owlory.app missing at {app}")
    return app


def fresh_install(udid: str, app: Path) -> None:
    """Uninstall + install so the onboarding-complete flag starts unset."""
    run(["xcrun", "simctl", "terminate", udid, BUNDLE_ID], check=False, quiet=True)
    run(["xcrun", "simctl", "uninstall", udid, BUNDLE_ID], check=False, quiet=True)
    run(["xcrun", "simctl", "install", udid, str(app)])


def launch_localized(udid: str, lang: str, locale: str) -> None:
    run(["xcrun", "simctl", "terminate", udid, BUNDLE_ID], check=False, quiet=True)
    time.sleep(0.6)
    # No --owlory-ui-testing => onboarding tour is shown. AppleLanguages/AppleLocale
    # land in the NSArgumentDomain so the app renders in `lang`.
    run([
        "xcrun", "simctl", "launch", udid, BUNDLE_ID,
        "-AppleLanguages", f'("{lang}")',
        "-AppleLocale", locale,
    ])


def screenshot(udid: str, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    run(["xcrun", "simctl", "io", udid, "screenshot", str(path)], quiet=True)


def dismiss_system_alerts(udid: str, attempts: int = 4) -> None:
    """Dismiss any system permission alert (e.g. notifications) before capture.

    Alert buttons sit mid-screen (~y 560); the onboarding Skip/Back/Next buttons
    sit at the very top or very bottom, so a mid-screen button is unambiguously
    an alert. Tapping the leftmost mid-screen button denies the request (and so
    avoids notification banners landing on later screenshots)."""
    for _ in range(attempts):
        mids = []
        for el in _describe_all(udid):
            frame = el.get("frame")
            if not frame or el.get("type") != "Button":
                continue
            cy = frame["y"] + frame["height"] / 2
            if 400 < cy < 720:
                mids.append(frame)
        if not mids:
            return
        f = min(mids, key=lambda fr: fr["x"])  # leftmost = "Don't Allow"
        run(["idb", "ui", "tap", "--udid", udid,
             str(int(f["x"] + f["width"] / 2)), str(int(f["y"] + f["height"] / 2))], quiet=True)
        time.sleep(1.2)


def _describe_all(udid: str) -> list[dict]:
    out = run(["idb", "ui", "describe-all", "--udid", udid], capture=True, quiet=True).stdout
    out = out.strip()
    if not out:
        return []
    try:
        return json.loads(out)
    except json.JSONDecodeError:
        # idb sometimes emits one JSON object per line.
        items = []
        for line in out.splitlines():
            line = line.strip()
            if line:
                try:
                    items.append(json.loads(line))
                except json.JSONDecodeError:
                    pass
        return items


def _center(frame: dict) -> tuple[int, int]:
    return int(frame["x"] + frame["width"] / 2), int(frame["y"] + frame["height"] / 2)


def tap_next(udid: str, rtl: bool, screen_h: float = 956.0) -> bool:
    """Locate and tap the onboarding "Next" button. Robust to text width + RTL.

    Strategy: prefer the element whose accessibility identifier is
    "onboarding.next"; otherwise tap the bottom-most button on the
    trailing edge (right for LTR, left for RTL).
    """
    elements = _describe_all(udid)

    def ident(el: dict) -> str:
        for key in ("AXUniqueId", "AXIdentifier", "identifier"):
            v = el.get(key)
            if v:
                return str(v)
        return ""

    # 1) Exact accessibility identifier match.
    for el in elements:
        if ident(el) == "onboarding.next" and el.get("frame"):
            x, y = _center(el["frame"])
            run(["idb", "ui", "tap", "--udid", udid, str(x), str(y)], quiet=True)
            return True

    # 2) Fallback: bottom-most button on the trailing edge.
    buttons = []
    for el in elements:
        frame = el.get("frame")
        if not frame:
            continue
        role = (el.get("role") or el.get("type") or "").lower()
        label = (el.get("AXLabel") or "").lower()
        looks_button = "button" in role or "button" in label
        cy = frame["y"] + frame["height"] / 2
        if looks_button and cy > screen_h * 0.78:
            buttons.append(frame)
    if buttons:
        # back button is at the leading edge; the primary "Next" is trailing.
        chosen = min(buttons, key=lambda f: f["x"]) if rtl else max(buttons, key=lambda f: f["x"])
        x, y = _center(chosen)
        run(["idb", "ui", "tap", "--udid", udid, str(x), str(y)], quiet=True)
        return True

    return False


def capture_locale(udid: str, lproj: str, lang: str, locale: str, rtl: bool, out_root: Path) -> None:
    out_dir = out_root / lproj
    if out_dir.exists():
        shutil.rmtree(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    launch_localized(udid, lang, locale)
    time.sleep(4.0)  # let onboarding render page 0
    dismiss_system_alerts(udid)  # clear notification prompt before first capture
    time.sleep(0.8)

    for i, page in enumerate(PAGES):
        screenshot(udid, out_dir / f"{page}.png")
        if i < len(PAGES) - 1:
            if not tap_next(udid, rtl):
                print(f"  !! could not find Next on page {i + 1} ({lproj})")
            time.sleep(1.0)

    pngs = sorted(out_dir.glob("*.png"))
    print(f"  {lproj}: {len(pngs)} pages -> {out_dir.relative_to(REPO_ROOT)}")


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--locales", default="", help="Comma-separated lproj codes to limit the run (default: all).")
    return p.parse_args()


def main() -> None:
    args = parse_args()
    selected = [t for t in LOCALES if (not args.locales or t[0] in set(args.locales.split(",")))]
    if not selected:
        raise SystemExit(f"No matching locales in: {args.locales}")

    out_root = REPO_ROOT / OUTPUT_SUBDIR
    out_root.mkdir(parents=True, exist_ok=True)

    udid = find_udid()
    print(f"using {DEVICE_NAME} {udid}")
    ensure_booted(udid)
    configure_chrome(udid)
    app = build_if_missing(udid)
    fresh_install(udid, app)

    print(f"capturing {len(selected)} locale(s) x {len(PAGES)} pages")
    for lproj, lang, locale, rtl in selected:
        print(f"[{lproj}] lang={lang} locale={locale} rtl={rtl}")
        capture_locale(udid, lproj, lang, locale, rtl, out_root)

    total = sum(1 for _ in out_root.rglob("*.png"))
    print(f"\nDone. {total} screenshots under {out_root.relative_to(REPO_ROOT)}/")


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as e:
        print(f"command failed: {e}", file=sys.stderr)
        raise SystemExit(e.returncode)
