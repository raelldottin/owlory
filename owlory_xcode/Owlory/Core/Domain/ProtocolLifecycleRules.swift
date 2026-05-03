import Foundation

enum ProtocolLifecycleRules {
    enum StartMode: Equatable {
        case resumeExistingIfActive
        case explicitNewRun
    }

    enum StartDecision: Equatable {
        case resumeExisting(UUID)
        case startNew
        case reject(StartRejection)
    }

    enum StartRejection: Equatable {
        case missingProtocol
        case emptyProtocol
    }

    enum StepResolution: Equatable {
        case complete
        case skip
    }

    struct StepResolutionResult: Equatable {
        let run: ProtocolRun
        let didCompleteRun: Bool
    }

    struct StepUnresolutionResult: Equatable {
        let run: ProtocolRun
        let didReopenRun: Bool
    }

    static func startDecision(
        template: HouseholdProtocol?,
        activeRun: ProtocolRun?,
        mode: StartMode
    ) -> StartDecision {
        if mode == .resumeExistingIfActive, let activeRun {
            return .resumeExisting(activeRun.id)
        }

        guard let template else {
            return .reject(.missingProtocol)
        }
        guard !template.steps.isEmpty else {
            return .reject(.emptyProtocol)
        }

        return .startNew
    }

    static func makeRun(
        from template: HouseholdProtocol,
        runID: UUID,
        stepIDs: [UUID],
        createdAt: Date
    ) -> ProtocolRun? {
        guard !template.steps.isEmpty else {
            return nil
        }
        guard stepIDs.count == template.steps.count else {
            return nil
        }

        let steps = zip(template.steps.indices, template.steps).map { index, title in
            ProtocolStepInstance(
                id: stepIDs[index],
                stepNumber: index + 1,
                title: title
            )
        }

        return ProtocolRun(
            id: runID,
            protocolID: template.id,
            protocolTitle: template.title,
            status: .active,
            createdAt: createdAt,
            steps: steps
        )
    }

    static func resolveStep(
        in run: ProtocolRun,
        stepID: UUID,
        resolution: StepResolution,
        at resolvedAt: Date
    ) -> StepResolutionResult {
        guard run.status == .active else {
            return StepResolutionResult(run: run, didCompleteRun: false)
        }
        guard let stepIndex = run.steps.firstIndex(where: { $0.id == stepID }) else {
            return StepResolutionResult(run: run, didCompleteRun: false)
        }
        guard run.steps[stepIndex].status == .pending else {
            return StepResolutionResult(run: run, didCompleteRun: false)
        }

        var updated = run
        switch resolution {
        case .complete:
            updated.steps[stepIndex].status = .completed
            updated.steps[stepIndex].completedAt = resolvedAt
        case .skip:
            updated.steps[stepIndex].status = .skipped
        }

        if updated.isFinished {
            updated.status = .completed
            updated.completedAt = resolvedAt
            return StepResolutionResult(run: updated, didCompleteRun: true)
        }

        return StepResolutionResult(run: updated, didCompleteRun: false)
    }

    static func unresolveStep(
        in run: ProtocolRun,
        stepID: UUID
    ) -> StepUnresolutionResult {
        guard run.status != .abandoned else {
            return StepUnresolutionResult(run: run, didReopenRun: false)
        }
        guard let stepIndex = run.steps.firstIndex(where: { $0.id == stepID }) else {
            return StepUnresolutionResult(run: run, didReopenRun: false)
        }
        guard run.steps[stepIndex].status != .pending else {
            return StepUnresolutionResult(run: run, didReopenRun: false)
        }

        var updated = run
        updated.steps[stepIndex].status = .pending
        updated.steps[stepIndex].completedAt = nil

        let didReopenRun = run.status == .completed
        if didReopenRun {
            updated.status = .active
            updated.completedAt = nil
        }

        return StepUnresolutionResult(run: updated, didReopenRun: didReopenRun)
    }

    static func abandon(_ run: ProtocolRun, at abandonedAt: Date) -> ProtocolRun {
        guard run.status == .active else {
            return run
        }

        var updated = run
        updated.status = .abandoned
        updated.completedAt = abandonedAt
        return updated
    }
}
