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

echo "Build provenance"
echo "  Version: v$MARKETING_VERSION ($BUILD_NUMBER)"
echo "  Version source: owlory_xcode/Owlory.xcodeproj/project.pbxproj"
echo "  Build number source: Xcode CURRENT_PROJECT_VERSION"
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

if [ "$REQUIRE_CLEAN" = "1" ] && [ "$WORKTREE_STATE" != "clean" ]; then
  warn "working tree has uncommitted changes"
  echo "$STATUS_LINES" | sed 's/^/  /' >&2
  fail "--require-clean needs a clean tree before archive or rollback shipment"
fi
