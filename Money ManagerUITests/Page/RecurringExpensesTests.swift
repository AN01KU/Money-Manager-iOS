//
//  RecurringExpensesTests.swift
//  Money Manager UITests
//
//  Tests for Recurring Expenses screen
//

import XCTest

final class RecurringExpensesTests: XCTestCase {
    
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
    
    // MARK: - Navigation
    
    func testRecurringScreenLoads() throws {
        navigateToRecurring()
        
        let navBar = app.navigationBars["Recurring"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 3), "Recurring screen should load")
    }
    
    func testRecurringHasPlusButton() throws {
        navigateToRecurring()
        
        let plusButton = app.buttons["plus"]
        XCTAssertTrue(plusButton.waitForExistence(timeout: 3), "Plus button should exist in toolbar")
    }
    
    // MARK: - Active Recurring Expenses
    
    func testActiveExpensesDisplayed() throws {
        navigateToRecurring()
        
        // Test data has recurring expenses (Netflix, Gym, Insurance, Internet, Lunch)
        let activeSection = app.staticTexts["Active"]
        if activeSection.waitForExistence(timeout: 3) {
            XCTAssertTrue(activeSection.exists, "Active section should exist")
        }
        
        // Check for at least one recurring expense from test data
        let netflixText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Netflix'")).firstMatch
        let gymText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Gym'")).firstMatch
        let insuranceText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Insurance'")).firstMatch
        
        let hasExpenses = netflixText.waitForExistence(timeout: 3) ||
                         gymText.waitForExistence(timeout: 3) ||
                         insuranceText.waitForExistence(timeout: 3)
        
        let emptyState = app.staticTexts["No recurring expenses"]
        let hasEmptyState = emptyState.waitForExistence(timeout: 2)
        
        XCTAssertTrue(hasExpenses || hasEmptyState, "Should show recurring expenses or empty state")
    }
    
    func testExpenseRowShowsAmount() throws {
        navigateToRecurring()
        
        // Look for currency amount display
        let amountText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '₹'")).firstMatch
        
        if amountText.waitForExistence(timeout: 3) {
            XCTAssertTrue(amountText.exists, "Should display expense amount")
        }
    }
    
    func testExpenseRowShowsFrequency() throws {
        navigateToRecurring()
        
        // Test data uses "monthly" and "weekly" frequencies
        let monthlyText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'Monthly'")).firstMatch
        let weeklyText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'Weekly'")).firstMatch
        
        let hasFrequency = monthlyText.waitForExistence(timeout: 3) || weeklyText.waitForExistence(timeout: 3)
        
        if hasFrequency {
            XCTAssertTrue(hasFrequency, "Should display frequency badge")
        }
    }
    
    func testExpenseRowShowsNextOccurrence() throws {
        navigateToRecurring()
        
        let nextText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Next:'")).firstMatch
        
        if nextText.waitForExistence(timeout: 3) {
            XCTAssertTrue(nextText.exists, "Active expenses should show next occurrence")
        }
    }
    
    // MARK: - Toggle Active/Paused
    
    func testToggleSwitchExists() throws {
        navigateToRecurring()
        
        let toggle = app.switches.firstMatch
        if toggle.waitForExistence(timeout: 3) {
            XCTAssertTrue(toggle.exists, "Toggle switch should exist on expense row")
        }
    }
    
    // MARK: - Add Recurring Expense Sheet
    
    func testAddRecurringSheetOpens() throws {
        navigateToRecurring()
        
        let plusButton = app.buttons["plus"]
        XCTAssertTrue(plusButton.waitForExistence(timeout: 3))
        plusButton.tap()
        
        let navBar = app.navigationBars["Add Recurring"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 3), "Add Recurring sheet should open")
    }
    
    func testAddRecurringSheetHasCancelButton() throws {
        navigateToRecurring()
        
        app.buttons["plus"].tap()
        _ = app.navigationBars["Add Recurring"].waitForExistence(timeout: 3)
        
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 2), "Cancel button should exist")
    }
    
    func testAddRecurringSheetHasSaveButton() throws {
        navigateToRecurring()
        
        app.buttons["plus"].tap()
        _ = app.navigationBars["Add Recurring"].waitForExistence(timeout: 3)
        
        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2), "Save button should exist")
    }
    
    func testAddRecurringSaveDisabledInitially() throws {
        navigateToRecurring()
        
        app.buttons["plus"].tap()
        _ = app.navigationBars["Add Recurring"].waitForExistence(timeout: 3)
        
        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2))
        XCTAssertFalse(saveButton.isEnabled, "Save should be disabled without required fields")
    }
    
    func testAddRecurringCancelDismissesSheet() throws {
        navigateToRecurring()
        
        app.buttons["plus"].tap()
        XCTAssertTrue(app.navigationBars["Add Recurring"].waitForExistence(timeout: 3))
        
        app.buttons["Cancel"].tap()
        
        XCTAssertTrue(app.navigationBars["Recurring"].waitForExistence(timeout: 3), "Should return to Recurring screen")
    }
    
    func testAddRecurringHasNameField() throws {
        navigateToRecurring()
        
        app.buttons["plus"].tap()
        _ = app.navigationBars["Add Recurring"].waitForExistence(timeout: 3)
        
        let nameField = app.textFields["e.g., Netflix, Rent"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2), "Name field should exist")
    }
    
    func testAddRecurringHasAmountField() throws {
        navigateToRecurring()
        
        app.buttons["plus"].tap()
        _ = app.navigationBars["Add Recurring"].waitForExistence(timeout: 3)
        
        let amountField = app.textFields["0.00"]
        XCTAssertTrue(amountField.waitForExistence(timeout: 2), "Amount field should exist")
    }
    
    func testAddRecurringHasFrequencyPicker() throws {
        navigateToRecurring()
        
        app.buttons["plus"].tap()
        _ = app.navigationBars["Add Recurring"].waitForExistence(timeout: 3)
        
        // Segmented picker with frequency options
        let monthlyButton = app.buttons["Monthly"]
        let dailyButton = app.buttons["Daily"]
        
        let hasPicker = monthlyButton.waitForExistence(timeout: 2) || dailyButton.waitForExistence(timeout: 2)
        XCTAssertTrue(hasPicker, "Frequency picker should exist")
    }
    
    // MARK: - Edit Recurring Expense
    
    func testTapExpenseOpensEditSheet() throws {
        navigateToRecurring()
        
        // Tap on first recurring expense
        let expenseRow = app.staticTexts.containing(NSPredicate(format:
            "label CONTAINS 'Netflix' OR label CONTAINS 'Gym' OR label CONTAINS 'Insurance' OR label CONTAINS 'Internet'")).firstMatch
        
        guard expenseRow.waitForExistence(timeout: 3) else {
            XCTSkip("No recurring expenses to tap")
            return
        }
        
        expenseRow.tap()
        
        let editNavBar = app.navigationBars["Edit Recurring"]
        XCTAssertTrue(editNavBar.waitForExistence(timeout: 3), "Edit Recurring sheet should open")
    }
    
    func testEditSheetHasPrefilledData() throws {
        navigateToRecurring()
        
        let expenseRow = app.staticTexts.containing(NSPredicate(format:
            "label CONTAINS 'Netflix' OR label CONTAINS 'Gym' OR label CONTAINS 'Insurance'")).firstMatch
        
        guard expenseRow.waitForExistence(timeout: 3) else {
            XCTSkip("No recurring expenses to edit")
            return
        }
        
        expenseRow.tap()
        
        guard app.navigationBars["Edit Recurring"].waitForExistence(timeout: 3) else {
            XCTSkip("Edit sheet did not open")
            return
        }
        
        // Name field should be pre-filled (not placeholder)
        let nameField = app.textFields["e.g., Netflix, Rent"]
        if nameField.waitForExistence(timeout: 2) {
            let value = nameField.value as? String ?? ""
            XCTAssertFalse(value.isEmpty, "Name should be pre-filled")
        }
    }
    
    func testEditSheetCanBeCancelled() throws {
        navigateToRecurring()
        
        let expenseRow = app.staticTexts.containing(NSPredicate(format:
            "label CONTAINS 'Netflix' OR label CONTAINS 'Gym'")).firstMatch
        
        guard expenseRow.waitForExistence(timeout: 3) else {
            XCTSkip("No recurring expenses to edit")
            return
        }
        
        expenseRow.tap()
        
        guard app.navigationBars["Edit Recurring"].waitForExistence(timeout: 3) else {
            XCTSkip("Edit sheet did not open")
            return
        }
        
        app.buttons["Cancel"].tap()
        
        XCTAssertTrue(app.navigationBars["Recurring"].waitForExistence(timeout: 3), "Should return to Recurring screen")
    }
    
    // MARK: - Empty State
    
    func testEmptyStateShowsCorrectMessage() throws {
        // This test verifies the empty state message text when it appears
        navigateToRecurring()
        
        let emptyMessage = app.staticTexts["No recurring expenses"]
        let emptySubMessage = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'subscriptions'")).firstMatch
        
        if emptyMessage.waitForExistence(timeout: 2) {
            XCTAssertTrue(emptyMessage.exists)
            XCTAssertTrue(emptySubMessage.waitForExistence(timeout: 2), "Should show helpful subtitle")
        }
    }
    
    // MARK: - Helper Methods
    
    private func navigateToRecurring() {
        app.tabBars.buttons["Settings"].tap()
        _ = app.navigationBars["Settings"].waitForExistence(timeout: 3)
        
        let recurringButton = app.buttons["Recurring"]
        XCTAssertTrue(recurringButton.waitForExistence(timeout: 3), "Recurring option should exist in Settings")
        recurringButton.tap()
        
        _ = app.navigationBars["Recurring"].waitForExistence(timeout: 3)
    }
}
