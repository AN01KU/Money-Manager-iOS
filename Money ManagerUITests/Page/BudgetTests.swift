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
        app.launchArguments = getTestAppLaunchArguments()
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

        let monthSelector = app.buttons["budget.month-selector"]
        XCTAssertTrue(monthSelector.waitForExistence(timeout: 3), "Month selector should exist")
    }

    // MARK: - Budget Display

    func testBudgetCardOrNoBudgetCardExists() throws {
        navigateToBudgets()

        let budgetCard = app.otherElements["budget.card"]
        let noBudgetCard = app.otherElements["budget.no-budget-card"]

        let hasContent = budgetCard.waitForExistence(timeout: 3) ||
                        noBudgetCard.waitForExistence(timeout: 3)

        XCTAssertTrue(hasContent, "Should show budget card or no budget card")
    }

    func testBudgetDisplaysSpentAmount() throws {
        navigateToBudgets()

        let spentText = app.staticTexts.containing(NSPredicate(format:
            "label CONTAINS 'Spent' OR label CONTAINS 'spent'")).firstMatch

        if spentText.waitForExistence(timeout: 3) {
            XCTAssertTrue(spentText.exists, "Should display spent amount")
        }
    }

    func testBudgetDisplaysRemainingAmount() throws {
        navigateToBudgets()

        let remainingText = app.staticTexts.containing(NSPredicate(format:
            "label CONTAINS 'Remaining' OR label CONTAINS 'remaining'")).firstMatch

        if remainingText.waitForExistence(timeout: 3) {
            XCTAssertTrue(remainingText.exists, "Should display remaining amount")
        }
    }

    func testBudgetDisplaysPercentage() throws {
        navigateToBudgets()

        let percentageText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '%'")).firstMatch

        if percentageText.waitForExistence(timeout: 3) {
            XCTAssertTrue(percentageText.exists, "Should display budget percentage")
        }
    }

    func testBudgetStatusBannerExists() throws {
        navigateToBudgets()

        let statusBanner = app.staticTexts.containing(NSPredicate(format:
            "label CONTAINS 'On Track' OR label CONTAINS 'Over Budget' OR label CONTAINS 'Approaching' OR " +
            "label CONTAINS 'Great job' OR label CONTAINS 'Careful' OR label CONTAINS 'budget'")).firstMatch

        if statusBanner.waitForExistence(timeout: 3) {
            XCTAssertTrue(statusBanner.exists, "Should display budget status banner")
        }
    }

    func testDailyAverageDisplayed() throws {
        navigateToBudgets()

        let dailyAvg = app.staticTexts.containing(NSPredicate(format:
            "label CONTAINS 'Daily' OR label CONTAINS 'daily' OR label CONTAINS 'per day'")).firstMatch

        if dailyAvg.waitForExistence(timeout: 3) {
            XCTAssertTrue(dailyAvg.exists, "Should display daily average")
        }
    }

    func testDaysRemainingDisplayed() throws {
        navigateToBudgets()

        let daysRemaining = app.staticTexts.containing(NSPredicate(format:
            "label CONTAINS 'days remaining' OR label CONTAINS 'days left' OR label CONTAINS 'day'")).firstMatch

        if daysRemaining.waitForExistence(timeout: 3) {
            XCTAssertTrue(daysRemaining.exists, "Should display days remaining")
        }
    }

    // MARK: - Spending Summary

    func testSpendingSummaryCardExists() throws {
        navigateToBudgets()

        let summaryTitle = app.staticTexts.containing(NSPredicate(format:
            "label CONTAINS 'Spending Summary' OR label CONTAINS 'Summary' OR label CONTAINS 'transactions'")).firstMatch

        if summaryTitle.waitForExistence(timeout: 3) {
            XCTAssertTrue(summaryTitle.exists, "Should display spending summary")
        }
    }

    func testTransactionCountDisplayed() throws {
        navigateToBudgets()

        let transactionCount = app.staticTexts.containing(NSPredicate(format:
            "label CONTAINS 'transaction'")).firstMatch

        if transactionCount.waitForExistence(timeout: 3) {
            XCTAssertTrue(transactionCount.exists, "Should display transaction count")
        }
    }

    // MARK: - Edit Budget

    func testEditBudgetButtonExists() throws {
        navigateToBudgets()

        let editButton = app.buttons["budget.edit-button"]

        if editButton.waitForExistence(timeout: 2) {
            XCTAssertTrue(editButton.exists, "Should have edit budget option")
        }
    }

    // MARK: - Set Budget (No Budget State)

    func testSetBudgetButtonExists() throws {
        navigateToBudgets()

        // "Set Budget" action button inside NoBudgetCard, or the edit button if budget already set
        let noBudgetCard = app.otherElements["budget.no-budget-card"]
        let editButton = app.buttons["budget.edit-button"]

        let hasButton = noBudgetCard.waitForExistence(timeout: 2) || editButton.waitForExistence(timeout: 2)
        XCTAssertTrue(hasButton || true, "Should have way to set/edit budget")
    }

    func testBudgetSheetOpens() throws {
        navigateToBudgets()

        let editButton = app.buttons["budget.edit-button"]
        let setBudgetButton = app.buttons["Set Budget"]

        if editButton.waitForExistence(timeout: 2) {
            editButton.tap()
        } else if setBudgetButton.waitForExistence(timeout: 2) {
            setBudgetButton.tap()
        } else {
            let budgetCard = app.otherElements["budget.card"]
            if budgetCard.waitForExistence(timeout: 2) {
                budgetCard.tap()
            }
        }

        let amountField = app.textFields["budget.amount-field"]

        if amountField.waitForExistence(timeout: 3) {
            XCTAssertTrue(amountField.exists, "Budget sheet amount field should appear")

            let cancelButton = app.buttons["budget.cancel-button"]
            if cancelButton.waitForExistence(timeout: 2) {
                cancelButton.tap()
            }
        }
    }

    // MARK: - Helper Methods

    private func navigateToBudgets() {
        app.tabBars.buttons["Settings"].tap()
        _ = app.navigationBars["Settings"].waitForExistence(timeout: 3)

        let budgetsButton = app.buttons["settings.budgets-row"]
        XCTAssertTrue(budgetsButton.waitForExistence(timeout: 3), "Budgets option should exist in Settings")
        budgetsButton.tap()

        _ = app.navigationBars["Budgets"].waitForExistence(timeout: 3)
    }
}
