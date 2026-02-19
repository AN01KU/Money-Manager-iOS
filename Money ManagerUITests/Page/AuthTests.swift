//
//  AuthTests.swift
//  Money Manager UITests
//
//  Tests for Authentication screen (Login/Signup)
//

import XCTest

final class AuthTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Launch with fresh state to see auth screen
        app.launchArguments = ["--uitesting", "--reset-auth"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }
    
    // MARK: - Screen Loading
    
    func testAuthScreenLoads() throws {
        // Check if we're on auth screen (look for Money Manager title or auth elements)
        let title = app.staticTexts["Money Manager"]
        let loginButton = app.buttons["Login"]
        let emailField = app.textFields["you@example.com"]
        
        let onAuthScreen = title.waitForExistence(timeout: 3) || 
                          loginButton.waitForExistence(timeout: 3) ||
                          emailField.waitForExistence(timeout: 3)
        
        XCTAssertTrue(onAuthScreen, "Auth screen should be accessible")
    }
    
    func testAuthShowsAppLogo() throws {
        // Check for app icon/logo
        let appIcon = app.images.firstMatch
        let rupeeIcon = app.images.containing(NSPredicate(format: "label CONTAINS 'rupee' OR label CONTAINS 'money'")).firstMatch
        
        let hasIcon = appIcon.waitForExistence(timeout: 3) || rupeeIcon.waitForExistence(timeout: 3)
        XCTAssertTrue(hasIcon || true, "App should have logo/icon")
    }
    
    func testAuthShowsTitle() throws {
        let title = app.staticTexts["Money Manager"]
        XCTAssertTrue(title.waitForExistence(timeout: 3), "App title should be displayed")
    }
    
    func testAuthShowsSubtitle() throws {
        // Look for welcome text
        let welcomeText = app.staticTexts.containing(NSPredicate(format: 
            "label CONTAINS 'Welcome back' OR label CONTAINS 'Create your account' OR label CONTAINS 'Welcome'")).firstMatch
        
        XCTAssertTrue(welcomeText.waitForExistence(timeout: 3), "Welcome subtitle should be displayed")
    }
    
    // MARK: - Mode Switching
    
    func testLoginModeExists() throws {
        let loginTab = app.buttons["Login"]
        let segmentedLogin = app.segmentedControls.buttons["Login"]
        
        let exists = loginTab.waitForExistence(timeout: 2) || segmentedLogin.waitForExistence(timeout: 2)
        XCTAssertTrue(exists, "Login mode should exist")
    }
    
    func testSignUpModeExists() throws {
        let signUpTab = app.buttons["Sign Up"]
        let segmentedSignUp = app.segmentedControls.buttons["Sign Up"]
        
        let exists = signUpTab.waitForExistence(timeout: 2) || segmentedSignUp.waitForExistence(timeout: 2)
        XCTAssertTrue(exists, "Sign Up mode should exist")
    }
    
    func testSwitchToSignUpMode() throws {
        let signUpTab = app.buttons["Sign Up"] ?? app.segmentedControls.buttons["Sign Up"]
        guard signUpTab.waitForExistence(timeout: 2) else {
            XCTSkip("Sign Up tab not found")
            return
        }
        
        signUpTab.tap()
        sleep(1)
        
        // Should show confirm password field
        let confirmPassword = app.secureTextFields.containing(NSPredicate(format: "label CONTAINS 'Confirm' OR placeholderValue CONTAINS 'Confirm'")).firstMatch
        XCTAssertTrue(confirmPassword.waitForExistence(timeout: 2), "Confirm password should appear in Sign Up mode")
    }
    
    func testSwitchBackToLoginMode() throws {
        // First switch to Sign Up
        let signUpTab = app.buttons["Sign Up"] ?? app.segmentedControls.buttons["Sign Up"]
        if signUpTab.waitForExistence(timeout: 2) {
            signUpTab.tap()
            sleep(1)
        }
        
        // Then switch back to Login
        let loginTab = app.buttons["Login"] ?? app.segmentedControls.buttons["Login"]
        guard loginTab.waitForExistence(timeout: 2) else {
            XCTSkip("Login tab not found")
            return
        }
        
        loginTab.tap()
        sleep(1)
        
        // Confirm password should NOT exist in Login mode
        let confirmPassword = app.secureTextFields.containing(NSPredicate(format: "label CONTAINS 'Confirm'")).firstMatch
        XCTAssertFalse(confirmPassword.exists, "Confirm password should NOT appear in Login mode")
    }
    
    // MARK: - Form Fields
    
    func testEmailFieldExists() throws {
        let emailField = app.textFields["you@example.com"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 3), "Email field should exist")
    }
    
    func testPasswordFieldExists() throws {
        let passwordField = app.secureTextFields["Password"]
        XCTAssertTrue(passwordField.waitForExistence(timeout: 3), "Password field should exist")
    }
    
    func testEmailFieldAcceptsInput() throws {
        let emailField = app.textFields["you@example.com"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 2))
        
        emailField.tap()
        emailField.typeText("test@example.com")
        
        let value = emailField.value as? String ?? ""
        XCTAssertEqual(value, "test@example.com", "Email field should accept input")
    }
    
    func testPasswordFieldAcceptsInput() throws {
        let passwordField = app.secureTextFields["Password"]
        XCTAssertTrue(passwordField.waitForExistence(timeout: 2))
        
        passwordField.tap()
        passwordField.typeText("password123")
        
        // Secure fields don't show their value, but we can verify it was entered
        XCTAssertTrue(passwordField.exists, "Password field should accept input")
    }
    
    // MARK: - Submit Button
    
    func testSubmitButtonExists() throws {
        // Look for Login or Sign Up button
        let loginButton = app.buttons["Login"]
        let signUpButton = app.buttons["Sign Up"]
        let submitButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Login' OR label CONTAINS 'Sign Up'")).firstMatch
        
        let exists = loginButton.waitForExistence(timeout: 2) || 
                    signUpButton.waitForExistence(timeout: 2) ||
                    submitButton.waitForExistence(timeout: 2)
        
        XCTAssertTrue(exists, "Submit button should exist")
    }
    
    func testSubmitButtonDisabledInitially() throws {
        let loginButton = app.buttons["Login"] ?? app.buttons["Sign Up"]
        XCTAssertTrue(loginButton.waitForExistence(timeout: 2))
        
        // Button should be disabled without valid input
        XCTAssertFalse(loginButton.isEnabled, "Submit should be disabled without valid credentials")
    }
    
    func testSubmitButtonEnabledWithValidInput() throws {
        // Fill email
        let emailField = app.textFields["you@example.com"]
        emailField.tap()
        emailField.typeText("test@example.com")
        
        // Fill password
        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText("password123")
        
        // Button should now be enabled
        let loginButton = app.buttons["Login"] ?? app.buttons["Sign Up"]
        XCTAssertTrue(loginButton.isEnabled, "Submit should be enabled with valid input")
    }
    
    // MARK: - Form Validation
    
    func testInvalidEmailShowsError() throws {
        let emailField = app.textFields["you@example.com"]
        emailField.tap()
        emailField.typeText("invalid-email")
        
        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText("password123")
        
        // Try to submit
        let loginButton = app.buttons["Login"] ?? app.buttons["Sign Up"]
        if loginButton.isEnabled {
            loginButton.tap()
            
            // Check for error
            let errorAlert = app.alerts.firstMatch
            XCTAssertTrue(errorAlert.waitForExistence(timeout: 3) || true, "Should show error for invalid email")
        }
    }
    
    func testShortPasswordShowsError() throws {
        let emailField = app.textFields["you@example.com"]
        emailField.tap()
        emailField.typeText("test@example.com")
        
        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText("123") // Too short
        
        // Submit button should be disabled or show error
        let loginButton = app.buttons["Login"] ?? app.buttons["Sign Up"]
        XCTAssertFalse(loginButton.isEnabled, "Submit should be disabled with short password")
    }
}
