#!/bin/sh
# Print and validate Owlory build provenance for release and TestFlight rollback work.

set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_FILE="$ROOT/owlory_xcode/Owlory.xcodeproj/project.pbxproj"
REQUIRE_CLEAN=0
EXPECTED_BUILD=""
EXPECTED_COMMIT=""

usage() {
  cat <<'EOF_USAGE'
usage:
  ./Tools/verify-build-provenance.sh
  ./Tools/verify-build-provenance.sh --require-clean
  ./Tools/verify-build-provenance.sh --expected-build <build-number> --expected-commit <git-sha>

Options:
  --expected-build <value>   Fail if Xcode CURRENT_PROJECT_VERSION differs from a TestFlight/build value.
  --expected-commit <sha>    Fail if the current Git commit does not match the supplied short or full SHA.
  --require-clean            Fail when the working tree has uncommitted changes.
  -h, --help                 Show this help.
EOF_USAGE
}

fail() {
  echo "error: $*" >&2
  exit 1
}

warn() {
  echo "warning: $*" >&2
}

unique_values_for() {
  key="$1"
  grep -E "$key = [^;]+;" "$PROJECT_FILE" 2>/dev/null \
    | sed -E "s/.*$key = ([^;]+);.*/\1/" \
    | sort -u
}

count_nonempty_lines() {
  sed '/^$/d' | wc -l | tr -d ' '
}

first_nonempty_line() {
  sed '/^$/d' | sed -n '1p'
}

strip_dirty_suffix() {
  value="$1"
  case "$value" in
    *-dirty) printf '%s\n' "${value%-dirty}" ;;
    *) printf '%s\n' "$value" ;;
  esac
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --expected-build)
      shift
      [ "$#" -gt 0 ] || fail "--expected-build requires a value"
      EXPECTED_BUILD="$1"
      ;;
    --expected-commit)
      shift
      [ "$#" -gt 0 ] || fail "--expected-commit requires a value"
      EXPECTED_COMMIT="$(strip_dirty_suffix "$1")"
      ;;
    --require-clean)
      REQUIRE_CLEAN=1
      ;;
    -h|--help|help)
      usage
      exit 0
      ;;
    *)
      fail "unknown argument '$1'"
      ;;
  esac
  shift
done

[ -f "$PROJECT_FILE" ] || fail "missing Xcode project file at $PROJECT_FILE"

BUILD_VALUES="$(unique_values_for CURRENT_PROJECT_VERSION)"
BUILD_VALUE_COUNT="$(printf '%s\n' "$BUILD_VALUES" | count_nonempty_lines)"
[ "$BUILD_VALUE_COUNT" = "1" ] || {
  printf '%s\n' "error: expected one CURRENT_PROJECT_VERSION value, found:" >&2
  printf '%s\n' "$BUILD_VALUES" | sed '/^$/d; s/^/  - /' >&2
  exit 1
}
BUILD_NUMBER="$(printf '%s\n' "$BUILD_VALUES" | first_nonempty_line)"

VERSION_VALUES="$(unique_values_for MARKETING_VERSION)"
VERSION_VALUE_COUNT="$(printf '%s\n' "$VERSION_VALUES" | count_nonempty_lines)"
[ "$VERSION_VALUE_COUNT" = "1" ] || {
  printf '%s\n' "error: expected one MARKETING_VERSION value, found:" >&2
  printf '%s\n' "$VERSION_VALUES" | sed '/^$/d; s/^/  - /' >&2
  exit 1
}
MARKETING_VERSION="$(printf '%s\n' "$VERSION_VALUES" | first_nonempty_line)"

case "$BUILD_NUMBER" in
  ""|*[!0123456789.]*)
    fail "CURRENT_PROJECT_VERSION must contain only digits and periods for TestFlight; found '$BUILD_NUMBER'"
    ;;
esac

BUILD_NUMBER_LENGTH=${#BUILD_NUMBER}
[ "$BUILD_NUMBER_LENGTH" -le 18 ] || fail "CURRENT_PROJECT_VERSION '$BUILD_NUMBER' is longer than App Store Connect's 18-character limit"

command -v git >/dev/null 2>&1 || fail "git is required to inspect build provenance"
GIT_ROOT="$(git -C "$ROOT" rev-parse --show-toplevel 2>/dev/null)" || fail "not inside a Git repository"
HEAD_FULL="$(git -C "$GIT_ROOT" rev-parse HEAD 2>/dev/null)" || fail "could not read current Git commit"
HEAD_SHORT="$(git -C "$GIT_ROOT" rev-parse --short=12 HEAD 2>/dev/null)" || fail "could not read short Git commit"
BRANCH="$(git -C "$GIT_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || printf 'unknown')"
DESCRIBE="$(git -C "$GIT_ROOT" describe --tags --always --dirty 2>/dev/null || printf '%s' "$HEAD_SHORT")"
STATUS_LINES="$(git -C "$GIT_ROOT" status --porcelain 2>/dev/null)"

if [ -n "$STATUS_LINES" ]; then
  WORKTREE_STATE="dirty"
  RELEASEABLE="no"
else
  WORKTREE_STATE="clean"
  RELEASEABLE="yes"
fi

PROJECT_FILE_REL="owlory_xcode/Owlory.xcodeproj/project.pbxproj"
COMMITTED_PBXPROJ="$(git -C "$GIT_ROOT" show "HEAD:$PROJECT_FILE_REL" 2>/dev/null || printf '')"
COMMITTED_BUILD_NUMBER=""
COMMITTED_MARKETING_VERSION=""
if [ -n "$COMMITTED_PBXPROJ" ]; then
  COMMITTED_BUILD_VALUES="$(printf '%s\n' "$COMMITTED_PBXPROJ" \
    | grep -E "CURRENT_PROJECT_VERSION = [^;]+;" \
    | sed -E "s/.*CURRENT_PROJECT_VERSION = ([^;]+);.*/\1/" \
    | sort -u)"
  COMMITTED_BUILD_VALUE_COUNT="$(printf '%s\n' "$COMMITTED_BUILD_VALUES" | count_nonempty_lines)"
  if [ "$COMMITTED_BUILD_VALUE_COUNT" = "1" ]; then
    COMMITTED_BUILD_NUMBER="$(printf '%s\n' "$COMMITTED_BUILD_VALUES" | first_nonempty_line)"
    if [ "$BUILD_NUMBER" = "$COMMITTED_BUILD_NUMBER" ]; then
      COMMITTED_BUILD_STATE="matches HEAD"
    else
      COMMITTED_BUILD_STATE="differs from HEAD (HEAD has $COMMITTED_BUILD_NUMBER)"
    fi
  else
    COMMITTED_BUILD_STATE="unverifiable (HEAD pbxproj has $COMMITTED_BUILD_VALUE_COUNT distinct CURRENT_PROJECT_VERSION values)"
  fi

  COMMITTED_MARKETING_VALUES="$(printf '%s\n' "$COMMITTED_PBXPROJ" \
    | grep -E "MARKETING_VERSION = [^;]+;" \
    | sed -E "s/.*MARKETING_VERSION = ([^;]+);.*/\1/" \
    | sort -u)"
  COMMITTED_MARKETING_VALUE_COUNT="$(printf '%s\n' "$COMMITTED_MARKETING_VALUES" | count_nonempty_lines)"
  if [ "$COMMITTED_MARKETING_VALUE_COUNT" = "1" ]; then
    COMMITTED_MARKETING_VERSION="$(printf '%s\n' "$COMMITTED_MARKETING_VALUES" | first_nonempty_line)"
    if [ "$MARKETING_VERSION" = "$COMMITTED_MARKETING_VERSION" ]; then
      COMMITTED_MARKETING_STATE="matches HEAD"
    else
      COMMITTED_MARKETING_STATE="differs from HEAD (HEAD has $COMMITTED_MARKETING_VERSION)"
    fi
  else
    COMMITTED_MARKETING_STATE="unverifiable (HEAD pbxproj has $COMMITTED_MARKETING_VALUE_COUNT distinct MARKETING_VERSION values)"
  fi
else
  COMMITTED_BUILD_STATE="unverifiable (no pbxproj at HEAD for $PROJECT_FILE_REL)"
  COMMITTED_MARKETING_STATE="unverifiable (no pbxproj at HEAD for $PROJECT_FILE_REL)"
fi

echo "Build provenance"
echo "  Version: v$MARKETING_VERSION ($BUILD_NUMBER)"
echo "  Version source: owlory_xcode/Owlory.xcodeproj/project.pbxproj"
echo "  Committed marketing version: $COMMITTED_MARKETING_STATE"
echo "  Build number source: Xcode CURRENT_PROJECT_VERSION"
echo "  Committed build number: $COMMITTED_BUILD_STATE"
echo "  Git commit: $HEAD_SHORT"
echo "  Git commit full: $HEAD_FULL"
echo "  Git branch: $BRANCH"
echo "  Git describe: $DESCRIBE"
echo "  Working tree: $WORKTREE_STATE"
echo "  Rollback checkout: git checkout $HEAD_FULL"
echo "  Releaseable: $RELEASEABLE"

if [ -n "$EXPECTED_BUILD" ]; then
  if [ "$EXPECTED_BUILD" = "$BUILD_NUMBER" ]; then
    echo "  Expected build: matched $EXPECTED_BUILD"
  else
    fail "expected build '$EXPECTED_BUILD' but Xcode CURRENT_PROJECT_VERSION is '$BUILD_NUMBER'"
  fi
fi

if [ -n "$EXPECTED_COMMIT" ]; then
  COMMIT_MATCH=0
  case "$HEAD_FULL" in
    "$EXPECTED_COMMIT"*) COMMIT_MATCH=1 ;;
  esac
  case "$HEAD_SHORT" in
    "$EXPECTED_COMMIT"*) COMMIT_MATCH=1 ;;
  esac

  if [ "$COMMIT_MATCH" = "1" ]; then
    echo "  Expected commit: matched $EXPECTED_COMMIT"
  else
    fail "expected commit '$EXPECTED_COMMIT' but current commit is '$HEAD_FULL'"
  fi
fi

if [ "$REQUIRE_CLEAN" = "1" ]; then
  REQUIRE_CLEAN_FAILED=0
  if [ "$WORKTREE_STATE" != "clean" ]; then
    warn "working tree has uncommitted changes"
    echo "$STATUS_LINES" | sed 's/^/  /' >&2
    echo "error: --require-clean needs a clean tree before archive or rollback shipment" >&2
    REQUIRE_CLEAN_FAILED=1
  fi
  if [ -n "$COMMITTED_BUILD_NUMBER" ] && [ "$BUILD_NUMBER" != "$COMMITTED_BUILD_NUMBER" ]; then
    echo "error: pbxproj CURRENT_PROJECT_VERSION '$BUILD_NUMBER' is not committed at HEAD (HEAD has '$COMMITTED_BUILD_NUMBER'); commit the build-number bump before re-running the verifier" >&2
    REQUIRE_CLEAN_FAILED=1
  fi
  if [ -n "$COMMITTED_MARKETING_VERSION" ] && [ "$MARKETING_VERSION" != "$COMMITTED_MARKETING_VERSION" ]; then
    echo "error: pbxproj MARKETING_VERSION '$MARKETING_VERSION' is not committed at HEAD (HEAD has '$COMMITTED_MARKETING_VERSION'); commit the app-version bump before re-running the verifier" >&2
    REQUIRE_CLEAN_FAILED=1
  fi
  if git -C "$GIT_ROOT" rev-parse --verify --quiet "refs/tags/v$MARKETING_VERSION" >/dev/null; then
    TAG_COMMIT="$(git -C "$GIT_ROOT" rev-parse "v$MARKETING_VERSION^{commit}" 2>/dev/null || printf '')"
    if [ -n "$TAG_COMMIT" ] && [ "$TAG_COMMIT" != "$HEAD_FULL" ]; then
      echo "error: MARKETING_VERSION '$MARKETING_VERSION' is already tagged as 'v$MARKETING_VERSION' at $TAG_COMMIT" >&2
      echo "error: App Store Connect closes a version's pre-release train once it is approved and rejects re-uploads with CFBundleShortVersionString == prior version" >&2
      echo "error: bump the version with ./Tools/bump-version.sh <major|minor|patch> before archiving a new build" >&2
      REQUIRE_CLEAN_FAILED=1
    fi
  fi
  [ "$REQUIRE_CLEAN_FAILED" = "0" ] || exit 1
fi
