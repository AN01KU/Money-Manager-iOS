import Foundation
import SwiftData
import Testing
@testable import Money_Manager

struct RecurringExpenseModelTests {
    
    @Test
    func testRecurringExpenseDefaultsIsActiveToTrue() {
        let expense = Expense(
            amount: 649,
            category: "Entertainment",
            date: Date(),
            expenseDescription: "Netflix",
            isRecurring: true,
            frequency: "monthly"
        )
        
        #expect(expense.isActive == true)
    }
    
    @Test
    func testRecurringExpenseEndDateIsNilWhenNotProvided() {
        let expense = Expense(
            amount: 5000,
            category: "Debt & Payments",
            date: Date(),
            expenseDescription: "Insurance",
            isRecurring: true,
            frequency: "monthly"
        )
        
        #expect(expense.recurringEndDate == nil)
    }
    
    @Test
    func testRecurringExpenseEndDateIsStoredWhenProvided() {
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .year, value: 1, to: startDate)!
        
        let expense = Expense(
            amount: 999,
            category: "Utilities",
            date: startDate,
            expenseDescription: "Subscription",
            isRecurring: true,
            frequency: "monthly",
            recurringEndDate: endDate
        )
        
        #expect(expense.recurringEndDate == endDate)
    }
    
    @Test
    func testRecurringExpenseDayOfMonthBoundaryValues() {
        let expense1 = Expense(
            amount: 15000,
            category: "Housing",
            date: Date(),
            expenseDescription: "Rent",
            isRecurring: true,
            frequency: "monthly",
            dayOfMonth: 1
        )
        
        let expense2 = Expense(
            amount: 5000,
            category: "Debt & Payments",
            date: Date(),
            expenseDescription: "Credit Card",
            isRecurring: true,
            frequency: "monthly",
            dayOfMonth: 28
        )
        
        #expect(expense1.dayOfMonth == 1)
        #expect(expense2.dayOfMonth == 28)
    }
    
    @Test
    func testRecurringExpenseWithNegativeAmount() {
        let expense = Expense(
            amount: -100,
            category: "Other",
            date: Date(),
            expenseDescription: "Refund",
            isRecurring: true,
            frequency: "monthly"
        )
        
        #expect(expense.amount == -100)
    }
    
    @Test
    func testRecurringExpenseWithZeroAmount() {
        let expense = Expense(
            amount: 0,
            category: "Entertainment",
            date: Date(),
            expenseDescription: "Free Trial",
            isRecurring: true,
            frequency: "monthly"
        )
        
        #expect(expense.amount == 0)
    }
    
    @Test
    func testRecurringExpenseSupportsDifferentFrequencies() {
        let frequencies = ["daily", "weekly", "monthly", "yearly"]
        
        for frequency in frequencies {
            let expense = Expense(
                amount: 100,
                category: "Other",
                date: Date(),
                expenseDescription: "Test \(frequency)",
                isRecurring: true,
                frequency: frequency
            )
            #expect(expense.frequency == frequency)
        }
    }
}
