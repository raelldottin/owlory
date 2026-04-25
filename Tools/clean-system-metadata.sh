#!/bin/sh
# Remove only obvious OS-generated metadata files from the workspace.

set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DRY_RUN=0

usage() {
  cat <<'EOF_USAGE'
usage:
  ./Tools/clean-system-metadata.sh [--dry-run]

Deletes only obvious system metadata files:
  .DS_Store, AppleDouble resource forks, .LSOverride, Thumbs.db,
  ehthumbs.db, and Desktop.ini.

It does not delete archives, source files, generated assets, legacy docs, or
duplicate code artifacts. Use make drift-report first when doing broader cleanup.
EOF_USAGE
}

fail() {
  echo "error: $*" >&2
  echo "why this matters: system metadata cleanup must stay narrow and repeatable." >&2
  echo "remediation: run with --help or inspect docs/workflows/drift-control.md." >&2
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
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

METADATA_PATHS="$(find "$ROOT" \
  \( -name .DS_Store \
    -o -name '._*' \
    -o -name .LSOverride \
    -o -name Thumbs.db \
    -o -name ehthumbs.db \
    -o -name Desktop.ini \) \
  -type f -print | sort)"

if [ -z "$METADATA_PATHS" ]; then
  echo "system-metadata-cleanup: no system metadata files found"
  exit 0
fi

echo "$METADATA_PATHS" | sed "s#^$ROOT/##" | sed 's/^/system-metadata-cleanup: /'

if [ "$DRY_RUN" = "1" ]; then
  echo "system-metadata-cleanup: dry run only"
  exit 0
fi

printf '%s\n' "$METADATA_PATHS" | while IFS= read -r path; do
  [ -n "$path" ] || continue
  rm -f "$path"
done

echo "system-metadata-cleanup: removed system metadata files"
