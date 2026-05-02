#!/bin/sh
# generate-build-info.sh
#
# Runs as a PBXShellScriptBuildPhase after the Owlory target's Info.plist has
# been processed. Stamps the built Info.plist with:
#
#   GitCommit             -> short SHA (+ "-dirty" if the working tree is dirty)
#   GitCommitFull         -> full SHA (+ "-dirty" if the working tree is dirty)
#   GitBranch             -> current branch name
#   GitTag                -> exact tag or nearest describe output
#   BuildDate             -> ISO 8601 UTC timestamp of this build
#   BuildConfiguration    -> Debug / Release / ... (matches $CONFIGURATION)
#   BuildNumberSource     -> where CFBundleVersion came from
#
# These keys let any installed build be mapped back to an exact source revision,
# which is the prerequisite for safe rollback and actionable bug reports.
#
# Required environment (provided by Xcode): TARGET_BUILD_DIR, INFOPLIST_PATH,
# SRCROOT, CONFIGURATION. The script exits 0 (with a warning) if the plist or
# git metadata is unavailable — builds must not fail because of stamping.

set -e

PB=/usr/libexec/PlistBuddy
PLIST="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
if [ ! -f "$PLIST" ]; then
  echo "warning: Info.plist not found at '$PLIST' — skipping build-info stamping."
  exit 0
fi

# Locate the git root. The Xcode project lives in owlory_xcode/, the git repo
# lives one level up. Using `git rev-parse --show-toplevel` makes this robust
# against future directory reshuffling. We then ask git to resolve the
# repository's gitdir; this works for normal checkouts AND worktrees (where
# `.git` is a file pointer, not a directory) AND submodules. A plain `[ -d ]`
# test would reject worktrees and stamp no-git fallback values.
GIT_ROOT="$(cd "$SRCROOT" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null || true)"

if [ -n "$GIT_ROOT" ] && git -C "$GIT_ROOT" rev-parse --git-dir > /dev/null 2>&1; then
  GIT_COMMIT="$(git -C "$GIT_ROOT" rev-parse --short=12 HEAD 2>/dev/null || echo unknown)"
  GIT_COMMIT_FULL="$(git -C "$GIT_ROOT" rev-parse HEAD 2>/dev/null || echo unknown)"
  GIT_BRANCH="$(git -C "$GIT_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo detached)"
  GIT_TAG="$(git -C "$GIT_ROOT" describe --tags --exact-match HEAD 2>/dev/null || git -C "$GIT_ROOT" describe --tags --always --dirty --long 2>/dev/null || echo untagged)"
  GIT_STATUS="clean"
  if [ -n "$(git -C "$GIT_ROOT" status --porcelain 2>/dev/null)" ]; then
    GIT_STATUS="dirty"
    GIT_COMMIT="${GIT_COMMIT}-dirty"
    GIT_COMMIT_FULL="${GIT_COMMIT_FULL}-dirty"
  fi
else
  echo "warning: no git repo detected for SRCROOT=$SRCROOT — stamping fallback values."
  GIT_COMMIT="no-git"
  GIT_COMMIT_FULL="no-git"
  GIT_BRANCH="no-git"
  GIT_TAG="no-git"
  GIT_STATUS="unknown"
fi

BUILD_NUMBER="$("$PB" -c "Print :CFBundleVersion" "$PLIST" 2>/dev/null || echo "${CURRENT_PROJECT_VERSION:-}")"
BUILD_NUMBER_SOURCE="Xcode CURRENT_PROJECT_VERSION"

BUILD_DATE="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

set_or_add() {
  key="$1"
  value="$2"
  if ! "$PB" -c "Set :$key $value" "$PLIST" 2>/dev/null; then
    "$PB" -c "Add :$key string $value" "$PLIST"
  fi
}

if [ -z "$BUILD_NUMBER" ]; then
  BUILD_NUMBER="1"
  BUILD_NUMBER_SOURCE="fallback"
  set_or_add "CFBundleVersion" "$BUILD_NUMBER"
fi

set_or_add "GitCommit"           "$GIT_COMMIT"
set_or_add "GitCommitFull"       "$GIT_COMMIT_FULL"
set_or_add "GitBranch"           "$GIT_BRANCH"
set_or_add "GitTag"              "$GIT_TAG"
set_or_add "GitStatus"           "$GIT_STATUS"
set_or_add "BuildDate"           "$BUILD_DATE"
set_or_add "BuildConfiguration"  "$CONFIGURATION"
set_or_add "BuildNumberSource"   "$BUILD_NUMBER_SOURCE"

VERSION="$("$PB" -c "Print :CFBundleShortVersionString" "$PLIST" 2>/dev/null || echo unknown)"
echo "Owlory build stamp: v${VERSION} (${BUILD_NUMBER}) · ${GIT_COMMIT} · ${GIT_BRANCH} · ${GIT_TAG} · ${BUILD_DATE} · ${CONFIGURATION}"
