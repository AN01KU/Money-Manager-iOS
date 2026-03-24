import Foundation
import SwiftData
import Testing
@testable import Money_Manager

struct ExpenseModelTests {

    @Test
    func testExpenseAmountCanBeZero() {
        let expense = Expense(amount: 0, category: "Other", date: Date())
        #expect(expense.amount == 0)
    }

    @Test
    func testExpenseAmountCanBeNegative() {
        let expense = Expense(amount: -50, category: "Other", date: Date(), notes: "Refund")
        #expect(expense.amount == -50)
        #expect(expense.notes == "Refund")
    }

    @Test
    func testExpenseCanBeMarkedAsDeleted() {
        let expense = Expense(amount: 100, category: "Other", date: Date())
        #expect(expense.isDeleted == false)
        expense.isDeleted = true
        #expect(expense.isDeleted == true)
    }
}
