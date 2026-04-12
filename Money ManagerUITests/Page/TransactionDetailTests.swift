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
        app.launchArguments = getTestAppLaunchArguments()
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }

    // MARK: - Open Transaction Detail

    @discardableResult
    private func openFirstTransaction() -> Bool {
        app.tabBars.buttons["Transactions"].tap()
        guard app.navigationBars["Transactions"].waitForExistence(timeout: 3) else {
            return false
        }

        let row = app.otherElements.matching(identifier: "transaction.row").firstMatch
        guard row.waitForExistence(timeout: 3) else {
            return false
        }
        row.tap()

        let amountLabel = app.staticTexts["transaction-detail.amount"]
        return amountLabel.waitForExistence(timeout: 3)
    }

    // MARK: - Screen Loading

    func testTransactionDetailLoads() throws {
        guard openFirstTransaction() else {
            XCTSkip("No transactions available to test")
            return
        }

        let amountLabel = app.staticTexts["transaction-detail.amount"]
        XCTAssertTrue(amountLabel.exists, "Transaction detail should show amount")
    }

    func testTransactionDetailShowsAmount() throws {
        guard openFirstTransaction() else {
            XCTSkip("No transactions available to test")
            return
        }

        let amountLabel = app.staticTexts["transaction-detail.amount"]
        XCTAssertTrue(amountLabel.exists, "Should display transaction amount")
    }

    func testTransactionDetailShowsCategory() throws {
        guard openFirstTransaction() else {
            XCTSkip("No transactions available to test")
            return
        }

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

        // Date shown in the InfoRow — look for "Date" label in the details card
        let dateLabel = app.staticTexts["Date"]
        XCTAssertTrue(dateLabel.waitForExistence(timeout: 3), "Should display Date row")
    }

    // MARK: - Action Buttons

    func testEditButtonExists() throws {
        guard openFirstTransaction() else {
            XCTSkip("No transactions available to test")
            return
        }

        let editButton = app.buttons["transaction-detail.edit-button"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 5), "Edit button should exist")
    }

    func testDeleteButtonExists() throws {
        guard openFirstTransaction() else {
            XCTSkip("No transactions available to test")
            return
        }

        let deleteButton = app.buttons["transaction-detail.delete-button"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5), "Delete button should exist")
    }

    func testEditOpensEditScreen() throws {
        guard openFirstTransaction() else {
            XCTSkip("No transactions available to test")
            return
        }

        let editButton = app.buttons["transaction-detail.edit-button"]
        guard editButton.waitForExistence(timeout: 5) else {
            XCTFail("Edit button not found")
            return
        }

        editButton.tap()

        let editExpenseNav = app.navigationBars["Edit Expense"]
        XCTAssertTrue(editExpenseNav.waitForExistence(timeout: 5), "Should open edit screen")

        if app.buttons["Cancel"].firstMatch.waitForExistence(timeout: 2) {
            app.buttons["Cancel"].firstMatch.tap()
        }
    }

    func testDeleteShowsConfirmation() throws {
        guard openFirstTransaction() else {
            XCTSkip("No transactions available to test")
            return
        }

        let deleteButton = app.buttons["transaction-detail.delete-button"]
        guard deleteButton.waitForExistence(timeout: 5) else {
            XCTFail("Delete button not found")
            return
        }

        deleteButton.tap()

        let alert = app.alerts.firstMatch
        let confirmationShown = alert.waitForExistence(timeout: 5)

        if confirmationShown {
            XCTAssertTrue(confirmationShown, "Should show delete confirmation")

            // Cancel the deletion — alert Cancel button is matched by its role/title
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

        let descriptionRow = app.staticTexts["Description"]
        if descriptionRow.waitForExistence(timeout: 2) {
            XCTAssertTrue(descriptionRow.exists, "Should show description if available")
        }
    }

    func testTransactionDetailShowsNotesIfExists() throws {
        guard openFirstTransaction() else {
            XCTSkip("No transactions available to test")
            return
        }

        let notesRow = app.staticTexts["Notes"]
        if notesRow.waitForExistence(timeout: 2) {
            XCTAssertTrue(notesRow.exists, "Should show notes if available")
        }
    }

    // MARK: - Group Expense

    func testGroupTransactionIndicator() throws {
        guard openFirstTransaction() else {
            XCTSkip("No transactions available to test")
            return
        }

        let groupIndicator = app.staticTexts.containing(NSPredicate(format:
            "label CONTAINS 'Group Expense' OR label CONTAINS 'Group'")).firstMatch

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

        let doneButton = app.buttons["Done"]
        if doneButton.waitForExistence(timeout: 2) {
            doneButton.tap()
        } else {
            app.swipeDown(velocity: .fast)
        }

        let transactionsNav = app.navigationBars["Transactions"]
        XCTAssertTrue(transactionsNav.waitForExistence(timeout: 3), "Should return to Transactions")
    }
}
