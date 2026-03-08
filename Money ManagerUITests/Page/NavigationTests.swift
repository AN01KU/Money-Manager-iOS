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
    
    // MARK: - Groups tab tests disabled (feature removed for offline-only v1)
    // func testGroupsTabExists() throws { ... }
    // func testSwitchToGroupsTab() throws { ... }
    // func testReturnToOverviewTab() throws { ... }
    // func testTabStatePersists() throws { ... }
    
    func testSettingsTabExists() throws {
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 3), "Settings tab should exist")
    }
    
    func testSwitchToSettingsTab() throws {
        app.tabBars.buttons["Settings"].tap()
        
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3), "Should navigate to Settings")
    }
    
    func testReturnToOverviewTab() throws {
        // Go to Settings
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
        
        // Return to Overview
        app.tabBars.buttons["Overview"].tap()
        XCTAssertTrue(app.navigationBars["Overview"].waitForExistence(timeout: 3), "Should return to Overview")
    }
}
