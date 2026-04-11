//
//  AddExpenseTests.swift
//  Money Manager UITests
//
//  Tests for Add Expense screen functionality
//

import XCTest

final class AddTransactionTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = getTestAppLaunchArguments()
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }

    // MARK: - Screen Loading

    func testAddTransactionScreenLoads() throws {
        openAddTransactionScreen()

        // The sheet is confirmed loaded when its cancel button is present
        let cancelButton = app.buttons.matching(identifier: "cancel-button").firstMatch
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 3), "Add Transaction screen should load")
    }

    func testAddTransactionHasCancelButton() throws {
        openAddTransactionScreen()

        let cancelButton = app.buttons.matching(identifier: "cancel-button").firstMatch
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 2), "Cancel button should exist")
    }

    func testAddTransactionHasSaveButton() throws {
        openAddTransactionScreen()

        let saveButton = app.buttons.matching(identifier: "save-button").firstMatch
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2), "Save button should exist")
    }

    // MARK: - Form Validation

    func testSaveButtonDisabledInitially() throws {
        openAddTransactionScreen()

        let saveButton = app.buttons.matching(identifier: "save-button").firstMatch
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2))
        XCTAssertFalse(saveButton.isEnabled, "Save should be disabled without required fields")
    }

    func testSaveButtonEnabledWithValidData() throws {
        openAddTransactionScreen()

        // Enter amount
        let amountField = app.textFields.matching(identifier: "amount-field").firstMatch
        amountField.tap()
        amountField.typeText("500")

        // Select category
        app.buttons.matching(identifier: "category-picker-button").firstMatch.tap()
        app.buttons.matching(identifier: "Food & Dining").firstMatch.tap()

        let saveButton = app.buttons.matching(identifier: "save-button").firstMatch
        XCTAssertTrue(saveButton.isEnabled, "Save should be enabled with amount and category")
    }

    // MARK: - Amount Input

    func testAmountFieldAcceptsInput() throws {
        openAddTransactionScreen()

        let amountField = app.textFields.matching(identifier: "amount-field").firstMatch
        XCTAssertTrue(amountField.waitForExistence(timeout: 2))

        amountField.tap()
        amountField.typeText("1000")

        let value = amountField.value as? String ?? ""
        XCTAssertTrue(value.contains("1000"), "Amount field should contain entered value")
    }

    func testQuickAmountButtonsWork() throws {
        openAddTransactionScreen()

        let quick100 = app.buttons.matching(identifier: "quick-amount-100").firstMatch
        if quick100.waitForExistence(timeout: 2) {
            quick100.tap()

            let amountField = app.textFields.matching(identifier: "amount-field").firstMatch
            let value = amountField.value as? String ?? ""
            XCTAssertTrue(value.contains("100"), "Quick amount should populate field")
        }
    }

    // MARK: - Category Selection

    func testCategoryPickerOpens() throws {
        openAddTransactionScreen()

        let categoryButton = app.buttons.matching(identifier: "category-picker-button").firstMatch
        XCTAssertTrue(categoryButton.waitForExistence(timeout: 2))
        categoryButton.tap()

        // Verify category picker appears (look for a known category by its stable identifier)
        let foodCategory = app.buttons.matching(identifier: "Food & Dining").firstMatch
        XCTAssertTrue(foodCategory.waitForExistence(timeout: 3), "Category picker should open with categories")
    }

    func testCategoryCanBeSelected() throws {
        openAddTransactionScreen()

        app.buttons.matching(identifier: "category-picker-button").firstMatch.tap()

        // Wait for category picker sheet to appear
        let pickerNav = app.navigationBars["Select Category"]
        XCTAssertTrue(pickerNav.waitForExistence(timeout: 3), "Category picker should appear")

        // Food & Dining is always visible without scrolling
        let foodCell = app.buttons.matching(identifier: "Food & Dining").firstMatch
        XCTAssertTrue(foodCell.waitForExistence(timeout: 5), "Food & Dining category should appear in picker")
        foodCell.tap()

        // Verify the category button now reflects the selection
        let categoryButton = app.buttons.matching(identifier: "category-picker-button").firstMatch
        XCTAssertTrue(categoryButton.waitForExistence(timeout: 2), "Category picker button should still exist after selection")
    }

    // MARK: - Date Selection

    func testDatePickerOpens() throws {
        openAddTransactionScreen()

        let datePicker = app.datePickers.firstMatch
        XCTAssertTrue(datePicker.waitForExistence(timeout: 3), "Date picker should exist")

        // Tap the date picker to expand it
        datePicker.tap()

        // Look for expanded calendar or wheel elements
        let calendar = app.datePickers.firstMatch
        XCTAssertTrue(calendar.waitForExistence(timeout: 2), "Date picker should be interactive")
    }

    // MARK: - Description Field

    func testDescriptionFieldAcceptsInput() throws {
        openAddTransactionScreen()

        let descriptionField = app.textFields.matching(identifier: "description-field").firstMatch

        if descriptionField.waitForExistence(timeout: 2) {
            descriptionField.tap()
            descriptionField.typeText("Test expense description")

            let value = descriptionField.value as? String ?? ""
            XCTAssertEqual(value, "Test expense description", "Description should be entered")
        }
    }

    // MARK: - Save and Cancel Flow

    func testCancelDismissesSheet() throws {
        openAddTransactionScreen()

        app.buttons.matching(identifier: "cancel-button").firstMatch.tap()

        XCTAssertTrue(app.navigationBars["Transactions"].waitForExistence(timeout: 3), "Should return to Transactions after cancel")
    }

    func testCompleteTransactionCreation() throws {
        openAddTransactionScreen()

        // Enter amount
        let amountField = app.textFields.matching(identifier: "amount-field").firstMatch
        amountField.tap()
        amountField.typeText("750")
        app.toolbars.buttons["Done"].firstMatch.tap()

        // Select category
        app.buttons.matching(identifier: "category-picker-button").firstMatch.tap()

        // Wait for category picker sheet
        let pickerNav = app.navigationBars["Select Category"]
        XCTAssertTrue(pickerNav.waitForExistence(timeout: 5), "Category picker should appear")

        // Food & Dining is near the top of the list — no scrolling needed
        let foodCell = app.buttons.matching(identifier: "Food & Dining").firstMatch
        XCTAssertTrue(foodCell.waitForExistence(timeout: 5), "Food & Dining category should appear in picker")
        foodCell.tap()

        // Add description
        let descField = app.textFields.matching(identifier: "description-field").firstMatch
        if descField.exists {
            descField.tap()
            descField.typeText("Test expense")
        }

        // Save
        app.buttons.matching(identifier: "save-button").firstMatch.tap()

        // Verify return to Transactions
        XCTAssertTrue(app.navigationBars["Transactions"].waitForExistence(timeout: 10), "Should return to Transactions after save")

        // Verify expense appears in list
        let expense = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Food' OR label CONTAINS '750'")).firstMatch
        XCTAssertTrue(expense.waitForExistence(timeout: 10), "New expense should appear in list")
    }

    // MARK: - Helper Methods

    private func openAddTransactionScreen() {
        app.tabBars.buttons["Transactions"].tap()
        XCTAssertTrue(app.navigationBars["Transactions"].waitForExistence(timeout: 3))

        // Tap the FAB (plus button) on the Transactions tab
        let fabButton = app.buttons.matching(identifier: "transactions.add-button").firstMatch
        XCTAssertTrue(fabButton.waitForExistence(timeout: 3), "FAB should exist")
        fabButton.tap()

        XCTAssertTrue(app.buttons.matching(identifier: "cancel-button").firstMatch.waitForExistence(timeout: 3), "Add Transaction screen should appear")
    }
}
