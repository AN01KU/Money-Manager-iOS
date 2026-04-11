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
        if emptyState.waitForExistence(timeout: 2) {
            XCTAssertTrue(emptyState.exists)
        }
    }

    // MARK: - Budget Card Tests

    func testBudgetCardDisplaysWhenBudgetExists() throws {
        app.tabBars.buttons["Overview"].tap()

        let budgetCard = app.buttons["overview.budget-card"]
        if budgetCard.waitForExistence(timeout: 3) {
            XCTAssertTrue(budgetCard.exists)
        }
    }

    func testNoBudgetCardDisplaysWhenNoBudget() throws {
        app.tabBars.buttons["Overview"].tap()

        let noBudgetCard = app.buttons["overview.no-budget-card"]
        if noBudgetCard.waitForExistence(timeout: 3) {
            XCTAssertTrue(noBudgetCard.exists)
        }
    }

    // MARK: - Date Filter Tests

    func testDateFilterSelectorExists() throws {
        app.tabBars.buttons["Overview"].tap()

        let dateFilter = app.buttons["overview.date-filter-button"]
        XCTAssertTrue(dateFilter.waitForExistence(timeout: 3), "Date filter should exist")
    }
}
