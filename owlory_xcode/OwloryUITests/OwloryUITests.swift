import XCTest

final class OwloryUITests: XCTestCase {
    private let continueFixtureItemID = "9D215686-176C-4C13-936E-AB3092D62A96"
    private let continueFixtureItemTitle = "Review seeded Continue item"
    private let homeTaskContinueFixtureItemID = "4D890346-1DE3-4A1E-A55F-FBD97FD08D4E"
    private let homeTaskContinueFixtureItemTitle = "Review seeded Home task"
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

    func testSeededTodayContinueItemCanBeMarkedDone() throws {
        launch(arguments: ["--owlory-ui-seed-today-continue-item"])

        let dashboardHeader = app.staticTexts["today.dashboard.header"]
        XCTAssertTrue(
            dashboardHeader.waitForExistence(timeout: 10),
            "Expected the deterministic Continue seed to launch on Today's dashboard surface."
        )

        let itemIdentifier = "today.continue.item.focusItem.\(continueFixtureItemID)"
        let item = app.buttons[itemIdentifier]
        XCTAssertTrue(
            item.waitForExistence(timeout: 10),
            "Expected the seeded Focus item to render before marking it done."
        )

        item.swipeRight()

        let doneIdentifier = "today.continue.action.done.focusItem.\(continueFixtureItemID)"
        let doneButton = app.buttons[doneIdentifier]
        XCTAssertTrue(
            doneButton.waitForExistence(timeout: 10),
            "Expected the seeded Focus-backed Continue row to expose the Done swipe action."
        )

        doneButton.tap()

        let rowRemoved = expectation(
            for: NSPredicate(format: "exists == false"),
            evaluatedWith: item,
            handler: nil
        )
        wait(for: [rowRemoved], timeout: 10)
    }

    func testSeededHomeTaskAppearsInTodayContinue() throws {
        launch(arguments: ["--owlory-ui-seed-home-task-continue-item"])

        let dashboardHeader = app.staticTexts["today.dashboard.header"]
        XCTAssertTrue(
            dashboardHeader.waitForExistence(timeout: 10),
            "Expected the deterministic Home task seed to launch on Today's dashboard surface."
        )

        let continueHeader = app.staticTexts["today.continue.header"]
        XCTAssertTrue(
            continueHeader.waitForExistence(timeout: 10),
            "Expected the deterministic Home task seed to render the Continue section."
        )

        let itemIdentifier = "today.continue.item.homeTask.\(homeTaskContinueFixtureItemID)"
        XCTAssertTrue(
            app.buttons[itemIdentifier].waitForExistence(timeout: 10),
            "Expected the seeded active Home task to render as a source-derived Continue row."
        )
        XCTAssertTrue(app.staticTexts[homeTaskContinueFixtureItemTitle].exists)
    }

    func testSeededHomeTaskContinueRowRoutesToHomeTask() throws {
        launch(arguments: ["--owlory-ui-seed-home-task-continue-item"])

        let dashboardHeader = app.staticTexts["today.dashboard.header"]
        XCTAssertTrue(
            dashboardHeader.waitForExistence(timeout: 10),
            "Expected the deterministic Home task seed to launch on Today's dashboard surface."
        )

        let continueItemIdentifier = "today.continue.item.homeTask.\(homeTaskContinueFixtureItemID)"
        let continueItem = app.buttons[continueItemIdentifier]
        XCTAssertTrue(
            continueItem.waitForExistence(timeout: 10),
            "Expected the seeded active Home task to render before routing from Continue."
        )

        continueItem.tap()

        let homeTaskIdentifier = "home.task.item.\(homeTaskContinueFixtureItemID)"
        let homeTask = app.buttons[homeTaskIdentifier]
        XCTAssertTrue(
            homeTask.waitForExistence(timeout: 10),
            "Expected tapping the Home-task-backed Continue row to route to Home with the seeded task visible."
        )
        XCTAssertTrue(app.staticTexts[homeTaskContinueFixtureItemTitle].exists)
    }

    private func launch(arguments: [String]) {
        app.launchArguments = ["--owlory-ui-testing"] + arguments
        app.launch()
    }
}
