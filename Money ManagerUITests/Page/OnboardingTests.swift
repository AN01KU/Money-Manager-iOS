//
//  OnboardingTests.swift
//  Money Manager UITests
//
//  Tests for Onboarding flow
//

import XCTest

final class OnboardingTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = getTestAppLaunchArguments(true)
        app.launch()

        // resetOnboarding also resets hasSeenLogin, so LoginView appears first.
        // Dismiss it to reach the onboarding screen.
        let skipLogin = app.buttons["Continue without account"]
        if skipLogin.waitForExistence(timeout: 3) {
            skipLogin.tap()
        }
    }
    
    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }
    
    // MARK: - Onboarding Flow Tests
    
    func testOnboardingScreenLoads() throws {
        let onboardingTitle = app.staticTexts["Track Expenses"]
        XCTAssertTrue(onboardingTitle.waitForExistence(timeout: 3), "Onboarding should load")
    }
    
    func testCanNavigateThroughOnboardingPages() throws {
        // Skip button should exist
        let skipButton = app.buttons["Skip onboarding"]
        XCTAssertTrue(skipButton.waitForExistence(timeout: 3), "Skip button should exist")
        
        // Get Started button should not exist on first page
        let getStartedButton = app.buttons["Get started with Money Manager"]
        XCTAssertFalse(getStartedButton.exists, "Get Started should not exist on first page")
        
        // Swipe left to go to next page
        app.swipeLeft()
    }
    
    func testGetStartedCompletesOnboarding() throws {
        // Navigate to last page (Get Started should be visible)
        let getStartedButton = app.buttons["Get started with Money Manager"]

        // Swipe through all 6 pages to get to the last one
        for _ in 0..<6 {
            if getStartedButton.waitForExistence(timeout: 1) {
                break
            }
            app.swipeLeft()
        }

        XCTAssertTrue(getStartedButton.waitForExistence(timeout: 3), "Get Started should be visible on last page")

        // Tap Get Started
        getStartedButton.tap()

        // Should now show main app (Overview tab)
        let overviewNavBar = app.navigationBars["Overview"]
        XCTAssertTrue(overviewNavBar.waitForExistence(timeout: 5), "Should navigate to Overview after onboarding")
    }

    func testGroupsSharingPageExists() throws {
        // Swipe through pages until Groups & Sharing is visible
        let groupsTitle = app.staticTexts["Groups & Sharing"]
        for _ in 0..<6 {
            if groupsTitle.waitForExistence(timeout: 1) { break }
            app.swipeLeft()
        }
        XCTAssertTrue(groupsTitle.waitForExistence(timeout: 3), "Groups & Sharing page should exist in onboarding")
    }
    
    func testSkipButtonCompletesOnboarding() throws {
        let skipButton = app.buttons["Skip onboarding"]
        XCTAssertTrue(skipButton.waitForExistence(timeout: 3), "Skip button should exist")
        
        // Tap skip
        skipButton.tap()
        
        // Should now show main app
        let overviewNavBar = app.navigationBars["Overview"]
        XCTAssertTrue(overviewNavBar.waitForExistence(timeout: 5), "Should navigate to Overview after skipping")
    }
}
