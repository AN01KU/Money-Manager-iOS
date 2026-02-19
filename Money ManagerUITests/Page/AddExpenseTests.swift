//
//  AddExpenseTests.swift
//  Money Manager UITests
//
//  Tests for Add Expense screen functionality
//

import XCTest

final class AddExpenseTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }
    
    // MARK: - Screen Loading
    
    func testAddExpenseScreenLoads() throws {
        openAddExpenseScreen()
        
        let navBar = app.navigationBars["Add Expense"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 3), "Add Expense screen should load")
    }
    
    func testAddExpenseHasCancelButton() throws {
        openAddExpenseScreen()
        
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 2), "Cancel button should exist")
    }
    
    func testAddExpenseHasSaveButton() throws {
        openAddExpenseScreen()
        
        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2), "Save button should exist")
    }
    
    // MARK: - Form Validation
    
    func testSaveButtonDisabledInitially() throws {
        openAddExpenseScreen()
        
        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2))
        XCTAssertFalse(saveButton.isEnabled, "Save should be disabled without required fields")
    }
    
    func testSaveButtonEnabledWithValidData() throws {
        openAddExpenseScreen()
        
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
        openAddExpenseScreen()
        
        let amountField = app.textFields["0.00"]
        XCTAssertTrue(amountField.waitForExistence(timeout: 2))
        
        amountField.tap()
        amountField.typeText("1000")
        
        let value = amountField.value as? String ?? ""
        XCTAssertTrue(value.contains("1000"), "Amount field should contain entered value")
    }
    
    func testQuickAmountButtonsWork() throws {
        openAddExpenseScreen()
        
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
        openAddExpenseScreen()
        
        let categoryButton = app.buttons["Select Category"]
        XCTAssertTrue(categoryButton.waitForExistence(timeout: 2))
        categoryButton.tap()
        
        // Verify category picker appears (look for any category)
        let foodCategory = app.buttons["Food & Dining"]
        XCTAssertTrue(foodCategory.waitForExistence(timeout: 3), "Category picker should open with categories")
    }
    
    func testCategoryCanBeSelected() throws {
        openAddExpenseScreen()
        
        app.buttons["Select Category"].tap()
        app.buttons["Transport"].firstMatch.tap()
        
        // Verify category is selected (button text should change)
        let categoryButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Transport'")).firstMatch
        XCTAssertTrue(categoryButton.waitForExistence(timeout: 2), "Transport category should be selected")
    }
    
    // MARK: - Date Selection
    
    func testDatePickerOpens() throws {
        openAddExpenseScreen()
        
        let dateButton = app.buttons.containing(NSPredicate(format: "label CONTAINS '2026' OR label CONTAINS '2025' OR label CONTAINS 'January' OR label CONTAINS 'February' OR label CONTAINS 'March' OR label CONTAINS 'April' OR label CONTAINS 'May' OR label CONTAINS 'June' OR label CONTAINS 'July' OR label CONTAINS 'August' OR label CONTAINS 'September' OR label CONTAINS 'October' OR label CONTAINS 'November' OR label CONTAINS 'December'")).firstMatch
        
        if dateButton.waitForExistence(timeout: 2) {
            dateButton.tap()
            
            // Look for date picker elements
            let datePicker = app.datePickers.firstMatch
            let calendar = app.otherElements.containing(NSPredicate(format: "label CONTAINS 'Calendar' OR label CONTAINS 'Picker'")).firstMatch
            
            let pickerExists = datePicker.waitForExistence(timeout: 2) || calendar.waitForExistence(timeout: 2)
            XCTAssertTrue(pickerExists, "Date picker should appear")
        }
    }
    
    // MARK: - Description Field
    
    func testDescriptionFieldAcceptsInput() throws {
        openAddExpenseScreen()
        
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
        openAddExpenseScreen()
        
        app.buttons["Cancel"].tap()
        
        XCTAssertTrue(app.navigationBars["Overview"].waitForExistence(timeout: 3), "Should return to Overview after cancel")
    }
    
    func testCompleteExpenseCreation() throws {
        openAddExpenseScreen()
        
        // Enter amount
        let amountField = app.textFields["0.00"]
        amountField.tap()
        amountField.typeText("750")
        
        // Select category
        app.buttons["Select Category"].tap()
        app.buttons["Shopping"].firstMatch.tap()
        
        // Add description
        let descField = app.textFields.containing(NSPredicate(format: "placeholderValue CONTAINS 'Description'")).firstMatch
        if descField.exists {
            descField.tap()
            descField.typeText("Test shopping expense")
        }
        
        // Save
        app.buttons["Save"].tap()
        
        // Verify return to Overview
        XCTAssertTrue(app.navigationBars["Overview"].waitForExistence(timeout: 5), "Should return to Overview after save")
        
        // Verify expense appears in list
        let expense = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Shopping' OR label CONTAINS '750'")).firstMatch
        XCTAssertTrue(expense.waitForExistence(timeout: 5), "New expense should appear in list")
    }
    
    // MARK: - Helper Methods
    
    private func openAddExpenseScreen() {
        app.tabBars.buttons["Overview"].tap()
        XCTAssertTrue(app.navigationBars["Overview"].waitForExistence(timeout: 3))
        
        // Tap the plus button
        let fabButton = app.buttons["plus"]
        XCTAssertTrue(fabButton.waitForExistence(timeout: 3), "FAB should exist")
        fabButton.tap()
        
        XCTAssertTrue(app.navigationBars["Add Expense"].waitForExistence(timeout: 3), "Add Expense screen should appear")
    }
}
