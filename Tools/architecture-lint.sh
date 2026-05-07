#!/bin/sh
# Structural checks for Owlory's agent-legible repository rules.

set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ERRORS="$(mktemp "${TMPDIR:-/tmp}/owlory-architecture-lint.XXXXXX")"
trap 'rm -f "$ERRORS" /tmp/owlory-architecture-lint-match.$$' EXIT

fail() {
  printf '%s\n' "architecture-lint: $1" >&2
  printf '%s\n' "$1" >> "$ERRORS"
}

require_file() {
  if [ ! -f "$ROOT/$1" ]; then
    fail "missing required file '$1'. Add it or update docs/README.md if ownership moved."
  fi
}

require_dir() {
  if [ ! -d "$ROOT/$1" ]; then
    fail "missing required directory '$1'. Keep root docs organized by progressive disclosure."
  fi
}

require_dir "docs/architecture"
require_dir "docs/product"
require_dir "docs/runtime"
require_dir "docs/workflows"
require_dir "docs/decisions"

require_file "AGENTS.md"
require_file "README.md"
require_file "docs/README.md"
require_file "docs/golden-principles.md"
require_file "docs/repo-map.md"
require_file "docs/architecture/boundaries.md"
require_file "docs/product/domain-index.md"
require_file "docs/runtime/ml-model-posture.md"
require_file "docs/runtime/ml-privacy.md"
require_file "docs/workflows/agent-handoff.md"
require_file "docs/workflows/app-icons.md"
require_file "docs/workflows/drift-control.md"
require_file "docs/workflows/historical-docs.md"
require_file "docs/workflows/legacy-xcode-docs.md"
require_file "docs/workflows/ml-qa.md"
require_file "docs/workflows/performance-observability.md"
require_file "docs/workflows/pr-hygiene.md"
require_file "docs/workflows/review.md"
require_file "docs/workflows/roadmap-status.md"
require_file "docs/workflows/ui-testing-hygiene.md"
require_file "docs/workflows/validation.md"
require_file "Tools/localization-parity.sh"

for domain_doc in \
  docs/product/domains/today.md \
  docs/product/domains/train.md \
  docs/product/domains/write.md \
  docs/product/domains/career.md \
  docs/product/domains/home.md \
  docs/product/domains/patterns.md \
  docs/product/domains/reminders.md \
  docs/product/domains/app-runtime.md
do
  require_file "$domain_doc"
done

if [ -f "$ROOT/AGENTS.md" ]; then
  AGENTS_LINES="$(wc -l < "$ROOT/AGENTS.md" | tr -d ' ')"
  if [ "$AGENTS_LINES" -gt 80 ]; then
    fail "AGENTS.md is $AGENTS_LINES lines. Keep it as a short map and move details into docs/."
  fi
fi

if [ -f "$ROOT/CLAUDE.md" ]; then
  CLAUDE_LINES="$(wc -l < "$ROOT/CLAUDE.md" | tr -d ' ')"
  if [ "$CLAUDE_LINES" -gt 40 ]; then
    fail "CLAUDE.md is $CLAUDE_LINES lines. Keep it as a short compatibility pointer to AGENTS.md and docs/README.md; move durable guidance into docs/."
  fi
  if ! grep -q 'AGENTS.md' "$ROOT/CLAUDE.md" || ! grep -q 'docs/README.md' "$ROOT/CLAUDE.md"; then
    fail "CLAUDE.md should point agents to AGENTS.md and docs/README.md. This prevents a second root instruction source from drifting."
  fi
fi

if [ -f "$ROOT/Makefile" ] && ! grep -Eq '^handoff:' "$ROOT/Makefile"; then
  fail "Makefile is missing a 'handoff' target. Add one that runs Tools/agent-handoff.sh so agents can resume without hidden chat context."
fi

if [ -f "$ROOT/Makefile" ] && ! grep -Eq '^drift-report:' "$ROOT/Makefile"; then
  fail "Makefile is missing a 'drift-report' target. Add one that runs Tools/drift-report.sh so cleanup starts with a read-only triage report."
fi

if [ -f "$ROOT/Makefile" ] && ! grep -Eq '^review-preflight:' "$ROOT/Makefile"; then
  fail "Makefile is missing a 'review-preflight' target. Add one that runs Tools/review-preflight.sh so reviewers can infer touched areas and validation without hidden chat context."
fi

if [ -f "$ROOT/Makefile" ] && ! grep -Eq '^clean-system-metadata:' "$ROOT/Makefile"; then
  fail "Makefile is missing a 'clean-system-metadata' target. Add one that runs Tools/clean-system-metadata.sh so OS metadata cleanup is repeatable and scoped."
fi

if [ -f "$ROOT/Makefile" ] && ! grep -Eq '^verify-app-icons:' "$ROOT/Makefile"; then
  fail "Makefile is missing a 'verify-app-icons' target. Add one that runs Tools/verify-app-icons.sh before app-icon archive or folder cleanup."
fi

if [ -f "$ROOT/Makefile" ] && ! grep -Eq '^localization-check:' "$ROOT/Makefile"; then
  fail "Makefile is missing a 'localization-check' target. Add one that runs Tools/localization-parity.sh so localization key drift is caught before build handoff."
fi

for ignored_metadata in .DS_Store '._*' .AppleDouble .LSOverride Thumbs.db ehthumbs.db Desktop.ini; do
  if [ -f "$ROOT/.gitignore" ] && ! grep -Fxq "$ignored_metadata" "$ROOT/.gitignore"; then
    fail ".gitignore does not ignore '$ignored_metadata'. System metadata obscures real source changes; add the pattern under the system metadata section and see docs/workflows/drift-control.md."
  fi
done

check_domain_imports() {
  find "$ROOT/owlory_xcode/Owlory/Core/Domain" -name '*.swift' -type f | while IFS= read -r file; do
    while IFS= read -r line; do
      module="${line#import }"
      [ -z "$module" ] && continue
      case "$module" in
        Foundation)
          ;;
        ActivityKit)
          fail "Core/Domain must not import ActivityKit. Move '$file' runtime coupling to Core/Application or OwloryWidgets."
          ;;
        *)
          fail "forbidden Core/Domain import '$module' in ${file#$ROOT/}. Domain rules must stay pure; move UI/framework work outward."
          ;;
      esac
    done <<EOF_IMPORTS
$(grep -E '^import ' "$file" || true)
EOF_IMPORTS

    if grep -nE '(@Published|ObservableObject|FileManager|UserDefaults|URLSession|UNUserNotificationCenter|AVAudio|SFSpeech|SwiftUI|UIKit|AppKit|Combine)' "$file" >/tmp/owlory-architecture-lint-match.$$ 2>/dev/null; then
      match="$(head -1 /tmp/owlory-architecture-lint-match.$$)"
      fail "Core/Domain contains framework/runtime coupling at ${file#$ROOT/}:$match. Put product rules in Domain and adapters in Application/Infrastructure."
    fi
    rm -f /tmp/owlory-architecture-lint-match.$$
  done
}

check_feature_runtime_coupling() {
  find "$ROOT/owlory_xcode/Owlory/Features" -name '*.swift' -type f | while IFS= read -r file; do
    if grep -nE '(FileManager|UserDefaults|UNUserNotificationCenter|AVAudioRecorder|SFSpeechRecognizer|FileItemListRepository)' "$file" >/tmp/owlory-architecture-lint-match.$$ 2>/dev/null; then
      match="$(head -1 /tmp/owlory-architecture-lint-match.$$)"
      fail "Feature file has direct persistence/runtime coupling at ${file#$ROOT/}:$match. Route through a store or infrastructure adapter."
    fi
    rm -f /tmp/owlory-architecture-lint-match.$$
  done
}

check_today_focus_surface_contract() {
  today_view="$ROOT/owlory_xcode/Owlory/Features/Today/TodayView.swift"
  [ -f "$today_view" ] || return 0
  if grep -nE '(focusPlanSection|focusPlanRow|Mark Focus items done here)' "$today_view" >/tmp/owlory-architecture-lint-match.$$ 2>/dev/null; then
    match="$(head -1 /tmp/owlory-architecture-lint-match.$$)"
    fail "Today must not reintroduce a standalone Focus dashboard section at ${today_view#$ROOT/}:$match. Focus work and Focus status actions belong in Continue."
  fi
  rm -f /tmp/owlory-architecture-lint-match.$$
}

check_domain_imports
check_feature_runtime_coupling
check_today_focus_surface_contract

"$ROOT/Tools/localization-parity.sh" >/dev/null || fail "localization parity failed. Run 'make localization-check' for locale/key packaging remediation."

FAILURES="$(wc -l < "$ERRORS" | tr -d ' ')"
if [ "$FAILURES" -ne 0 ]; then
  printf '%s\n' "architecture-lint: failed with $FAILURES issue(s)." >&2
  exit 1
fi

printf '%s\n' "architecture-lint: passed"
