import Foundation
import SwiftData
import Testing
@testable import Money_Manager

struct RecurringExpenseModelTests {

    @Test
    func isActiveCanBeToggled() {
        let expense = RecurringExpense(name: "Test", amount: 100, category: "Other", frequency: "daily")
        #expect(expense.isActive == true)
        expense.isActive = false
        #expect(expense.isActive == false)
    }
}
