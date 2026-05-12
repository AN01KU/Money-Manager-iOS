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
        XCTAssertTrue(emptyState.waitForExistence(timeout: 3), "Empty state should appear when there are no transactions")
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
        XCTAssertTrue(noBudgetCard.waitForExistence(timeout: 3), "No-budget card should appear when no budget is set")
    }

    // MARK: - Date Filter Tests

    func testDateFilterSelectorExists() throws {
        app.tabBars.buttons["Overview"].tap()

        let dateFilter = app.buttons["overview.date-filter-button"]
        XCTAssertTrue(dateFilter.waitForExistence(timeout: 3), "Date filter should exist")
    }
}
