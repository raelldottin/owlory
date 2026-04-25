#!/bin/sh
# Read-only verification for Owlory app icon source-of-truth and non-canonical root artifacts.

set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_FILE="$ROOT/owlory_xcode/Owlory.xcodeproj/project.pbxproj"
CANONICAL="$ROOT/owlory_xcode/Owlory/Resources/Assets.xcassets/AppIcon.appiconset"

fail() {
  echo "error: $*" >&2
  echo "why this matters: app-icon cleanup must not remove shipped assets or leave root-level icon bundles ambiguous." >&2
  echo "remediation: keep shipped icons under owlory_xcode/Owlory/Resources/Assets.xcassets/AppIcon.appiconset and see docs/workflows/app-icons.md." >&2
  exit 1
}

relative() {
  sed "s#^$ROOT/##"
}

folder_classification() {
  case "$1" in
    Owlory_AppIcon|Owlory_BlueWhite_AppIcon|Owlory_Fixed_AppIcon|Owlory_RC_AppIcon|Owlory_TransparentBase_AppIcon|Owlory_UnifiedBlue_AppIcon|Owlory_WhiteBG_BlueOwl_AppIcon)
      echo "non-canonical root icon set; preserve any useful note in docs, then remove"
      ;;
    *)
      echo "non-canonical root icon set; investigate, document if useful, then remove or relocate"
      ;;
  esac
}

reference_classification() {
  case "$1" in
    "Angry owl face on blue backdrop.png")
      echo "non-canonical loose reference artifact"
      ;;
    "Fierce owl logo with nest.png")
      echo "obsolete duplicate of canonical marketing icon"
      ;;
    "Owlory_BlueWhite_AppIcon.app.textClipping")
      echo "obsolete generated text clipping"
      ;;
    *)
      echo "non-canonical loose reference; investigate, document if useful, then remove or relocate"
      ;;
  esac
}

[ -f "$PROJECT_FILE" ] || fail "missing Xcode project file"
[ -d "$CANONICAL" ] || fail "missing canonical AppIcon.appiconset"
[ -f "$CANONICAL/Contents.json" ] || fail "missing canonical AppIcon Contents.json"
[ -f "$CANONICAL/ios-marketing-1024.png" ] || fail "missing canonical marketing icon"
[ -f "$CANONICAL/iphone-60@3x.png" ] || fail "missing canonical iPhone 60@3x icon"

grep -q 'Assets.xcassets in Resources' "$PROJECT_FILE" || fail "Xcode project does not include Assets.xcassets in Resources"
grep -q 'ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;' "$PROJECT_FILE" || fail "Xcode project does not compile AppIcon as the app icon"

canonical_count="$(find "$CANONICAL" -maxdepth 1 -type f | wc -l | tr -d ' ')"

echo "Owlory App Icon Verification"
echo
echo "Canonical shipped asset"
echo "  Path: $(printf '%s\n' "$CANONICAL" | relative)"
echo "  Files: $canonical_count"
echo "  Xcode resources: Assets.xcassets included"
echo "  Xcode app icon name: AppIcon"

echo
echo "Supported build path"
echo "  Update the canonical AppIcon.appiconset above and let Xcode compile AppIcon."

echo
echo "Root generated folders"
folders="$(find "$ROOT" -maxdepth 1 -type d -name 'Owlory*_AppIcon*' -print | sort)"
if [ -z "$folders" ]; then
  echo "  none"
else
  for folder in $folders; do
    [ -n "$folder" ] || continue
    iconset="$folder/AppIcon.appiconset"
    label="$(printf '%s\n' "$folder" | relative)"
    if [ ! -d "$iconset" ]; then
      echo "  $label: non-canonical root folder without AppIcon.appiconset; investigate then remove or relocate"
    elif diff -qr "$CANONICAL" "$iconset" >/dev/null 2>&1; then
      echo "  $label: matches canonical but still lives at the root; remove after preserving the canonical catalog"
    else
      classification="$(folder_classification "$(basename "$folder")")"
      echo "  $label: differs from canonical; classification: $classification"
    fi
  done
fi

echo
echo "Root generated archives"
archives="$(find "$ROOT" -maxdepth 1 -type f -name '*AppIcon*.zip' -print | sort)"
if [ -z "$archives" ]; then
  echo "  none"
else
  printf '%s\n' "$archives" | while IFS= read -r archive; do
    [ -n "$archive" ] || continue
    echo "  $(printf '%s\n' "$archive" | relative): non-canonical root app-icon archive; remove or relocate after preserving any useful note"
  done
fi

echo
echo "Root loose image and clipping references"
references="$(find "$ROOT" -maxdepth 1 -type f \( -name '*.textClipping' -o -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' \) -print | sort)"
if [ -z "$references" ]; then
  echo "  none"
else
  printf '%s\n' "$references" | while IFS= read -r reference; do
    [ -n "$reference" ] || continue
    name="$(basename "$reference")"
    label="$(printf '%s\n' "$reference" | relative)"
    classification="$(reference_classification "$name")"
    echo "  $label: classification: $classification"
  done
fi

echo
echo "Policy"
echo "  The shipped app icon source of truth is the canonical asset catalog above."
echo "  The only supported build/export path is to update the canonical AppIcon.appiconset and let Xcode compile AppIcon."
echo "  Root app-icon folders are non-canonical and should be removed after preserving any useful note in docs/workflows/app-icons.md."
echo "  Loose root references are non-canonical and should be removed once the canonical path remains verified."
