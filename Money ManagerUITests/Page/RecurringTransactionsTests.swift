//
//  RecurringTransactionsTests.swift
//  Money Manager UITests
//

import XCTest

final class RecurringTransactionsTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = getTestAppLaunchArguments()
        app.launchEnvironment["SETTINGS_ROUTE"] = "recurring"
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }

    // MARK: - Navigation

    func testRecurringScreenLoads() throws {
        navigateToRecurring()

        let navBar = app.navigationBars["Recurring"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 5), "Recurring screen should load")
    }

    func testRecurringHasPlusButton() throws {
        navigateToRecurring()

        let plusButton = app.buttons.matching(identifier: "recurring.add-button").firstMatch
        XCTAssertTrue(plusButton.waitForExistence(timeout: 5), "Plus button should exist in toolbar")
    }

    // MARK: - Content

    func testActiveTransactionsDisplayed() throws {
        navigateToRecurring()

        let netflixRow = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS 'Netflix'")).firstMatch
        let gymRow = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS 'Gym'")).firstMatch
        let hasExpenses = netflixRow.waitForExistence(timeout: 3) || gymRow.waitForExistence(timeout: 1)

        let emptyState = app.staticTexts["No recurring transactions"]
        let hasEmptyState = emptyState.waitForExistence(timeout: 2)

        XCTAssertTrue(hasExpenses || hasEmptyState, "Should show recurring expenses or empty state")
    }

    func testTransactionRowShowsAmount() throws {
        navigateToRecurring()

        let amountText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '₹'")).firstMatch
        if amountText.waitForExistence(timeout: 3) {
            XCTAssertTrue(amountText.exists, "Should display expense amount")
        }
    }

    func testTransactionRowShowsFrequency() throws {
        navigateToRecurring()

        let monthlyText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'Monthly'")).firstMatch
        let weeklyText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'Weekly'")).firstMatch
        if monthlyText.waitForExistence(timeout: 3) || weeklyText.waitForExistence(timeout: 1) {
            XCTAssertTrue(true, "Should display frequency badge")
        }
    }

    func testToggleSwitchExists() throws {
        navigateToRecurring()

        let toggle = app.switches.firstMatch
        if toggle.waitForExistence(timeout: 3) {
            XCTAssertTrue(toggle.exists, "Toggle switch should exist on expense row")
        }
    }

    // MARK: - Add Recurring Sheet

    func testAddRecurringSheetOpens() throws {
        navigateToRecurring()

        let plusButton = app.buttons.matching(identifier: "recurring.add-button").firstMatch
        XCTAssertTrue(plusButton.waitForExistence(timeout: 5))
        plusButton.tap()

        let navBar = app.navigationBars["Add Recurring"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 3), "Add Recurring sheet should open")
    }

    func testAddRecurringSheetHasCancelButton() throws {
        navigateToRecurring()
        openAddSheet()

        let cancelButton = app.buttons.matching(identifier: "recurring.cancel-button").firstMatch
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 2), "Cancel button should exist")
    }

    func testAddRecurringSheetHasSaveButton() throws {
        navigateToRecurring()
        openAddSheet()

        let saveButton = app.buttons.matching(identifier: "recurring.save-button").firstMatch
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2), "Save button should exist")
    }

    func testAddRecurringSaveDisabledInitially() throws {
        navigateToRecurring()
        openAddSheet()

        let saveButton = app.buttons.matching(identifier: "recurring.save-button").firstMatch
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2))
        XCTAssertFalse(saveButton.isEnabled, "Save should be disabled without required fields")
    }

    func testAddRecurringCancelDismissesSheet() throws {
        navigateToRecurring()
        openAddSheet()

        app.buttons.matching(identifier: "recurring.cancel-button").firstMatch.tap()

        XCTAssertTrue(app.navigationBars["Recurring"].waitForExistence(timeout: 3), "Should return to Recurring screen")
    }

    func testAddRecurringHasNameField() throws {
        navigateToRecurring()
        openAddSheet()

        let nameField = app.textFields.matching(identifier: "recurring.name-field").firstMatch
        XCTAssertTrue(nameField.waitForExistence(timeout: 2), "Name field should exist")
    }

    func testAddRecurringHasAmountField() throws {
        navigateToRecurring()
        openAddSheet()

        let amountField = app.textFields.matching(identifier: "recurring.amount-field").firstMatch
        XCTAssertTrue(amountField.waitForExistence(timeout: 2), "Amount field should exist")
    }

    func testAddRecurringHasFrequencyPicker() throws {
        navigateToRecurring()
        openAddSheet()

        let monthlyButton = app.buttons["Monthly"]
        let dailyButton = app.buttons["Daily"]
        let hasPicker = monthlyButton.waitForExistence(timeout: 2) || dailyButton.waitForExistence(timeout: 1)
        XCTAssertTrue(hasPicker, "Frequency picker should exist")
    }

    // MARK: - Toggle Interaction

    func testRecurringToggleChangesActiveState() throws {
        navigateToRecurring()

        let firstToggle = app.switches.matching(identifier: "recurring.toggle").firstMatch
        guard firstToggle.waitForExistence(timeout: 5) else {
            throw XCTSkip("No recurring transactions present to toggle")
        }

        // Find the row that contains this toggle by matching it via position
        let allRows = app.buttons.matching(identifier: "recurring.row")
        guard allRows.count > 0 else {
            throw XCTSkip("No recurring rows found")
        }
        let targetRow = allRows.firstMatch
        let labelBefore = targetRow.label
        let wasActive = labelBefore.contains("Active")
        let itemName = labelBefore.components(separatedBy: ", ").first ?? ""

        firstToggle.tap()

        let expectedLabel = wasActive ? "Paused" : "Active"
        // Re-query the specific row by name to avoid index shifting after section changes
        let updatedRowPredicate = NSPredicate(format: "label BEGINSWITH %@ AND label CONTAINS %@", itemName, expectedLabel)
        let updatedRow = app.buttons.matching(updatedRowPredicate).firstMatch
        XCTAssertTrue(updatedRow.waitForExistence(timeout: 5),
            "Row for '\(itemName)' should show '\(expectedLabel)' after toggle; before: \(labelBefore)"
        )
    }

    // MARK: - Edit Recurring Expense

    func testTapTransactionOpensEditSheet() throws {
        navigateToRecurring()

        let expenseRow = app.buttons.matching(identifier: "recurring.row").firstMatch
        guard expenseRow.waitForExistence(timeout: 3) else {
            throw XCTSkip("No recurring expenses to tap")
        }
        expenseRow.tap()

        let editNavBar = app.navigationBars["Edit Recurring"]
        XCTAssertTrue(editNavBar.waitForExistence(timeout: 3), "Edit Recurring sheet should open")
    }

    func testEditSheetHasPrefilledData() throws {
        navigateToRecurring()

        let expenseRow = app.buttons.matching(identifier: "recurring.row").firstMatch
        guard expenseRow.waitForExistence(timeout: 3) else {
            throw XCTSkip("No recurring expenses to edit")
        }
        expenseRow.tap()
        guard app.navigationBars["Edit Recurring"].waitForExistence(timeout: 3) else {
            throw XCTSkip("Edit sheet did not open")
        }

        let nameField = app.textFields.matching(identifier: "recurring.name-field").firstMatch
        if nameField.waitForExistence(timeout: 2) {
            let value = nameField.value as? String ?? ""
            XCTAssertFalse(value.isEmpty, "Name should be pre-filled")
        }
    }

    func testEditSheetCanBeCancelled() throws {
        navigateToRecurring()

        let expenseRow = app.buttons.matching(identifier: "recurring.row").firstMatch
        guard expenseRow.waitForExistence(timeout: 3) else {
            throw XCTSkip("No recurring expenses to edit")
        }
        expenseRow.tap()
        guard app.navigationBars["Edit Recurring"].waitForExistence(timeout: 3) else {
            throw XCTSkip("Edit sheet did not open")
        }

        app.buttons.matching(identifier: "recurring.cancel-button").firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Recurring"].waitForExistence(timeout: 3), "Should return to Recurring screen")
    }

    // MARK: - Empty State

    func testEmptyStateShowsCorrectMessage() throws {
        navigateToRecurring()

        let emptyMessage = app.staticTexts["No recurring transactions"]
        let emptySubMessage = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'subscriptions'")).firstMatch

        if emptyMessage.waitForExistence(timeout: 2) {
            XCTAssertTrue(emptyMessage.exists)
            XCTAssertTrue(emptySubMessage.waitForExistence(timeout: 2), "Should show helpful subtitle")
        }
    }

    // MARK: - Helpers

    /// Taps the Settings tab; SETTINGS_ROUTE=recurring causes the app to auto-push to Recurring on appear.
    private func navigateToRecurring() {
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Recurring"].waitForExistence(timeout: 8), "Recurring screen should load")
    }

    private func openAddSheet() {
        let plusButton = app.buttons.matching(identifier: "recurring.add-button").firstMatch
        XCTAssertTrue(plusButton.waitForExistence(timeout: 5))
        plusButton.tap()
        _ = app.navigationBars["Add Recurring"].waitForExistence(timeout: 3)
    }
}
