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
        captureScreenshot(named: "01-today-launch")
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
        captureScreenshot(named: "02-focus-continue-item")
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
        captureScreenshot(named: "08-done-action-revealed")

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
        captureScreenshot(named: "12-defer-action-revealed")

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
        captureScreenshot(named: "13-drop-action-revealed")

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
        captureScreenshot(named: "03-home-task-continue-item")
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
        captureScreenshot(named: "09-home-task-routing")
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
        captureScreenshot(named: "04-home-protocol-routing")
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
        captureScreenshot(named: "05-training-continue-item")
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
        captureScreenshot(named: "07-carried-forward-continue-item")
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
        captureScreenshot(named: "06-writing-continue-item")
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
        captureScreenshot(named: "10-writing-routing")
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
        captureScreenshot(named: "11-training-routing")
    }

    private func launch(arguments: [String]) {
        app.launchArguments = ["--owlory-ui-testing"] + arguments
        app.launch()
    }

    /// Attach a PNG screenshot of the current simulator surface to the test
    /// result with a stable, deterministic name. The `name` parameter is the
    /// proof-pack filename stem (e.g. `01-today-launch`) so the extraction
    /// script can map it directly to `automation/proofs/owlory-ui-smoke-proof/`.
    /// `keepAlways` preserves the attachment even on passing tests, which is
    /// the screenshot-proof goal — XCUITest's default is to drop attachments
    /// on success.
    private func captureScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

/// First UI regression batch defined by `docs/workflows/ui-regression-plan.md`
/// Lane 2. Lives in the same `OwloryUITests` target as the maintained smoke
/// class above but is excluded from `make ui-smoke` via
/// `-only-testing:OwloryUITests/OwloryUITests`. The Makefile target
/// `make ui-regression` targets this class with `-only-testing:OwloryUITests/
/// TodayContinueRegression` and its own isolated DerivedData path so the smoke
/// loop stays fast and the regression lane can grow without bloating the smoke.
///
/// Initial scope per `owlory-ui-regression-batch-1-today-continue`:
///
/// - source visibility for all six composer-backed Continue sources
/// - source-derived routing for Home task, active Home protocol run,
///   in-progress Writing note, due-today Training session (focusItem and
///   carriedFocusItem routing are `N/A by contract`; both flow through the
///   same handler exercised by the source-derived tests)
/// - Continue actions exposed on focus rows: Done, Defer, Drop
final class TodayContinueRegression: XCTestCase {
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

    // MARK: - Source visibility

    func testSeededFocusItemSourceIsVisible() throws {
        launch(arguments: ["--owlory-ui-seed-today-continue-item"])
        assertTodayDashboardVisible()
        assertContinueSectionHeaderVisible()
        assertContinueRowVisible(
            identifier: "today.continue.item.focusItem.\(continueFixtureItemID)",
            title: continueFixtureItemTitle
        )
    }

    func testSeededHomeTaskSourceIsVisible() throws {
        launch(arguments: ["--owlory-ui-seed-home-task-continue-item"])
        assertTodayDashboardVisible()
        assertContinueSectionHeaderVisible()
        assertContinueRowVisible(
            identifier: "today.continue.item.homeTask.\(homeTaskContinueFixtureItemID)",
            title: homeTaskContinueFixtureItemTitle
        )
    }

    func testSeededHomeProtocolRunSourceIsVisible() throws {
        launch(arguments: ["--owlory-ui-seed-home-protocol-run-continue-item"])
        assertTodayDashboardVisible()
        assertContinueSectionHeaderVisible()
        assertContinueRowVisible(
            identifier: "today.continue.item.homeProtocolRun.\(homeProtocolRunContinueFixtureRunID)",
            title: homeProtocolRunContinueFixtureTitle
        )
    }

    func testSeededDueTodayTrainingSourceIsVisible() throws {
        launch(arguments: ["--owlory-ui-seed-due-today-training-continue-item"])
        assertTodayDashboardVisible()
        assertContinueSectionHeaderVisible()
        assertContinueRowVisible(
            identifier: "today.continue.item.trainingSession.\(dueTodayTrainingContinueFixtureSessionID)",
            title: dueTodayTrainingContinueFixtureTitle
        )
    }

    func testSeededCarriedForwardFocusSourceIsVisible() throws {
        launch(arguments: ["--owlory-ui-seed-carried-forward-focus-continue-item"])
        assertTodayDashboardVisible()
        assertContinueSectionHeaderVisible()
        assertContinueRowVisible(
            identifier: "today.continue.item.carriedFocusItem.\(carriedForwardFocusContinueFixtureItemID)",
            title: carriedForwardFocusContinueFixtureTitle
        )
    }

    func testSeededInProgressWritingSourceIsVisible() throws {
        launch(arguments: ["--owlory-ui-seed-in-progress-writing-continue-item"])
        assertTodayDashboardVisible()
        assertContinueSectionHeaderVisible()
        assertContinueRowVisible(
            identifier: "today.continue.item.writingNote.\(inProgressWritingContinueFixtureNoteID)",
            title: inProgressWritingContinueFixtureTitle
        )
    }

    // MARK: - Source-derived routing

    func testSeededHomeTaskRowRoutesToHome() throws {
        launch(arguments: ["--owlory-ui-seed-home-task-continue-item"])
        assertTodayDashboardVisible()

        let rowIdentifier = "today.continue.item.homeTask.\(homeTaskContinueFixtureItemID)"
        let row = app.buttons[rowIdentifier]
        XCTAssertTrue(
            row.waitForExistence(timeout: 10),
            "Expected the seeded Home task Continue row to render before routing."
        )

        row.tap()

        let highlightIdentifier = "home.task.item.\(homeTaskContinueFixtureItemID)"
        XCTAssertTrue(
            app.buttons[highlightIdentifier].waitForExistence(timeout: 10),
            "Expected the Home tab to surface the seeded task after tapping the Continue row."
        )
        XCTAssertTrue(app.staticTexts[homeTaskContinueFixtureItemTitle].exists)
    }

    func testSeededHomeProtocolRunRowRoutesToActiveRunSheet() throws {
        launch(arguments: ["--owlory-ui-seed-home-protocol-run-continue-item"])
        assertTodayDashboardVisible()

        let rowIdentifier = "today.continue.item.homeProtocolRun.\(homeProtocolRunContinueFixtureRunID)"
        let row = app.buttons[rowIdentifier]
        XCTAssertTrue(
            row.waitForExistence(timeout: 10),
            "Expected the seeded protocol run Continue row to render before routing."
        )

        row.tap()

        let sheetIdentifier = "home.protocolRun.sheet.\(homeProtocolRunContinueFixtureRunID)"
        XCTAssertTrue(
            app.staticTexts[sheetIdentifier].waitForExistence(timeout: 10),
            "Expected the active protocol-run sheet to present after tapping the Continue row."
        )
        XCTAssertTrue(app.navigationBars[homeProtocolRunContinueFixtureTitle].exists)
        XCTAssertTrue(app.staticTexts[homeProtocolRunContinueFixtureStepTitle].exists)
    }

    func testSeededDueTodayTrainingRowRoutesToTrain() throws {
        launch(arguments: ["--owlory-ui-seed-due-today-training-continue-item"])
        assertTodayDashboardVisible()

        let rowIdentifier = "today.continue.item.trainingSession.\(dueTodayTrainingContinueFixtureSessionID)"
        let row = app.buttons[rowIdentifier]
        XCTAssertTrue(
            row.waitForExistence(timeout: 10),
            "Expected the seeded Training session Continue row to render before routing."
        )

        row.tap()

        let highlightIdentifier = "train.session.item.\(dueTodayTrainingContinueFixtureSessionID)"
        XCTAssertTrue(
            app.otherElements[highlightIdentifier].waitForExistence(timeout: 10),
            "Expected the Train tab to surface the seeded session after tapping the Continue row."
        )
        XCTAssertTrue(app.staticTexts[dueTodayTrainingContinueFixtureTitle].exists)
    }

    func testSeededInProgressWritingRowRoutesToWriteNoteDetail() throws {
        launch(arguments: ["--owlory-ui-seed-in-progress-writing-continue-item"])
        assertTodayDashboardVisible()

        let rowIdentifier = "today.continue.item.writingNote.\(inProgressWritingContinueFixtureNoteID)"
        let row = app.buttons[rowIdentifier]
        XCTAssertTrue(
            row.waitForExistence(timeout: 10),
            "Expected the seeded Writing note Continue row to render before routing."
        )

        row.tap()

        let detailIdentifier = "write.note.detail.\(inProgressWritingContinueFixtureNoteID)"
        let detail = app
            .descendants(matching: .any)
            .matching(identifier: detailIdentifier)
            .firstMatch
        XCTAssertTrue(
            detail.waitForExistence(timeout: 10),
            "Expected the Write note detail sheet to auto-present after tapping the Continue row."
        )
    }

    // MARK: - Focus row actions

    func testSeededFocusRowExposesDoneAction() throws {
        let rowIdentifier = "today.continue.item.focusItem.\(continueFixtureItemID)"
        let row = launchAndLocateFocusRow(identifier: rowIdentifier)

        row.swipeRight()

        let doneIdentifier = "today.continue.action.done.focusItem.\(continueFixtureItemID)"
        let doneButton = app.buttons[doneIdentifier]
        XCTAssertTrue(
            doneButton.waitForExistence(timeout: 10),
            "Expected the Done leading-edge swipe action on a Focus-backed Continue row."
        )

        doneButton.tap()
        waitForRowToDisappear(row)
    }

    func testSeededFocusRowExposesDeferAction() throws {
        let rowIdentifier = "today.continue.item.focusItem.\(continueFixtureItemID)"
        let row = launchAndLocateFocusRow(identifier: rowIdentifier)

        row.swipeLeft()

        let deferIdentifier = "today.continue.action.defer.focusItem.\(continueFixtureItemID)"
        let deferButton = app.buttons[deferIdentifier]
        XCTAssertTrue(
            deferButton.waitForExistence(timeout: 10),
            "Expected the Defer trailing-edge swipe action on a Focus-backed Continue row."
        )

        deferButton.tap()
        waitForRowToDisappear(row)
    }

    func testSeededFocusRowExposesDropAction() throws {
        let rowIdentifier = "today.continue.item.focusItem.\(continueFixtureItemID)"
        let row = launchAndLocateFocusRow(identifier: rowIdentifier)

        row.swipeLeft()

        let dropIdentifier = "today.continue.action.drop.focusItem.\(continueFixtureItemID)"
        let dropButton = app.buttons[dropIdentifier]
        XCTAssertTrue(
            dropButton.waitForExistence(timeout: 10),
            "Expected the Drop trailing-edge swipe action on a Focus-backed Continue row."
        )

        dropButton.tap()
        waitForRowToDisappear(row)
    }

    // MARK: - Helpers

    private func launch(arguments: [String]) {
        app.launchArguments = ["--owlory-ui-testing"] + arguments
        app.launch()
    }

    private func launchAndLocateFocusRow(identifier: String) -> XCUIElement {
        launch(arguments: ["--owlory-ui-seed-today-continue-item"])
        assertTodayDashboardVisible()
        let row = app.buttons[identifier]
        XCTAssertTrue(
            row.waitForExistence(timeout: 10),
            "Expected the seeded Focus-backed Continue row to render before exercising swipe actions."
        )
        return row
    }

    private func assertTodayDashboardVisible() {
        let dashboardHeader = app.staticTexts["today.dashboard.header"]
        XCTAssertTrue(
            dashboardHeader.waitForExistence(timeout: 10),
            "Expected the deterministic seed to launch on Today's dashboard surface."
        )
    }

    private func assertContinueSectionHeaderVisible() {
        let continueHeader = app.staticTexts["today.continue.header"]
        XCTAssertTrue(
            continueHeader.waitForExistence(timeout: 10),
            "Expected the deterministic seed to render the Continue section header."
        )
    }

    private func assertContinueRowVisible(identifier: String, title: String) {
        XCTAssertTrue(
            app.buttons[identifier].waitForExistence(timeout: 10),
            "Expected the seeded Continue row '\(identifier)' to render."
        )
        XCTAssertTrue(
            app.staticTexts[title].exists,
            "Expected the seeded Continue row title '\(title)' to be present."
        )
    }

    private func waitForRowToDisappear(_ row: XCUIElement) {
        let removal = expectation(
            for: NSPredicate(format: "exists == false"),
            evaluatedWith: row,
            handler: nil
        )
        wait(for: [removal], timeout: 10)
    }
}

/// Second UI regression batch defined by `docs/workflows/ui-regression-plan.md`
/// Lane 2. Targets the Write capture inbox surface (the Write tab), not Today
/// Continue. Lives in the same `OwloryUITests` target as the smoke and
/// `TodayContinueRegression` classes but is reached via
/// `make ui-regression DOMAIN=write` (or by default `make ui-regression`,
/// which runs every regression class).
///
/// Scope per `owlory-ui-regression-expansion-next-surface` (selected by
/// `owlory-ui-regression-next-surface-triage` on 2026-05-13):
///
/// - Open Write from the tab bar.
/// - Render one seeded in-progress Writing note row and the capture entry
///   affordance on the Write surface.
/// - Assert one promotion affordance (Add to Today) is reachable from the
///   note detail sheet without exercising the cross-domain side effect.
///
/// Reuses `--owlory-ui-seed-in-progress-writing-continue-item` because that
/// arg already resets app-local state and writes a single capture-stage
/// `WritingNote`; the slice scope requires a deterministic seed, not a new
/// one.
///
/// Out of scope: voice/live transcription paths, task promotion side
/// effects, protocol promotion side effects, screenshot proof pack, device
/// proof, TestFlight proof.
final class WriteCaptureRegression: XCTestCase {
    private let inProgressWritingFixtureNoteID = "3D5F7A91-1E2F-4C5D-86A7-9C8D0E1F2A3B"
    private let inProgressWritingFixtureTitle = "Review seeded Writing note"
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Tests

    func testSeededWriteCaptureInboxRendersInProgressNoteRowAndCaptureEntry() throws {
        launchWriteSurface()

        let rowIdentifier = "write.note.row.\(inProgressWritingFixtureNoteID)"
        let row = app.buttons[rowIdentifier]
        XCTAssertTrue(
            row.waitForExistence(timeout: 10),
            "Expected the seeded in-progress Writing note row to render on the Write surface."
        )
        XCTAssertTrue(
            app.staticTexts[inProgressWritingFixtureTitle].exists,
            "Expected the seeded Writing note title to be visible inside its row."
        )

        let captureEntry = app.buttons["write.capture.entry"]
        XCTAssertTrue(
            captureEntry.waitForExistence(timeout: 10),
            "Expected the Write capture entry affordance to render alongside the seeded note row."
        )
    }

    func testSeededWriteNoteDetailExposesAddToTodayPromotion() throws {
        launchWriteSurface()

        let rowIdentifier = "write.note.row.\(inProgressWritingFixtureNoteID)"
        let row = app.buttons[rowIdentifier]
        XCTAssertTrue(
            row.waitForExistence(timeout: 10),
            "Expected the seeded in-progress Writing note row to render before opening the detail sheet."
        )

        row.tap()

        let detailIdentifier = "write.note.detail.\(inProgressWritingFixtureNoteID)"
        let detail = app
            .descendants(matching: .any)
            .matching(identifier: detailIdentifier)
            .firstMatch
        XCTAssertTrue(
            detail.waitForExistence(timeout: 10),
            "Expected the Write note detail sheet to present after tapping the row."
        )

        let optionsMenu = app.buttons["Note options"]
        XCTAssertTrue(
            optionsMenu.waitForExistence(timeout: 10),
            "Expected the note-options menu button to render in the detail sheet toolbar."
        )
        optionsMenu.tap()

        let addToTodayIdentifier = "write.note.action.addToToday.\(inProgressWritingFixtureNoteID)"
        let addToTodayButton = app.buttons[addToTodayIdentifier]
        XCTAssertTrue(
            addToTodayButton.waitForExistence(timeout: 10),
            "Expected Add to Today to be reachable from the note detail options menu without exercising the cross-domain side effect."
        )
        // Do not tap. The slice scope intentionally stops at affordance
        // visibility; exercising the side effect belongs to a follow-up
        // slice with its own Today-side seed and assertion.
    }

    // MARK: - Helpers

    private func launch(arguments: [String]) {
        app.launchArguments = ["--owlory-ui-testing"] + arguments
        app.launch()
    }

    private func launchWriteSurface() {
        launch(arguments: ["--owlory-ui-seed-in-progress-writing-continue-item"])
        let dashboardHeader = app.staticTexts["today.dashboard.header"]
        XCTAssertTrue(
            dashboardHeader.waitForExistence(timeout: 10),
            "Expected the deterministic seed to launch on Today's dashboard before navigating to Write."
        )

        let writeTab = app.tabBars.buttons["Write"]
        XCTAssertTrue(
            writeTab.waitForExistence(timeout: 10),
            "Expected the Write tab to be reachable from the tab bar."
        )
        writeTab.tap()
    }
}
