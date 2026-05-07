import XCTest

final class OwloryUITests: XCTestCase {
    private let continueFixtureItemID = "9D215686-176C-4C13-936E-AB3092D62A96"
    private let continueFixtureItemTitle = "Review seeded Continue item"
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testSeededTodayLaunchSurface() throws {
        launch(arguments: ["--owlory-ui-seed-fresh-day"])

        let dashboardHeader = app.staticTexts["today.dashboard.header"]
        XCTAssertTrue(
            dashboardHeader.waitForExistence(timeout: 10),
            "Expected the deterministic fresh-day seed to launch on Today's dashboard surface."
        )

        XCTAssertTrue(app.tabBars.buttons["Today"].exists)
    }

    func testSeededTodayContinueItemAppears() throws {
        launch(arguments: ["--owlory-ui-seed-today-continue-item"])

        let dashboardHeader = app.staticTexts["today.dashboard.header"]
        XCTAssertTrue(
            dashboardHeader.waitForExistence(timeout: 10),
            "Expected the deterministic Continue seed to launch on Today's dashboard surface."
        )

        let continueHeader = app.staticTexts["today.continue.header"]
        XCTAssertTrue(
            continueHeader.waitForExistence(timeout: 10),
            "Expected the deterministic Continue seed to render the Continue section."
        )

        let itemIdentifier = "today.continue.item.focusItem.\(continueFixtureItemID)"
        XCTAssertTrue(
            app.buttons[itemIdentifier].waitForExistence(timeout: 10),
            "Expected the seeded Focus item to render as a Continue row."
        )
        XCTAssertTrue(app.staticTexts[continueFixtureItemTitle].exists)
    }

    private func launch(arguments: [String]) {
        app.launchArguments = ["--owlory-ui-testing"] + arguments
        app.launch()
    }
}
