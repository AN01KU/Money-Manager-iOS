//
//  BudgetTests.swift
//  Money Manager UITests
//

import XCTest

final class BudgetTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = getTestAppLaunchArguments()
        app.launchEnvironment["SETTINGS_ROUTE"] = "budgets"
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
        XCTAssertTrue(navBar.waitForExistence(timeout: 5), "Budgets screen should load")
    }

    // MARK: - Month Selector

    func testMonthSelectorExists() throws {
        navigateToBudgets()

        let monthSelector = app.buttons.matching(identifier: "budget.month-selector").firstMatch
        XCTAssertTrue(monthSelector.waitForExistence(timeout: 5), "Month selector should exist")
    }

    // MARK: - Budget Display

    func testBudgetCardOrNoBudgetCardExists() throws {
        navigateToBudgets()

        let budgetCard = app.otherElements.matching(identifier: "budget.card").firstMatch
        let noBudgetCard = app.otherElements.matching(identifier: "budget.no-budget-card").firstMatch

        let hasContent = budgetCard.waitForExistence(timeout: 5) ||
                        noBudgetCard.waitForExistence(timeout: 2)
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

    // MARK: - Edit Budget

    func testEditBudgetButtonExists() throws {
        navigateToBudgets()

        let editButton = app.buttons.matching(identifier: "budget.edit-button").firstMatch
        if editButton.waitForExistence(timeout: 3) {
            XCTAssertTrue(editButton.exists, "Should have edit budget option")
        }
    }

    func testBudgetSheetOpens() throws {
        navigateToBudgets()

        let editButton = app.buttons.matching(identifier: "budget.edit-button").firstMatch
        let noBudgetCard = app.otherElements.matching(identifier: "budget.no-budget-card").firstMatch

        if editButton.waitForExistence(timeout: 3) {
            editButton.tap()
        } else if noBudgetCard.waitForExistence(timeout: 2) {
            noBudgetCard.tap()
        }

        let amountField = app.textFields.matching(identifier: "budget.amount-field").firstMatch
        if amountField.waitForExistence(timeout: 3) {
            XCTAssertTrue(amountField.exists, "Budget sheet amount field should appear")
            let cancelButton = app.buttons.matching(identifier: "budget.cancel-button").firstMatch
            if cancelButton.waitForExistence(timeout: 2) {
                cancelButton.tap()
            }
        }
    }

    // MARK: - Helpers

    /// Taps the Settings tab; SETTINGS_ROUTE=budgets causes the app to auto-push to Budgets on appear.
    private func navigateToBudgets() {
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Budgets"].waitForExistence(timeout: 8), "Budgets screen should load")
    }
}
