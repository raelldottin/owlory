#!/bin/sh
# Read-only report for root clutter, legacy docs, and cleanup candidates.

set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIMIT=80

usage() {
  cat <<'EOF_USAGE'
usage:
  ./Tools/drift-report.sh [--limit <paths-per-category>]

Prints a read-only drift-control report. It classifies root clutter, generated
asset archives, historical docs, duplicate source/test artifacts, and likely
cleanup candidates. It never deletes, moves, stages, or rewrites files.

Approved remediation lives in docs/workflows/drift-control.md.
EOF_USAGE
}

fail() {
  echo "error: $*" >&2
  echo "remediation: rerun with --help, or use make drift-report for the default report." >&2
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

relative_paths() {
  sed "s#^$ROOT/##"
}

count_paths() {
  sed '/^$/d' | wc -l | tr -d ' '
}

print_category() {
  title="$1"
  rule="$2"
  remediation="$3"
  paths="$4"

  count="$(printf '%s\n' "$paths" | count_paths)"

  echo
  echo "$title"
  echo "  Count: $count"
  echo "  Why it matters: $rule"
  echo "  Approved remediation: $remediation"

  if [ "$count" -eq 0 ]; then
    echo "  Paths: none found"
    return
  fi

  echo "  Paths:"
  printf '%s\n' "$paths" | sed '/^$/d' | sed -n "1,${LIMIT}p" | sed 's/^/    - /'
  if [ "$count" -gt "$LIMIT" ]; then
    remaining=$((count - LIMIT))
    echo "    ... $remaining more path(s). Rerun with --limit $count for the full category."
  fi
}

find_root() {
  find "$ROOT" -maxdepth 1 "$@" -print 2>/dev/null | sort | relative_paths
}

find_any() {
  find "$ROOT" "$@" -print 2>/dev/null | sort | relative_paths
}

paths_if_exists() {
  for path in "$@"; do
    if [ -e "$ROOT/$path" ]; then
      printf '%s\n' "$path"
    fi
  done | sort
}

system_noise="$(find_any \( -name .DS_Store -o -name '._*' -o -name .AppleDouble -o -name .LSOverride -o -name Thumbs.db -o -name ehthumbs.db -o -name Desktop.ini \))"
root_asset_archives="$(find_root \( -name '*AppIcon*.zip' -o -name '*.textClipping' \))"
root_asset_folders="$(find_root -type d \( -name 'Owlory*_AppIcon*' -o -name '*AppIcon.appiconset' \))"
root_reference_images="$(find_root -type f \( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' \))"
legacy_docs="$(paths_if_exists PROJECT_SPEC.md LESSONS_FROM_GYMPHANT.md SKILL.md)"
legacy_xcode_docs="$(find "$ROOT/owlory_xcode/Docs" -maxdepth 1 -type f -name '*.md' -print 2>/dev/null | sort | relative_paths)"
duplicate_or_archived_code="$(paths_if_exists trajectory_xcode OwloryCoreTests owlory_xcode.zip owlory_xcode_v2.zip owlory_xcode_v3.zip)"

if command -v git >/dev/null 2>&1 && git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git_noise="$(git -C "$ROOT" status --short | sed -n '1,200p')"
else
  git_noise=""
fi

echo "Owlory Drift-Control Report"
echo
echo "Purpose"
echo "  Classify repo clutter before cleanup. This report is read-only."
echo "  Do not delete or move candidates until docs/workflows/drift-control.md has been followed."

print_category \
  "System Metadata Noise" \
  "OS metadata obscures real source changes and should not be part of repo history." \
  "Run make clean-system-metadata for this category only. Do not mix metadata cleanup with asset, archive, docs, or code cleanup." \
  "$system_noise"

print_category \
  "Generated Asset Archives" \
  "Root icon zips and text clippings make discovery noisy and can be mistaken for source of truth." \
  "For app icons, run make verify-app-icons and read docs/workflows/app-icons.md. Treat root app-icon archives and clippings as non-canonical and remove them after preserving any useful note in docs." \
  "$root_asset_archives"

print_category \
  "Generated Asset Folders" \
  "Root asset folders duplicate generated icon work outside the app asset catalog." \
  "For app icons, run make verify-app-icons and read docs/workflows/app-icons.md. Keep one canonical icon source path and remove root-level non-canonical icon bundles after preserving any useful note in docs." \
  "$root_asset_folders"

print_category \
  "Root Reference Images" \
  "Loose images at the root lack ownership and can be confused with shipped assets." \
  "For app-icon-related images, run make verify-app-icons and read docs/workflows/app-icons.md. Treat loose root images as non-canonical unless a maintained doc gives them an active owner and location." \
  "$root_reference_images"

print_category \
  "Historical Root Docs" \
  "Root docs outside the progressive docs tree may duplicate or contradict docs/." \
  "Follow docs/workflows/historical-docs.md. Promote useful content into docs/ first; remove only docs classified as superseded or obsolete." \
  "$legacy_docs"

print_category \
  "Legacy Xcode Docs" \
  "owlory_xcode/Docs is historical context; future agents should rely on root docs unless content has been promoted." \
  "Follow docs/workflows/legacy-xcode-docs.md. Promote useful content into root docs before removing a legacy copy; do not edit product behavior while moving docs." \
  "$legacy_xcode_docs"

print_category \
  "Duplicate Or Archived Code Artifacts" \
  "Old project zips, duplicate test roots, and legacy source trees make search results ambiguous." \
  "Follow docs/workflows/archived-code-artifacts.md. Promote still-useful material first; remove only artifacts classified as superseded or inactive." \
  "$duplicate_or_archived_code"

print_category \
  "Current Git Status Noise" \
  "Dirty and untracked paths may be user work, generated output, or cleanup candidates; agents must not revert unrelated changes." \
  "Use this as a triage list only. Preserve unrelated user changes, and clean only paths intentionally covered by the current task." \
  "$git_noise"

echo
echo "Next Safe Step"
echo "  Read docs/workflows/drift-control.md, then choose one cleanup class. Keep cleanup patches small and run make architecture plus any affected validation."
