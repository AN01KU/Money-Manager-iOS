//
//  ScreenshotGenerator.swift
//  Money Manager UITests
//
//  Generates screenshots for all app screens using a real test account.
//  Screenshots are attached to the XCTest result bundle (keepAlways),
//  then exported to Screenshots/ via `make screenshots`.
//
//  Usage:
//    make screenshots                      → capture all screens
//    make screenshot-one TAG=overview      → capture a single screen
//
//  To add a new screen:
//    1. Add a case to ScreenshotTag
//    2. Add a captureXxx() method and call it from testGenerateAllScreenshots()
//    3. Add a case in captureScreen(_:)
//

import XCTest

// MARK: - Credentials (test account only — never a real user account)

private let screenshotEmail    = "ankush@gmail.com"
private let screenshotPassword = "12345678"

// MARK: - ScreenshotGenerator

final class ScreenshotGenerator: XCTestCase {

    var app: XCUIApplication!

    // MARK: Setup / Teardown

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            "--uitesting",
            "--screenshotMode",
            "--skipOnboarding",
            "--testEmail", screenshotEmail,
            "--testPassword", screenshotPassword
        ]
        app.launch()

        // App logs in automatically on startup — just wait for the tab bar
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 20), "App did not load after login")
        wait(seconds: 1.5) // let sync settle
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }

    // MARK: - All Screens

    func testGenerateAllScreenshots() throws {
        try captureOverview()
        try captureTransactionsList()
        try captureAddTransaction()
        try captureBudgets()
        try captureRecurringList()
        try captureCategories()
        try captureSettings()
        try captureGroupsList()
        try captureGroupDetail()
        try captureGroupBalances()
    }

    // MARK: - Single Screen (run via `make screenshot-one TAG=<rawValue>`)

    func testCaptureSingleScreen() throws {
        guard let tagValue = ProcessInfo.processInfo.environment["SCREENSHOT_TAG"],
              let tag = ScreenshotTag(rawValue: tagValue) else {
            XCTFail("Set SCREENSHOT_TAG env var to a valid ScreenshotTag rawValue")
            return
        }
        try captureScreen(tag)
    }

    // MARK: - Per-Screen Capture Methods

    private func captureOverview() throws {
        navigateToTab("Overview")
        wait(seconds: 1.5)
        save(.overview)
    }

    private func captureTransactionsList() throws {
        navigateToTab("Transactions")
        wait(seconds: 1)
        save(.transactionsList)
    }

    private func captureAddTransaction() throws {
        navigateToTab("Transactions")
        let fab = app.buttons["transactions.add-button"]
        if fab.waitForExistence(timeout: 3) {
            fab.tap()
            wait(seconds: 0.8)
            save(.addTransaction)
            dismissSheet()
        }
    }

    private func captureBudgets() throws {
        navigateToSettings()
        tapRow("settings.budgets-row")
        wait(seconds: 1)
        save(.budgets)
        goBack()
    }

    private func captureRecurringList() throws {
        navigateToSettings()
        tapRow("settings.recurring-row")
        wait(seconds: 1)
        save(.recurringList)
        goBack()
    }

    private func captureCategories() throws {
        navigateToSettings()
        tapRow("settings.categories-row")
        wait(seconds: 1)
        save(.categories)
        goBack()
    }

    private func captureSettings() throws {
        navigateToTab("Settings")
        wait(seconds: 1)
        save(.settings)
    }

    private func captureGroupsList() throws {
        navigateToTab("Groups")
        wait(seconds: 1.5)
        save(.groupsList)
    }

    private func captureGroupDetail() throws {
        navigateToTab("Groups")
        let firstGroup = app.buttons.matching(identifier: "groups.group-row").firstMatch
        if firstGroup.waitForExistence(timeout: 5) {
            firstGroup.tap()
            wait(seconds: 1)
            save(.groupDetail)
            goBack()
        }
    }

    private func captureGroupBalances() throws {
        navigateToTab("Groups")
        let firstGroup = app.buttons.matching(identifier: "groups.group-row").firstMatch
        if firstGroup.waitForExistence(timeout: 5) {
            firstGroup.tap()
            wait(seconds: 0.8)
            let balancesButton = app.buttons["Balances"]
            if balancesButton.waitForExistence(timeout: 2) {
                balancesButton.tap()
                wait(seconds: 0.8)
            }
            save(.groupBalances)
            goBack()
        }
    }

    // MARK: - Dispatch by Tag

    private func captureScreen(_ tag: ScreenshotTag) throws {
        switch tag {
        case .overview:       try captureOverview()
        case .transactionsList: try captureTransactionsList()
        case .addTransaction:   try captureAddTransaction()
        case .budgets:        try captureBudgets()
        case .recurringList:  try captureRecurringList()
        case .categories:     try captureCategories()
        case .settings:       try captureSettings()
        case .groupsList:     try captureGroupsList()
        case .groupDetail:    try captureGroupDetail()
        case .groupBalances:  try captureGroupBalances()
        }
    }

    // MARK: - Helpers

    private func navigateToTab(_ label: String) {
        let tab = app.tabBars.buttons[label]
        if tab.waitForExistence(timeout: 3) {
            tab.tap()
        }
    }

    private func navigateToSettings() {
        navigateToTab("Settings")
        wait(seconds: 0.4)
    }

    private func tapRow(_ identifier: String) {
        // NavigationLink in a List is a button in the XCTest hierarchy
        let row = app.buttons.matching(identifier: identifier).firstMatch
        if row.waitForExistence(timeout: 3) {
            row.tap()
        }
    }

    /// Navigate back — works for both nav push and sheet presentation.
    private func goBack() {
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.waitForExistence(timeout: 1) && backButton.isHittable {
            backButton.tap()
            return
        }
        dismissSheet()
    }

    private func dismissSheet() {
        let cancel = app.buttons["Cancel"]
        if cancel.waitForExistence(timeout: 1) {
            cancel.tap()
            return
        }
        app.swipeDown()
    }

    /// Attach screenshot to the XCTest result bundle under the tag's filename.
    /// The Makefile exports these from .xcresult → Screenshots/ using the manifest.
    private func save(_ tag: ScreenshotTag) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = tag.filename
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func wait(seconds: TimeInterval) {
        Thread.sleep(forTimeInterval: seconds)
    }
}
