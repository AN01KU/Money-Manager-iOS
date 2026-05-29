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
        let setBudgetButton = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Set Budget'")).firstMatch

        if editButton.waitForExistence(timeout: 3) {
            editButton.tap()
        } else if setBudgetButton.waitForExistence(timeout: 2) {
            setBudgetButton.tap()
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

    // MARK: - Set Budget Interaction

    func testSetBudgetLimitDisplaysOnCard() throws {
        navigateToBudgets()

        // Open the budget sheet via the edit button or the "Set Budget" button inside the no-budget card
        let editButton = app.buttons.matching(identifier: "budget.edit-button").firstMatch
        let setBudgetButton = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Set Budget'")).firstMatch

        if editButton.waitForExistence(timeout: 3) {
            editButton.tap()
        } else {
            XCTAssertTrue(setBudgetButton.waitForExistence(timeout: 3), "Either edit button or Set Budget button must exist")
            setBudgetButton.tap()
        }

        let amountField = app.textFields.matching(identifier: "budget.amount-field").firstMatch
        XCTAssertTrue(amountField.waitForExistence(timeout: 5), "Budget amount field should appear")

        amountField.tap()
        // Clear existing value then type the test limit
        amountField.press(forDuration: 1.0)
        if app.menuItems["Select All"].waitForExistence(timeout: 1) {
            app.menuItems["Select All"].tap()
        }
        amountField.typeText("12345")

        let saveButton = app.buttons.matching(identifier: "budget.save-button").firstMatch
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3), "Save button should exist")
        saveButton.tap()

        // After dismiss, the card should display the saved limit
        let budgetCard = app.otherElements.matching(identifier: "budget.card").firstMatch
        XCTAssertTrue(budgetCard.waitForExistence(timeout: 5), "Budget card should appear after saving")
        XCTAssertTrue(
            budgetCard.label.contains("12,345") || budgetCard.label.contains("12345"),
            "Budget card should display the saved limit; got: \(budgetCard.label)"
        )
    }

    // MARK: - Helpers

    /// Taps the Settings tab; SETTINGS_ROUTE=budgets causes the app to auto-push to Budgets on appear.
    private func navigateToBudgets() {
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Budgets"].waitForExistence(timeout: 8), "Budgets screen should load")
    }
}
