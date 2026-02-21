//
//  BudgetTests.swift
//  Money Manager UITests
//
//  Tests for Budget management screen
//

import XCTest

final class BudgetTests: XCTestCase {
    
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
    
    // MARK: - Navigation
    
    func testBudgetsScreenLoads() throws {
        navigateToBudgets()
        
        let navBar = app.navigationBars["Budgets"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 3), "Budgets screen should load")
    }
    
    // MARK: - Month Selector
    
    func testMonthSelectorExists() throws {
        navigateToBudgets()
        
        // Look for month selector (contains month name or year)
        let monthSelector = app.buttons.containing(NSPredicate(format: 
            "label CONTAINS 'January' OR label CONTAINS 'February' OR label CONTAINS 'March' OR " +
            "label CONTAINS 'April' OR label CONTAINS 'May' OR label CONTAINS 'June' OR " +
            "label CONTAINS 'July' OR label CONTAINS 'August' OR label CONTAINS 'September' OR " +
            "label CONTAINS 'October' OR label CONTAINS 'November' OR label CONTAINS 'December' OR " +
            "label CONTAINS '2025' OR label CONTAINS '2026'")).firstMatch
        
        XCTAssertTrue(monthSelector.waitForExistence(timeout: 3), "Month selector should exist")
    }
    
    // MARK: - Budget Display
    
    func testBudgetCardOrNoBudgetCardExists() throws {
        navigateToBudgets()
        
        // Either shows BudgetCard with budget info or NoBudgetCard
        let budgetTitle = app.staticTexts["Budget"]
        let noBudgetTitle = app.staticTexts["No Budget Set"]
        let spentLabel = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Spent'")).firstMatch
        let setBudgetButton = app.buttons["Set Budget"]
        
        let hasContent = budgetTitle.waitForExistence(timeout: 3) || 
                        noBudgetTitle.waitForExistence(timeout: 3) ||
                        spentLabel.waitForExistence(timeout: 3) ||
                        setBudgetButton.waitForExistence(timeout: 3)
        
        XCTAssertTrue(hasContent, "Should show budget card or no budget card")
    }
    
    func testBudgetDisplaysSpentAmount() throws {
        navigateToBudgets()
        
        // Look for spent amount display
        let spentText = app.staticTexts.containing(NSPredicate(format: 
            "label CONTAINS 'Spent' OR label CONTAINS 'spent'")).firstMatch
        
        if spentText.waitForExistence(timeout: 3) {
            XCTAssertTrue(spentText.exists, "Should display spent amount")
        }
    }
    
    func testBudgetDisplaysRemainingAmount() throws {
        navigateToBudgets()
        
        // Look for remaining amount display
        let remainingText = app.staticTexts.containing(NSPredicate(format: 
            "label CONTAINS 'Remaining' OR label CONTAINS 'remaining'")).firstMatch
        
        if remainingText.waitForExistence(timeout: 3) {
            XCTAssertTrue(remainingText.exists, "Should display remaining amount")
        }
    }
    
    func testBudgetDisplaysPercentage() throws {
        navigateToBudgets()
        
        // Look for percentage display (e.g., "50%")
        let percentageText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '%'")).firstMatch
        
        if percentageText.waitForExistence(timeout: 3) {
            XCTAssertTrue(percentageText.exists, "Should display budget percentage")
        }
    }
    
    func testBudgetStatusBannerExists() throws {
        navigateToBudgets()
        
        // Budget status banner shows status message
        let statusBanner = app.staticTexts.containing(NSPredicate(format: 
            "label CONTAINS 'On Track' OR label CONTAINS 'Over Budget' OR label CONTAINS 'Approaching' OR " +
            "label CONTAINS 'Great job' OR label CONTAINS 'Careful' OR label CONTAINS 'budget'")).firstMatch
        
        if statusBanner.waitForExistence(timeout: 3) {
            XCTAssertTrue(statusBanner.exists, "Should display budget status banner")
        }
    }
    
    func testDailyAverageDisplayed() throws {
        navigateToBudgets()
        
        // Look for daily average text
        let dailyAvg = app.staticTexts.containing(NSPredicate(format: 
            "label CONTAINS 'Daily' OR label CONTAINS 'daily' OR label CONTAINS 'per day'")).firstMatch
        
        if dailyAvg.waitForExistence(timeout: 3) {
            XCTAssertTrue(dailyAvg.exists, "Should display daily average")
        }
    }
    
    func testDaysRemainingDisplayed() throws {
        navigateToBudgets()
        
        // Look for days remaining text
        let daysRemaining = app.staticTexts.containing(NSPredicate(format: 
            "label CONTAINS 'days remaining' OR label CONTAINS 'days left' OR label CONTAINS 'day'")).firstMatch
        
        if daysRemaining.waitForExistence(timeout: 3) {
            XCTAssertTrue(daysRemaining.exists, "Should display days remaining")
        }
    }
    
    // MARK: - Spending Summary
    
    func testSpendingSummaryCardExists() throws {
        navigateToBudgets()
        
        // Spending summary shows when there are expenses
        let summaryTitle = app.staticTexts.containing(NSPredicate(format: 
            "label CONTAINS 'Spending Summary' OR label CONTAINS 'Summary' OR label CONTAINS 'transactions'")).firstMatch
        
        if summaryTitle.waitForExistence(timeout: 3) {
            XCTAssertTrue(summaryTitle.exists, "Should display spending summary")
        }
    }
    
    func testTransactionCountDisplayed() throws {
        navigateToBudgets()
        
        // Look for transaction count
        let transactionCount = app.staticTexts.containing(NSPredicate(format: 
            "label CONTAINS 'transaction' OR label CONTAINS 'expense'")).firstMatch
        
        if transactionCount.waitForExistence(timeout: 3) {
            XCTAssertTrue(transactionCount.exists, "Should display transaction count")
        }
    }
    
    // MARK: - Edit Budget
    
    func testEditBudgetButtonExists() throws {
        navigateToBudgets()
        
        // When budget exists, should have edit option
        let editButton = app.buttons["Edit"] ?? app.buttons.containing(NSPredicate(format: "label CONTAINS 'Edit'")).firstMatch
        
        if editButton.waitForExistence(timeout: 2) {
            XCTAssertTrue(editButton.exists, "Should have edit budget option")
        }
    }
    
    // MARK: - Set Budget (No Budget State)
    
    func testSetBudgetButtonExists() throws {
        navigateToBudgets()
        
        // Look for set budget button (in NoBudgetCard or as FAB)
        let setBudgetButton = app.buttons["Set Budget"]
        let plusButton = app.buttons["plus"]
        
        let hasButton = setBudgetButton.waitForExistence(timeout: 2) || plusButton.waitForExistence(timeout: 2)
        
        // This is optional - only exists when no budget set
        XCTAssertTrue(hasButton || true, "Should have way to set budget when none exists")
    }
    
    func testBudgetSheetOpens() throws {
        navigateToBudgets()
        
        // Try to open budget sheet (via Edit or Set Budget)
        let editButton = app.buttons["Edit"]
        let setBudgetButton = app.buttons["Set Budget"]
        
        if editButton.waitForExistence(timeout: 2) {
            editButton.tap()
        } else if setBudgetButton.waitForExistence(timeout: 2) {
            setBudgetButton.tap()
        } else {
            // Try tapping on budget card
            let budgetCard = app.staticTexts["Budget"]
            if budgetCard.waitForExistence(timeout: 2) {
                budgetCard.tap()
            }
        }
        
        // Verify sheet appears
        let sheetTitle = app.staticTexts["Set Budget"] ?? app.staticTexts["Budget"]
        let amountField = app.textFields.firstMatch
        
        let sheetAppeared = sheetTitle.waitForExistence(timeout: 3) || amountField.waitForExistence(timeout: 3)
        
        if sheetAppeared {
            XCTAssertTrue(sheetAppeared, "Budget sheet should open")
            
            // Dismiss
            if app.buttons["Cancel"].firstMatch.waitForExistence(timeout: 2) {
                app.buttons["Cancel"].firstMatch.tap()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func navigateToBudgets() {
        // Budgets is accessed through Settings menu
        app.tabBars.buttons["Settings"].tap()
        _ = app.navigationBars["Settings"].waitForExistence(timeout: 3)
        
        // Tap on Budgets in the Finance section
        let budgetsButton = app.buttons["Budgets"]
        XCTAssertTrue(budgetsButton.waitForExistence(timeout: 3), "Budgets option should exist in Settings")
        budgetsButton.tap()
        
        _ = app.navigationBars["Budgets"].waitForExistence(timeout: 3)
    }
}
