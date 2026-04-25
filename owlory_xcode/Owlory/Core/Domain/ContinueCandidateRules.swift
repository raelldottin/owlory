import Foundation

struct ContinueCandidateLimitPolicy: Equatable {
    let maxTotalCount: Int
    let maxPerDomainCount: Int

    static let todayDefault = ContinueCandidateLimitPolicy(
        maxTotalCount: 5,
        maxPerDomainCount: 2
    )
}

enum ContinueCandidateRules {
    enum AdmissionRejection: Equatable {
        case emptyTitle
        case totalLimitReached
        case domainLimitReached(LifeDomain)
    }

    static func isDueTodayCandidate(_ session: TrainingSession) -> Bool {
        session.status == .planned && hasDisplayableTitle(session.plannedActivity)
    }

    static func isCarriedForwardCandidate(
        _ item: FocusItem,
        staleDayCount: Int?
    ) -> Bool {
        item.status == .planned &&
            staleDayCount != nil &&
            hasDisplayableTitle(item.title) &&
            !isRetiredScaffoldFocusItem(item)
    }

    static func isActiveHomeTaskCandidate(_ task: HomeTask) -> Bool {
        !task.isCompleted &&
            !task.isSkipped &&
            hasDisplayableTitle(task.title)
    }

    static func isActiveHomeProtocolRunCandidate(_ run: ProtocolRun) -> Bool {
        run.status == .active &&
            hasDisplayableTitle(run.protocolTitle)
    }

    static func isInProgressWritingCandidate(_ note: WritingNote) -> Bool {
        ![WritingStage.published, .archived].contains(note.stage) &&
            hasDisplayableTitle(note.title)
    }

    static func admissionRejection(
        title: String,
        domain: LifeDomain,
        selectedDomains: [LifeDomain],
        policy: ContinueCandidateLimitPolicy = .todayDefault
    ) -> AdmissionRejection? {
        guard hasDisplayableTitle(title) else { return .emptyTitle }
        guard selectedDomains.count < policy.maxTotalCount else {
            return .totalLimitReached
        }
        let domainCount = selectedDomains.filter { $0 == domain }.count
        guard domainCount < policy.maxPerDomainCount else {
            return .domainLimitReached(domain)
        }
        return nil
    }

    static func canAdmit(
        title: String,
        domain: LifeDomain,
        selectedDomains: [LifeDomain],
        policy: ContinueCandidateLimitPolicy = .todayDefault
    ) -> Bool {
        admissionRejection(
            title: title,
            domain: domain,
            selectedDomains: selectedDomains,
            policy: policy
        ) == nil
    }

    static func isRetiredScaffoldFocusItem(_ item: FocusItem) -> Bool {
        guard item.linkedRecordID == nil else { return false }
        let scaffold = RetiredScaffold(
            normalizedTitle: normalize(item.title),
            domain: item.domain
        )
        return retiredScaffolds.contains(scaffold)
    }

    private static func hasDisplayableTitle(_ title: String) -> Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private struct RetiredScaffold: Hashable {
        let normalizedTitle: String
        let domain: LifeDomain
    }

    private static let retiredScaffolds: Set<RetiredScaffold> = [
        RetiredScaffold(normalizedTitle: normalize("Log one writing intention"), domain: .writing),
        RetiredScaffold(normalizedTitle: normalize("Capture one career win"), domain: .career),
    ]

    private static func normalize(_ title: String) -> String {
        title
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
