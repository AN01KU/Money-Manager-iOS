//
//  NavigationTests.swift
//  Money Manager UITests
//
//  Tests for app navigation and tab switching
//

import XCTest

final class NavigationTests: XCTestCase {
    
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
    
    // MARK: - Tab Bar Navigation
    
    func testOverviewTabExists() throws {
        let overviewTab = app.tabBars.buttons["Overview"]
        XCTAssertTrue(overviewTab.waitForExistence(timeout: 3), "Overview tab should exist")
    }
    
    func testGroupsTabExists() throws {
        let groupsTab = app.tabBars.buttons["Groups"]
        XCTAssertTrue(groupsTab.waitForExistence(timeout: 3), "Groups tab should exist")
    }
    
    func testSettingsTabExists() throws {
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 3), "Settings tab should exist")
    }
    
    func testSwitchToGroupsTab() throws {
        app.tabBars.buttons["Groups"].tap()
        
        XCTAssertTrue(app.navigationBars["Groups"].waitForExistence(timeout: 3), "Should navigate to Groups")
    }
    
    func testSwitchToSettingsTab() throws {
        app.tabBars.buttons["Settings"].tap()
        
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3), "Should navigate to Settings")
    }
    
    func testReturnToOverviewTab() throws {
        // Go to Groups
        app.tabBars.buttons["Groups"].tap()
        XCTAssertTrue(app.navigationBars["Groups"].waitForExistence(timeout: 3))
        
        // Return to Overview
        app.tabBars.buttons["Overview"].tap()
        XCTAssertTrue(app.navigationBars["Overview"].waitForExistence(timeout: 3), "Should return to Overview")
    }
    
    // MARK: - Tab Bar Persistence
    
    func testTabStatePersists() throws {
        // Go to Groups
        app.tabBars.buttons["Groups"].tap()
        sleep(1)
        
        // Go to Settings
        app.tabBars.buttons["Settings"].tap()
        sleep(1)
        
        // Back to Groups
        app.tabBars.buttons["Groups"].tap()
        sleep(1)
        
        // Verify we're on Groups
        XCTAssertTrue(app.navigationBars["Groups"].waitForExistence(timeout: 3), "Groups should still be accessible")
    }
}
