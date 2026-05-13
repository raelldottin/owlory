#!/bin/sh
# Print a compact, read-only handoff for agents resuming work in Owlory.

set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIMIT=80

usage() {
  cat <<'EOF_USAGE'
usage:
  ./Tools/agent-handoff.sh [--limit <status-lines>]

Prints a read-only repo handoff:
  - current Git identity
  - dirty workspace summary
  - recent SecondBrain entries
  - minimum read order
  - validation commands

Use this after context compaction, when taking over a dirty workspace, or before
writing a final handoff.
EOF_USAGE
}

fail() {
  echo "error: $*" >&2
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --limit)
      shift
      [ "$#" -gt 0 ] || fail "--limit requires a number"
      LIMIT="$1"
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

case "$LIMIT" in
  ''|*[!0123456789]*)
    fail "--limit must be a positive integer"
    ;;
esac

cd "$ROOT" || exit 1

echo "Owlory Agent Handoff"
echo

echo "Repository"
echo "  Root: $ROOT"
if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || printf 'unknown')"
  HEAD_SHORT="$(git rev-parse --short=12 HEAD 2>/dev/null || printf 'unknown')"
  HEAD_FULL="$(git rev-parse HEAD 2>/dev/null || printf 'unknown')"
  echo "  Branch: $BRANCH"
  echo "  HEAD: $HEAD_SHORT ($HEAD_FULL)"
else
  echo "  Git: unavailable"
fi

echo
echo "Minimum Read Order"
echo "  1. AGENTS.md"
echo "  2. docs/README.md"
echo "  3. docs/repo-map.md"
echo "  4. docs/product/domain-index.md"
echo "  5. docs/workflows/validation.md"
echo "  6. The domain/workflow doc for the current task"

echo
echo "Validation Shortcuts"
echo "  make handoff"
echo "  make clean-stop"
echo "  make drift-report"
echo "  make review-preflight"
echo "  make architecture"
echo "  make test-domain DOMAIN=<today|train|write|career|home|patterns|reminders|runtime|voice>"
echo "  make fast"
echo "  make verify"
echo "  make build-provenance"

echo
echo "Dirty Workspace"
if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  STATUS="$(git status --short)"
  STATUS_COUNT="$(printf '%s\n' "$STATUS" | sed '/^$/d' | wc -l | tr -d ' ')"
  echo "  Changed paths: $STATUS_COUNT"
  if [ "$STATUS_COUNT" -gt 0 ]; then
    printf '%s\n' "$STATUS" | sed '/^$/d' | sed -n "1,${LIMIT}p" | sed 's/^/  /'
    if [ "$STATUS_COUNT" -gt "$LIMIT" ]; then
      REMAINING=$((STATUS_COUNT - LIMIT))
      echo "  ... $REMAINING more path(s). Rerun with --limit $STATUS_COUNT for the full list."
    fi
  fi
else
  echo "  Git status unavailable."
fi

echo
echo "Recent SecondBrain Entries"
if [ -f "$ROOT/SecondBrain/INDEX.md" ]; then
  sed -n '5,10p' "$ROOT/SecondBrain/INDEX.md" | sed 's/^/  /'
else
  echo "  No SecondBrain/INDEX.md found."
fi

echo
echo "Handoff Rule"
echo "  Log every prompt in SecondBrain, run the narrowest honest validation, and report residual risk explicitly."
