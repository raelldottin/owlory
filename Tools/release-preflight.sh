#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

cd "$ROOT"

echo "Owlory release preflight"

dirty_state="$(git status --short --untracked-files=all)"
if [[ -n "$dirty_state" ]]; then
  cat >&2 <<'EOF'
error: release preflight requires a clean working tree before Archive.

Why this exists:
  Xcode Organizer can archive local uncommitted state. A clean post-push repo is
  not enough if Archive happened before app-version or build-number metadata was
  committed.

How to fix:
  Commit the intended changes, especially project.pbxproj MARKETING_VERSION or
  CURRENT_PROJECT_VERSION bumps, or remove/stash unrelated local files. Then rerun:
    make release-preflight

Dirty paths:
EOF
  printf '%s\n' "$dirty_state" >&2
  exit 1
fi
echo "  Working tree: clean"

mirror_counts="$(git rev-list --left-right --count HEAD...@{u} 2>/dev/null)" || {
  cat >&2 <<'EOF'
error: release preflight could not compare HEAD with upstream.

Why this exists:
  A TestFlight archive must point at source history that is already available
  outside this machine.

How to fix:
  Set or restore the upstream branch, then push/pull until:
    git rev-list --left-right --count HEAD...@{u}
  prints:
    0 0
EOF
  exit 1
}

read -r ahead behind <<<"$mirror_counts"
echo "  Git mirror: $ahead $behind"
if [[ "$ahead" != "0" || "$behind" != "0" ]]; then
  cat >&2 <<EOF
error: release preflight requires HEAD to be mirrored with upstream; found '$ahead $behind'.

Why this exists:
  TestFlight provenance must be recoverable from pushed Git history, not a local
  commit that only exists on this machine.

How to fix:
  Push local commits or pull/rebase remote commits until:
    git rev-list --left-right --count HEAD...@{u}
  prints:
    0 0
EOF
  exit 1
fi

"$ROOT/Tools/verify-build-provenance.sh" --require-clean --refuse-released-version
make -C "$ROOT" build-provenance

echo "Release preflight passed."
