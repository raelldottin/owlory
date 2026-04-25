#!/bin/sh
# set-build-number.sh [--auto|<build-number>]
#
# Updates every CURRENT_PROJECT_VERSION in the Xcode project so the build
# number Xcode shows, TestFlight receives, and Owlory reports all agree.
#
# Rollback workflow:
#   1. git checkout <known-good-commit>
#   2. ./Tools/set-build-number.sh --auto
#   3. git commit -am "Release rollback build <build-number>"
#   4. Archive in Xcode and upload to TestFlight.
#
# `--auto` uses a UTC timestamp (yyyyMMddHHmmss). That stays monotonic even
# when the source commit moves backward during a rollback.

set -e

usage() {
  echo "usage: $0 [--auto|<build-number>]" >&2
  echo "example: $0 --auto" >&2
  echo "example: $0 20260417081904" >&2
}

if [ "$#" -gt 1 ]; then
  usage
  exit 1
fi

if [ "$#" -eq 0 ] || [ "$1" = "--auto" ]; then
  BUILD_NUMBER="$(date -u +"%Y%m%d%H%M%S")"
elif [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  usage
  exit 0
else
  BUILD_NUMBER="$1"
fi

case "$BUILD_NUMBER" in
  ""|*[!0-9.]*)
    echo "error: build number must contain only digits and periods (got '$BUILD_NUMBER')" >&2
    exit 1
    ;;
esac

if [ "${#BUILD_NUMBER}" -gt 18 ]; then
  echo "error: build number must be 18 characters or fewer for App Store Connect (got ${#BUILD_NUMBER})" >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PBXPROJ="$REPO_ROOT/owlory_xcode/Owlory.xcodeproj/project.pbxproj"

if [ ! -f "$PBXPROJ" ]; then
  echo "error: project.pbxproj not found at $PBXPROJ" >&2
  exit 1
fi

MARKETING_VERSION="$(grep -m1 -E 'MARKETING_VERSION = [0-9]+\.[0-9]+\.[0-9]+;' "$PBXPROJ" | sed -E 's/.*MARKETING_VERSION = ([0-9]+\.[0-9]+\.[0-9]+);.*/\1/')"
if [ -z "$MARKETING_VERSION" ]; then
  MARKETING_VERSION="unknown"
fi

export BUILD_NUMBER
/usr/bin/perl -0pi -e 's/CURRENT_PROJECT_VERSION = [^;]+;/CURRENT_PROJECT_VERSION = $ENV{BUILD_NUMBER};/g' "$PBXPROJ"

echo "Set CURRENT_PROJECT_VERSION to $BUILD_NUMBER for Owlory $MARKETING_VERSION."
echo "Next: commit owlory_xcode/Owlory.xcodeproj/project.pbxproj before archiving."
