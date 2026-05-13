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
        app.launchArguments = getTestAppLaunchArguments()
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

    // MARK: - Empty State Tests

    func testEmptyStateDisplaysWhenNoTransactions() throws {
        app.tabBars.buttons["Overview"].tap()

        let emptyState = app.otherElements["overview.empty-state"]
        let budgetCard = app.buttons["overview.budget-card"]
        let noBudgetCard = app.buttons["overview.no-budget-card"]
        let hasData = budgetCard.waitForExistence(timeout: 3) || noBudgetCard.waitForExistence(timeout: 1)
        if hasData {
            // Test account has data — empty state should not be visible
            XCTAssertFalse(emptyState.exists, "Empty state should not appear when transactions exist")
        } else {
            XCTAssertTrue(emptyState.waitForExistence(timeout: 3), "Empty state should appear when there are no transactions")
        }
    }

    // MARK: - Budget Card Tests

    func testBudgetCardDisplaysWhenBudgetExists() throws {
        app.tabBars.buttons["Overview"].tap()

        let budgetCard = app.buttons["overview.budget-card"]
        XCTAssertTrue(budgetCard.waitForExistence(timeout: 3), "Budget card should appear when a budget exists")
    }

    func testNoBudgetCardDisplaysWhenNoBudget() throws {
        app.tabBars.buttons["Overview"].tap()

        let noBudgetCard = app.buttons["overview.no-budget-card"]
        let budgetCard = app.buttons["overview.budget-card"]
        if budgetCard.waitForExistence(timeout: 3) {
            // Test account has a budget — budget card should be shown, no-budget card should not
            XCTAssertFalse(noBudgetCard.exists, "No-budget card should not appear when a budget is set")
        } else {
            XCTAssertTrue(noBudgetCard.waitForExistence(timeout: 3), "No-budget card should appear when no budget is set")
        }
    }

    // MARK: - Date Filter Tests

    func testDateFilterSelectorExists() throws {
        app.tabBars.buttons["Overview"].tap()

        let dateFilter = app.buttons["overview.date-filter-button"]
        XCTAssertTrue(dateFilter.waitForExistence(timeout: 3), "Date filter should exist")
    }
}
