import Foundation
import SwiftData
import Testing
@testable import Money_Manager

struct RecurringExpenseModelTests {
    
    @Test
    func testRecurringExpenseDefaultsIsActiveToTrue() {
        let expense = RecurringExpense(
            name: "Netflix",
            amount: 649,
            category: "Entertainment",
            frequency: "monthly",
            startDate: Date()
        )
        
        #expect(expense.isActive == true)
    }
    
    @Test
    func testRecurringExpenseDefaultsSkipWeekendsToFalse() {
        let expense = RecurringExpense(
            name: "Gym",
            amount: 500,
            category: "Health & Medical",
            frequency: "monthly",
            startDate: Date()
        )
        
        #expect(expense.skipWeekends == false)
    }
    
    @Test
    func testRecurringExpenseEndDateIsNilWhenNotProvided() {
        let expense = RecurringExpense(
            name: "Insurance",
            amount: 5000,
            category: "Debt & Payments",
            frequency: "monthly",
            startDate: Date()
        )
        
        #expect(expense.endDate == nil)
    }
    
    @Test
    func testRecurringExpenseEndDateIsStoredWhenProvided() {
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .year, value: 1, to: startDate)!
        
        let expense = RecurringExpense(
            name: "Subscription",
            amount: 999,
            category: "Utilities",
            frequency: "monthly",
            startDate: startDate,
            endDate: endDate
        )
        
        #expect(expense.endDate == endDate)
    }
    
    @Test
    func testRecurringExpenseDayOfMonthBoundaryValues() {
        let expense1 = RecurringExpense(
            name: "Rent",
            amount: 15000,
            category: "Housing",
            frequency: "monthly",
            startDate: Date(),
            dayOfMonth: 1
        )
        
        let expense2 = RecurringExpense(
            name: "Credit Card",
            amount: 5000,
            category: "Debt & Payments",
            frequency: "monthly",
            startDate: Date(),
            dayOfMonth: 31
        )
        
        #expect(expense1.dayOfMonth == 1)
        #expect(expense2.dayOfMonth == 31)
    }
    
    @Test
    func testRecurringExpenseDayOfWeekStoredCorrectly() {
        let expense = RecurringExpense(
            name: "Weekly Lunch",
            amount: 500,
            category: "Food & Dining",
            frequency: "weekly",
            startDate: Date(),
            dayOfWeek: [1, 3, 5]
        )
        
        #expect(expense.dayOfWeek == [1, 3, 5])
    }
    
    @Test
    func testRecurringExpenseWithNegativeAmount() {
        let expense = RecurringExpense(
            name: "Refund",
            amount: -100,
            category: "Other",
            frequency: "monthly",
            startDate: Date()
        )
        
        #expect(expense.amount == -100)
    }
    
    @Test
    func testRecurringExpenseWithZeroAmount() {
        let expense = RecurringExpense(
            name: "Free Trial",
            amount: 0,
            category: "Entertainment",
            frequency: "monthly",
            startDate: Date()
        )
        
        #expect(expense.amount == 0)
    }
    
    @Test
    func testRecurringExpenseLastGeneratedDateIsNilInitially() {
        let expense = RecurringExpense(
            name: "Test",
            amount: 100,
            category: "Other",
            frequency: "monthly",
            startDate: Date()
        )
        
        #expect(expense.lastGeneratedDate == nil)
    }
    
    @Test
    func testRecurringExpenseSupportsDifferentFrequencies() {
        let frequencies = ["daily", "weekly", "monthly", "yearly", "custom"]
        
        for frequency in frequencies {
            let expense = RecurringExpense(
                name: "Test \(frequency)",
                amount: 100,
                category: "Other",
                frequency: frequency,
                startDate: Date()
            )
            #expect(expense.frequency == frequency)
        }
    }
}
