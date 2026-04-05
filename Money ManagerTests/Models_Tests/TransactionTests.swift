import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct TransactionModelTests {

    @Test
    func testTransactionAmountCanBeZero() {
        let expense = Transaction(amount: 0, category: "Other", date: Date())
        #expect(expense.amount == 0)
    }

    @Test
    func testTransactionAmountCanBeNegative() {
        let expense = Transaction(amount: -50, category: "Other", date: Date(), notes: "Refund")
        #expect(expense.amount == -50)
        #expect(expense.notes == "Refund")
    }

    @Test
    func testTransactionCanBeMarkedAsDeleted() {
        let expense = Transaction(amount: 100, category: "Other", date: Date())
        #expect(expense.isSoftDeleted == false)
        expense.isSoftDeleted = true
        #expect(expense.isSoftDeleted == true)
    }

    @Test
    func testTransactionDefaultTypeIsExpense() {
        let expense = Transaction(amount: 100, category: "Food & Dining", date: Date())
        #expect(expense.type == .expense)
    }

    @Test
    func testIncomeType() {
        let income = Transaction(type: .income, amount: 5000, category: "Work & Professional", date: Date())
        #expect(income.type == .income)
    }
}
