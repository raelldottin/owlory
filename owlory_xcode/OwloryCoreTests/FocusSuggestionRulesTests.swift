import XCTest
#if SWIFT_PACKAGE
@testable import OwloryCore
#endif

final class FocusSuggestionRulesTests: XCTestCase {
    func testReadinessMatchedCompletionCanOutrankMoreFrequentMismatchedHistory() {
        let today = DailyEntry(
            date: makeDate("2026-04-08T10:00:00Z"),
            energy: 2,
            mood: 2,
            sleepQuality: 2
        )
        let recentEntries = [
            DailyEntry(
                date: makeDate("2026-04-07T10:00:00Z"),
                focusThree: [
                    FocusItem(title: "Water plants", domain: .home, status: .done),
                ],
                energy: 2,
                mood: 2,
                sleepQuality: 2
            ),
            DailyEntry(
                date: makeDate("2026-04-06T10:00:00Z"),
                focusThree: [
                    FocusItem(title: "Draft pitch", domain: .career, status: .done),
                ],
                energy: 5,
                mood: 5,
                sleepQuality: 5
            ),
            DailyEntry(
                date: makeDate("2026-04-05T10:00:00Z"),
                focusThree: [
                    FocusItem(title: "Draft pitch", domain: .career, status: .done),
                ],
                energy: 5,
                mood: 5,
                sleepQuality: 5
            ),
        ]

        let candidates = FocusSuggestionRules.candidates(
            todayEntry: today,
            recentEntries: recentEntries,
            predictions: [:],
            now: makeDate("2026-04-08T10:00:00Z"),
            calendar: makeCalendar()
        )

        XCTAssertEqual(candidates.map(\.title), ["Water plants", "Draft pitch"])
        if case .similarReadinessHistory(_, let context) = candidates.first?.reason?.completion {
            XCTAssertEqual(context, .low)
        } else {
            XCTFail("Expected .similarReadinessHistory completion with .low context")
        }
    }

    func testCurrentAndActiveItemsAreExcludedFromFallbackCandidates() {
        let today = DailyEntry(
            date: makeDate("2026-04-08T10:00:00Z"),
            focusThree: [
                FocusItem(title: "Water plants", domain: .home),
            ]
        )
        let recentEntries = [
            DailyEntry(
                date: makeDate("2026-04-07T10:00:00Z"),
                focusThree: [
                    FocusItem(title: "Water plants", domain: .home, status: .done),
                    FocusItem(title: "Morning run", domain: .training, status: .done),
                    FocusItem(title: "Review notes", domain: .career, status: .done),
                ]
            ),
            DailyEntry(
                date: makeDate("2026-04-06T10:00:00Z"),
                focusThree: [
                    FocusItem(title: "Review notes", domain: .career, status: .done),
                ]
            ),
        ]

        let candidates = FocusSuggestionRules.candidates(
            todayEntry: today,
            recentEntries: recentEntries,
            predictions: [
                CompletionTimePredictor.key(forTrainingSession: "Morning run"): prediction(
                    key: CompletionTimePredictor.key(forTrainingSession: "Morning run")
                ),
            ],
            now: makeDate("2026-04-08T10:00:00Z"),
            calendar: makeCalendar(),
            activeItems: [
                FocusSuggestionRules.ActiveItem(title: "Morning run", domain: .training),
            ]
        )

        XCTAssertEqual(candidates.map(\.title), ["Review notes"])
    }

    func testPredictionFallbackSurfacesCandidateWithoutDailyHistory() {
        let predictionKey = CompletionTimePredictor.key(forProtocolRun: "Kitchen Reset")

        let candidates = FocusSuggestionRules.candidates(
            todayEntry: DailyEntry(date: makeDate("2026-04-08T10:00:00Z")),
            recentEntries: [],
            predictions: [
                predictionKey: prediction(key: predictionKey, sampleCount: 5, medianTimeOfDay: 19 * 3600),
            ],
            now: makeDate("2026-04-08T18:30:00Z"),
            calendar: makeCalendar()
        )

        XCTAssertEqual(candidates.map(\.title), ["Kitchen Reset"])
        XCTAssertEqual(candidates.first?.domain, .home)
        if case .predictedTime(let secondsSinceMidnight) = candidates.first?.reason?.timing {
            XCTAssertEqual(secondsSinceMidnight, 19 * 3600, accuracy: 0.001)
        } else {
            XCTFail("Expected .predictedTime timing with 19h offset")
        }
    }

    func testSparseHistoryWithoutReadinessMatchOrPredictionDoesNotSuggest() {
        let today = DailyEntry(
            date: makeDate("2026-04-08T10:00:00Z"),
            energy: 5,
            mood: 5,
            sleepQuality: 5
        )
        let recentEntries = [
            DailyEntry(
                date: makeDate("2026-04-07T10:00:00Z"),
                focusThree: [
                    FocusItem(title: "Clean desk", domain: .home, status: .done),
                ],
                energy: 2,
                mood: 2,
                sleepQuality: 2
            ),
        ]

        let candidates = FocusSuggestionRules.candidates(
            todayEntry: today,
            recentEntries: recentEntries,
            predictions: [:],
            now: makeDate("2026-04-08T10:00:00Z"),
            calendar: makeCalendar()
        )

        XCTAssertTrue(candidates.isEmpty)
    }

    func testEqualFallbackCandidatesUseStableSourceOrderTieBreak() {
        let today = DailyEntry(
            date: makeDate("2026-04-08T10:00:00Z"),
            energy: 5,
            mood: 5,
            sleepQuality: 5
        )
        let recentEntries = [
            DailyEntry(
                date: makeDate("2026-04-07T10:00:00Z"),
                focusThree: [
                    FocusItem(title: "First equal", domain: .home, status: .done),
                    FocusItem(title: "Second equal", domain: .career, status: .done),
                ],
                energy: 5,
                mood: 5,
                sleepQuality: 5
            ),
        ]

        let candidates = FocusSuggestionRules.candidates(
            todayEntry: today,
            recentEntries: recentEntries,
            predictions: [:],
            now: makeDate("2026-04-08T10:00:00Z"),
            calendar: makeCalendar()
        )

        XCTAssertEqual(candidates.map(\.title), ["First equal", "Second equal"])
    }

    func testDraftAdmissionCapsExistingDismissedAndDuplicateCandidates() {
        let existing = FocusItem(title: "Existing", domain: .home)
        let dismissedKey = FocusSuggestionRules.key(
            title: "Dismissed",
            domain: .career,
            linkedRecordID: nil
        )
        var ids = [
            UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
            UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!,
        ].makeIterator()

        let drafts = FocusSuggestionRules.drafts(
            todayEntry: DailyEntry(date: makeDate("2026-04-08T10:00:00Z"), focusThree: [existing]),
            suggestedFocusLoad: 3,
            candidates: [
                .init(title: "Existing", domain: .home, priority: 0),
                .init(title: "Dismissed", domain: .career, priority: 1),
                .init(title: "First kept", domain: .writing, priority: 2),
                .init(title: "First kept", domain: .writing, priority: 3),
                .init(title: "Second kept", domain: .training, priority: 4),
                .init(title: "Capped out", domain: .home, priority: 5),
            ],
            dismissedKeys: [dismissedKey],
            makeID: { ids.next()! }
        )

        XCTAssertEqual(drafts.map(\.title), ["First kept", "Second kept"])
        XCTAssertEqual(drafts.map(\.id), [
            UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
            UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!,
        ])
    }

    private func makeDate(_ value: String) -> Date {
        ISO8601DateFormatter().date(from: value)!
    }

    private func makeCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func prediction(
        key: String,
        sampleCount: Int = 4,
        medianTimeOfDay: TimeInterval = 7 * 3600
    ) -> CompletionTimePredictor.Prediction {
        CompletionTimePredictor.Prediction(
            itemKey: key,
            medianTimeOfDay: medianTimeOfDay,
            madSeconds: 30 * 60,
            sampleCount: sampleCount
        )
    }
}
