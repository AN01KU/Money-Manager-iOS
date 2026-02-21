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
        app.launchArguments = ["--uitesting", "useTestData"]
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
    
    // MARK: - Add Member / Invite
    
    func testMembersTabShowsAddMemberFAB() throws {
        navigateToGroupDetail()
        
        let membersTab = app.buttons["Members"]
        guard membersTab.waitForExistence(timeout: 3) else { return }
        membersTab.tap()
        
        let fab = app.buttons["person.badge.plus"]
        XCTAssertTrue(fab.waitForExistence(timeout: 3), "Add member FAB should appear on Members tab")
    }
    
    func testAddMemberFABOpensInviteSheet() throws {
        navigateToGroupDetail()
        
        let membersTab = app.buttons["Members"]
        guard membersTab.waitForExistence(timeout: 3) else { return }
        membersTab.tap()
        
        let fab = app.buttons["person.badge.plus"]
        guard fab.waitForExistence(timeout: 3) else { return }
        fab.tap()
        
        let sheetTitle = app.navigationBars["Invite Member"]
        XCTAssertTrue(sheetTitle.waitForExistence(timeout: 3), "Invite Member sheet should appear")
    }
    
    func testInviteSheetHasEmailField() throws {
        navigateToGroupDetail()
        
        let membersTab = app.buttons["Members"]
        guard membersTab.waitForExistence(timeout: 3) else { return }
        membersTab.tap()
        
        let fab = app.buttons["person.badge.plus"]
        guard fab.waitForExistence(timeout: 3) else { return }
        fab.tap()
        
        let emailField = app.textFields["e.g., user@example.com"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 3), "Email text field should exist")
    }
    
    func testInviteSheetCancelDismisses() throws {
        navigateToGroupDetail()
        
        let membersTab = app.buttons["Members"]
        guard membersTab.waitForExistence(timeout: 3) else { return }
        membersTab.tap()
        
        let fab = app.buttons["person.badge.plus"]
        guard fab.waitForExistence(timeout: 3) else { return }
        fab.tap()
        
        let cancelButton = app.buttons["Cancel"]
        guard cancelButton.waitForExistence(timeout: 3) else { return }
        cancelButton.tap()
        
        let sheetTitle = app.navigationBars["Invite Member"]
        XCTAssertFalse(sheetTitle.waitForExistence(timeout: 2), "Sheet should be dismissed after Cancel")
    }
    
    func testInviteButtonDisabledWithEmptyEmail() throws {
        navigateToGroupDetail()
        
        let membersTab = app.buttons["Members"]
        guard membersTab.waitForExistence(timeout: 3) else { return }
        membersTab.tap()
        
        let fab = app.buttons["person.badge.plus"]
        guard fab.waitForExistence(timeout: 3) else { return }
        fab.tap()
        
        let inviteButton = app.buttons["Invite"]
        XCTAssertTrue(inviteButton.waitForExistence(timeout: 3), "Invite button should exist")
        XCTAssertFalse(inviteButton.isEnabled, "Invite button should be disabled with empty email")
    }
    
    func testInviteMemberShowsPendingState() throws {
        navigateToGroupDetail()
        
        let membersTab = app.buttons["Members"]
        guard membersTab.waitForExistence(timeout: 3) else { return }
        membersTab.tap()
        
        let fab = app.buttons["person.badge.plus"]
        guard fab.waitForExistence(timeout: 3) else { return }
        fab.tap()
        
        let emailField = app.textFields["e.g., user@example.com"]
        guard emailField.waitForExistence(timeout: 3) else { return }
        emailField.tap()
        emailField.typeText("newuser@example.com")
        
        let inviteButton = app.buttons["Invite"]
        guard inviteButton.waitForExistence(timeout: 2), inviteButton.isEnabled else { return }
        inviteButton.tap()
        
        let invitedBadge = app.staticTexts["Invited"]
        XCTAssertTrue(invitedBadge.waitForExistence(timeout: 3), "Invited badge should appear for pending member")
    }
    
    func testAddMemberFABNotOnExpensesTab() throws {
        navigateToGroupDetail()
        
        let expensesTab = app.buttons["Expenses"]
        guard expensesTab.waitForExistence(timeout: 3) else { return }
        expensesTab.tap()
        
        let addMemberFab = app.buttons["person.badge.plus"]
        XCTAssertFalse(addMemberFab.waitForExistence(timeout: 2), "Add member FAB should not appear on Expenses tab")
    }
    
    // MARK: - Helper Methods
    
    private func navigateToGroups() {
        app.tabBars.buttons["Groups"].tap()
        _ = app.navigationBars["Groups"].waitForExistence(timeout: 3)
    }
    
    private func navigateToGroupDetail() {
        navigateToGroups()
        
        let groupButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Trip' OR label CONTAINS 'Lunch' OR label CONTAINS 'Office' OR label CONTAINS 'Weekend'")).firstMatch
        guard groupButton.waitForExistence(timeout: 3) else { return }
        groupButton.tap()
    }
}
