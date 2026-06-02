"""Capture localized App Store *app-surface* screenshots (6.9" / 1320x2868).

Companion to `capture_app_store_onboarding_localized.py`. Where that harness
captures the localized onboarding tour, this one captures the real in-app
surfaces with realistic seeded data: Today, Train, Write, Career, Home, and the
weekly Digest (Today scrolled to the reflection card).

It boots the iPhone 17 Pro Max simulator (6.9" -> 1320x2868, the size Apple
reuses for every iPhone size + localization), forces light appearance and the
Apple-standard cellular status bar (9:41, cellular bars, no Wi-Fi, full
battery), then for each supported language relaunches the app with
`--owlory-ui-testing --owlory-ui-seed-marketing` (lands directly on a seeded
dashboard; onboarding suppressed) plus `-AppleLanguages`/`-AppleLocale`, and
taps through the five tabs.

NOTE ON CONTENT: the app *chrome* (tab labels, section headers, dates, buttons)
is fully localized. The seeded sample content (focus-item titles, note bodies,
etc. from OwloryUITestSupport.seedMarketing) is English in every language, since
that fixture is hardcoded English. To fully localize the sample text too, the
seedMarketing fixtures would need per-locale translations.

Tab navigation is by coordinate (idb does not reliably expose SwiftUI tab-bar
items). The tab bar mirrors under RTL, so Arabic taps are mirrored.

Usage:
    python3 automation/smoke/capture_app_store_surfaces_localized.py
    python3 automation/smoke/capture_app_store_surfaces_localized.py --locales en,de,ar

Output (per-locale subdir cleared per run):
    automation/proofs/app-store-screenshots-surfaces-localized/<lproj>/N-<surface>.png
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
OUTPUT_SUBDIR = "automation/proofs/app-store-screenshots-surfaces-localized"
DERIVED_DATA_DIR = Path("/tmp/owlory-app-store-derived")
BUNDLE_ID = "com.raelldottin.owlory"
DEVICE_NAME = "iPhone 17 Pro Max"
LAUNCH_SEED_ARGS = ["--owlory-ui-testing", "--owlory-ui-seed-marketing"]

# iPhone 17 Pro Max logical points.
SCREEN_W, SCREEN_H = 440, 956
TAB_Y = SCREEN_H - 36
TAB_CENTERS_X = [int(SCREEN_W / 5 * (i + 0.5)) for i in range(5)]  # [44,132,220,308,396]
# Tab declaration order (LTR, left->right). RTL mirrors this.
TAB_ORDER = ["today", "train", "write", "career", "home"]

# (lproj dir, AppleLanguages value, AppleLocale, is_RTL).
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
    out = run(["xcrun", "simctl", "list", "devices", DEVICE_NAME, "--json"], capture=True, quiet=True).stdout
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
    run(["xcrun", "simctl", "ui", udid, "appearance", "light"], check=False)
    run([
        "xcrun", "simctl", "status_bar", udid, "override",
        "--time", "9:41",
        "--cellularBars", "4",
        "--cellularMode", "active",
        "--operatorName", "Carrier",
        "--dataNetwork", "hide",  # cellular-only look (no Wi-Fi glyph)
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


def install(udid: str, app: Path) -> None:
    run(["xcrun", "simctl", "terminate", udid, BUNDLE_ID], check=False, quiet=True)
    run(["xcrun", "simctl", "install", udid, str(app)])


def launch_localized(udid: str, lang: str, locale: str) -> None:
    run(["xcrun", "simctl", "terminate", udid, BUNDLE_ID], check=False, quiet=True)
    time.sleep(0.6)
    run([
        "xcrun", "simctl", "launch", udid, BUNDLE_ID,
        *LAUNCH_SEED_ARGS,
        "-AppleLanguages", f'("{lang}")',
        "-AppleLocale", locale,
    ])


def screenshot(udid: str, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    run(["xcrun", "simctl", "io", udid, "screenshot", str(path)], quiet=True)


def tab_x(name: str, rtl: bool) -> int:
    i = TAB_ORDER.index(name)
    return TAB_CENTERS_X[(len(TAB_ORDER) - 1 - i) if rtl else i]


def tap_tab(udid: str, name: str, rtl: bool) -> None:
    run(["idb", "ui", "tap", "--udid", udid, str(tab_x(name, rtl)), str(TAB_Y)], quiet=True)


def swipe_up(udid: str, times: int = 1) -> None:
    cx = SCREEN_W // 2
    y0, y1 = int(SCREEN_H * 0.72), int(SCREEN_H * 0.24)
    for _ in range(times):
        run(["idb", "ui", "swipe", "--udid", udid, str(cx), str(y0), str(cx), str(y1), "--duration", "0.3"], quiet=True)
        time.sleep(0.6)


def capture_locale(udid: str, lproj: str, lang: str, locale: str, rtl: bool, out_root: Path) -> None:
    out_dir = out_root / lproj
    if out_dir.exists():
        shutil.rmtree(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    launch_localized(udid, lang, locale)
    time.sleep(4.5)  # land on the seeded Today dashboard (no permission prompt under ui-testing)

    # 1) Today (landing surface).
    screenshot(udid, out_dir / "1-today.png")

    # 2-5) The other four tabs.
    for idx, surface in [(2, "train"), (3, "write"), (4, "career"), (5, "home")]:
        tap_tab(udid, surface, rtl)
        time.sleep(1.8)
        screenshot(udid, out_dir / f"{idx}-{surface}.png")

    # 6) Weekly Digest: back to Today, scroll to the reflection/digest card.
    tap_tab(udid, "today", rtl)
    time.sleep(1.5)
    swipe_up(udid, times=2)
    time.sleep(0.8)
    screenshot(udid, out_dir / "6-digest.png")

    pngs = sorted(out_dir.glob("*.png"))
    print(f"  {lproj}: {len(pngs)} surfaces -> {out_dir.relative_to(REPO_ROOT)}")


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
    install(udid, app)

    print(f"capturing {len(selected)} locale(s) x 6 surfaces")
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
