import XCTest
#if SWIFT_PACKAGE
@testable import OwloryCore
#endif

final class ProvenanceCodableTests: XCTestCase {
    func testFocusItemEncodesAndDecodesProvenanceWhenSet() throws {
        let item = FocusItem(
            title: "Review backlog",
            domain: .career,
            provenance: .focusSuggestion
        )

        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(FocusItem.self, from: data)

        XCTAssertEqual(decoded.provenance, .focusSuggestion)
    }

    func testFocusItemEncodesAndDecodesNilProvenanceAsUserAuthored() throws {
        let item = FocusItem(
            title: "Plan weekly review",
            domain: .home
        )

        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(FocusItem.self, from: data)

        XCTAssertNil(decoded.provenance, "Default provenance must be nil so legacy records read as user-authored.")
    }

    func testLegacyFocusItemJSONWithoutProvenanceDecodesAsNil() throws {
        // Simulates a DailyEntry that was persisted before the provenance
        // field existed. The DailyEntry decoder must still accept it.
        let legacyJSON = """
        {
          "date": "2026-05-01T00:00:00Z",
          "focusThree": [
            {
              "title": "Old item",
              "domain": "home",
              "status": "planned"
            }
          ]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let entry = try decoder.decode(DailyEntry.self, from: legacyJSON)

        XCTAssertEqual(entry.focusThree.count, 1)
        XCTAssertNil(entry.focusThree.first?.provenance)
    }

    func testNewFocusItemJSONWithProvenanceRoundTripsThroughDailyEntry() throws {
        let entry = DailyEntry(
            date: ISO8601DateFormatter().date(from: "2026-05-29T00:00:00Z")!,
            focusThree: [
                FocusItem(
                    title: "Suggested item",
                    domain: .career,
                    provenance: .focusSuggestion
                )
            ]
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(entry)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(DailyEntry.self, from: data)

        XCTAssertEqual(decoded.focusThree.first?.provenance, .focusSuggestion)
    }
}
