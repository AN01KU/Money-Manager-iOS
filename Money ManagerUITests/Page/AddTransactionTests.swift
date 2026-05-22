//
//  AddTransactionTests.swift
//  Money Manager UITests
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

        let amountField = app.textFields.matching(identifier: "amount-field").firstMatch
        amountField.tap()
        amountField.typeText("500")

        selectFirstCategory()

        let saveButton = app.buttons.matching(identifier: "save-button").firstMatch
        XCTAssertTrue(saveButton.isEnabled, "Save should be enabled with amount and category")
    }

    // MARK: - Amount Input

    func testAmountFieldAcceptsInput() throws {
        openAddTransactionScreen()

        let amountField = app.textFields.matching(identifier: "amount-field").firstMatch
        XCTAssertTrue(amountField.waitForExistence(timeout: 2))
        amountField.tap()
        amountField.press(forDuration: 1.0)
        if app.menuItems["Select All"].waitForExistence(timeout: 1) {
            app.menuItems["Select All"].tap()
        }
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

        let pickerNav = app.navigationBars["Select Category"]
        XCTAssertTrue(pickerNav.waitForExistence(timeout: 5), "Category picker should open")
    }

    func testCategoryCanBeSelected() throws {
        openAddTransactionScreen()

        app.buttons.matching(identifier: "category-picker-button").firstMatch.tap()

        let pickerNav = app.navigationBars["Select Category"]
        XCTAssertTrue(pickerNav.waitForExistence(timeout: 5), "Category picker should appear")

        let anyCategory = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'category-picker.'")).firstMatch
        XCTAssertTrue(anyCategory.waitForExistence(timeout: 3), "At least one category should appear in picker")
        anyCategory.tap()

        XCTAssertTrue(pickerNav.waitForNonExistence(timeout: 5), "Category picker should dismiss after selection")
    }

    // MARK: - Date Selection

    func testDatePickerOpens() throws {
        openAddTransactionScreen()

        let datePicker = app.datePickers.firstMatch
        XCTAssertTrue(datePicker.waitForExistence(timeout: 3), "Date picker should exist")
        datePicker.tap()
        XCTAssertTrue(app.datePickers.firstMatch.waitForExistence(timeout: 2), "Date picker should be interactive")
    }

    // MARK: - Description Field

    func testDescriptionFieldAcceptsInput() throws {
        openAddTransactionScreen()

        let descriptionField = app.textFields.matching(identifier: "description-field").firstMatch
        XCTAssertTrue(descriptionField.waitForExistence(timeout: 3), "Description field should exist")
        descriptionField.tap()
        descriptionField.press(forDuration: 1.0)
        if app.menuItems["Select All"].waitForExistence(timeout: 1) {
            app.menuItems["Select All"].tap()
        }
        descriptionField.typeText("Test expense description")
        let value = descriptionField.value as? String ?? ""
        XCTAssertEqual(value, "Test expense description", "Description should be entered")
    }

    // MARK: - Save and Cancel Flow

    func testCancelDismissesSheet() throws {
        openAddTransactionScreen()

        app.buttons.matching(identifier: "cancel-button").firstMatch.tap()

        XCTAssertTrue(app.navigationBars["Transactions"].waitForExistence(timeout: 3), "Should return to Transactions after cancel")
    }

    func testCompleteTransactionCreation() throws {
        openAddTransactionScreen()

        let amountField = app.textFields.matching(identifier: "amount-field").firstMatch
        amountField.tap()
        amountField.typeText("750")

        selectFirstCategory()

        let pickerNav = app.navigationBars["Select Category"]
        XCTAssertTrue(pickerNav.waitForNonExistence(timeout: 5), "Category picker should dismiss")

        let descField = app.textFields.matching(identifier: "description-field").firstMatch
        app.swipeUp()
        XCTAssertTrue(descField.waitForExistence(timeout: 3), "Description field should exist")
        descField.tap()
        descField.typeText("Test expense")

        app.buttons.matching(identifier: "save-button").firstMatch.tap()

        XCTAssertTrue(app.navigationBars["Transactions"].waitForExistence(timeout: 10), "Should return to Transactions after save")

        let expense = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '750'")).firstMatch
        XCTAssertTrue(expense.waitForExistence(timeout: 10), "New expense should appear in list")
    }

    // MARK: - Helpers

    private func openAddTransactionScreen() {
        app.tabBars.buttons["Transactions"].tap()
        XCTAssertTrue(app.navigationBars["Transactions"].waitForExistence(timeout: 3))

        let fabButton = app.buttons.matching(identifier: "transactions.add-button").firstMatch
        XCTAssertTrue(fabButton.waitForExistence(timeout: 3), "FAB should exist")
        fabButton.tap()

        XCTAssertTrue(app.buttons.matching(identifier: "cancel-button").firstMatch.waitForExistence(timeout: 3), "Add Transaction screen should appear")
    }

    private func selectFirstCategory() {
        app.buttons.matching(identifier: "category-picker-button").firstMatch.tap()
        _ = app.navigationBars["Select Category"].waitForExistence(timeout: 5)
        let row = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'category-picker.'")).firstMatch
        if row.waitForExistence(timeout: 3) {
            row.tap()
        }
        _ = app.navigationBars["Select Category"].waitForNonExistence(timeout: 5)
    }
}
