import XCTest
#if SWIFT_PACKAGE
@testable import OwloryCore
#endif

final class ContinueCandidateRulesTests: XCTestCase {
    private let testDate = Date(timeIntervalSinceReferenceDate: 0)

    func testDueTodayEligibilityRequiresPlannedTrainingWithDisplayableTitle() {
        XCTAssertTrue(
            ContinueCandidateRules.isDueTodayCandidate(
                TrainingSession(date: testDate, plannedActivity: "Intervals", status: .planned)
            )
        )

        XCTAssertFalse(
            ContinueCandidateRules.isDueTodayCandidate(
                TrainingSession(date: testDate, plannedActivity: "Intervals", status: .skipped)
            )
        )
        XCTAssertFalse(
            ContinueCandidateRules.isDueTodayCandidate(
                TrainingSession(date: testDate, plannedActivity: "   ", status: .planned)
            )
        )
    }

    func testCarriedForwardEligibilityRequiresPlannedStaleNonRetiredItem() {
        let planned = FocusItem(title: "Draft outline", domain: .writing, status: .planned)
        let done = FocusItem(title: "Draft outline", domain: .writing, status: .done)
        let retired = FocusItem(title: "Log one writing intention", domain: .writing, status: .planned)
        let linkedRetired = FocusItem(
            title: "Log one writing intention",
            domain: .writing,
            status: .planned,
            linkedRecordID: UUID()
        )

        XCTAssertTrue(ContinueCandidateRules.isCarriedForwardCandidate(planned, staleDayCount: 3))
        XCTAssertFalse(ContinueCandidateRules.isCarriedForwardCandidate(planned, staleDayCount: nil))
        XCTAssertFalse(ContinueCandidateRules.isCarriedForwardCandidate(done, staleDayCount: 3))
        XCTAssertFalse(ContinueCandidateRules.isCarriedForwardCandidate(retired, staleDayCount: 3))
        XCTAssertTrue(ContinueCandidateRules.isCarriedForwardCandidate(linkedRetired, staleDayCount: 3))
    }

    func testActiveHomeTaskEligibilityRequiresUnresolvedDisplayableTask() {
        XCTAssertTrue(ContinueCandidateRules.isActiveHomeTaskCandidate(HomeTask(title: "Laundry")))
        XCTAssertFalse(
            ContinueCandidateRules.isActiveHomeTaskCandidate(
                HomeTask(title: "Laundry", isCompleted: true)
            )
        )
        XCTAssertFalse(
            ContinueCandidateRules.isActiveHomeTaskCandidate(
                HomeTask(title: "Laundry", isSkipped: true)
            )
        )
        XCTAssertFalse(ContinueCandidateRules.isActiveHomeTaskCandidate(HomeTask(title: "")))
    }

    func testInProgressWritingEligibilityExcludesTerminalStagesAndBlankTitles() {
        XCTAssertTrue(
            ContinueCandidateRules.isInProgressWritingCandidate(
                WritingNote(title: "Essay source", body: "", stage: .source)
            )
        )
        XCTAssertFalse(
            ContinueCandidateRules.isInProgressWritingCandidate(
                WritingNote(title: "Published essay", body: "", stage: .published)
            )
        )
        XCTAssertFalse(
            ContinueCandidateRules.isInProgressWritingCandidate(
                WritingNote(title: "Archived idea", body: "", stage: .archived)
            )
        )
        XCTAssertFalse(
            ContinueCandidateRules.isInProgressWritingCandidate(
                WritingNote(title: "  ", body: "", stage: .draft)
            )
        )
    }

    func testDefaultAdmissionPolicyCapsAtFiveTotalAndTwoPerDomain() {
        let selected: [LifeDomain] = [.training, .training, .home, .home, .writing]

        XCTAssertEqual(
            ContinueCandidateRules.admissionRejection(
                title: "Career story",
                domain: .career,
                selectedDomains: selected
            ),
            .totalLimitReached
        )
        XCTAssertEqual(
            ContinueCandidateRules.admissionRejection(
                title: "Mobility",
                domain: .training,
                selectedDomains: [.training, .training]
            ),
            .domainLimitReached(.training)
        )
        XCTAssertEqual(
            ContinueCandidateRules.admissionRejection(
                title: " ",
                domain: .home,
                selectedDomains: []
            ),
            .emptyTitle
        )
        XCTAssertTrue(
            ContinueCandidateRules.canAdmit(
                title: "Laundry",
                domain: .home,
                selectedDomains: [.training, .training, .home]
            )
        )
    }

    func testCustomAdmissionPolicySupportsFocusedDomainChecks() {
        let policy = ContinueCandidateLimitPolicy(maxTotalCount: 3, maxPerDomainCount: 1)

        XCTAssertTrue(
            ContinueCandidateRules.canAdmit(
                title: "Laundry",
                domain: .home,
                selectedDomains: [.training],
                policy: policy
            )
        )
        XCTAssertFalse(
            ContinueCandidateRules.canAdmit(
                title: "Dishes",
                domain: .home,
                selectedDomains: [.training, .home],
                policy: policy
            )
        )
    }
}
