import XCTest

final class OwloryUITests: XCTestCase {
    private let continueFixtureItemID = "9D215686-176C-4C13-936E-AB3092D62A96"
    private let continueFixtureItemTitle = "Review seeded Continue item"
    private let homeTaskContinueFixtureItemID = "4D890346-1DE3-4A1E-A55F-FBD97FD08D4E"
    private let homeTaskContinueFixtureItemTitle = "Review seeded Home task"
    private let homeProtocolRunContinueFixtureRunID = "C9B98DD8-9AA9-4D8C-B0F7-8E82CF280A5A"
    private let homeProtocolRunContinueFixtureTitle = "Review seeded protocol run"
    private let homeProtocolRunContinueFixtureStepTitle = "Check seeded protocol step"
    private let dueTodayTrainingContinueFixtureSessionID = "B7E14C81-6D2A-4F3E-9C0B-5A8D2E1F4C9D"
    private let dueTodayTrainingContinueFixtureTitle = "Review seeded Training session"
    private let carriedForwardFocusContinueFixtureItemID = "A5B7C9D1-3E5F-4A9B-8D6F-0E2C4A6B8D0F"
    private let carriedForwardFocusContinueFixtureTitle = "Review seeded carried Focus"
    private let inProgressWritingContinueFixtureNoteID = "3D5F7A91-1E2F-4C5D-86A7-9C8D0E1F2A3B"
    private let inProgressWritingContinueFixtureTitle = "Review seeded Writing note"
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

    func testSeededTodayContinueItemCanBeDeferred() throws {
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
            "Expected the seeded Focus item to render before exposing trailing swipe actions."
        )

        item.swipeLeft()

        let deferIdentifier = "today.continue.action.defer.focusItem.\(continueFixtureItemID)"
        let deferButton = app.buttons[deferIdentifier]
        XCTAssertTrue(
            deferButton.waitForExistence(timeout: 10),
            "Expected the seeded Focus-backed Continue row to expose the Defer swipe action via the trailing edge."
        )

        deferButton.tap()

        let rowRemoved = expectation(
            for: NSPredicate(format: "exists == false"),
            evaluatedWith: item,
            handler: nil
        )
        wait(for: [rowRemoved], timeout: 10)
    }

    func testSeededTodayContinueItemCanBeDropped() throws {
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
            "Expected the seeded Focus item to render before exposing trailing swipe actions."
        )

        item.swipeLeft()

        let dropIdentifier = "today.continue.action.drop.focusItem.\(continueFixtureItemID)"
        let dropButton = app.buttons[dropIdentifier]
        XCTAssertTrue(
            dropButton.waitForExistence(timeout: 10),
            "Expected the seeded Focus-backed Continue row to expose the Drop swipe action via the trailing edge."
        )

        dropButton.tap()

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

    func testSeededHomeProtocolRunContinueRowRoutesToActiveRun() throws {
        launch(arguments: ["--owlory-ui-seed-home-protocol-run-continue-item"])

        let dashboardHeader = app.staticTexts["today.dashboard.header"]
        XCTAssertTrue(
            dashboardHeader.waitForExistence(timeout: 10),
            "Expected the deterministic Home protocol run seed to launch on Today's dashboard surface."
        )

        let continueItemIdentifier = "today.continue.item.homeProtocolRun.\(homeProtocolRunContinueFixtureRunID)"
        let continueItem = app.buttons[continueItemIdentifier]
        XCTAssertTrue(
            continueItem.waitForExistence(timeout: 10),
            "Expected the seeded active Home protocol run to render before routing from Continue."
        )
        XCTAssertTrue(app.staticTexts[homeProtocolRunContinueFixtureTitle].exists)

        continueItem.tap()

        let runSheetIdentifier = "home.protocolRun.sheet.\(homeProtocolRunContinueFixtureRunID)"
        let runSheet = app.staticTexts[runSheetIdentifier]
        XCTAssertTrue(
            runSheet.waitForExistence(timeout: 10),
            "Expected tapping the protocol-run-backed Continue row to present the active run sheet."
        )
        XCTAssertTrue(app.navigationBars[homeProtocolRunContinueFixtureTitle].exists)
        XCTAssertTrue(app.staticTexts[homeProtocolRunContinueFixtureStepTitle].exists)
    }

    func testSeededDueTodayTrainingAppearsInTodayContinue() throws {
        launch(arguments: ["--owlory-ui-seed-due-today-training-continue-item"])

        let dashboardHeader = app.staticTexts["today.dashboard.header"]
        XCTAssertTrue(
            dashboardHeader.waitForExistence(timeout: 10),
            "Expected the deterministic due-today Training seed to launch on Today's dashboard surface."
        )

        let continueHeader = app.staticTexts["today.continue.header"]
        XCTAssertTrue(
            continueHeader.waitForExistence(timeout: 10),
            "Expected the deterministic due-today Training seed to render the Continue section."
        )

        let itemIdentifier = "today.continue.item.trainingSession.\(dueTodayTrainingContinueFixtureSessionID)"
        XCTAssertTrue(
            app.buttons[itemIdentifier].waitForExistence(timeout: 10),
            "Expected the seeded planned Training session to render as a due-today Continue row."
        )
        XCTAssertTrue(app.staticTexts[dueTodayTrainingContinueFixtureTitle].exists)
    }

    func testSeededCarriedForwardFocusAppearsInTodayContinue() throws {
        launch(arguments: ["--owlory-ui-seed-carried-forward-focus-continue-item"])

        let dashboardHeader = app.staticTexts["today.dashboard.header"]
        XCTAssertTrue(
            dashboardHeader.waitForExistence(timeout: 10),
            "Expected the deterministic carried-forward Focus seed to launch on Today's dashboard surface."
        )

        let continueHeader = app.staticTexts["today.continue.header"]
        XCTAssertTrue(
            continueHeader.waitForExistence(timeout: 10),
            "Expected the deterministic carried-forward Focus seed to render the Continue section."
        )

        let itemIdentifier = "today.continue.item.carriedFocusItem.\(carriedForwardFocusContinueFixtureItemID)"
        XCTAssertTrue(
            app.buttons[itemIdentifier].waitForExistence(timeout: 10),
            "Expected the seeded carried-forward Focus item to render as a Continue row via the carriedFocusItem source."
        )
        XCTAssertTrue(app.staticTexts[carriedForwardFocusContinueFixtureTitle].exists)
    }

    func testSeededInProgressWritingAppearsInTodayContinue() throws {
        launch(arguments: ["--owlory-ui-seed-in-progress-writing-continue-item"])

        let dashboardHeader = app.staticTexts["today.dashboard.header"]
        XCTAssertTrue(
            dashboardHeader.waitForExistence(timeout: 10),
            "Expected the deterministic in-progress Writing seed to launch on Today's dashboard surface."
        )

        let continueHeader = app.staticTexts["today.continue.header"]
        XCTAssertTrue(
            continueHeader.waitForExistence(timeout: 10),
            "Expected the deterministic in-progress Writing seed to render the Continue section."
        )

        let itemIdentifier = "today.continue.item.writingNote.\(inProgressWritingContinueFixtureNoteID)"
        XCTAssertTrue(
            app.buttons[itemIdentifier].waitForExistence(timeout: 10),
            "Expected the seeded in-progress Writing note to render as a Continue row via the writingNote source."
        )
        XCTAssertTrue(app.staticTexts[inProgressWritingContinueFixtureTitle].exists)
    }

    func testSeededInProgressWritingContinueRowRoutesToWriteNoteDetail() throws {
        launch(arguments: ["--owlory-ui-seed-in-progress-writing-continue-item"])

        let dashboardHeader = app.staticTexts["today.dashboard.header"]
        XCTAssertTrue(
            dashboardHeader.waitForExistence(timeout: 10),
            "Expected the deterministic in-progress Writing seed to launch on Today's dashboard surface."
        )

        let continueItemIdentifier = "today.continue.item.writingNote.\(inProgressWritingContinueFixtureNoteID)"
        let continueItem = app.buttons[continueItemIdentifier]
        XCTAssertTrue(
            continueItem.waitForExistence(timeout: 10),
            "Expected the seeded in-progress Writing note to render before routing from Continue."
        )

        continueItem.tap()

        let noteDetailIdentifier = "write.note.detail.\(inProgressWritingContinueFixtureNoteID)"
        let noteDetail = app
            .descendants(matching: .any)
            .matching(identifier: noteDetailIdentifier)
            .firstMatch
        XCTAssertTrue(
            noteDetail.waitForExistence(timeout: 10),
            "Expected tapping the writing-note-backed Continue row to auto-present the Write note detail sheet."
        )
    }

    func testSeededDueTodayTrainingContinueRowRoutesToTrain() throws {
        launch(arguments: ["--owlory-ui-seed-due-today-training-continue-item"])

        let dashboardHeader = app.staticTexts["today.dashboard.header"]
        XCTAssertTrue(
            dashboardHeader.waitForExistence(timeout: 10),
            "Expected the deterministic due-today Training seed to launch on Today's dashboard surface."
        )

        let continueItemIdentifier = "today.continue.item.trainingSession.\(dueTodayTrainingContinueFixtureSessionID)"
        let continueItem = app.buttons[continueItemIdentifier]
        XCTAssertTrue(
            continueItem.waitForExistence(timeout: 10),
            "Expected the seeded due-today Training session to render before routing from Continue."
        )

        continueItem.tap()

        let trainSessionIdentifier = "train.session.item.\(dueTodayTrainingContinueFixtureSessionID)"
        let trainSession = app.otherElements[trainSessionIdentifier]
        XCTAssertTrue(
            trainSession.waitForExistence(timeout: 10),
            "Expected tapping the training-session-backed Continue row to route to Train with the seeded session visible."
        )
        XCTAssertTrue(app.staticTexts[dueTodayTrainingContinueFixtureTitle].exists)
    }

    private func launch(arguments: [String]) {
        app.launchArguments = ["--owlory-ui-testing"] + arguments
        app.launch()
    }
}
