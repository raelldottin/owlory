import XCTest

final class OwloryUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = [
            "--owlory-ui-testing",
            "--owlory-ui-seed-fresh-day"
        ]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testSeededTodayLaunchSurface() throws {
        app.launch()

        let dashboardHeader = app.staticTexts["today.dashboard.header"]
        XCTAssertTrue(
            dashboardHeader.waitForExistence(timeout: 10),
            "Expected the deterministic fresh-day seed to launch on Today's dashboard surface."
        )

        XCTAssertTrue(app.tabBars.buttons["Today"].exists)
    }
}
