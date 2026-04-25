import XCTest
#if SWIFT_PACKAGE
@testable import OwloryCore
#endif

final class ProtocolLifecycleRulesTests: XCTestCase {
    private let createdAt = ISO8601DateFormatter().date(from: "2026-04-18T12:00:00Z")!
    private let completedAt = ISO8601DateFormatter().date(from: "2026-04-18T12:05:00Z")!
    private let runID = UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!
    private let step1ID = UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!
    private let step2ID = UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC")!

    func testStartDecisionResumesExistingRunOnPrimaryPath() {
        let template = makeTemplate()
        let existing = makeRun(template: template)

        let decision = ProtocolLifecycleRules.startDecision(
            template: template,
            activeRun: existing,
            mode: .resumeExistingIfActive
        )

        XCTAssertEqual(decision, .resumeExisting(existing.id))
    }

    func testStartDecisionResumesExistingRunEvenWhenTemplateIsMissing() {
        let existing = makeRun()

        let decision = ProtocolLifecycleRules.startDecision(
            template: nil,
            activeRun: existing,
            mode: .resumeExistingIfActive
        )

        XCTAssertEqual(decision, .resumeExisting(existing.id))
    }

    func testExplicitNewRunDecisionAllowsSecondaryStartWhenActiveRunExists() {
        let template = makeTemplate()
        let existing = makeRun(template: template)

        let decision = ProtocolLifecycleRules.startDecision(
            template: template,
            activeRun: existing,
            mode: .explicitNewRun
        )

        XCTAssertEqual(decision, .startNew)
    }

    func testStartDecisionRejectsMissingOrEmptyProtocols() {
        XCTAssertEqual(
            ProtocolLifecycleRules.startDecision(
                template: nil,
                activeRun: nil,
                mode: .resumeExistingIfActive
            ),
            .reject(.missingProtocol)
        )

        XCTAssertEqual(
            ProtocolLifecycleRules.startDecision(
                template: HouseholdProtocol(title: "Empty", steps: []),
                activeRun: nil,
                mode: .resumeExistingIfActive
            ),
            .reject(.emptyProtocol)
        )
    }

    func testMakeRunCopiesTemplateStepsWithDeterministicIdentifiers() throws {
        let template = makeTemplate(title: "Kitchen Reset", steps: ["Clear sink", "Wipe counters"])

        let run = try XCTUnwrap(ProtocolLifecycleRules.makeRun(
            from: template,
            runID: runID,
            stepIDs: [step1ID, step2ID],
            createdAt: createdAt
        ))

        XCTAssertEqual(run.id, runID)
        XCTAssertEqual(run.protocolID, template.id)
        XCTAssertEqual(run.protocolTitle, "Kitchen Reset")
        XCTAssertEqual(run.status, .active)
        XCTAssertEqual(run.createdAt, createdAt)
        XCTAssertEqual(run.steps.map(\.id), [step1ID, step2ID])
        XCTAssertEqual(run.steps.map(\.stepNumber), [1, 2])
        XCTAssertEqual(run.steps.map(\.title), ["Clear sink", "Wipe counters"])
        XCTAssertEqual(run.steps.map(\.status), [.pending, .pending])
    }

    func testMakeRunRejectsMismatchedStepIdentifiers() {
        let template = makeTemplate(steps: ["One", "Two"])

        XCTAssertNil(ProtocolLifecycleRules.makeRun(
            from: template,
            runID: runID,
            stepIDs: [step1ID],
            createdAt: createdAt
        ))
    }

    func testResolvingFinalPendingStepCompletesRunOnce() {
        let run = makeRun(
            steps: [
                ProtocolStepInstance(id: step1ID, stepNumber: 1, title: "One", status: .completed),
                ProtocolStepInstance(id: step2ID, stepNumber: 2, title: "Two"),
            ]
        )

        let result = ProtocolLifecycleRules.resolveStep(
            in: run,
            stepID: step2ID,
            resolution: .complete,
            at: completedAt
        )

        XCTAssertTrue(result.didCompleteRun)
        XCTAssertEqual(result.run.status, .completed)
        XCTAssertEqual(result.run.completedAt, completedAt)
        XCTAssertEqual(result.run.steps[1].status, .completed)
        XCTAssertEqual(result.run.steps[1].completedAt, completedAt)
    }

    func testSkippingFinalPendingStepAlsoCompletesRun() {
        let run = makeRun(
            steps: [
                ProtocolStepInstance(id: step1ID, stepNumber: 1, title: "One", status: .completed),
                ProtocolStepInstance(id: step2ID, stepNumber: 2, title: "Two"),
            ]
        )

        let result = ProtocolLifecycleRules.resolveStep(
            in: run,
            stepID: step2ID,
            resolution: .skip,
            at: completedAt
        )

        XCTAssertTrue(result.didCompleteRun)
        XCTAssertEqual(result.run.status, .completed)
        XCTAssertEqual(result.run.completedAt, completedAt)
        XCTAssertEqual(result.run.steps[1].status, .skipped)
        XCTAssertNil(result.run.steps[1].completedAt)
    }

    func testResolvingTerminalOrAlreadyResolvedStepIsNoOp() {
        let terminalRun = makeRun(
            status: .completed,
            completedAt: completedAt,
            steps: [
                ProtocolStepInstance(
                    id: step1ID,
                    stepNumber: 1,
                    title: "One",
                    status: .completed,
                    completedAt: completedAt
                ),
            ]
        )

        let terminalResult = ProtocolLifecycleRules.resolveStep(
            in: terminalRun,
            stepID: step1ID,
            resolution: .complete,
            at: createdAt
        )
        XCTAssertFalse(terminalResult.didCompleteRun)
        XCTAssertEqual(terminalResult.run, terminalRun)

        let activeRun = makeRun(
            steps: [
                ProtocolStepInstance(
                    id: step1ID,
                    stepNumber: 1,
                    title: "One",
                    status: .skipped
                ),
            ]
        )
        let activeResult = ProtocolLifecycleRules.resolveStep(
            in: activeRun,
            stepID: step1ID,
            resolution: .complete,
            at: completedAt
        )
        XCTAssertFalse(activeResult.didCompleteRun)
        XCTAssertEqual(activeResult.run, activeRun)
    }

    func testAbandonOnlyMutatesActiveRuns() {
        let activeRun = makeRun()
        let abandoned = ProtocolLifecycleRules.abandon(activeRun, at: completedAt)

        XCTAssertEqual(abandoned.status, .abandoned)
        XCTAssertEqual(abandoned.completedAt, completedAt)

        let completedRun = makeRun(status: .completed, completedAt: completedAt)
        XCTAssertEqual(
            ProtocolLifecycleRules.abandon(completedRun, at: createdAt),
            completedRun
        )
    }

    private func makeTemplate(
        title: String = "Kitchen Reset",
        steps: [String] = ["Clear sink"]
    ) -> HouseholdProtocol {
        HouseholdProtocol(
            id: UUID(uuidString: "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD")!,
            title: title,
            steps: steps
        )
    }

    private func makeRun(
        template: HouseholdProtocol? = nil,
        status: ProtocolRunStatus = .active,
        completedAt: Date? = nil,
        steps: [ProtocolStepInstance]? = nil
    ) -> ProtocolRun {
        let template = template ?? makeTemplate()
        return ProtocolRun(
            id: runID,
            protocolID: template.id,
            protocolTitle: template.title,
            status: status,
            createdAt: createdAt,
            completedAt: completedAt,
            steps: steps ?? [
                ProtocolStepInstance(id: step1ID, stepNumber: 1, title: "Clear sink"),
            ]
        )
    }
}
