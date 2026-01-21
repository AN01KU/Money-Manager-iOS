//
//  NavigationTests.swift
//  Money Manager UITests
//
//  Created by Ankush Ganesh on 13/01/26.
//

import XCTest

/// Tests for navigation flows and screen transitions
/// These tests verify that navigation works correctly throughout the app
final class NavigationTests: XCTestCase {
    
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
    
    // MARK: - Tab Navigation Tests
    
    /// Test: User can navigate between Overview and Budgets tabs
    /// Basic navigation functionality - core app navigation
    func testTabNavigation() throws {
        // Start on Overview
        let overviewTab = app.tabBars.buttons["Overview"]
        XCTAssertTrue(overviewTab.waitForExistence(timeout: 3), "Overview tab should exist")
        overviewTab.tap()
        
        // Verify Overview screen is displayed
        let overviewNavBar = app.navigationBars["Overview"]
        XCTAssertTrue(overviewNavBar.waitForExistence(timeout: 3), "Overview screen should be displayed")
        
        // Navigate to Budgets
        let budgetsTab = app.tabBars.buttons["Budgets"]
        XCTAssertTrue(budgetsTab.waitForExistence(timeout: 3), "Budgets tab should exist")
        budgetsTab.tap()
        
        // Verify Budgets screen is displayed
        let budgetsNavBar = app.navigationBars["Budgets"]
        XCTAssertTrue(budgetsNavBar.waitForExistence(timeout: 3), "Budgets screen should be displayed")
        
        // Navigate back to Overview
        overviewTab.tap()
        
        // Verify Overview screen is displayed again
        XCTAssertTrue(overviewNavBar.waitForExistence(timeout: 5), "Should return to Overview screen")
    }
    
    // MARK: - Sheet Presentation Tests
    
    /// Test: Add Expense sheet can be opened and dismissed
    /// Critical modal flow - primary way to add expenses
    func testAddExpenseSheetPresentation() throws {
        app.tabBars.buttons["Overview"].tap()
        XCTAssertTrue(app.navigationBars["Overview"].waitForExistence(timeout: 3))
        
        // Open Add Expense sheet
        let addButton = findAddExpenseButton()
        addButton.tap()
        
        // Verify sheet is presented
        let addExpenseNavBar = app.navigationBars["Add Expense"]
        XCTAssertTrue(addExpenseNavBar.waitForExistence(timeout: 3), "Add Expense sheet should be presented")
        
        // Dismiss sheet using Cancel button
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.waitForExistence(timeout: 2) {
            cancelButton.tap()
            
            // Verify we're back on Overview
            let overviewNavBar = app.navigationBars["Overview"]
            XCTAssertTrue(overviewNavBar.waitForExistence(timeout: 3), "Should return to Overview after canceling")
        }
    }
    
    /// Test: Budget sheet can be opened and dismissed
    /// Modal flow for budget management
    func testBudgetSheetPresentation() throws {
        app.tabBars.buttons["Budgets"].tap()
        XCTAssertTrue(app.navigationBars["Budgets"].waitForExistence(timeout: 3))
        
        // Open budget sheet
        openBudgetSheet()
        
        // Verify sheet is presented
        let budgetNavBar = app.navigationBars["Set Budget"]
        XCTAssertTrue(budgetNavBar.waitForExistence(timeout: 3), "Budget sheet should be presented")
        
        // Dismiss sheet using Cancel button
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.waitForExistence(timeout: 2) {
            cancelButton.tap()
            
            // Verify we're back on Budgets
            let budgetsNavBar = app.navigationBars["Budgets"]
            XCTAssertTrue(budgetsNavBar.waitForExistence(timeout: 3), "Should return to Budgets after canceling")
        }
    }
    
    // MARK: - Detail View Navigation Tests
    
    /// Test: Transaction detail view can be opened from list
    /// Navigation to detail screens - allows users to view expense details
    func testTransactionDetailNavigation() throws {
        // First add an expense
        app.tabBars.buttons["Overview"].tap()
        XCTAssertTrue(app.navigationBars["Overview"].waitForExistence(timeout: 3))
        addExpense(amount: "250", category: "Shopping")
        
        // Wait for transaction to appear - look for the category text
        let transactionCategory = app.staticTexts["Shopping"].firstMatch
        XCTAssertTrue(transactionCategory.waitForExistence(timeout: 5), "Transaction should exist in list")
        
        // Try tapping the category text - with contentShape(Rectangle()) it should work
        transactionCategory.tap()
        
        // Wait for sheet animation - give it more time
        sleep(3)
        
        // Verify detail view appears - check for navigation bar
        let detailNavBar = app.navigationBars["Transaction Details"]
        if !detailNavBar.waitForExistence(timeout: 5) {
            // If that didn't work, try tapping the amount text instead
            let amountText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '₹250' OR label CONTAINS '250'")).firstMatch
            if amountText.exists {
                amountText.tap()
                sleep(2)
            }
        }
        
        // Final verification
        XCTAssertTrue(detailNavBar.waitForExistence(timeout: 5), "Transaction detail should be accessible")
    }
    
    // MARK: - Back Navigation Tests
    
    /// Test: Back navigation works correctly from detail views
    /// Basic navigation pattern - ensures users can navigate back
    func testBackNavigation() throws {
        // Navigate to a detail view
        app.tabBars.buttons["Overview"].tap()
        XCTAssertTrue(app.navigationBars["Overview"].waitForExistence(timeout: 3))
        
        // Add and view an expense
        addExpense(amount: "150", category: "Entertainment")
        
        // Tap transaction to view details
        let transaction = app.staticTexts["Entertainment"].firstMatch
        XCTAssertTrue(transaction.waitForExistence(timeout: 5), "Transaction should exist")
        transaction.tap()
        
        // Wait for sheet animation
        sleep(2)
        
        // Verify detail screen appears
        let detailNavBar = app.navigationBars["Transaction Details"]
        XCTAssertTrue(detailNavBar.waitForExistence(timeout: 5), "Detail screen should appear")
        
        // Navigate back using Done button (TransactionDetailView uses Done button)
        let doneButton = app.buttons["Done"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 3), "Done button should exist")
        doneButton.tap()
        
        // Wait for sheet dismissal animation
        sleep(1)
        
        // Should be back on Overview
        let overviewNavBar = app.navigationBars["Overview"]
        XCTAssertTrue(overviewNavBar.waitForExistence(timeout: 5), "Should return to Overview after back navigation")
    }
    
    /// Test: Navigation persists correctly when switching tabs
    /// Ensures app state is maintained when switching between tabs
    func testTabSwitchingPreservesState() throws {
        // Start on Overview
        app.tabBars.buttons["Overview"].tap()
        XCTAssertTrue(app.navigationBars["Overview"].waitForExistence(timeout: 3))
        
        // Add an expense
        addExpense(amount: "100", category: "Food & Dining")
        
        // Switch to Budgets tab
        app.tabBars.buttons["Budgets"].tap()
        XCTAssertTrue(app.navigationBars["Budgets"].waitForExistence(timeout: 3))
        
        // Switch back to Overview
        app.tabBars.buttons["Overview"].tap()
        XCTAssertTrue(app.navigationBars["Overview"].waitForExistence(timeout: 3))
        
        // Verify expense is still visible
        let expense = app.staticTexts["Food & Dining"].firstMatch
        XCTAssertTrue(expense.waitForExistence(timeout: 5), "Expense should still be visible after tab switching")
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
        let addButton = findAddExpenseButton()
        addButton.tap()
        
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
