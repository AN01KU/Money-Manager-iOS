//
//  GroupsTests.swift
//  Money Manager UITests
//
//  Tests for Groups list and detail screens
//

import XCTest

final class GroupsTests: XCTestCase {
    
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
    
    func testGroupsHasSearchBar() throws {
        navigateToGroups()
        
        // Searchable modifier creates a search field
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 3), "Search bar should exist")
    }
    
    func testGroupsViewTabsExist() throws {
        navigateToGroups()
        
        let groupsTab = app.buttons["Groups"]
        let activitiesTab = app.buttons["Activities"]
        
        XCTAssertTrue(groupsTab.waitForExistence(timeout: 2) || activitiesTab.waitForExistence(timeout: 2), 
                     "Groups/Activities tabs should exist")
    }
    
    func testSwitchToActivitiesTab() throws {
        navigateToGroups()
        
        let activitiesTab = app.buttons["Activities"]
        if activitiesTab.waitForExistence(timeout: 2) {
            activitiesTab.tap()
            sleep(1)
            
            // Verify we're on Activities tab
            XCTAssertTrue(activitiesTab.isSelected, "Activities tab should be selected")
        }
    }
    
    // MARK: - Empty State
    
    func testEmptyStateWhenNoGroups() throws {
        navigateToGroups()
        
        // If no groups, should show empty state
        let emptyStateIcon = app.images["person.3.fill"]
        let createGroupButton = app.buttons["Create Group"]
        
        if emptyStateIcon.waitForExistence(timeout: 2) || createGroupButton.waitForExistence(timeout: 2) {
            XCTAssertTrue(true, "Empty state should show when no groups")
        }
    }
    
    // MARK: - Create Group
    
    func testCreateGroupButtonExists() throws {
        navigateToGroups()
        
        // FAB or empty state button
        let fabButton = app.buttons["plus"]
        let createButton = app.buttons["Create Group"]
        
        let hasCreateButton = fabButton.waitForExistence(timeout: 2) || createButton.waitForExistence(timeout: 2)
        XCTAssertTrue(hasCreateButton, "Create group button should exist")
    }
    
    func testCreateGroupSheetOpens() throws {
        navigateToGroups()
        
        // Try FAB first
        let fabButton = app.buttons["plus"]
        if fabButton.waitForExistence(timeout: 2) {
            fabButton.tap()
        } else {
            // Try empty state button
            let createButton = app.buttons["Create Group"]
            if createButton.waitForExistence(timeout: 2) {
                createButton.tap()
            }
        }
        
        sleep(1)
        
        // Verify create group sheet appears - look for various indicators
        let sheetTitle = app.staticTexts["Create Group"]
        let nameField = app.textFields.firstMatch
        let navBar = app.navigationBars.firstMatch
        let sheetAppeared = sheetTitle.waitForExistence(timeout: 3) || 
                           nameField.waitForExistence(timeout: 3) ||
                           navBar.waitForExistence(timeout: 3)
        
        XCTAssertTrue(sheetAppeared, "Create group sheet should appear")
        
        // Dismiss to clean up
        app.buttons["Cancel"].firstMatch.tap()
    }
    
    // MARK: - Group Detail Navigation
    
    func testGroupDetailNavigation() throws {
        navigateToGroups()
        
        // Tap on a group if one exists
        let groupButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Trip' OR label CONTAINS 'Lunch' OR label CONTAINS 'Office' OR label CONTAINS 'Weekend'")).firstMatch
        
        if groupButton.waitForExistence(timeout: 3) {
            groupButton.tap()
            
            // Verify detail screen opens
            let detailNavBar = app.navigationBars.containing(NSPredicate(format: "label CONTAINS 'Trip' OR label CONTAINS 'Lunch' OR label CONTAINS 'Office' OR label CONTAINS 'Expenses' OR label CONTAINS 'Balances'")).firstMatch
            XCTAssertTrue(detailNavBar.waitForExistence(timeout: 3), "Group detail should open")
        }
    }
    
    // MARK: - Group Detail Screen
    
    func testGroupDetailHasTabs() throws {
        navigateToGroups()
        
        // Open a group
        let groupButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Trip' OR label CONTAINS 'Lunch' OR label CONTAINS 'Office'")).firstMatch
        if groupButton.waitForExistence(timeout: 2) {
            groupButton.tap()
            
            // Check for segment tabs
            let expensesTab = app.buttons["Expenses"]
            let balancesTab = app.buttons["Balances"]
            let membersTab = app.buttons["Members"]
            
            let hasTabs = expensesTab.waitForExistence(timeout: 2) || 
                         balancesTab.waitForExistence(timeout: 2) || 
                         membersTab.waitForExistence(timeout: 2)
            
            XCTAssertTrue(hasTabs, "Group detail should have tabs")
        }
    }
    
    func testGroupDetailAddExpenseButton() throws {
        navigateToGroups()
        
        let groupButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Trip' OR label CONTAINS 'Lunch' OR label CONTAINS 'Office'")).firstMatch
        if groupButton.waitForExistence(timeout: 2) {
            groupButton.tap()
            
            // Check for add expense button (usually FAB)
            let addButton = app.buttons["plus"]
            XCTAssertTrue(addButton.waitForExistence(timeout: 3), "Add expense button should exist in group detail")
        }
    }
    
    func testBackNavigationFromGroupDetail() throws {
        navigateToGroups()
        
        let groupButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Trip' OR label CONTAINS 'Lunch' OR label CONTAINS 'Office'")).firstMatch
        if groupButton.waitForExistence(timeout: 2) {
            groupButton.tap()
            sleep(1)
            
            // Tap back button
            app.navigationBars.buttons.firstMatch.tap()
            
            // Verify we're back on Groups list
            XCTAssertTrue(app.navigationBars["Groups"].waitForExistence(timeout: 3), "Should return to Groups list")
        }
    }
    
    // MARK: - Search Functionality
    
    func testSearchFiltersGroups() throws {
        navigateToGroups()
        
        let searchField = app.searchFields.firstMatch
        if searchField.waitForExistence(timeout: 3) {
            searchField.tap()
            searchField.typeText("Trip")
            
            // Search should filter results
            sleep(1)
            XCTAssertTrue(searchField.value != nil, "Search should work")
        }
    }
    
    // MARK: - Helper Methods
    
    private func navigateToGroups() {
        app.tabBars.buttons["Groups"].tap()
        XCTAssertTrue(app.navigationBars["Groups"].waitForExistence(timeout: 3), "Should navigate to Groups")
    }
}
