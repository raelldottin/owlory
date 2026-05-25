#!/bin/sh
# Unified validation entry point for agents.

set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_DIR="$ROOT/owlory_xcode"
DESTINATION="${OWLORY_XCODE_DESTINATION:-platform=iOS Simulator,name=iPhone 17,OS=26.5}"
MODE="${1:-fast}"
DOMAIN="${2:-${DOMAIN:-}}"

usage() {
  cat <<'EOF_USAGE'
usage:
  ./Tools/validate.sh architecture
  ./Tools/validate.sh build-provenance
  ./Tools/validate.sh release-preflight
  ./Tools/validate.sh drift-report
  ./Tools/validate.sh handoff
  ./Tools/validate.sh clean-stop
  ./Tools/validate.sh review-preflight
  ./Tools/validate.sh system-metadata
  ./Tools/validate.sh app-icons
  ./Tools/validate.sh localization
  ./Tools/validate.sh fast
  ./Tools/validate.sh full
  ./Tools/validate.sh domain <today|train|write|career|home|patterns|reminders|runtime|voice>

Set OWLORY_XCODE_DESTINATION to override the simulator destination.
EOF_USAGE
}

run_architecture() {
  "$ROOT/Tools/architecture-lint.sh"
}

run_xcode_tests() {
  cd "$PROJECT_DIR"
  xcodebuild test \
    -project Owlory.xcodeproj \
    -scheme Owlory \
    -destination "$DESTINATION" \
    -derivedDataPath /tmp/owlory-validate-xcode \
    "$@"
}

run_domain() {
  domain="$1"
  case "$domain" in
    today)
      run_xcode_tests \
        -only-testing:OwloryCoreTests/TodayStoreTests \
        -only-testing:OwloryCoreTests/CarryForwardRulesTests \
        -only-testing:OwloryCoreTests/DailyPlanningRulesTests \
        -only-testing:OwloryCoreTests/FocusSuggestionRulesTests \
        -only-testing:OwloryCoreTests/ReadinessRulesTests \
        -only-testing:OwloryCoreTests/TodayContinuationRulesTests \
        -only-testing:OwloryCoreTests/TodayContinueSourceComposerTests \
        -only-testing:OwloryCoreTests/TodayContinueItemAssemblerTests \
        -only-testing:OwloryCoreTests/ContinuePipelineTraceTests \
        -only-testing:OwloryCoreTests/ContinueCandidateRulesTests \
        -only-testing:OwloryCoreTests/ContinueRankingRulesTests
      ;;
    train)
      run_xcode_tests \
        -only-testing:OwloryCoreTests/TrainStoreTests \
        -only-testing:OwloryCoreTests/TrainingConsistencyTests \
        -only-testing:OwloryCoreTests/RecurrenceRulesTests \
        -only-testing:OwloryCoreTests/RecurringRolloverPlannerTests
      ;;
    write)
      run_xcode_tests \
        -only-testing:OwloryCoreTests/WriteStoreTests \
        -only-testing:OwloryCoreTests/WritingStageRulesTests \
        -only-testing:OwloryCoreTests/WritingVelocityTests
      ;;
    career)
      run_xcode_tests \
        -only-testing:OwloryCoreTests/CareerStoreTests \
        -only-testing:OwloryCoreTests/CareerAssistantTests
      ;;
    home)
      run_xcode_tests \
        -only-testing:OwloryCoreTests/HomeStoreTests \
        -only-testing:OwloryCoreTests/ProtocolLifecycleRulesTests \
        -only-testing:OwloryCoreTests/ProtocolScheduleRulesTests \
        -only-testing:OwloryCoreTests/RecurrenceRulesTests \
        -only-testing:OwloryCoreTests/RecurringRolloverPlannerTests
      ;;
    patterns)
      run_xcode_tests \
        -only-testing:OwloryCoreTests/PatternEngineTests \
        -only-testing:OwloryCoreTests/CalibrationRulesTests \
        -only-testing:OwloryCoreTests/PatternNudgeRulesTests \
        -only-testing:OwloryCoreTests/ReadinessOutcomeRulesTests \
        -only-testing:OwloryCoreTests/WeeklyDigestRulesTests \
        -only-testing:OwloryCoreTests/WeeklyDigestCadenceRulesTests \
        -only-testing:OwloryCoreTests/WeeklyDigestPresentationFormattingTests
      ;;
    reminders)
      run_xcode_tests \
        -only-testing:OwloryCoreTests/CompletionTimePredictorTests \
        -only-testing:OwloryCoreTests/ReminderSchedulingRulesTests \
        -only-testing:OwloryCoreTests/ProtocolScheduleNotificationRulesTests \
        -only-testing:OwloryCoreTests/ReminderSchedulerTerminalStatusCancelIntegrationTests \
        -only-testing:OwloryCoreTests/ReminderSuppressionRulesTests
      ;;
    runtime)
      run_xcode_tests \
        -only-testing:OwloryCoreTests/BuildInfoTests \
        -only-testing:OwloryCoreTests/PerformanceTelemetryTests
      ;;
    voice)
      run_xcode_tests \
        -only-testing:OwloryCoreTests/VoiceTranscriptionRoutingRulesTests \
        -only-testing:OwloryCoreTests/TrainStoreTests/testUpdateSessionUsesVoiceTranscriptionWhenReflectionIsBlank \
        -only-testing:OwloryCoreTests/TrainStoreTests/testUpdateSessionKeepsTypedReflectionWhenVoiceTranscriptionExists
      ;;
    *)
      echo "unknown domain '$domain'" >&2
      usage >&2
      exit 2
      ;;
  esac
}

case "$MODE" in
  architecture)
    run_architecture
    ;;
  app-icons)
    "$ROOT/Tools/verify-app-icons.sh" >/dev/null
    ;;
  localization)
    "$ROOT/Tools/localization-parity.sh"
    ;;
  build-provenance)
    "$ROOT/Tools/verify-build-provenance.sh"
    ;;
  release-preflight)
    "$ROOT/Tools/release-preflight.sh"
    ;;
  drift-report)
    "$ROOT/Tools/drift-report.sh" >/dev/null
    ;;
  handoff)
    "$ROOT/Tools/agent-handoff.sh" >/dev/null
    ;;
  clean-stop)
    python3 "$ROOT/Tools/clean-stop-check.py" >/dev/null
    ;;
  review-preflight)
    "$ROOT/Tools/review-preflight.sh" >/dev/null
    ;;
  system-metadata)
    "$ROOT/Tools/clean-system-metadata.sh" --dry-run >/dev/null
    ;;
  fast)
    run_architecture
    run_xcode_tests \
      -only-testing:OwloryCoreTests/CarryForwardRulesTests \
      -only-testing:OwloryCoreTests/DailyPlanningRulesTests \
      -only-testing:OwloryCoreTests/FocusSuggestionRulesTests \
      -only-testing:OwloryCoreTests/VoiceTranscriptionRoutingRulesTests \
      -only-testing:OwloryCoreTests/ReadinessRulesTests \
      -only-testing:OwloryCoreTests/TodayContinueSourceComposerTests \
      -only-testing:OwloryCoreTests/TodayContinueItemAssemblerTests \
      -only-testing:OwloryCoreTests/ContinuePipelineTraceTests \
      -only-testing:OwloryCoreTests/ContinueCandidateRulesTests \
      -only-testing:OwloryCoreTests/ContinueRankingRulesTests \
      -only-testing:OwloryCoreTests/RecurrenceRulesTests \
      -only-testing:OwloryCoreTests/RecurringRolloverPlannerTests \
      -only-testing:OwloryCoreTests/ReminderSchedulingRulesTests \
      -only-testing:OwloryCoreTests/ProtocolScheduleNotificationRulesTests \
      -only-testing:OwloryCoreTests/BuildInfoTests
    ;;
  full)
    run_architecture
    run_xcode_tests -only-testing:OwloryCoreTests
    ;;
  domain)
    if [ -z "$DOMAIN" ]; then
      usage >&2
      exit 2
    fi
    run_architecture
    run_domain "$DOMAIN"
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    echo "unknown validation mode '$MODE'" >&2
    usage >&2
    exit 2
    ;;
esac
