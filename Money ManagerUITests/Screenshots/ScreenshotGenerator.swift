//
//  ScreenshotGenerator.swift
//  Money Manager UITests
//
//  Generates screenshots for all app screens using a throw-away test account.
//  The account is created fresh each run, seeded with realistic data, and
//  deleted once all screenshots are captured.
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

// MARK: - ScreenshotGenerator

final class ScreenshotGenerator: XCTestCase {

    var app: XCUIApplication!
    private let testUser = ScreenshotTestUser()

    // MARK: Setup / Teardown

    override func setUpWithError() throws {
        continueAfterFailure = true

        var token: String = ""
        var setupError: Error?
        let setupExpectation = expectation(description: "test user created")
        Task {
            do {
                token = try await testUser.setUp()
            } catch {
                setupError = error
            }
            setupExpectation.fulfill()
        }
        wait(for: [setupExpectation], timeout: 30)
        if let setupError {
            XCTFail("Screenshot test user setup failed: \(setupError.localizedDescription)")
            return
        }

        app = XCUIApplication()
        app.launchArguments = [
            "--uitesting",
            "--screenshotMode",
            "--skipOnboarding",
        ]
        app.launchEnvironment["SCREENSHOT_TOKEN"] = token
        app.launch()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 20), "App did not load after login")

        // Wait for sync to complete by confirming seeded data appears in the Transactions tab.
        // waitForExistence polls at ~0.1s intervals — no artificial sleep.
        app.tabBars.buttons["Transactions"].tap()
        XCTAssertTrue(
            app.buttons.matching(identifier: "transaction.row").firstMatch.waitForExistence(timeout: 30),
            "Sync did not deliver transactions within 30 seconds"
        )
        app.tabBars.buttons["Overview"].tap()
    }

    override func tearDownWithError() throws {
        app?.terminate()
        app = nil

        let teardownExpectation = expectation(description: "test user deleted")
        Task {
            await testUser.tearDown()
            teardownExpectation.fulfill()
        }
        wait(for: [teardownExpectation], timeout: 15)
    }

    // MARK: - All Screens

    func testGenerateAllScreenshots() throws {
        // Main tabs
        try captureOverview()
        try captureTransactionsList()
        try captureSettings()

        // Transactions
        try captureAddTransaction()
        try captureTransactionDetail()
        try captureTransactionEdit()

        // Settings sub-pages
        try captureBudgets()
        try captureRecurringList()
        try captureCategories()
        try captureAddCategory()
        try captureCategoryEditor()
        try captureCurrencyPicker()
        try captureExportData()
        try captureEditProfile()

        // Groups (tabs + sheets)
        try captureGroupsList()
        try captureGroupDetail()
        try captureGroupMembers()
        try captureGroupBalances()
        try captureGroupTransactionDetail()
        try captureGroupAddTransaction()
        try captureGroupAddMember()
        try captureRecordSettlement()
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

    // MARK: - Main Tabs

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

    private func captureSettings() throws {
        navigateToTab("Settings")
        wait(seconds: 1)
        save(.settings)
    }

    // MARK: - Transactions

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

    private func captureTransactionDetail() throws {
        navigateToTab("Transactions")
        let row = app.buttons.matching(identifier: "transaction.row").firstMatch
        if row.waitForExistence(timeout: 3) {
            row.tap()
            wait(seconds: 0.8)
            save(.transactionDetail)
            dismissSheet()
        }
    }

    private func captureTransactionEdit() throws {
        navigateToTab("Transactions")
        let row = app.buttons.matching(identifier: "transaction.row").firstMatch
        if row.waitForExistence(timeout: 3) {
            row.tap()
            wait(seconds: 0.8)
            let editButton = app.buttons["transaction-detail.edit-button"]
            if editButton.waitForExistence(timeout: 2) {
                editButton.tap()
                wait(seconds: 0.8)
                save(.transactionEdit)
                dismissSheet()
            }
            dismissSheet()
        }
    }

    // MARK: - Settings Sub-pages

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
        // stay on categories for the next two captures
    }

    private func captureAddCategory() throws {
        // Should still be on categories after captureCategories()
        // If not, navigate there first
        if !app.navigationBars["Categories"].waitForExistence(timeout: 1) {
            navigateToSettings()
            tapRow("settings.categories-row")
            wait(seconds: 0.8)
        }
        let addButton = app.buttons["categories.add-button"]
        if addButton.waitForExistence(timeout: 3) {
            addButton.tap()
            wait(seconds: 0.8)
            save(.addCategory)
            dismissSheet()
        }
    }

    private func captureCategoryEditor() throws {
        // Should still be on categories page
        if !app.navigationBars["Categories"].waitForExistence(timeout: 1) {
            navigateToSettings()
            tapRow("settings.categories-row")
            wait(seconds: 0.8)
        }
        let row = app.buttons.matching(identifier: "category.row").firstMatch
        if row.waitForExistence(timeout: 3) {
            row.tap()
            wait(seconds: 0.8)
            save(.categoryEditor)
            dismissSheet()
        }
        goBack()
    }

    private func captureCurrencyPicker() throws {
        navigateToSettings()
        tapRow("settings.currency-row")
        wait(seconds: 0.8)
        save(.currencyPicker)
        goBack()
    }

    private func captureExportData() throws {
        navigateToSettings()
        tapRow("settings.backup-row")
        wait(seconds: 0.8)
        save(.exportData)
        goBack()
    }

    private func captureEditProfile() throws {
        navigateToSettings()
        let profileButton = app.buttons["settings.edit-profile-button"]
        if profileButton.waitForExistence(timeout: 3) {
            profileButton.tap()
            wait(seconds: 0.8)
            save(.editProfile)
            dismissSheet()
        }
    }

    // MARK: - Groups

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
            // stay in group detail for next captures
        }
    }

    private func captureGroupMembers() throws {
        ensureInGroupDetail()
        let seg = app.segmentedControls.firstMatch
        if seg.waitForExistence(timeout: 2) {
            seg.buttons["Members"].tap()
            wait(seconds: 0.8)
        }
        save(.groupMembers)
    }

    private func captureGroupBalances() throws {
        ensureInGroupDetail()
        let seg = app.segmentedControls.firstMatch
        if seg.waitForExistence(timeout: 2) {
            seg.buttons["Balances"].tap()
            wait(seconds: 0.8)
        }
        save(.groupBalances)
        // Tap back to Transactions segment — scope to the segmented control to avoid
        // ambiguity with the tab bar "Transactions" button.
        let segControl = app.segmentedControls.firstMatch
        if segControl.waitForExistence(timeout: 2) {
            segControl.buttons["Transactions"].tap()
            wait(seconds: 0.5)
        }
    }

    private func captureGroupTransactionDetail() throws {
        ensureInGroupDetail()
        let txRow = app.buttons.matching(identifier: "group-detail.transaction-row").firstMatch
        if txRow.waitForExistence(timeout: 3) {
            txRow.tap()
            wait(seconds: 0.8)
            save(.groupTransactionDetail)
            dismissSheet()
        }
    }

    private func captureGroupAddTransaction() throws {
        ensureInGroupDetail()
        let addButton = app.buttons["group-detail.add-transaction-button"]
        if addButton.waitForExistence(timeout: 3) {
            addButton.tap()
            wait(seconds: 0.8)
            save(.groupAddTransaction)
            dismissSheet()
        }
    }

    private func captureGroupAddMember() throws {
        ensureInGroupDetail()
        let seg = app.segmentedControls.firstMatch
        if seg.waitForExistence(timeout: 2) {
            seg.buttons["Members"].tap()
            wait(seconds: 0.5)
        }
        let addMemberButton = app.buttons["group-detail.add-member-button"]
        if addMemberButton.waitForExistence(timeout: 3) {
            addMemberButton.tap()
            wait(seconds: 0.8)
            save(.groupAddMember)
            dismissSheet()
        }
        // Restore Transactions segment
        if seg.waitForExistence(timeout: 2) { seg.buttons["Transactions"].tap() }
    }

    private func captureRecordSettlement() throws {
        ensureInGroupDetail()
        let seg = app.segmentedControls.firstMatch
        if seg.waitForExistence(timeout: 2) {
            seg.buttons["Balances"].tap()
            wait(seconds: 0.5)
        }
        let settleButton = app.buttons["group-detail.settle-button"]
        if settleButton.waitForExistence(timeout: 3) {
            settleButton.tap()
            wait(seconds: 0.8)
            save(.recordSettlement)
            dismissSheet()
        } else {
            // No unsettled balances — still save a placeholder of the balances screen
            save(.recordSettlement)
        }
        goBack()
    }

    // MARK: - Dispatch by Tag

    private func captureScreen(_ tag: ScreenshotTag) throws {
        switch tag {
        case .overview:               try captureOverview()
        case .transactionsList:       try captureTransactionsList()
        case .settings:               try captureSettings()
        case .addTransaction:         try captureAddTransaction()
        case .addTransactionShared:   try captureGroupAddTransaction()
        case .transactionDetail:      try captureTransactionDetail()
        case .transactionEdit:        try captureTransactionEdit()
        case .budgets:                try captureBudgets()
        case .recurringList:          try captureRecurringList()
        case .categories:             try captureCategories(); goBack()
        case .addCategory:            try captureCategories(); try captureAddCategory(); goBack()
        case .categoryEditor:         try captureCategories(); try captureCategoryEditor()
        case .currencyPicker:         try captureCurrencyPicker()
        case .exportData:             try captureExportData()
        case .editProfile:            try captureEditProfile()
        case .groupsList:             try captureGroupsList()
        case .groupDetail:            try captureGroupDetail(); goBack()
        case .groupMembers:           try captureGroupDetail(); try captureGroupMembers(); goBack()
        case .groupBalances:          try captureGroupDetail(); try captureGroupBalances(); goBack()
        case .groupTransactionDetail: try captureGroupDetail(); try captureGroupTransactionDetail(); goBack()
        case .groupAddTransaction:    try captureGroupDetail(); try captureGroupAddTransaction(); goBack()
        case .groupAddMember:         try captureGroupDetail(); try captureGroupAddMember(); goBack()
        case .recordSettlement:       try captureGroupDetail(); try captureRecordSettlement()
        }
    }

    // MARK: - Helpers

    /// Ensures we are on the group detail screen. If not, navigates there.
    private func ensureInGroupDetail() {
        // Check if the segmented control (Transactions/Members/Balances) is visible.
        // We cannot use app.buttons["Transactions"] because the tab bar always has a
        // "Transactions" button, causing a false positive even when not in group detail.
        guard !app.segmentedControls.firstMatch.waitForExistence(timeout: 1) else { return }

        navigateToTab("Groups")
        let firstGroup = app.buttons.matching(identifier: "groups.group-row").firstMatch
        if firstGroup.waitForExistence(timeout: 5) {
            firstGroup.tap()
            wait(seconds: 1)
        }
    }

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
        let row = app.buttons.matching(identifier: identifier).firstMatch
        if row.waitForExistence(timeout: 3) {
            row.tap()
        }
    }

    private func goBack() {
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.waitForExistence(timeout: 1) && backButton.isHittable {
            backButton.tap()
            wait(seconds: 0.4)
            return
        }
        dismissSheet()
    }

    private func dismissSheet() {
        for label in ["Cancel", "Done", "Close"] {
            let btn = app.buttons[label]
            if btn.waitForExistence(timeout: 1) && btn.isHittable {
                btn.tap()
                wait(seconds: 0.3)
                return
            }
        }
        app.swipeDown()
        wait(seconds: 0.3)
    }

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
