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

/// Second UI regression batch defined by `docs/workflows/ui-regression-plan.md`.
/// Targets the Write capture inbox surface, not Today Continue.
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
        // visibility; exercising the side effect belongs to a follow-up slice.
    }

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

/// Third UI regression batch defined by `docs/workflows/ui-regression-plan.md`.
/// Keeps the Train active/history transition separate from the Today Continue
/// and Write capture regression batches.
final class TrainRegression: XCTestCase {
    private let dueTodayTrainingContinueFixtureSessionID = "B7E14C81-6D2A-4F3E-9C0B-5A8D2E1F4C9D"
    private let dueTodayTrainingContinueFixtureTitle = "Review seeded Training session"
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testSeededTrainSessionMovesFromActiveTodayToHistoryWhenCompleted() throws {
        launch(arguments: ["--owlory-ui-seed-due-today-training-continue-item"])

        let trainTab = app.tabBars.buttons["Train"]
        XCTAssertTrue(
            trainTab.waitForExistence(timeout: 10),
            "Expected the Train tab to be available after seeded launch."
        )
        trainTab.tap()

        let activeIdentifier = "train.session.item.\(dueTodayTrainingContinueFixtureSessionID)"
        let activeSession = app.otherElements[activeIdentifier]
        XCTAssertTrue(
            activeSession.waitForExistence(timeout: 10),
            "Expected the seeded planned Train session to appear in the active Today section."
        )
        XCTAssertTrue(app.staticTexts[dueTodayTrainingContinueFixtureTitle].exists)

        let readinessIdentifier = "train.session.readiness.\(dueTodayTrainingContinueFixtureSessionID)"
        let readinessDisclosure = app.buttons[readinessIdentifier]
        if readinessDisclosure.waitForExistence(timeout: 3), readinessDisclosure.isHittable {
            readinessDisclosure.tap()
        }

        let completedIdentifier = "train.session.status.completed.\(dueTodayTrainingContinueFixtureSessionID)"
        let completedButton = app.buttons[completedIdentifier]
        scrollToElement(completedButton)
        XCTAssertTrue(
            completedButton.waitForExistence(timeout: 10),
            "Expected the seeded Train session to expose a Completed status action."
        )
        completedButton.tap()

        let saveIdentifier = "train.session.save.\(dueTodayTrainingContinueFixtureSessionID)"
        let saveButton = app.buttons[saveIdentifier]
        scrollToElement(saveButton)
        XCTAssertTrue(
            saveButton.waitForExistence(timeout: 10),
            "Expected the seeded Train session to expose Save after choosing a terminal status."
        )
        let saveEnabled = expectation(
            for: NSPredicate(format: "isEnabled == true"),
            evaluatedWith: saveButton,
            handler: nil
        )
        wait(for: [saveEnabled], timeout: 5)
        saveButton.tap()

        let activeRowRemoved = expectation(
            for: NSPredicate(format: "exists == false"),
            evaluatedWith: activeSession,
            handler: nil
        )
        wait(for: [activeRowRemoved], timeout: 10)

        let historyIdentifier = "train.session.history.item.\(dueTodayTrainingContinueFixtureSessionID)"
        let historySession = app.otherElements[historyIdentifier]
        scrollToElement(historySession)
        XCTAssertTrue(
            historySession.waitForExistence(timeout: 10),
            "Expected the completed Train session to move into History."
        )
        XCTAssertTrue(app.staticTexts[dueTodayTrainingContinueFixtureTitle].exists)

        let completedHistoryStatusIdentifier = "train.session.history.status.completed.\(dueTodayTrainingContinueFixtureSessionID)"
        XCTAssertTrue(
            app.staticTexts[completedHistoryStatusIdentifier].exists,
            "Expected the Train history row to show the completed status."
        )
    }

    private func launch(arguments: [String]) {
        app.launchArguments = ["--owlory-ui-testing"] + arguments
        app.launch()
    }

    private func scrollToElement(_ element: XCUIElement, maxSwipes: Int = 4) {
        var remainingSwipes = maxSwipes
        while !element.isHittable && remainingSwipes > 0 {
            app.swipeUp()
            remainingSwipes -= 1
        }
    }
}

/// Fourth UI regression batch defined by `docs/workflows/ui-regression-plan.md`.
/// Targets Home protocol template archive/restore management only. Active-run
/// lifecycle, schedule labels, step revert, and per-step archive are separate
/// product/testing surfaces.
final class HomeProtocolRegression: XCTestCase {
    private let protocolTemplateFixtureID = "8B82E9F0-7A18-4B5D-A23E-3CF9C61C7A1D"
    private let protocolTemplateFixtureTitle = "Review seeded protocol template"
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testSeededProtocolTemplateCanArchiveAndRestore() throws {
        launch(arguments: ["--owlory-ui-seed-home-protocol-template"])
        openHome()

        let activeIdentifier = "home.protocol.item.\(protocolTemplateFixtureID)"
        let activeProtocol = element(identifier: activeIdentifier)
        XCTAssertTrue(
            activeProtocol.waitForExistence(timeout: 10),
            "Expected the seeded protocol template to appear in the active Protocols list."
        )
        XCTAssertTrue(app.staticTexts[protocolTemplateFixtureTitle].exists)

        let archiveIdentifier = "home.protocol.archive.\(protocolTemplateFixtureID)"
        let archiveButton = app.buttons[archiveIdentifier]
        XCTAssertTrue(
            archiveButton.waitForExistence(timeout: 10),
            "Expected the seeded protocol template to expose a direct protocol-level archive affordance."
        )
        archiveButton.tap()

        waitForElementToDisappear(activeProtocol)

        let archivedDisclosure = app.buttons["Archived Protocols"]
        XCTAssertTrue(
            archivedDisclosure.waitForExistence(timeout: 10),
            "Expected archiving the protocol template to reveal the Archived Protocols section."
        )
        archivedDisclosure.tap()

        let archivedIdentifier = "home.protocol.archived.item.\(protocolTemplateFixtureID)"
        let archivedProtocol = element(identifier: archivedIdentifier)
        XCTAssertTrue(
            archivedProtocol.waitForExistence(timeout: 10),
            "Expected the archived protocol template to move into Archived Protocols."
        )
        XCTAssertTrue(app.staticTexts[protocolTemplateFixtureTitle].exists)

        let restoreIdentifier = "home.protocol.restore.\(protocolTemplateFixtureID)"
        let restoreButton = app.buttons[restoreIdentifier]
        XCTAssertTrue(
            restoreButton.waitForExistence(timeout: 10),
            "Expected the archived protocol template to expose a restore affordance."
        )
        restoreButton.tap()

        waitForElementToDisappear(archivedProtocol)
        XCTAssertTrue(
            activeProtocol.waitForExistence(timeout: 10),
            "Expected restoring the protocol template to return it to the active Protocols list."
        )
        XCTAssertTrue(app.staticTexts[protocolTemplateFixtureTitle].exists)
    }

    private func launch(arguments: [String]) {
        app.launchArguments = ["--owlory-ui-testing"] + arguments
        app.terminate()
        app.launch()
    }

    private func openHome() {
        let dashboardHeader = app.staticTexts["today.dashboard.header"]
        XCTAssertTrue(
            dashboardHeader.waitForExistence(timeout: 10),
            "Expected the deterministic seed to launch on Today's dashboard before navigating to Home."
        )

        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(
            homeTab.waitForExistence(timeout: 10),
            "Expected the Home tab to be reachable from the tab bar."
        )
        homeTab.tap()
    }

    private func element(identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private func waitForElementToDisappear(_ element: XCUIElement) {
        let removal = expectation(
            for: NSPredicate(format: "exists == false"),
            evaluatedWith: element,
            handler: nil
        )
        wait(for: [removal], timeout: 10)
    }
}

/// Batch 5 regression: Home protocol run step progression. Separate from
/// `HomeProtocolRegression` (Batch 4 archive/restore of templates). Reaches the
/// active-run sheet via the existing Today Continue route smoke and proves the
/// per-step Complete action transitions a pending step out of pending state.
///
/// Scope intentionally narrow: only the first pending step's Complete action.
/// Step skip, step revert, schedule windows, protocol template editing, and
/// archive flows are out of scope.
final class HomeProtocolRunStepRegression: XCTestCase {
    private let homeProtocolRunContinueFixtureRunID = "C9B98DD8-9AA9-4D8C-B0F7-8E82CF280A5A"
    private let homeProtocolRunContinueFixtureStepID = "079B060C-76D4-466A-82FB-22D69F65E8DE"
    private let homeProtocolRunContinueFixtureTitle = "Review seeded protocol run"
    private let homeProtocolRunContinueFixtureStepTitle = "Check seeded protocol step"
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testSeededProtocolRunStepCompleteTransitionsOutOfPending() throws {
        launch(arguments: ["--owlory-ui-seed-home-protocol-run-continue-item"])

        let dashboardHeader = app.staticTexts["today.dashboard.header"]
        XCTAssertTrue(
            dashboardHeader.waitForExistence(timeout: 10),
            "Expected the deterministic seed to launch on Today's dashboard."
        )

        let continueRowIdentifier = "today.continue.item.homeProtocolRun.\(homeProtocolRunContinueFixtureRunID)"
        let continueRow = app.buttons[continueRowIdentifier]
        XCTAssertTrue(
            continueRow.waitForExistence(timeout: 10),
            "Expected the seeded protocol run to render as a Continue row."
        )
        continueRow.tap()

        let sheetIdentifier = "home.protocolRun.sheet.\(homeProtocolRunContinueFixtureRunID)"
        XCTAssertTrue(
            app.staticTexts[sheetIdentifier].waitForExistence(timeout: 10),
            "Expected the active protocol-run sheet to present after tapping the Continue row."
        )

        let stepIdentifier = "home.protocolRun.step.\(homeProtocolRunContinueFixtureStepID)"
        let stepRow = app
            .descendants(matching: .any)
            .matching(identifier: stepIdentifier)
            .firstMatch
        XCTAssertTrue(
            stepRow.waitForExistence(timeout: 10),
            "Expected the seeded pending step row to render in the active-run sheet."
        )

        let completeActionIdentifier = "home.protocolRun.step.action.complete.\(homeProtocolRunContinueFixtureStepID)"
        let completeButton = app
            .descendants(matching: .any)
            .matching(identifier: completeActionIdentifier)
            .firstMatch
        XCTAssertTrue(
            completeButton.waitForExistence(timeout: 10),
            "Expected the per-step Complete action to be reachable on the seeded pending step."
        )
        completeButton.tap()

        let completeButtonGone = expectation(
            for: NSPredicate(format: "exists == false"),
            evaluatedWith: completeButton,
            handler: nil
        )
        wait(for: [completeButtonGone], timeout: 10)

        XCTAssertTrue(
            app.staticTexts[homeProtocolRunContinueFixtureStepTitle].exists,
            "Expected the step title to remain visible after the step transitions out of pending."
        )
    }

    private func launch(arguments: [String]) {
        app.launchArguments = ["--owlory-ui-testing"] + arguments
        app.launch()
    }
}

/// Batch 7 regression: representative locale launch-shell stability.
///
/// Scope: prove the Today dashboard shell and the root tab bar remain reachable
/// under `-AppleLanguages` / `-AppleLocale` launch arguments for four
/// representative locales: English (`en`), German (`de`), Arabic (`ar`, RTL),
/// and Simplified Chinese (`zh-Hans`, CJK). Assertions go through stable
/// accessibility identifiers, not translated labels.
///
/// Does NOT prove: translation quality, translated-text layout correctness, all
/// 19 supported locales in Lane 2, pseudo or long-text layout stress, Dynamic
/// Type matrix coverage, screenshot proof, device proof, or TestFlight proof.
/// Non-English values currently fall back to English placeholders; this batch
/// is a launch-shell guard only.
final class LocalizationLayoutRegression: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testFreshDayShellSettlesUnderEnglishLocale() throws {
        launch(language: "en", locale: "en_US")
        assertShellSettled()
    }

    func testFreshDayShellSettlesUnderGermanLocale() throws {
        launch(language: "de", locale: "de_DE")
        assertShellSettled()
    }

    func testFreshDayShellSettlesUnderArabicLocale() throws {
        launch(language: "ar", locale: "ar_SA")
        assertShellSettled()
    }

    func testFreshDayShellSettlesUnderSimplifiedChineseLocale() throws {
        launch(language: "zh-Hans", locale: "zh_Hans_CN")
        assertShellSettled()
    }

    private func launch(language: String, locale: String) {
        app.launchArguments = [
            "--owlory-ui-testing",
            "--owlory-ui-seed-fresh-day",
            "-AppleLanguages",
            "(\(language))",
            "-AppleLocale",
            locale,
        ]
        app.launch()
    }

    private func assertShellSettled() {
        let dashboardHeader = app.staticTexts["today.dashboard.header"]
        XCTAssertTrue(
            dashboardHeader.waitForExistence(timeout: 15),
            "Expected the Today dashboard shell to settle under the seeded fresh-day launch for this locale."
        )

        // Tab-bar presence is the locale-agnostic shell signal: stable
        // accessibility identifiers on TabView children attach to active-tab
        // content rather than tab-bar buttons, so the tab bar itself is the
        // load-bearing element. SwiftUI exposes the five tab buttons through
        // `app.tabBars.firstMatch.buttons` regardless of locale or
        // translated `tabItem` labels.
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(
            tabBar.waitForExistence(timeout: 10),
            "Expected the root tab bar to remain present under this locale."
        )

        let expectedTabCount = 5
        let tabButtons = tabBar.buttons
        XCTAssertEqual(
            tabButtons.count, expectedTabCount,
            "Expected exactly \(expectedTabCount) tab-bar buttons under this locale; the shell must not blank or hide tabs."
        )

        for index in 0..<expectedTabCount {
            let tabButton = tabButtons.element(boundBy: index)
            XCTAssertTrue(
                tabButton.exists,
                "Expected tab-bar button at index \(index) to exist under this locale."
            )
            XCTAssertTrue(
                tabButton.isHittable,
                "Expected tab-bar button at index \(index) to remain hittable under this locale."
            )
        }
    }
}

/// Maintained representative checks that the Owlory tab shell remains usable
/// when localized text grows under Dynamic Type/Larger Accessibility Text and
/// that the root tab bar exposes non-empty accessibility labels and reasonable
/// touch targets across locales.
///
/// These checks are explicit non-claims: they prove launch-shell stability
/// under accessibility text-size launch arguments and tab-bar reachability
/// across two representative locales (English source + German native-reviewed).
/// They do NOT prove translation quality, full HIG layout correctness for
/// other locales, device behavior, or TestFlight behavior. They do NOT claim
/// `hig-ui-reviewed` for any locale.
final class LocalizationAccessibilityRegression: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testFreshDayShellSettlesUnderLargerAccessibilityTextEnglish() throws {
        launch(
            language: "en",
            locale: "en_US",
            contentSizeCategory: "UICTContentSizeCategoryAccessibilityXL"
        )
        assertShellSettled()
    }

    func testFreshDayShellSettlesUnderLargerAccessibilityTextGerman() throws {
        launch(
            language: "de",
            locale: "de_DE",
            contentSizeCategory: "UICTContentSizeCategoryAccessibilityXL"
        )
        assertShellSettled()
    }

    // The seven tests below cover the bucket-gate locales whose tab labels were
    // flagged for tab-bar truncation risk (HIG-FR-001, HIG-JA-001, HIG-NL-001,
    // HIG-RU-001, HIG-TR-001, HIG-UK-001, HIG-AR-003). At iPhone default width
    // and default Dynamic Type iOS auto-shrinks the longer labels rather than
    // truncating; these tests assert that the shell still settles and all five
    // tabs remain hittable when accessibility text size is bumped to XL.
    func testFreshDayShellSettlesUnderLargerAccessibilityTextFrench() throws {
        launch(
            language: "fr",
            locale: "fr_FR",
            contentSizeCategory: "UICTContentSizeCategoryAccessibilityXL"
        )
        assertShellSettled()
    }

    func testFreshDayShellSettlesUnderLargerAccessibilityTextJapanese() throws {
        launch(
            language: "ja",
            locale: "ja_JP",
            contentSizeCategory: "UICTContentSizeCategoryAccessibilityXL"
        )
        assertShellSettled()
    }

    func testFreshDayShellSettlesUnderLargerAccessibilityTextDutch() throws {
        launch(
            language: "nl",
            locale: "nl_NL",
            contentSizeCategory: "UICTContentSizeCategoryAccessibilityXL"
        )
        assertShellSettled()
    }

    func testFreshDayShellSettlesUnderLargerAccessibilityTextRussian() throws {
        launch(
            language: "ru",
            locale: "ru_RU",
            contentSizeCategory: "UICTContentSizeCategoryAccessibilityXL"
        )
        assertShellSettled()
    }

    func testFreshDayShellSettlesUnderLargerAccessibilityTextTurkish() throws {
        launch(
            language: "tr",
            locale: "tr_TR",
            contentSizeCategory: "UICTContentSizeCategoryAccessibilityXL"
        )
        assertShellSettled()
    }

    func testFreshDayShellSettlesUnderLargerAccessibilityTextUkrainian() throws {
        launch(
            language: "uk",
            locale: "uk_UA",
            contentSizeCategory: "UICTContentSizeCategoryAccessibilityXL"
        )
        assertShellSettled()
    }

    func testFreshDayShellSettlesUnderLargerAccessibilityTextArabic() throws {
        launch(
            language: "ar",
            locale: "ar_SA",
            contentSizeCategory: "UICTContentSizeCategoryAccessibilityXL"
        )
        assertShellSettled()
    }

    func testRootTabsExposeNonEmptyAccessibilityLabelsUnderEnglish() throws {
        try assertRootTabsExposeNonEmptyAccessibilityLabels(language: "en", locale: "en_US")
    }

    // VoiceOver-coverage tests for non-English locales. XCUITest reads
    // `XCUIElement.label`, which is the accessibility label VoiceOver announces.
    // Asserting non-empty labels per locale catches the class of regression where
    // a translated tab item ends up with an empty `accessibilityLabel(...)`
    // override, which would block VoiceOver users in that locale.
    func testRootTabsExposeNonEmptyAccessibilityLabelsUnderGerman() throws {
        try assertRootTabsExposeNonEmptyAccessibilityLabels(language: "de", locale: "de_DE")
    }

    func testRootTabsExposeNonEmptyAccessibilityLabelsUnderArabic() throws {
        try assertRootTabsExposeNonEmptyAccessibilityLabels(language: "ar", locale: "ar_SA")
    }

    func testRootTabsExposeNonEmptyAccessibilityLabelsUnderJapanese() throws {
        try assertRootTabsExposeNonEmptyAccessibilityLabels(language: "ja", locale: "ja_JP")
    }

    func testRootTabsExposeNonEmptyAccessibilityLabelsUnderRussian() throws {
        try assertRootTabsExposeNonEmptyAccessibilityLabels(language: "ru", locale: "ru_RU")
    }

    private func assertRootTabsExposeNonEmptyAccessibilityLabels(
        language: String,
        locale: String
    ) throws {
        launch(language: language, locale: locale, contentSizeCategory: nil)

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(
            tabBar.waitForExistence(timeout: 15),
            "[\(language)] Expected the root tab bar to remain present for accessibility-label inspection."
        )

        let tabButtons = tabBar.buttons
        let expectedTabCount = 5
        XCTAssertEqual(
            tabButtons.count, expectedTabCount,
            "[\(language)] Expected exactly \(expectedTabCount) tab-bar buttons for accessibility-label inspection."
        )

        for index in 0..<expectedTabCount {
            let tabButton = tabButtons.element(boundBy: index)
            XCTAssertTrue(
                tabButton.exists,
                "[\(language)] Expected tab-bar button at index \(index) to exist."
            )
            let label = tabButton.label
            XCTAssertFalse(
                label.isEmpty,
                "[\(language)] Expected tab-bar button at index \(index) to expose a non-empty accessibility label; missing labels block VoiceOver users under this locale."
            )
        }
    }

    func testRootTabsRemainAt44ptTouchTargetsUnderEnglish() throws {
        launch(language: "en", locale: "en_US", contentSizeCategory: nil)

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(
            tabBar.waitForExistence(timeout: 15),
            "Expected the root tab bar to remain present for touch-target inspection."
        )

        let tabButtons = tabBar.buttons
        let expectedTabCount = 5
        XCTAssertEqual(
            tabButtons.count, expectedTabCount,
            "Expected exactly \(expectedTabCount) tab-bar buttons for touch-target inspection."
        )

        let minimumTouchTargetPoints: CGFloat = 44
        for index in 0..<expectedTabCount {
            let tabButton = tabButtons.element(boundBy: index)
            XCTAssertTrue(
                tabButton.exists,
                "Expected tab-bar button at index \(index) to exist."
            )
            let frame = tabButton.frame
            XCTAssertGreaterThanOrEqual(
                frame.width, minimumTouchTargetPoints,
                "Expected tab-bar button at index \(index) to expose at least \(minimumTouchTargetPoints)pt of hittable width per Apple HIG."
            )
            XCTAssertGreaterThanOrEqual(
                frame.height, minimumTouchTargetPoints,
                "Expected tab-bar button at index \(index) to expose at least \(minimumTouchTargetPoints)pt of hittable height per Apple HIG."
            )
        }
    }

    private func launch(language: String, locale: String, contentSizeCategory: String?) {
        var arguments = [
            "--owlory-ui-testing",
            "--owlory-ui-seed-fresh-day",
            "-AppleLanguages",
            "(\(language))",
            "-AppleLocale",
            locale,
        ]
        if let contentSizeCategory {
            arguments.append("-UIPreferredContentSizeCategoryName")
            arguments.append(contentSizeCategory)
        }
        app.launchArguments = arguments
        app.launch()
    }

    private func assertShellSettled() {
        let dashboardHeader = app.staticTexts["today.dashboard.header"]
        XCTAssertTrue(
            dashboardHeader.waitForExistence(timeout: 15),
            "Expected the Today dashboard shell to settle under the seeded fresh-day launch."
        )

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(
            tabBar.waitForExistence(timeout: 10),
            "Expected the root tab bar to remain present after settle."
        )

        let expectedTabCount = 5
        let tabButtons = tabBar.buttons
        XCTAssertEqual(
            tabButtons.count, expectedTabCount,
            "Expected exactly \(expectedTabCount) tab-bar buttons after settle; the shell must not blank or hide tabs at larger text sizes."
        )

        for index in 0..<expectedTabCount {
            let tabButton = tabButtons.element(boundBy: index)
            XCTAssertTrue(
                tabButton.exists,
                "Expected tab-bar button at index \(index) to exist after settle."
            )
            XCTAssertTrue(
                tabButton.isHittable,
                "Expected tab-bar button at index \(index) to remain hittable after settle."
            )
        }
    }
}
