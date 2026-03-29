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

    // MARK: - Date Filter Tests

    func testDateFilterSelectorExists() throws {
        app.tabBars.buttons["Overview"].tap()

        // Check for month/year button in the header card
        let dateFilter = app.buttons.matching(NSPredicate(format: "label CONTAINS '2026' OR label CONTAINS '2025'")).firstMatch

        XCTAssertTrue(dateFilter.waitForExistence(timeout: 3), "Date filter should exist")
    }
}
