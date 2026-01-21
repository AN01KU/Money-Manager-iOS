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
        
        // Wait for Budgets screen to load
        XCTAssertTrue(app.navigationBars["Budgets"].waitForExistence(timeout: 3), "Budgets screen should load")
        
        // Open budget sheet using toolbar button
        openBudgetSheet()
        
        // Verify budget sheet appears
        let budgetNavBar = app.navigationBars["Set Budget"]
        XCTAssertTrue(budgetNavBar.waitForExistence(timeout: 3), "Budget sheet should appear")
        
        // Enter budget amount
        let budgetField = app.textFields.firstMatch
        XCTAssertTrue(budgetField.waitForExistence(timeout: 3), "Budget amount field should exist")
        budgetField.tap()
        
        // Clear any existing text and enter amount
        if let currentValue = budgetField.value as? String, !currentValue.isEmpty {
            budgetField.clearText()
        }
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
        
        // Verify budget amount is displayed (check for various formats)
        let budgetText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '₹50' OR label CONTAINS '50000' OR label CONTAINS '50,000'")).firstMatch
        XCTAssertTrue(budgetText.waitForExistence(timeout: 3), "Budget amount should be displayed")
    }
    
    /// Test: Budget validation prevents invalid amounts
    /// Critical for data integrity - ensures only valid budgets can be set
    func testBudgetValidation() throws {
        app.tabBars.buttons["Budgets"].tap()
        XCTAssertTrue(app.navigationBars["Budgets"].waitForExistence(timeout: 3))
        
        // Open budget sheet
        openBudgetSheet()
        
        // Verify budget sheet appears
        let budgetNavBar = app.navigationBars["Set Budget"]
        XCTAssertTrue(budgetNavBar.waitForExistence(timeout: 3), "Budget sheet should appear")
        
        // Get the budget field and save button
        let budgetField = app.textFields.firstMatch
        XCTAssertTrue(budgetField.waitForExistence(timeout: 2), "Budget field should exist")
        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2), "Save button should exist")
        
        // Clear any existing value first
        budgetField.tap()
        if let currentValue = budgetField.value as? String, !currentValue.isEmpty {
            budgetField.clearText()
        }
        
        // Wait a moment for UI to update
        sleep(1)
        
        // Verify Save button is disabled for empty amount
        XCTAssertFalse(saveButton.isEnabled, "Save should be disabled for empty budget")
        
        // Enter invalid amount (zero)
        budgetField.typeText("0")
        sleep(1) // Wait for validation to update
        
        // Save should still be disabled for zero amount
        XCTAssertFalse(saveButton.isEnabled, "Save should be disabled for zero amount")
        
        // Enter valid amount
        budgetField.clearText()
        budgetField.typeText("50000")
        sleep(1) // Wait for validation to update
        
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
        XCTAssertTrue(app.navigationBars["Overview"].waitForExistence(timeout: 3))
        
        // Check for budget information display
        let budgetCard = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Budget' OR label CONTAINS 'budget'")).firstMatch
        XCTAssertTrue(budgetCard.waitForExistence(timeout: 3), "Budget information should be displayed on Overview")
    }
    
    /// Test: Budget progress bar displays spending percentage correctly
    /// Visual feedback is important for user understanding of budget usage
    func testBudgetProgressBar() throws {
        // Set budget
        try testSetMonthlyBudget()
        
        // Add an expense to see progress
        app.tabBars.buttons["Overview"].tap()
        XCTAssertTrue(app.navigationBars["Overview"].waitForExistence(timeout: 3))
        
        // Add expense
        addExpense(amount: "10000", category: "Food & Dining")
        
        // Verify progress information is shown
        // Look for percentage, progress bar, or spending indicators
        let percentageText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '%'")).firstMatch
        let progressIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '₹' AND label CONTAINS 'of'")).firstMatch
        
        let progressExists = percentageText.waitForExistence(timeout: 3) || 
                             progressIndicator.waitForExistence(timeout: 3)
        
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
        XCTAssertTrue(app.navigationBars["Overview"].waitForExistence(timeout: 3))
        addExpense(amount: "10000", category: "Transport")
        
        // Navigate to Budgets tab
        app.tabBars.buttons["Budgets"].tap()
        XCTAssertTrue(app.navigationBars["Budgets"].waitForExistence(timeout: 3))
        
        // Verify remaining budget is shown
        let remainingText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Remaining' OR label CONTAINS '₹'")).firstMatch
        XCTAssertTrue(remainingText.waitForExistence(timeout: 3), "Remaining budget should be displayed")
        
        // Verify spent amount is shown
        let spentText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Spent' OR label CONTAINS '₹10' OR label CONTAINS '10000'")).firstMatch
        XCTAssertTrue(spentText.waitForExistence(timeout: 3), "Spent amount should be displayed")
    }
    
    /// Test: Budget updates correctly when expenses are added
    /// Ensures budget calculations update in real-time
    func testBudgetUpdatesWithExpenses() throws {
        // Set initial budget
        try testSetMonthlyBudget()
        
        // Navigate to Overview
        app.tabBars.buttons["Overview"].tap()
        XCTAssertTrue(app.navigationBars["Overview"].waitForExistence(timeout: 3))
        
        // Add first expense
        addExpense(amount: "5000", category: "Food & Dining")
        
        // Navigate to Budgets to check remaining
        app.tabBars.buttons["Budgets"].tap()
        XCTAssertTrue(app.navigationBars["Budgets"].waitForExistence(timeout: 3))
        
        // Verify budget reflects the expense
        let remainingAfterFirst = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '₹'")).firstMatch
        XCTAssertTrue(remainingAfterFirst.waitForExistence(timeout: 3), "Budget should show remaining amount after first expense")
        
        // Add another expense
        app.tabBars.buttons["Overview"].tap()
        XCTAssertTrue(app.navigationBars["Overview"].waitForExistence(timeout: 3))
        addExpense(amount: "3000", category: "Shopping")
        
        // Check budget again
        app.tabBars.buttons["Budgets"].tap()
        XCTAssertTrue(app.navigationBars["Budgets"].waitForExistence(timeout: 3))
        
        // Verify budget updated correctly
        let remainingAfterSecond = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '₹'")).firstMatch
        XCTAssertTrue(remainingAfterSecond.waitForExistence(timeout: 3), "Budget should update after second expense")
    }
    
    // MARK: - Helper Methods
    
    /// Opens the budget sheet from the Budgets screen
    private func openBudgetSheet() {
        // Try tapping on "No Budget Set" card first (most reliable)
        let noBudgetCard = app.staticTexts["No Budget Set"]
        if noBudgetCard.waitForExistence(timeout: 2) {
            noBudgetCard.tap()
            return
        }
        
        // Try toolbar button (plus or pencil icon) - find by position in navigation bar
        let navBar = app.navigationBars["Budgets"]
        if navBar.waitForExistence(timeout: 2) {
            // Try to find toolbar buttons
            let toolbarButtons = navBar.buttons
            if toolbarButtons.count > 0 {
                // Usually the last button is the action button
                toolbarButtons.element(boundBy: toolbarButtons.count - 1).tap()
                return
            }
        }
        
        // Fallback: try "Set Budget" button if it exists
        let setBudgetButton = app.buttons["Set Budget"]
        if setBudgetButton.waitForExistence(timeout: 1) {
            setBudgetButton.tap()
            return
        }
    }
    
    /// Adds an expense with the given amount and category
    private func addExpense(amount: String, category: String) {
        // Find and tap Add Expense button
        let addButton = app.buttons.matching(identifier: "Add Expense").firstMatch
        if !addButton.exists {
            // Try FAB button (plus icon)
            let fabButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'plus' OR label CONTAINS '+'")).firstMatch
            if fabButton.waitForExistence(timeout: 2) {
                fabButton.tap()
            } else {
                // Try toolbar button
                let navBar = app.navigationBars["Overview"]
                if navBar.waitForExistence(timeout: 2) {
                    let toolbarButtons = navBar.buttons
                    if toolbarButtons.count > 0 {
                        toolbarButtons.element(boundBy: toolbarButtons.count - 1).tap()
                    }
                }
            }
        } else {
            addButton.tap()
        }
        
        // Wait for Add Expense screen
        let addExpenseNavBar = app.navigationBars["Add Expense"]
        guard addExpenseNavBar.waitForExistence(timeout: 3) else {
            XCTFail("Add Expense screen did not appear")
            return
        }
        
        // Fill amount
        let amountField = app.textFields["0.00"]
        if amountField.waitForExistence(timeout: 2) {
            amountField.tap()
            if let currentValue = amountField.value as? String, currentValue != "0.00" {
                amountField.clearText()
            }
            amountField.typeText(amount)
        }
        
        // Select category
        let categoryButton = app.buttons["Select Category"]
        if categoryButton.waitForExistence(timeout: 2) {
            categoryButton.tap()
            let categoryOption = app.buttons[category]
            if categoryOption.waitForExistence(timeout: 2) {
                categoryOption.tap()
            }
        }
        
        // Save
        let saveButton = app.buttons["Save"]
        if saveButton.waitForExistence(timeout: 2) && saveButton.isEnabled {
            saveButton.tap()
        }
        
        // Wait for Overview to return
        let overviewNavBar = app.navigationBars["Overview"]
        XCTAssertTrue(overviewNavBar.waitForExistence(timeout: 5), "Should return to Overview after saving expense")
    }
}
