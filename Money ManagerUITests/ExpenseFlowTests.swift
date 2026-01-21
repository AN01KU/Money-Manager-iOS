//
//  ExpenseFlowTests.swift
//  Money Manager UITests
//
//  Created by Ankush Ganesh on 13/01/26.
//

import XCTest

/// Tests for the core expense management flow - adding, viewing, editing, and deleting expenses
/// These tests verify the primary user workflows for expense tracking
final class ExpenseFlowTests: XCTestCase {
    
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
    
    // MARK: - Add Expense Tests
    
    /// Test: User can successfully add a complete expense with all fields
    /// This is the primary happy path - most common user action
    func testAddCompleteExpense() throws {
        // Navigate to Overview tab
        let overviewTab = app.tabBars.buttons["Overview"]
        XCTAssertTrue(overviewTab.waitForExistence(timeout: 3), "Overview tab should exist")
        overviewTab.tap()
        
        // Tap FAB to add expense
        let addButton = findAddExpenseButton()
        addButton.tap()
        
        // Verify Add Expense screen appears
        let addExpenseNavBar = app.navigationBars["Add Expense"]
        XCTAssertTrue(addExpenseNavBar.waitForExistence(timeout: 3), "Add Expense screen should appear")
        
        // Fill amount
        let amountField = app.textFields["0.00"]
        XCTAssertTrue(amountField.waitForExistence(timeout: 2), "Amount field should exist")
        amountField.tap()
        amountField.typeText("450")
        
        // Select category
        let categoryButton = app.buttons["Select Category"]
        XCTAssertTrue(categoryButton.waitForExistence(timeout: 2), "Category button should exist")
        categoryButton.tap()
        
        // Select Food & Dining category
        let foodCategory = app.buttons["Food & Dining"]
        XCTAssertTrue(foodCategory.waitForExistence(timeout: 2), "Food & Dining category should exist")
        foodCategory.tap()
        
        // Add description (optional field)
        let descriptionField = app.textFields["Description (e.g., Lunch at cafe)"]
        if descriptionField.exists {
            descriptionField.tap()
            descriptionField.typeText("Lunch at cafe")
        }
        
        // Verify Save button is enabled
        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2), "Save button should exist")
        XCTAssertTrue(saveButton.isEnabled, "Save button should be enabled with required fields filled")
        
        // Save expense
        saveButton.tap()
        
        // Verify we're back on Overview
        XCTAssertTrue(app.navigationBars["Overview"].waitForExistence(timeout: 5), 
                     "Should return to Overview after saving")
        
        // Verify expense appears in list
        let expenseText = app.staticTexts["Food & Dining"].firstMatch
        XCTAssertTrue(expenseText.waitForExistence(timeout: 5), "Expense should appear in transaction list")
        
        // Verify amount is displayed
        let amountText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '₹450' OR label CONTAINS '450'")).firstMatch
        XCTAssertTrue(amountText.exists, "Expense amount should be displayed")
    }
    
    /// Test: Form validation prevents saving expense without required fields
    /// Critical for data integrity - ensures users can't create invalid expenses
    func testFormValidationPreventsInvalidSubmission() throws {
        // Navigate to Overview
        app.tabBars.buttons["Overview"].tap()
        
        // Open Add Expense
        let addButton = findAddExpenseButton()
        addButton.tap()
        
        // Verify Add Expense screen appears
        XCTAssertTrue(app.navigationBars["Add Expense"].waitForExistence(timeout: 3))
        
        // Verify Save button is disabled without required fields
        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2), "Save button should exist")
        XCTAssertFalse(saveButton.isEnabled, "Save button should be disabled when required fields are empty")
        
        // Fill only amount (missing category)
        let amountField = app.textFields["0.00"]
        amountField.tap()
        amountField.typeText("100")
        
        // Save should still be disabled without category
        XCTAssertFalse(saveButton.isEnabled, "Save button should remain disabled without category")
        
        // Fill category
        app.buttons["Select Category"].tap()
        let transportCategory = app.buttons["Transport"]
        XCTAssertTrue(transportCategory.waitForExistence(timeout: 2), "Transport category should exist")
        transportCategory.tap()
        
        // Now Save should be enabled
        XCTAssertTrue(saveButton.isEnabled, "Save button should be enabled with amount and category")
    }
    
    /// Test: Quick amount buttons populate amount field correctly
    /// Tests the UX convenience feature for common amounts
    func testQuickAmountButtons() throws {
        app.tabBars.buttons["Overview"].tap()
        
        // Open Add Expense
        let addButton = findAddExpenseButton()
        addButton.tap()
        
        // Test quick amount buttons if they exist
        let quick100 = app.buttons["₹100"]
        if quick100.waitForExistence(timeout: 1) {
            quick100.tap()
            
            // Verify amount field is populated
            let amountField = app.textFields["0.00"]
            let value = amountField.value as? String ?? ""
            XCTAssertTrue(value.contains("100"), "Quick amount button should populate amount field with ₹100")
        }
    }
    
    // MARK: - View Expense Tests
    
    /// Test: User can view expense details by tapping on transaction
    /// Critical for reviewing expense information
    func testViewExpenseDetails() throws {
        // First add an expense
        try testAddCompleteExpense()
        
        // Tap on the expense in the list
        let categoryText = app.staticTexts["Food & Dining"].firstMatch
        XCTAssertTrue(categoryText.waitForExistence(timeout: 5), "Expense should exist in list")
        
        // Try tapping the text directly - with contentShape it should work
        categoryText.tap()
        
        // If that doesn't work, try tapping the amount text as fallback
        if !app.navigationBars["Transaction Details"].waitForExistence(timeout: 2) {
            let amountText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '₹450' OR label CONTAINS '450'")).firstMatch
            if amountText.exists {
                amountText.tap()
            }
        }
        
        // Wait for sheet animation
        sleep(2)
        
        // Verify detail screen appears - check for "Transaction Details" navigation title
        let detailNavBar = app.navigationBars["Transaction Details"]
        XCTAssertTrue(detailNavBar.waitForExistence(timeout: 5), "Transaction detail screen should appear")
        
        // Verify expense details are displayed
        let amountText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '₹'")).firstMatch
        XCTAssertTrue(amountText.waitForExistence(timeout: 3), "Expense amount should be displayed in detail view")
        
        // Verify category is displayed
        let categoryTextInDetail = app.staticTexts["Food & Dining"].firstMatch
        XCTAssertTrue(categoryTextInDetail.waitForExistence(timeout: 3), "Category should be displayed in detail view")
    }
    
    // MARK: - Edit Expense Tests
    
    /// Test: User can edit an existing expense
    /// Critical for correcting mistakes and updating expense information
    func testEditExpense() throws {
        // Add an expense first
        try testAddCompleteExpense()
        
        // Tap to view details
        let categoryText = app.staticTexts["Food & Dining"].firstMatch
        XCTAssertTrue(categoryText.waitForExistence(timeout: 5), "Expense should exist")
        categoryText.tap()
        
        // Wait for sheet animation
        sleep(2)
        
        // Verify detail screen appears
        let detailNavBar = app.navigationBars["Transaction Details"]
        XCTAssertTrue(detailNavBar.waitForExistence(timeout: 5), "Detail screen should appear")
        
        // Tap Edit button
        let editButton = app.buttons["Edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 3), "Edit button should exist")
        editButton.tap()
        
        // Wait for edit sheet to appear
        sleep(1)
        
        // Verify Add Expense screen appears (edit mode uses AddExpenseView)
        let addExpenseNavBar = app.navigationBars["Add Expense"]
        XCTAssertTrue(addExpenseNavBar.waitForExistence(timeout: 3), "Edit screen should appear")
        
        // Modify amount - find the amount field
        let amountField = app.textFields["0.00"]
        if !amountField.exists {
            // Try first text field if "0.00" placeholder doesn't exist
            let firstTextField = app.textFields.firstMatch
            if firstTextField.exists {
                firstTextField.tap()
                firstTextField.clearText()
                firstTextField.typeText("500")
            }
        } else {
            amountField.tap()
            if let currentValue = amountField.value as? String, currentValue != "0.00" {
                amountField.clearText()
            }
            amountField.typeText("500")
        }
        
        // Save changes
        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2), "Save button should exist")
        XCTAssertTrue(saveButton.isEnabled, "Save button should be enabled")
        saveButton.tap()
        
        // Wait for edit sheet to dismiss (goes back to detail view)
        sleep(1)
        
        // After saving, we're back on detail view, need to dismiss it
        let doneButton = app.buttons["Done"]
        if doneButton.waitForExistence(timeout: 3) {
            doneButton.tap()
            sleep(1) // Wait for sheet dismissal
        }
        
        // Verify we're back on Overview
        XCTAssertTrue(app.navigationBars["Overview"].waitForExistence(timeout: 5),
                     "Should return to Overview after editing")
        
        // Verify updated amount appears
        let updatedAmount = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '₹500' OR label CONTAINS '500'")).firstMatch
        XCTAssertTrue(updatedAmount.waitForExistence(timeout: 5), "Updated amount should be displayed")
    }
    
    // MARK: - Delete Expense Tests
    
    /// Test: User can delete an expense with confirmation
    /// Critical for data management - ensures users can remove expenses
    func testDeleteExpense() throws {
        // Add an expense first
        try testAddCompleteExpense()
        
        // Navigate to detail view
        let categoryText = app.staticTexts["Food & Dining"].firstMatch
        XCTAssertTrue(categoryText.waitForExistence(timeout: 5), "Expense should exist")
        categoryText.tap()
        
        // Wait for sheet animation
        sleep(2)
        
        // Verify detail screen appears
        let detailNavBar = app.navigationBars["Transaction Details"]
        XCTAssertTrue(detailNavBar.waitForExistence(timeout: 5), "Detail screen should appear")
        
        // Tap Delete button
        let deleteButton = app.buttons["Delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 3), "Delete button should exist")
        deleteButton.tap()
        
        // Wait for alert to appear
        sleep(1)
        
        // Confirm deletion in alert
        let confirmButton = app.alerts.buttons["Delete"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 3), "Delete confirmation button should exist")
        confirmButton.tap()
        
        // Wait for deletion and sheet dismissal
        sleep(2)
        
        // Verify we're back on Overview
        let overviewNavBar = app.navigationBars["Overview"]
        XCTAssertTrue(overviewNavBar.waitForExistence(timeout: 5),
                     "Should return to Overview after deletion")
        
        // Wait a bit more for UI to update
        sleep(1)
        
        // Verify expense is removed from list (it might still exist but be marked as deleted)
        // Check that the expense is no longer visible or accessible
        let expenseStillExists = app.staticTexts["Food & Dining"].firstMatch.exists
        XCTAssertFalse(expenseStillExists, "Expense should be removed after deletion")
    }
    
    // MARK: - Helper Methods
    
    /// Finds the Add Expense button (FAB) with fallback options
    private func findAddExpenseButton() -> XCUIElement {
        // Try primary identifier first
        let addButton = app.buttons.matching(identifier: "Add Expense").firstMatch
        if addButton.exists {
            return addButton
        }
        
        // Try alternative FAB button (plus icon)
        let fabButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'plus' OR label CONTAINS '+'")).firstMatch
        if fabButton.exists {
            return fabButton
        }
        
        // Try toolbar button in navigation bar
        let navBar = app.navigationBars["Overview"]
        if navBar.waitForExistence(timeout: 1) {
            let toolbarButtons = navBar.buttons
            if toolbarButtons.count > 0 {
                return toolbarButtons.element(boundBy: toolbarButtons.count - 1)
            }
        }
        
        // Fallback: try any button with "Add" in label
        return app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'add'")).firstMatch
    }
}

// MARK: - XCUIElement Extensions

extension XCUIElement {
    /// Clears text from a text field
    func clearText() {
        guard let stringValue = self.value as? String else {
            return
        }
        
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        typeText(deleteString)
    }
}
