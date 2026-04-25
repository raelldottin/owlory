import XCTest

#if SWIFT_PACKAGE
    @testable import OwloryCore
#endif

final class PerformanceTelemetryTests: XCTestCase {
    func testMeasureReturnsOperationValue() {
        let value = PerformanceTelemetry.measure(
            "PerformanceTelemetryTests.value",
            category: .performance
        ) {
            42
        }

        XCTAssertEqual(value, 42)
    }

    func testMeasurePropagatesOperationError() {
        enum TestError: Error {
            case expected
        }

        XCTAssertThrowsError(
            try PerformanceTelemetry.measure(
                "PerformanceTelemetryTests.error",
                category: .performance
            ) {
                throw TestError.expected
            }
        ) { error in
            XCTAssertTrue(error is TestError)
        }
    }
}
