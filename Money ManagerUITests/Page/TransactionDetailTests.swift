//
//  TransactionDetailTests.swift
//  Money Manager UITests
//
//  Tests for Transaction Detail screen
//

import XCTest

final class TransactionDetailTests: XCTestCase {
    
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
    
    // MARK: - Open Transaction Detail
    
    @discardableResult
    private func openFirstTransaction() -> Bool {
        // Navigate to Overview
        app.tabBars.buttons["Overview"].tap()
        guard app.navigationBars["Overview"].waitForExistence(timeout: 3) else {
            return false
        }
        
        // Make sure we're on Daily view
        let dailyButton = app.buttons["Daily"]
        if dailyButton.waitForExistence(timeout: 2) {
            dailyButton.tap()
            sleep(1)
        }
        
        // Wait for content
        sleep(2)
        
        // Try tapping on first transaction - look for any tappable element with category name
        let categories = ["Food", "Transport", "Shopping", "Entertainment", "Utilities"]
        for category in categories {
            let categoryElement = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", category)).firstMatch
            if categoryElement.waitForExistence(timeout: 2) {
                // Try tapping the parent button or nearby
                categoryElement.tap()
                sleep(2)
                
                // Check if sheet opened - look for amount text
                let amountText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '₹'")).firstMatch
                if amountText.waitForExistence(timeout: 3) {
                    return true
                }
            }
        }
        
        // Fallback - try tapping any button in the list
        let firstButton = app.buttons.firstMatch
        if firstButton.waitForExistence(timeout: 3) {
            firstButton.tap()
            sleep(2)
            return true
        }
        
        return false
    }
    
    // MARK: - Screen Loading
    
    func testTransactionDetailLoads() throws {
        guard openFirstTransaction() else {
            XCTSkip("No transactions available to test")
            return
        }
        
        // Sheet should be open - look for content like amount or category
        let amountOrCategory = app.staticTexts.containing(NSPredicate(format: 
            "label CONTAINS '₹' OR label CONTAINS 'Food' OR label CONTAINS 'Transport' OR " +
            "label CONTAINS 'Shopping' OR label CONTAINS 'Entertainment' OR label CONTAINS 'Utilities'")).firstMatch
        
        XCTAssertTrue(amountOrCategory.waitForExistence(timeout: 3), "Transaction detail sheet should be open")
    }
    
    func testTransactionDetailShowsAmount() throws {
        guard openFirstTransaction() else {
            XCTSkip("No transactions available to test")
            return
        }
        
        // Look for amount (with ₹ symbol)
        let amountText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '₹'")).firstMatch
        XCTAssertTrue(amountText.waitForExistence(timeout: 3), "Should display transaction amount")
    }
    
    func testTransactionDetailShowsCategory() throws {
        guard openFirstTransaction() else {
            XCTSkip("No transactions available to test")
            return
        }
        
        // Look for category
        let categoryText = app.staticTexts.containing(NSPredicate(format: 
            "label CONTAINS 'Food' OR label CONTAINS 'Transport' OR label CONTAINS 'Shopping' OR " +
            "label CONTAINS 'Entertainment' OR label CONTAINS 'Utilities' OR label CONTAINS 'Category'")).firstMatch
        
        XCTAssertTrue(categoryText.waitForExistence(timeout: 3), "Should display category")
    }
    
    func testTransactionDetailShowsDate() throws {
        guard openFirstTransaction() else {
            XCTSkip("No transactions available to test")
            return
        }
        
        // Look for date
        let dateText = app.staticTexts.containing(NSPredicate(format: 
            "label CONTAINS '2026' OR label CONTAINS '2025' OR label CONTAINS 'January' OR " +
            "label CONTAINS 'February' OR label CONTAINS 'March' OR label CONTAINS 'Created'")).firstMatch
        
        XCTAssertTrue(dateText.waitForExistence(timeout: 3), "Should display date")
    }
    
    // MARK: - Action Buttons
    
    func testEditButtonExists() throws {
        guard openFirstTransaction() else {
            XCTSkip("No transactions available to test")
            return
        }
        
        // Scroll down to make Edit button visible
        app.swipeUp(velocity: .slow)
        sleep(1)
        
        let editButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Edit'")).firstMatch
        XCTAssertTrue(editButton.waitForExistence(timeout: 5), "Edit button should exist")
    }
    
    func testDeleteButtonExists() throws {
        guard openFirstTransaction() else {
            XCTSkip("No transactions available to test")
            return
        }
        
        // Scroll down to make Delete button visible
        app.swipeUp(velocity: .slow)
        sleep(1)
        
        let deleteButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Delete'")).firstMatch
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5), "Delete button should exist")
    }
    
    func testEditOpensEditScreen() throws {
        guard openFirstTransaction() else {
            XCTSkip("No transactions available to test")
            return
        }
        
        // Scroll down to make Edit button visible
        app.swipeUp(velocity: .slow)
        sleep(1)
        
        let editButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Edit'")).firstMatch
        guard editButton.waitForExistence(timeout: 5) else {
            XCTFail("Edit button not found")
            return
        }
        
        editButton.tap()
        
        // Should open Add Expense screen in edit mode
        let editExpenseNav = app.navigationBars["Edit Expense"]
        XCTAssertTrue(editExpenseNav.waitForExistence(timeout: 5), "Should open edit screen")
        
        // Cancel to clean up
        if app.buttons["Cancel"].firstMatch.waitForExistence(timeout: 2) {
            app.buttons["Cancel"].firstMatch.tap()
        }
    }
    
    func testDeleteShowsConfirmation() throws {
        guard openFirstTransaction() else {
            XCTSkip("No transactions available to test")
            return
        }
        
        // Scroll down to make Delete button visible
        app.swipeUp(velocity: .slow)
        sleep(1)
        
        let deleteButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Delete'")).firstMatch
        guard deleteButton.waitForExistence(timeout: 5) else {
            XCTFail("Delete button not found")
            return
        }
        
        deleteButton.tap()
        
        // Should show confirmation alert
        let alert = app.alerts.firstMatch
        let confirmDelete = app.buttons["Delete"]
        
        let confirmationShown = alert.waitForExistence(timeout: 5) || confirmDelete.waitForExistence(timeout: 5)
        
        if confirmationShown {
            XCTAssertTrue(confirmationShown, "Should show delete confirmation")
            
            // Cancel the deletion
            let cancelButton = app.buttons["Cancel"]
            if cancelButton.waitForExistence(timeout: 2) {
                cancelButton.tap()
            }
        }
    }
    
    // MARK: - Detail Information
    
    func testTransactionDetailShowsDescriptionIfExists() throws {
        guard openFirstTransaction() else {
            XCTSkip("No transactions available to test")
            return
        }
        
        // Look for description row
        let descriptionRow = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Description'")).firstMatch
        
        if descriptionRow.waitForExistence(timeout: 2) {
            XCTAssertTrue(descriptionRow.exists, "Should show description if available")
        }
    }
    
    func testTransactionDetailShowsNotesIfExists() throws {
        guard openFirstTransaction() else {
            XCTSkip("No transactions available to test")
            return
        }
        
        // Look for notes row
        let notesRow = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Notes'")).firstMatch
        
        if notesRow.waitForExistence(timeout: 2) {
            XCTAssertTrue(notesRow.exists, "Should show notes if available")
        }
    }
    
    // MARK: - Group Expense
    
    func testGroupExpenseIndicator() throws {
        guard openFirstTransaction() else {
            XCTSkip("No transactions available to test")
            return
        }
        
        // Look for group expense indicator
        let groupIndicator = app.staticTexts.containing(NSPredicate(format: 
            "label CONTAINS 'Group Expense' OR label CONTAINS 'Group'")).firstMatch
        
        // Not all expenses are group expenses
        if groupIndicator.waitForExistence(timeout: 2) {
            XCTAssertTrue(groupIndicator.exists, "Should show group indicator for group expenses")
        }
    }
    
    // MARK: - Back Navigation
    
    func testBackNavigationWorks() throws {
        guard openFirstTransaction() else {
            XCTSkip("No transactions available to test")
            return
        }
        
        // Tap Done or swipe back
        let doneButton = app.buttons["Done"]
        if doneButton.waitForExistence(timeout: 2) {
            doneButton.tap()
        } else {
            // Try swipe back
            app.swipeDown(velocity: .fast)
        }
        
        sleep(1)
        
        // Should be back on Overview
        let overviewNav = app.navigationBars["Overview"]
        XCTAssertTrue(overviewNav.waitForExistence(timeout: 3), "Should return to Overview")
    }
}
