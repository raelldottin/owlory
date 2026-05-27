// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "OwloryCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "OwloryCore", targets: ["OwloryCore"])
    ],
    targets: [
        .target(
            name: "OwloryCore",
            path: "Owlory/Core",
            exclude: [
                "Infrastructure"
            ],
            sources: [
                "Application",
                "Domain",
                "Persistence"
            ]
        ),
        .testTarget(
            name: "OwloryCoreTests",
            dependencies: ["OwloryCore"],
            path: "OwloryCoreTests",
            exclude: [
                "BuildInfoTests.swift",
                "CalibrationRulesTests.swift",
                "CareerAssistantTests.swift",
                "CareerStoreTests.swift",
                "CarryForwardRulesTests.swift",
                "CompletionTimePredictorTests.swift",
                "ContinueCandidateRulesTests.swift",
                "ContinuePipelineTraceTests.swift",
                "ContinueRankingRulesTests.swift",
                "DailyPlanningRulesTests.swift",
                "DigestInsightStoreTests.swift",
                "FocusSuggestionRulesTests.swift",
                "HomeStoreTests.swift",
                "HomeProtocolSchedulePresentationFormattingTests.swift",
                "MLServiceContractTests.swift",
                "MLSuggestionTests.swift",
                "PatternEngineTests.swift",
                "PerformanceTelemetryTests.swift",
                "ProtocolLifecycleRulesTests.swift",
                "ReadinessOutcomeRulesTests.swift",
                "ReadinessRulesTests.swift",
                "RecurrenceRulesTests.swift",
                "RecurringRolloverPlannerTests.swift",
                "ReminderSchedulingRulesTests.swift",
                "TodayContinuationRulesTests.swift",
                "TodayContinueItemAssemblerTests.swift",
                "TodayContinueSourceComposerTests.swift",
                "TodayStoreTests.swift",
                "TrainStoreTests.swift",
                "TrainingConsistencyTests.swift",
                "VoiceTranscriptionRoutingRulesTests.swift",
                "WeeklyDigestCadenceRulesTests.swift",
                "WeeklyDigestRulesTests.swift",
                "WriteStoreTests.swift",
                "WritingStageRulesTests.swift",
                "WritingVelocityTests.swift"
            ],
            sources: [
                "PatternNudgeRulesTests.swift"
            ]
        )
    ]
)
