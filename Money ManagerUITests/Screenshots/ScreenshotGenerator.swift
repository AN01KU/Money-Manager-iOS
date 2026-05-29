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
    private var screenshotToken: String = ""

    // MARK: Setup / Teardown

    override func setUpWithError() throws {
        continueAfterFailure = true

        var setupError: Error?
        let setupExpectation = expectation(description: "test user created")
        Task {
            do {
                screenshotToken = try await testUser.setUp()
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

        launchApp()

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

        // Settings sub-pages — each requires a fresh launch with SETTINGS_ROUTE
        try captureBudgets()
        try captureRecurringList()
        try captureCategories()
        try captureAddCategory()
        try captureCategoryEditor()
        try captureCurrencyPicker()
        try captureExportData()
        try captureEditProfile()

        // Groups list — relaunch without GROUP_ROUTE so we see the list
        relaunchAppForGroups()
        try captureGroupsList()

        // Group detail screens — relaunch with GROUP_ROUTE=first to auto-push into detail
        guard relaunchAppInGroupDetail() else { return }
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
    //
    // Each capture relaunches the app with SETTINGS_ROUTE=<route>, which causes
    // SettingsView.onAppear to pre-push the destination onto the NavigationStack.
    // This sidesteps the XCUITest / SwiftUI tap-action reliability issue.

    private func captureBudgets() throws {
        relaunchApp(settingsRoute: "budgets")
        navigateToSettingsRoute(navBarTitle: "Budgets")
        save(.budgets)
    }

    private func captureRecurringList() throws {
        relaunchApp(settingsRoute: "recurring")
        navigateToSettingsRoute(navBarTitle: "Recurring")
        save(.recurringList)
    }

    private func captureCategories() throws {
        relaunchApp(settingsRoute: "categories")
        navigateToSettingsRoute(navBarTitle: "Categories")
        save(.categories)
    }

    private func captureAddCategory() throws {
        // Reuse the categories relaunch — the Categories nav bar should be visible.
        if !app.navigationBars["Categories"].waitForExistence(timeout: 3) {
            relaunchApp(settingsRoute: "categories")
            navigateToSettingsRoute(navBarTitle: "Categories")
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
        if !app.navigationBars["Categories"].waitForExistence(timeout: 3) {
            relaunchApp(settingsRoute: "categories")
            navigateToSettingsRoute(navBarTitle: "Categories")
        }
        let row = app.buttons.matching(identifier: "category.row").firstMatch
        if row.waitForExistence(timeout: 3) {
            row.tap()
            wait(seconds: 0.8)
            save(.categoryEditor)
            dismissSheet()
        }
    }

    private func captureCurrencyPicker() throws {
        relaunchApp(settingsRoute: "currency")
        navigateToSettingsRoute(navBarTitle: "Currency")
        save(.currencyPicker)
    }

    private func captureExportData() throws {
        relaunchApp(settingsRoute: "backup")
        navigateToSettingsRoute(navBarTitle: "Backup")
        save(.exportData)
    }

    private func captureEditProfile() throws {
        relaunchApp()
        navigateToSettings()
        let profileButton = app.buttons["settings.edit-profile-button"]
        if profileButton.waitForExistence(timeout: 5) {
            profileButton.tap()
            wait(seconds: 0.8)
            save(.editProfile)
            dismissSheet()
        }
    }

    // MARK: - Groups

    private func captureGroupsList() throws {
        navigateToTab("Groups")
        _ = app.buttons.matching(identifier: "groups.group-row").firstMatch.waitForExistence(timeout: 10)
        wait(seconds: 0.5)
        save(.groupsList)
    }

    private func captureGroupDetail() throws {
        // Already in group detail from relaunchAppInGroupDetail() — just save.
        wait(seconds: 0.5)
        save(.groupDetail)
    }

    private func captureGroupMembers() throws {
        guard ensureInGroupDetail() else { return }
        let seg = app.segmentedControls.matching(identifier: "group-detail.section-picker").firstMatch
        if seg.waitForExistence(timeout: 3) {
            seg.buttons["Members"].tap()
            // Wait for the add-member button to appear — it only shows on the Members tab
            _ = app.buttons["group-detail.add-member-button"].waitForExistence(timeout: 3)
            wait(seconds: 0.5)
        }
        save(.groupMembers)
    }

    private func captureGroupBalances() throws {
        guard ensureInGroupDetail() else { return }
        let seg = app.segmentedControls.matching(identifier: "group-detail.section-picker").firstMatch
        if seg.waitForExistence(timeout: 3) {
            seg.buttons["Balances"].tap()
            wait(seconds: 0.8)
        }
        save(.groupBalances)
        // Restore Transactions segment
        if seg.waitForExistence(timeout: 2) {
            seg.buttons["Transactions"].tap()
            _ = app.buttons["group-detail.add-transaction-button"].waitForExistence(timeout: 3)
        }
    }

    private func captureGroupTransactionDetail() throws {
        guard ensureInGroupDetail() else { return }
        let txRow = app.buttons.matching(identifier: "group-detail.transaction-row").firstMatch
        if txRow.waitForExistence(timeout: 3) {
            txRow.tap()
            wait(seconds: 0.8)
            save(.groupTransactionDetail)
            dismissSheet()
        }
    }

    private func captureGroupAddTransaction() throws {
        guard ensureInGroupDetail() else { return }
        let addButton = app.buttons["group-detail.add-transaction-button"]
        if addButton.waitForExistence(timeout: 3) {
            addButton.tap()
            wait(seconds: 0.8)
            save(.groupAddTransaction)
            dismissSheet()
        }
    }

    private func captureGroupAddMember() throws {
        guard ensureInGroupDetail() else { return }
        let seg = app.segmentedControls.matching(identifier: "group-detail.section-picker").firstMatch
        if seg.waitForExistence(timeout: 3) {
            seg.buttons["Members"].tap()
            _ = app.buttons["group-detail.add-member-button"].waitForExistence(timeout: 3)
            wait(seconds: 0.3)
        }
        let addMemberButton = app.buttons["group-detail.add-member-button"]
        if addMemberButton.waitForExistence(timeout: 3) {
            addMemberButton.tap()
            wait(seconds: 0.8)
            save(.groupAddMember)
            dismissSheet()
        }
        // Restore Transactions segment
        if seg.waitForExistence(timeout: 2) {
            seg.buttons["Transactions"].tap()
            _ = app.buttons["group-detail.add-transaction-button"].waitForExistence(timeout: 3)
        }
    }

    private func captureRecordSettlement() throws {
        guard ensureInGroupDetail() else { return }
        let seg = app.segmentedControls.matching(identifier: "group-detail.section-picker").firstMatch
        if seg.waitForExistence(timeout: 3) {
            seg.buttons["Balances"].tap()
            wait(seconds: 0.8)
        }
        let settleButton = app.buttons["group-detail.settle-button"]
        if settleButton.waitForExistence(timeout: 3) {
            settleButton.tap()
            _ = app.navigationBars["Record Settlement"].waitForExistence(timeout: 5)
            wait(seconds: 0.5)
            save(.recordSettlement)
            dismissSheet()
        } else {
            // No unsettled balances — save balances screen as fallback
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
        case .categories:             try captureCategories()
        case .addCategory:            try captureCategories(); try captureAddCategory()
        case .categoryEditor:         try captureCategories(); try captureCategoryEditor()
        case .currencyPicker:         try captureCurrencyPicker()
        case .exportData:             try captureExportData()
        case .editProfile:            try captureEditProfile()
        case .groupsList:             relaunchAppForGroups(); try captureGroupsList()
        case .groupDetail:            if relaunchAppInGroupDetail() { try captureGroupDetail() }
        case .groupMembers:           if relaunchAppInGroupDetail() { try captureGroupMembers() }
        case .groupBalances:          if relaunchAppInGroupDetail() { try captureGroupBalances() }
        case .groupTransactionDetail: if relaunchAppInGroupDetail() { try captureGroupTransactionDetail() }
        case .groupAddTransaction:    if relaunchAppInGroupDetail() { try captureGroupAddTransaction() }
        case .groupAddMember:         if relaunchAppInGroupDetail() { try captureGroupAddMember() }
        case .recordSettlement:       if relaunchAppInGroupDetail() { try captureRecordSettlement() }
        }
    }

    // MARK: - Helpers

    /// Launches the app fresh. Call once in setUp; call again to relaunch mid-test.
    private func launchApp(settingsRoute: String? = nil, groupRoute: String? = nil) {
        app = XCUIApplication()
        app.launchArguments = [
            "--uitesting",
            "--screenshotMode",
            "--skipOnboarding",
        ]
        app.launchEnvironment["SCREENSHOT_TOKEN"] = screenshotToken
        if let route = settingsRoute {
            app.launchEnvironment["SETTINGS_ROUTE"] = route
        }
        if let route = groupRoute {
            app.launchEnvironment["GROUP_ROUTE"] = route
        }
        app.launch()
    }

    /// Terminates the current app instance and relaunches, waiting for tab bar and sync data.
    private func relaunchApp(settingsRoute: String? = nil) {
        app.terminate()
        launchApp(settingsRoute: settingsRoute)

        _ = app.tabBars.firstMatch.waitForExistence(timeout: 20)

        // Confirm sync data is still present before proceeding.
        app.tabBars.buttons["Transactions"].tap()
        _ = app.buttons.matching(identifier: "transaction.row").firstMatch.waitForExistence(timeout: 30)
        app.tabBars.buttons["Overview"].tap()
    }

    /// Relaunches showing the groups list. Used only for the groups-list screenshot.
    private func relaunchAppForGroups() {
        app.terminate()
        launchApp()

        _ = app.tabBars.firstMatch.waitForExistence(timeout: 20)

        // Wait for transactions to confirm sync completed.
        app.tabBars.buttons["Transactions"].tap()
        _ = app.buttons.matching(identifier: "transaction.row").firstMatch.waitForExistence(timeout: 30)

        // Navigate to Groups and wait for the list to populate.
        app.tabBars.buttons["Groups"].tap()
        _ = app.buttons.matching(identifier: "groups.group-row").firstMatch.waitForExistence(timeout: 30)
        wait(seconds: 0.5)
    }

    /// Relaunches with GROUP_ROUTE=first so the app auto-pushes into the first group's detail.
    /// Waits for the section picker, which confirms data is loaded. Returns false if it times out.
    @discardableResult
    private func relaunchAppInGroupDetail() -> Bool {
        app.terminate()
        launchApp(groupRoute: "first")

        _ = app.tabBars.firstMatch.waitForExistence(timeout: 20)

        // Tap Groups tab to trigger the task that loads groups and auto-pushes to detail.
        app.tabBars.buttons["Groups"].tap()

        // Picker appears once isLoading = false in GroupDetailViewModel — wait generously.
        let picker = app.segmentedControls.matching(identifier: "group-detail.section-picker").firstMatch
        return picker.waitForExistence(timeout: 40)
    }

    /// Ensures we are on the group detail screen.
    /// Returns true if we are (or successfully got to) group detail.
    @discardableResult
    private func ensureInGroupDetail() -> Bool {
        let picker = app.segmentedControls.matching(identifier: "group-detail.section-picker").firstMatch
        if picker.waitForExistence(timeout: 3) { return true }
        return relaunchAppInGroupDetail()
    }

    private func navigateToTab(_ label: String) {
        let tab = app.tabBars.buttons[label]
        if tab.waitForExistence(timeout: 3) {
            tab.tap()
        }
    }

    private func navigateToSettings() {
        navigateToTab("Settings")
        _ = app.navigationBars["Settings"].waitForExistence(timeout: 5)
        wait(seconds: 0.5)
    }

    /// Navigates to Settings tab and waits for a specific sub-page nav bar pushed via SETTINGS_ROUTE.
    /// Because onAppear immediately pushes the route, the "Settings" title may never be visible.
    private func navigateToSettingsRoute(navBarTitle: String) {
        navigateToTab("Settings")
        _ = app.navigationBars[navBarTitle].waitForExistence(timeout: 8)
        wait(seconds: 0.5)
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
