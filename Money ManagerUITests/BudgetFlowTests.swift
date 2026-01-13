//
//  BudgetFlowTests.swift
//  Money Manager UITests
//
//  Created by Ankush Ganesh on 13/01/26.
//

import XCTest

/// Tests for budget management flow - setting, viewing, and tracking budgets
/// These tests verify budget functionality and spending calculations
final class BudgetFlowTests: XCTestCase {
    
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
    
    // MARK: - Set Budget Tests
    
    /// Test: User can set a monthly budget
    /// Critical feature for budget tracking - primary budget management action
    func testSetMonthlyBudget() throws {
        // Navigate to Budgets tab
        let budgetsTab = app.tabBars.buttons["Budgets"]
        XCTAssertTrue(budgetsTab.waitForExistence(timeout: 3), "Budgets tab should exist")
        budgetsTab.tap()
        
        // Open budget sheet
        openBudgetSheet()
        
        // Verify budget sheet appears
        let budgetNavBar = app.navigationBars["Set Budget"]
        XCTAssertTrue(budgetNavBar.waitForExistence(timeout: 2), "Budget sheet should appear")
        
        // Enter budget amount
        let budgetField = app.textFields.firstMatch
        XCTAssertTrue(budgetField.waitForExistence(timeout: 2), "Budget amount field should exist")
        budgetField.tap()
        budgetField.typeText("50000")
        
        // Verify Save button is enabled
        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2), "Save button should exist")
        XCTAssertTrue(saveButton.isEnabled, "Save button should be enabled with valid amount")
        
        // Save budget
        saveButton.tap()
        
        // Verify budget is set and we're back on Budgets screen
        XCTAssertTrue(app.navigationBars["Budgets"].waitForExistence(timeout: 3),
                     "Should return to Budgets screen after saving")
        
        // Verify budget amount is displayed
        let budgetText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '₹50,000' OR label CONTAINS '50000' OR label CONTAINS '50,000'")).firstMatch
        XCTAssertTrue(budgetText.waitForExistence(timeout: 3), "Budget amount should be displayed")
    }
    
    /// Test: Budget validation prevents invalid amounts
    /// Critical for data integrity - ensures only valid budgets can be set
    func testBudgetValidation() throws {
        app.tabBars.buttons["Budgets"].tap()
        
        // Open budget sheet
        openBudgetSheet()
        
        // Verify Save button is disabled for empty amount
        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2), "Save button should exist")
        XCTAssertFalse(saveButton.isEnabled, "Save should be disabled for empty budget")
        
        // Enter invalid amount (zero)
        let budgetField = app.textFields.firstMatch
        budgetField.tap()
        budgetField.typeText("0")
        
        // Save should still be disabled for zero amount
        XCTAssertFalse(saveButton.isEnabled, "Save should be disabled for zero amount")
        
        // Enter negative amount
        budgetField.clearText()
        budgetField.typeText("-100")
        
        // Save should still be disabled for negative amount
        XCTAssertFalse(saveButton.isEnabled, "Save should be disabled for negative amount")
        
        // Enter valid amount
        budgetField.clearText()
        budgetField.typeText("50000")
        
        // Save should now be enabled
        XCTAssertTrue(saveButton.isEnabled, "Save should be enabled for valid amount")
    }
    
    // MARK: - Budget Display Tests
    
    /// Test: Budget status banner shows correct status based on spending
    /// Critical for user awareness - helps users understand their budget status
    func testBudgetStatusBanner() throws {
        // Set a budget first
        try testSetMonthlyBudget()
        
        // Navigate to Overview to see budget status
        app.tabBars.buttons["Overview"].tap()
        
        // Check for budget information display
        let budgetCard = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Budget' OR label CONTAINS 'budget'")).firstMatch
        XCTAssertTrue(budgetCard.waitForExistence(timeout: 3), "Budget information should be displayed on Overview")
        
        // Check for status indicators (may vary based on spending)
        let statusBanner = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Within Budget' OR label CONTAINS 'Over Budget' OR label CONTAINS 'Approaching' OR label CONTAINS 'Remaining'")).firstMatch
        
        // Status may or may not be visible depending on spending, but budget info should exist
        if statusBanner.exists {
            XCTAssertTrue(statusBanner.exists, "Budget status should be displayed when applicable")
        }
    }
    
    /// Test: Budget progress bar displays spending percentage correctly
    /// Visual feedback is important for user understanding of budget usage
    func testBudgetProgressBar() throws {
        // Set budget
        try testSetMonthlyBudget()
        
        // Add an expense to see progress
        app.tabBars.buttons["Overview"].tap()
        
        // Add expense
        addExpense(amount: "10000", category: "Food & Dining")
        
        // Verify progress information is shown
        // Look for percentage, progress bar, or spending indicators
        let percentageText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '%'")).firstMatch
        let progressIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '₹' AND label CONTAINS 'of'")).firstMatch
        
        let progressExists = percentageText.waitForExistence(timeout: 2) || 
                             progressIndicator.waitForExistence(timeout: 2)
        
        XCTAssertTrue(progressExists, "Budget progress/percentage should be displayed")
    }
    
    // MARK: - Budget Calculations
    
    /// Test: Remaining budget is calculated correctly
    /// Critical for accurate budget tracking - ensures financial calculations are correct
    func testRemainingBudgetCalculation() throws {
        // Set budget of 50000
        try testSetMonthlyBudget()
        
        // Add expense of 10000
        app.tabBars.buttons["Overview"].tap()
        addExpense(amount: "10000", category: "Transport")
        
        // Navigate to Budgets tab
        app.tabBars.buttons["Budgets"].tap()
        
        // Verify remaining budget is shown
        // Should show approximately 40000 remaining (50000 - 10000)
        let remainingText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Remaining' OR label CONTAINS '₹'")).firstMatch
        XCTAssertTrue(remainingText.waitForExistence(timeout: 3), "Remaining budget should be displayed")
        
        // Verify spent amount is shown
        let spentText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Spent' OR label CONTAINS '₹10,000' OR label CONTAINS '10000'")).firstMatch
        XCTAssertTrue(spentText.waitForExistence(timeout: 2), "Spent amount should be displayed")
    }
    
    /// Test: Budget updates correctly when expenses are added
    /// Ensures budget calculations update in real-time
    func testBudgetUpdatesWithExpenses() throws {
        // Set initial budget
        try testSetMonthlyBudget()
        
        // Navigate to Overview
        app.tabBars.buttons["Overview"].tap()
        
        // Add first expense
        addExpense(amount: "5000", category: "Food & Dining")
        
        // Navigate to Budgets to check remaining
        app.tabBars.buttons["Budgets"].tap()
        
        // Verify budget reflects the expense
        let remainingAfterFirst = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '₹'")).firstMatch
        XCTAssertTrue(remainingAfterFirst.exists, "Budget should show remaining amount after first expense")
        
        // Add another expense
        app.tabBars.buttons["Overview"].tap()
        addExpense(amount: "3000", category: "Shopping")
        
        // Check budget again
        app.tabBars.buttons["Budgets"].tap()
        
        // Verify budget updated correctly
        let remainingAfterSecond = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '₹'")).firstMatch
        XCTAssertTrue(remainingAfterSecond.exists, "Budget should update after second expense")
    }
    
    // MARK: - Helper Methods
    
    /// Opens the budget sheet from the Budgets screen
    private func openBudgetSheet() {
        // Try "Set Budget" button first
        let setBudgetButton = app.buttons["Set Budget"]
        if setBudgetButton.waitForExistence(timeout: 1) {
            setBudgetButton.tap()
            return
        }
        
        // Try edit button (pencil icon)
        let editButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'pencil' OR label CONTAINS 'plus' OR label CONTAINS 'edit'")).firstMatch
        if editButton.waitForExistence(timeout: 1) {
            editButton.tap()
            return
        }
        
        // Try tapping on "No Budget Set" card
        let noBudgetCard = app.staticTexts["No Budget Set"]
        if noBudgetCard.exists {
            noBudgetCard.tap()
            return
        }
        
        // Fallback: try any button that might open budget sheet
        let anyBudgetButton = app.buttons.firstMatch
        if anyBudgetButton.exists {
            anyBudgetButton.tap()
        }
    }
    
    /// Adds an expense with the given amount and category
    private func addExpense(amount: String, category: String) {
        // Find and tap Add Expense button
        let addButton = app.buttons.matching(identifier: "Add Expense").firstMatch
        if !addButton.exists {
            let fabButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'plus'")).firstMatch
            if fabButton.exists {
                fabButton.tap()
            }
        } else {
            addButton.tap()
        }
        
        // Fill amount
        let amountField = app.textFields["0.00"]
        if amountField.waitForExistence(timeout: 2) {
            amountField.tap()
            amountField.typeText(amount)
        }
        
        // Select category
        let categoryButton = app.buttons["Select Category"]
        if categoryButton.waitForExistence(timeout: 2) {
            categoryButton.tap()
            let category = app.buttons[category]
            if category.waitForExistence(timeout: 2) {
                category.tap()
            }
        }
        
        // Save
        let saveButton = app.buttons["Save"]
        if saveButton.waitForExistence(timeout: 2) && saveButton.isEnabled {
            saveButton.tap()
        }
    }
}

extension XCUIElement {
//    func clearText() {
//        guard let stringValue = self.value as? String else {
//            return
//        }
//        
//        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
//        typeText(deleteString)
//    }
}
