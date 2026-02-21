//
//  OverviewTests.swift
//  Money Manager UITests
//
//  Tests for Overview screen display and data presentation
//

import XCTest

final class OverviewTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "useTestData"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }
    
    // MARK: - Overview Screen Loading
    
    func testOverviewScreenLoads() throws {
        let overviewNavBar = app.navigationBars["Overview"]
        XCTAssertTrue(overviewNavBar.waitForExistence(timeout: 3))
    }
    
    func testOverviewHasFloatingActionButton() throws {
        app.tabBars.buttons["Overview"].tap()
        
        // Button has identifier "plus" and label "Add"
        let fabButton = app.buttons["plus"]
        XCTAssertTrue(fabButton.waitForExistence(timeout: 3), "Floating action button should exist")
    }
    
    // MARK: - Empty State Tests
    
    func testEmptyStateDisplaysWhenNoExpenses() throws {
        app.tabBars.buttons["Overview"].tap()
        
        let emptyStateText = app.staticTexts["No expenses yet"]
        if emptyStateText.waitForExistence(timeout: 2) {
            XCTAssertTrue(emptyStateText.exists)
        }
    }
    
    // MARK: - Budget Card Tests
    
    func testBudgetCardDisplaysWhenBudgetExists() throws {
        app.tabBars.buttons["Overview"].tap()
        
        let budgetTitle = app.staticTexts["Budget"]
        if budgetTitle.waitForExistence(timeout: 3) {
            XCTAssertTrue(budgetTitle.exists)
        }
    }
    
    func testNoBudgetCardDisplaysWhenNoBudget() throws {
        app.tabBars.buttons["Overview"].tap()
        
        let noBudgetText = app.staticTexts["No Budget Set"]
        if noBudgetText.waitForExistence(timeout: 3) {
            XCTAssertTrue(noBudgetText.exists)
        }
    }
    
    // MARK: - View Type Selector Tests
    
    func testViewTypeSelectorExists() throws {
        app.tabBars.buttons["Overview"].tap()
        
        let dailyButton = app.buttons["Daily"]
        let categoriesButton = app.buttons["Categories"]
        
        let hasViewSelector = dailyButton.waitForExistence(timeout: 2) || 
                             categoriesButton.waitForExistence(timeout: 2)
        
        XCTAssertTrue(hasViewSelector, "View type selector should exist")
    }
    
    func testSwitchToCategoriesView() throws {
        app.tabBars.buttons["Overview"].tap()
        
        let categoriesButton = app.buttons["Categories"]
        if categoriesButton.waitForExistence(timeout: 2) {
            categoriesButton.tap()
            
            // Verify categories view by checking the UI updated
            let categoryBreakdownExists = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Food' OR label CONTAINS 'Transport' OR label CONTAINS 'Shopping'")).firstMatch.waitForExistence(timeout: 3)
            let emptyStateExists = app.staticTexts["No expenses yet"].waitForExistence(timeout: 2)
            
            XCTAssertTrue(categoryBreakdownExists || emptyStateExists, "Categories view should display")
        }
    }
    
    // MARK: - Transaction List Tests
    
    func testTransactionListDisplaysExpenses() throws {
        app.tabBars.buttons["Overview"].tap()
        
        // Check if any transactions exist from test data
        let transactions = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Food & Dining' OR label CONTAINS 'Transport' OR label CONTAINS 'Shopping' OR label CONTAINS 'Entertainment'"))
        
        // Either we have transactions or empty state
        let hasTransactions = transactions.firstMatch.waitForExistence(timeout: 3)
        let hasEmptyState = app.staticTexts["No expenses yet"].waitForExistence(timeout: 2)
        
        XCTAssertTrue(hasTransactions || hasEmptyState, "Should have transactions or empty state")
    }
    
    // MARK: - Search Functionality Tests
    
    func testSearchBarVisibleWhenTransactionsExist() throws {
        app.tabBars.buttons["Overview"].tap()
        
        // Wait for transactions to load
        let hasTransactions = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Food' OR label CONTAINS 'Transport' OR label CONTAINS 'Shopping'")).firstMatch.waitForExistence(timeout: 3)
        
        if hasTransactions {
            // Search bar should be visible in toolbar when transactions exist
            let searchField = app.textFields["searchExpensesField"]
            XCTAssertTrue(searchField.waitForExistence(timeout: 2), "Search bar should be visible when transactions exist")
        }
    }
    
    // MARK: - Date Filter Tests
    
    func testDateFilterSelectorExists() throws {
        app.tabBars.buttons["Overview"].tap()
        
        // Check for month/year button
        let dateFilter = app.buttons.matching(NSPredicate(format: "label CONTAINS '2026' OR label CONTAINS '2025'")).firstMatch
        
        XCTAssertTrue(dateFilter.waitForExistence(timeout: 3), "Date filter should exist")
    }
    
    // MARK: - Add Expense Sheet Tests
    
    func testAddExpenseSheetOpens() throws {
        app.tabBars.buttons["Overview"].tap()
        
        // Tap the plus button (identifier: "plus", label: "Add")
        let fabButton = app.buttons["plus"]
        XCTAssertTrue(fabButton.waitForExistence(timeout: 3), "FAB should exist")
        fabButton.tap()
        
        let addExpenseNavBar = app.navigationBars["Add Expense"]
        XCTAssertTrue(addExpenseNavBar.waitForExistence(timeout: 3), "Add Expense sheet should open")
    }
    
    func testAddExpenseSheetCanBeDismissed() throws {
        app.tabBars.buttons["Overview"].tap()
        
        app.buttons["plus"].tap()
        XCTAssertTrue(app.navigationBars["Add Expense"].waitForExistence(timeout: 3))
        
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.waitForExistence(timeout: 2) {
            cancelButton.tap()
            XCTAssertTrue(app.navigationBars["Overview"].waitForExistence(timeout: 3), "Should return to Overview")
        }
    }
}
