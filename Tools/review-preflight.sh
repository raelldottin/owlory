#!/bin/sh
# Read-only reviewer preflight for dirty or branch-based Owlory changes.

set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASE=""
LIMIT=80

usage() {
  cat <<'EOF_USAGE'
usage:
  ./Tools/review-preflight.sh [--base <git-ref>] [--limit <paths>]

Prints a read-only review preflight:
  - changed path sample
  - touched areas inferred from paths
  - recommended docs to read
  - suggested validation commands
  - review risks that need human/agent attention

Without --base, the report uses the current dirty workspace. With --base, it
also includes committed path changes since that ref.
EOF_USAGE
}

fail() {
  echo "error: $*" >&2
  echo "why this matters: review preflight needs Git path data to recommend validation without hidden chat context." >&2
  echo "remediation: run from the repo root, or pass --help for usage." >&2
  echo "doc: docs/workflows/review.md" >&2
  exit 1
}

add_once() {
  file="$1"
  shift
  value="$*"
  [ -n "$value" ] || return
  if ! grep -Fxq "$value" "$file" 2>/dev/null; then
    printf '%s\n' "$value" >> "$file"
  fi
}

count_lines() {
  sed '/^$/d' | wc -l | tr -d ' '
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --base)
      shift
      [ "$#" -gt 0 ] || fail "--base requires a Git ref"
      BASE="$1"
      ;;
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

command -v git >/dev/null 2>&1 || fail "git is required"
git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail "not inside a Git repository"

PATHS="$(mktemp "${TMPDIR:-/tmp}/owlory-review-paths.XXXXXX")"
AREAS="$(mktemp "${TMPDIR:-/tmp}/owlory-review-areas.XXXXXX")"
DOCS="$(mktemp "${TMPDIR:-/tmp}/owlory-review-docs.XXXXXX")"
COMMANDS="$(mktemp "${TMPDIR:-/tmp}/owlory-review-commands.XXXXXX")"
RISKS="$(mktemp "${TMPDIR:-/tmp}/owlory-review-risks.XXXXXX")"
trap 'rm -f "$PATHS" "$AREAS" "$DOCS" "$COMMANDS" "$RISKS"' EXIT

if [ -n "$BASE" ]; then
  git -C "$ROOT" rev-parse --verify "$BASE" >/dev/null 2>&1 || fail "unknown base ref '$BASE'"
  git -C "$ROOT" diff --name-only "$BASE"...HEAD >> "$PATHS"
fi

git -C "$ROOT" status --short | sed -E 's/^...//' >> "$PATHS"
sort -u "$PATHS" -o "$PATHS"

add_once "$DOCS" "AGENTS.md"
add_once "$DOCS" "docs/README.md"
add_once "$DOCS" "docs/workflows/review.md"
add_once "$COMMANDS" "make architecture"

while IFS= read -r path; do
  [ -n "$path" ] || continue

  case "$path" in
    AGENTS.md|README.md|Makefile|Tools/*|docs/*|SecondBrain/*)
      add_once "$AREAS" "Harness / docs / workflow"
      add_once "$DOCS" "docs/repo-map.md"
      add_once "$DOCS" "docs/workflows/validation.md"
      add_once "$COMMANDS" "make review-preflight"
      add_once "$COMMANDS" "make handoff"
      ;;
  esac

  case "$path" in
    docs/workflows/drift-control.md|Tools/drift-report.sh|*AppIcon*|*.zip|*.textClipping|owlory_xcode/Docs/*|PROJECT_SPEC.md|LESSONS_FROM_GYMPHANT.md|CLAUDE.md|SKILL.md)
      add_once "$AREAS" "Drift control / cleanup"
      add_once "$DOCS" "docs/workflows/drift-control.md"
      add_once "$DOCS" "docs/workflows/historical-docs.md"
      add_once "$DOCS" "docs/workflows/legacy-xcode-docs.md"
      add_once "$COMMANDS" "make drift-report"
      ;;
  esac

  case "$path" in
    OwloryCoreTests|OwloryCoreTests/*|owlory_xcode.zip|owlory_xcode_v2.zip|owlory_xcode_v3.zip|docs/workflows/archived-code-artifacts.md)
      add_once "$AREAS" "Archived code artifacts"
      add_once "$DOCS" "docs/workflows/archived-code-artifacts.md"
      add_once "$DOCS" "docs/workflows/drift-control.md"
      add_once "$COMMANDS" "make drift-report"
      add_once "$RISKS" "Archived code artifacts changed: verify build/test ownership still points only to owlory_xcode/, no live recovery workflow depends on the artifact, and executable-looking duplicates were not left ambiguous."
      ;;
  esac

  case "$path" in
    owlory_xcode/Owlory.xcodeproj/*|Tools/bump-version.sh|Tools/set-build-number.sh|Tools/generate-build-info.sh|Tools/verify-build-provenance.sh|*BuildInfo*)
      add_once "$AREAS" "App Runtime / release provenance"
      add_once "$DOCS" "docs/product/domains/app-runtime.md"
      add_once "$DOCS" "docs/workflows/release.md"
      add_once "$COMMANDS" "make build-provenance"
      add_once "$COMMANDS" "make test-domain DOMAIN=runtime"
      ;;
  esac

  case "$path" in
    *PerformanceTelemetry*|*MetricKit*|*OSLog*|*Signpost*|*OSSignpost*|*Instruments*|docs/runtime/observability.md|docs/workflows/performance-observability.md)
      add_once "$AREAS" "Runtime observability / performance"
      add_once "$DOCS" "docs/runtime/observability.md"
      add_once "$DOCS" "docs/workflows/performance-observability.md"
      add_once "$DOCS" "docs/product/domains/app-runtime.md"
      add_once "$COMMANDS" "make test-domain DOMAIN=runtime"
      add_once "$RISKS" "Observability or performance path changed: verify signpost/log names are low-cardinality, no user content is logged, simulator tests are not treated as battery proof, and any performance claim has measured evidence."
      ;;
  esac

  case "$path" in
    owlory_xcode/Owlory/Core/Domain/*)
      add_once "$AREAS" "Pure domain policy"
      add_once "$DOCS" "docs/architecture/boundaries.md"
      add_once "$RISKS" "Domain code changed: verify it stays deterministic and free of UI, persistence, notification, audio, speech, and app-lifecycle coupling."
      ;;
  esac

  case "$path" in
    *Today*|*Continue*|*CarryForward*|*DailyPlanning*|*FocusSuggestion*|*Readiness*)
      add_once "$AREAS" "Today"
      add_once "$DOCS" "docs/product/domains/today.md"
      add_once "$COMMANDS" "make test-domain DOMAIN=today"
      ;;
    *Train*|*Training*|*Recurrence*|*RecurringRollover*)
      add_once "$AREAS" "Train / recurrence"
      add_once "$DOCS" "docs/product/domains/train.md"
      add_once "$COMMANDS" "make test-domain DOMAIN=train"
      ;;
    *Home*|*ProtocolLifecycle*|*Protocol*)
      add_once "$AREAS" "Home / protocols"
      add_once "$DOCS" "docs/product/domains/home.md"
      add_once "$COMMANDS" "make test-domain DOMAIN=home"
      ;;
    *Write*|*Writing*)
      add_once "$AREAS" "Write"
      add_once "$DOCS" "docs/product/domains/write.md"
      add_once "$COMMANDS" "make test-domain DOMAIN=write"
      ;;
    *Career*)
      add_once "$AREAS" "Career"
      add_once "$DOCS" "docs/product/domains/career.md"
      add_once "$COMMANDS" "make test-domain DOMAIN=career"
      ;;
    *Pattern*|*Calibration*|*WeeklyDigest*|*ReadinessOutcome*)
      add_once "$AREAS" "Patterns"
      add_once "$DOCS" "docs/product/domains/patterns.md"
      add_once "$COMMANDS" "make test-domain DOMAIN=patterns"
      ;;
    *Reminder*|*CompletionTimePredictor*)
      add_once "$AREAS" "Reminders"
      add_once "$DOCS" "docs/product/domains/reminders.md"
      add_once "$COMMANDS" "make test-domain DOMAIN=reminders"
      ;;
    *Voice*|*Speech*|*AudioCapture*|*Transcription*)
      add_once "$AREAS" "Voice Transcription"
      add_once "$DOCS" "docs/product/voice-transcription.md"
      add_once "$DOCS" "docs/runtime/ml-privacy.md"
      add_once "$DOCS" "docs/workflows/ml-qa.md"
      add_once "$COMMANDS" "make test-domain DOMAIN=voice"
      ;;
    *ML*|*ModelAvailability*|*StructuredCapture*|*FoundationModel*|*DigestInsight*|docs/runtime/ml-privacy.md|docs/workflows/ml-qa.md)
      add_once "$AREAS" "ML / generated output"
      add_once "$DOCS" "docs/runtime/ml-model-posture.md"
      add_once "$DOCS" "docs/runtime/ml-privacy.md"
      add_once "$DOCS" "docs/workflows/ml-qa.md"
      add_once "$DOCS" "docs/runtime/observability.md"
      add_once "$RISKS" "ML, speech, or generated-output path changed: verify output remains draft-only, unavailable states degrade safely, fake response categories cover failure modes, and privacy claims match implementation."
      ;;
  esac

  case "$path" in
    *.swift)
      case "$path" in
        *Tests*|*OwloryCoreTests*) ;;
        *)
          add_once "$RISKS" "Swift source changed: confirm there is focused coverage at the lowest honest test layer, or state why this is docs/tooling only."
          ;;
      esac
      ;;
  esac
done < "$PATHS"

PATH_COUNT="$(count_lines < "$PATHS")"

echo "Owlory Review Preflight"
echo
echo "Scope"
echo "  Path count: $PATH_COUNT"
if [ -n "$BASE" ]; then
  echo "  Base ref: $BASE"
else
  echo "  Source: current dirty workspace"
fi

echo
echo "Changed Paths"
if [ "$PATH_COUNT" -eq 0 ]; then
  echo "  none"
else
  sed -n "1,${LIMIT}p" "$PATHS" | sed 's/^/  - /'
  if [ "$PATH_COUNT" -gt "$LIMIT" ]; then
    remaining=$((PATH_COUNT - LIMIT))
    echo "  ... $remaining more path(s). Rerun with --limit $PATH_COUNT for the full list."
  fi
fi

echo
echo "Touched Areas"
if [ ! -s "$AREAS" ]; then
  echo "  - No specific area inferred. Start from docs/repo-map.md and inspect paths manually."
else
  sed 's/^/  - /' "$AREAS"
fi

echo
echo "Recommended Docs"
sed 's/^/  - /' "$DOCS"

echo
echo "Suggested Validation"
sed 's/^/  - /' "$COMMANDS"

echo
echo "Review Risks"
if [ ! -s "$RISKS" ]; then
  echo "  - No path-specific risks inferred. Still review behavior, tests, and residual risk honestly."
else
  sed 's/^/  - /' "$RISKS"
fi

echo
echo "Next Safe Step"
echo "  Read docs/workflows/review.md, run the narrowest suggested validation, and report any checks not run."
