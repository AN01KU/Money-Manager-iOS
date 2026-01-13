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
        // Stop immediately if a test fails
        continueAfterFailure = false
        
        // Launch app with UI testing flag for isolated test data
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
        XCTAssertTrue(addExpenseNavBar.waitForExistence(timeout: 2), "Add Expense screen should appear")
        
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
        XCTAssertTrue(app.navigationBars["Overview"].waitForExistence(timeout: 3), 
                     "Should return to Overview after saving")
        
        // Verify expense appears in list
        let expenseText = app.staticTexts["Food & Dining"]
        XCTAssertTrue(expenseText.waitForExistence(timeout: 3), "Expense should appear in transaction list")
        
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
        XCTAssertTrue(app.navigationBars["Add Expense"].waitForExistence(timeout: 2))
        
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
        let expenseRow = app.staticTexts["Food & Dining"].firstMatch
        XCTAssertTrue(expenseRow.waitForExistence(timeout: 3), "Expense should exist in list")
        expenseRow.tap()
        
        // Verify detail screen appears
        let detailNavBar = app.navigationBars["Transaction Details"]
        let detailExists = detailNavBar.waitForExistence(timeout: 2) ||
                          app.navigationBars.matching(identifier: "Details").firstMatch.exists
        
        XCTAssertTrue(detailExists, "Transaction detail screen should appear")
        
        // Verify expense details are displayed
        let amountText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '₹'")).firstMatch
        XCTAssertTrue(amountText.exists, "Expense amount should be displayed in detail view")
        
        // Verify category is displayed
        let categoryText = app.staticTexts["Food & Dining"]
        XCTAssertTrue(categoryText.exists, "Category should be displayed in detail view")
    }
    
    // MARK: - Edit Expense Tests
    
    /// Test: User can edit an existing expense
    /// Critical for correcting mistakes and updating expense information
    func testEditExpense() throws {
        // Add an expense first
        try testAddCompleteExpense()
        
        // Tap to view details
        app.staticTexts["Food & Dining"].firstMatch.tap()
        
        // Tap Edit button
        let editButton = app.buttons["Edit"]
        if editButton.waitForExistence(timeout: 2) {
            editButton.tap()
            
            // Modify amount
            let amountField = app.textFields.firstMatch
            XCTAssertTrue(amountField.exists, "Amount field should exist in edit mode")
            amountField.tap()
            amountField.clearText()
            amountField.typeText("500")
            
            // Save changes
            let saveButton = app.buttons["Save"]
            XCTAssertTrue(saveButton.waitForExistence(timeout: 2), "Save button should exist")
            XCTAssertTrue(saveButton.isEnabled, "Save button should be enabled")
            saveButton.tap()
            
            // Verify changes are saved and we're back on Overview
            XCTAssertTrue(app.navigationBars["Overview"].waitForExistence(timeout: 3),
                         "Should return to Overview after editing")
            
            // Verify updated amount appears
            let updatedAmount = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '₹500' OR label CONTAINS '500'")).firstMatch
            XCTAssertTrue(updatedAmount.exists, "Updated amount should be displayed")
        }
    }
    
    // MARK: - Delete Expense Tests
    
    /// Test: User can delete an expense with confirmation
    /// Critical for data management - ensures users can remove expenses
    func testDeleteExpense() throws {
        // Add an expense first
        try testAddCompleteExpense()
        
        // Navigate to detail view
        app.staticTexts["Food & Dining"].firstMatch.tap()
        
        // Tap Delete button
        let deleteButton = app.buttons["Delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 2), "Delete button should exist")
        deleteButton.tap()
        
        // Confirm deletion in alert
        let confirmButton = app.alerts.buttons["Delete"]
        if confirmButton.waitForExistence(timeout: 2) {
            confirmButton.tap()
            
            // Verify we're back on Overview
            XCTAssertTrue(app.navigationBars["Overview"].waitForExistence(timeout: 3),
                         "Should return to Overview after deletion")
            
            // Verify expense is removed from list
            let expenseStillExists = app.staticTexts["Food & Dining"].firstMatch.exists
            XCTAssertFalse(expenseStillExists, "Expense should be removed after deletion")
        }
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
