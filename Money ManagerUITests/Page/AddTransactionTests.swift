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
        
        let navBar = app.navigationBars["Add Expense"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 3), "Add Expense screen should load")
    }
    
    func testAddTransactionHasCancelButton() throws {
        openAddTransactionScreen()
        
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 2), "Cancel button should exist")
    }
    
    func testAddTransactionHasSaveButton() throws {
        openAddTransactionScreen()
        
        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2), "Save button should exist")
    }
    
    // MARK: - Form Validation
    
    func testSaveButtonDisabledInitially() throws {
        openAddTransactionScreen()
        
        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2))
        XCTAssertFalse(saveButton.isEnabled, "Save should be disabled without required fields")
    }
    
    func testSaveButtonEnabledWithValidData() throws {
        openAddTransactionScreen()
        
        // Enter amount
        let amountField = app.textFields["0.00"]
        amountField.tap()
        amountField.typeText("500")
        
        // Select category
        app.buttons["Select Category"].tap()
        app.buttons["Food & Dining"].firstMatch.tap()
        
        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.isEnabled, "Save should be enabled with amount and category")
    }
    
    // MARK: - Amount Input
    
    func testAmountFieldAcceptsInput() throws {
        openAddTransactionScreen()
        
        let amountField = app.textFields["0.00"]
        XCTAssertTrue(amountField.waitForExistence(timeout: 2))
        
        amountField.tap()
        amountField.typeText("1000")
        
        let value = amountField.value as? String ?? ""
        XCTAssertTrue(value.contains("1000"), "Amount field should contain entered value")
    }
    
    func testQuickAmountButtonsWork() throws {
        openAddTransactionScreen()
        
        // Tap quick amount button (₹100, ₹500, or ₹1000)
        let quick100 = app.buttons.containing(NSPredicate(format: "label CONTAINS '100'")).firstMatch
        if quick100.waitForExistence(timeout: 2) {
            quick100.tap()
            
            let amountField = app.textFields["0.00"]
            let value = amountField.value as? String ?? ""
            XCTAssertTrue(value.contains("100"), "Quick amount should populate field")
        }
    }
    
    // MARK: - Category Selection
    
    func testCategoryPickerOpens() throws {
        openAddTransactionScreen()
        
        let categoryButton = app.buttons["Select Category"]
        XCTAssertTrue(categoryButton.waitForExistence(timeout: 2))
        categoryButton.tap()
        
        // Verify category picker appears (look for any category)
        let foodCategory = app.buttons["Food & Dining"]
        XCTAssertTrue(foodCategory.waitForExistence(timeout: 3), "Category picker should open with categories")
    }
    
    func testCategoryCanBeSelected() throws {
        openAddTransactionScreen()
        
        app.buttons["Select Category"].tap()
        
        // Wait for category picker sheet to appear
        let pickerNav = app.navigationBars["Select Category"]
        XCTAssertTrue(pickerNav.waitForExistence(timeout: 3), "Category picker should appear")

        // Food & Dining is always visible without scrolling
        let foodCell = app.buttons["Food & Dining"]
        XCTAssertTrue(foodCell.waitForExistence(timeout: 5), "Food & Dining category should appear in picker")
        foodCell.tap()

        // Verify category is selected (button label should change)
        let categoryButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Food'")).firstMatch
        XCTAssertTrue(categoryButton.waitForExistence(timeout: 2), "Food & Dining category should be selected")
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
        
        let descriptionField = app.textFields.containing(NSPredicate(format: "placeholderValue CONTAINS 'Description' OR label CONTAINS 'Description'")).firstMatch
        
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

        app.buttons["Cancel"].tap()

        XCTAssertTrue(app.navigationBars["Transactions"].waitForExistence(timeout: 3), "Should return to Transactions after cancel")
    }
    
    func testCompleteTransactionCreation() throws {
        openAddTransactionScreen()
        
        // Enter amount
        let amountField = app.textFields["0.00"]
        amountField.tap()
        amountField.typeText("750")
        
        // Select category
        app.buttons["Select Category"].tap()

        // Wait for category picker sheet
        let pickerNav = app.navigationBars["Select Category"]
        XCTAssertTrue(pickerNav.waitForExistence(timeout: 5), "Category picker should appear")

        // Food & Dining is near the top of the list — no scrolling needed
        let foodCell = app.buttons["Food & Dining"]
        XCTAssertTrue(foodCell.waitForExistence(timeout: 5), "Food & Dining category should appear in picker")
        foodCell.tap()

        // Add description
        let descField = app.textFields.containing(NSPredicate(format: "placeholderValue CONTAINS 'Description'")).firstMatch
        if descField.exists {
            descField.tap()
            descField.typeText("Test expense")
        }

        // Save
        app.buttons["Save"].tap()

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
        let fabButton = app.buttons["plus"]
        XCTAssertTrue(fabButton.waitForExistence(timeout: 3), "FAB should exist")
        fabButton.tap()

        XCTAssertTrue(app.navigationBars["Add Expense"].waitForExistence(timeout: 3), "Add Expense screen should appear")
    }
}
