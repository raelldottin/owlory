#!/bin/sh
# bump-version.sh <major|minor|patch>
#
# Bumps the MARKETING_VERSION (CFBundleShortVersionString) in project.pbxproj
# according to SemVer, bumps CURRENT_PROJECT_VERSION to a rollback-safe UTC
# timestamp, then moves the CHANGELOG "[Unreleased]" section to a new versioned
# section dated today.
#
# Intended workflow:
#   1. ./Tools/bump-version.sh minor
#   2. Review CHANGELOG.md, stage changes.
#   3. git commit -m "Release v0.3.0"
#   4. git tag v0.3.0
#   5. Archive in Xcode — the committed CURRENT_PROJECT_VERSION is the
#      TestFlight build number.

set -e

if [ "$#" -ne 1 ]; then
  echo "usage: $0 <major|minor|patch>" >&2
  exit 1
fi

BUMP="$1"
case "$BUMP" in
  major|minor|patch) ;;
  *) echo "error: bump type must be 'major', 'minor', or 'patch' (got '$BUMP')" >&2; exit 1 ;;
esac

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PBXPROJ="$REPO_ROOT/owlory_xcode/Owlory.xcodeproj/project.pbxproj"
CHANGELOG="$REPO_ROOT/CHANGELOG.md"

if [ ! -f "$PBXPROJ" ]; then
  echo "error: project.pbxproj not found at $PBXPROJ" >&2
  exit 1
fi

if [ ! -f "$CHANGELOG" ]; then
  echo "error: CHANGELOG.md not found at $CHANGELOG" >&2
  echo "error: refusing to update MARKETING_VERSION or CURRENT_PROJECT_VERSION without changelog release notes." >&2
  exit 1
fi

if ! grep -q '^## \[Unreleased\]' "$CHANGELOG"; then
  echo "error: CHANGELOG.md must contain a '## [Unreleased]' section before bumping MARKETING_VERSION." >&2
  echo "error: refusing to update MARKETING_VERSION or CURRENT_PROJECT_VERSION without a promotable changelog section." >&2
  exit 1
fi

CURRENT="$(grep -m1 -E 'MARKETING_VERSION = [0-9]+\.[0-9]+\.[0-9]+;' "$PBXPROJ" | sed -E 's/.*MARKETING_VERSION = ([0-9]+\.[0-9]+\.[0-9]+);.*/\1/')"
if [ -z "$CURRENT" ]; then
  echo "error: could not parse current MARKETING_VERSION from pbxproj" >&2
  exit 1
fi

MAJOR="$(echo "$CURRENT" | cut -d. -f1)"
MINOR="$(echo "$CURRENT" | cut -d. -f2)"
PATCH="$(echo "$CURRENT" | cut -d. -f3)"

case "$BUMP" in
  major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
  minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
  patch) PATCH=$((PATCH + 1)) ;;
esac

NEW="${MAJOR}.${MINOR}.${PATCH}"
TODAY="$(date -u +"%Y-%m-%d")"

echo "Bumping MARKETING_VERSION: $CURRENT -> $NEW"

# Replace every MARKETING_VERSION = X.Y.Z; line (both Debug and Release configs
# for every target in the workspace, so versions stay synchronized).
/usr/bin/sed -i '' -E "s/MARKETING_VERSION = [0-9]+\\.[0-9]+\\.[0-9]+;/MARKETING_VERSION = ${NEW};/g" "$PBXPROJ"

"$REPO_ROOT/Tools/set-build-number.sh" --auto

echo "Promoting [Unreleased] -> [$NEW] in CHANGELOG.md"
TMP="$(mktemp)"
/usr/bin/awk -v new="$NEW" -v today="$TODAY" '
  BEGIN { promoted = 0 }
  /^## \[Unreleased\]/ && !promoted {
    print "## [Unreleased]"
    print ""
    print "### Added"
    print ""
    print "### Changed"
    print ""
    print "### Fixed"
    print ""
    print "### Localization"
    print ""
    print "### Release And Validation"
    print ""
    print "## [" new "] - " today
    promoted = 1
    next
  }
  { print }
' "$CHANGELOG" > "$TMP"
mv "$TMP" "$CHANGELOG"

echo ""
echo "Done. Next steps:"
echo "  1. Review CHANGELOG.md and fill in the [${NEW}] section."
echo "  2. git add owlory_xcode/Owlory.xcodeproj/project.pbxproj CHANGELOG.md"
echo "  3. git commit -m \"Release v${NEW}\""
echo "  4. git tag v${NEW}"
echo "  5. Archive in Xcode — the committed CURRENT_PROJECT_VERSION is the TestFlight build number."
