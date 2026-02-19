//
//  GroupDetailTests.swift
//  Money Manager UITests
//
//  Tests for Groups screen (list view)
//

import XCTest

final class GroupDetailTests: XCTestCase {
    
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
    
    // MARK: - Groups List Screen
    
    func testGroupsScreenLoads() throws {
        navigateToGroups()
        
        let navBar = app.navigationBars["Groups"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 3), "Groups screen should load")
    }
    
    func testGroupsHasContentOrEmptyState() throws {
        navigateToGroups()
        
        // Either has groups list or empty state
        let hasGroups = app.cells.firstMatch.waitForExistence(timeout: 2) ||
                       app.buttons.count > 3 // More than just tab bar buttons
        let emptyState = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'No groups' OR label CONTAINS 'empty' OR label CONTAINS 'Create Group'")).firstMatch.waitForExistence(timeout: 2)
        
        XCTAssertTrue(hasGroups || emptyState, "Should have groups or empty state")
    }
    
    func testGroupsHasSearchBar() throws {
        navigateToGroups()
        
        // Searchable modifier creates search field
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 3), "Search bar should exist")
    }
    
    func testGroupsHasViewTabs() throws {
        navigateToGroups()
        
        // Look for Groups/Activities segmented control
        let groupsTab = app.buttons["Groups"]
        let activitiesTab = app.buttons["Activities"]
        
        let hasTabs = groupsTab.waitForExistence(timeout: 2) || activitiesTab.waitForExistence(timeout: 2)
        XCTAssertTrue(hasTabs, "Should have Groups/Activities tabs")
    }
    
    func testCreateGroupButtonExists() throws {
        navigateToGroups()
        
        // Look for FAB or create button
        let fab = app.buttons["plus"]
        let createBtn = app.buttons["Create Group"]
        
        let hasButton = fab.waitForExistence(timeout: 2) || createBtn.waitForExistence(timeout: 2)
        XCTAssertTrue(hasButton, "Should have create group button")
    }
    
    // MARK: - Helper Methods
    
    private func navigateToGroups() {
        app.tabBars.buttons["Groups"].tap()
        _ = app.navigationBars["Groups"].waitForExistence(timeout: 3)
    }
}
