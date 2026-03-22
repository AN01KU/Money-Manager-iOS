import Foundation
import SwiftData
import Testing
@testable import Money_Manager

struct RecurringExpenseModelTests {
    
    // MARK: - Initialization
    
    @Test
    func initSetsRequiredProperties() {
        let expense = RecurringExpense(
            name: "Netflix",
            amount: 649,
            category: "Entertainment",
            frequency: "monthly"
        )
        
        #expect(expense.name == "Netflix")
        #expect(expense.amount == 649)
        #expect(expense.category == "Entertainment")
        #expect(expense.frequency == "monthly")
    }
    
    @Test
    func initSetsDefaults() {
        let expense = RecurringExpense(
            name: "Test",
            amount: 100,
            category: "Other",
            frequency: "daily"
        )
        
        #expect(expense.isActive == true)
        #expect(expense.dayOfMonth == nil)
        #expect(expense.daysOfWeek == nil)
        #expect(expense.endDate == nil)
        #expect(expense.lastAddedDate == nil)
        #expect(expense.notes == nil)
    }
    
    @Test
    func initSetsAllOptionalParameters() {
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .year, value: 1, to: startDate)!
        let lastAdded = Calendar.current.date(byAdding: .day, value: -5, to: startDate)!
        
        let expense = RecurringExpense(
            name: "Gym",
            amount: 500,
            category: "Health",
            frequency: "weekly",
            dayOfMonth: 15,
            daysOfWeek: [1, 3, 5],
            startDate: startDate,
            endDate: endDate,
            isActive: false,
            lastAddedDate: lastAdded,
            notes: "Monthly gym membership"
        )
        
        #expect(expense.dayOfMonth == 15)
        #expect(expense.daysOfWeek == [1, 3, 5])
        #expect(expense.startDate == startDate)
        #expect(expense.endDate == endDate)
        #expect(expense.isActive == false)
        #expect(expense.lastAddedDate == lastAdded)
        #expect(expense.notes == "Monthly gym membership")
    }
    
    @Test
    func initGeneratesUniqueIds() {
        let expense1 = RecurringExpense(name: "A", amount: 100, category: "Other", frequency: "daily")
        let expense2 = RecurringExpense(name: "B", amount: 200, category: "Other", frequency: "daily")
        
        #expect(expense1.id != expense2.id)
    }
    
    @Test
    func initSetsTimestamps() {
        let expense = RecurringExpense(name: "Test", amount: 100, category: "Other", frequency: "daily")
        
        #expect(expense.createdAt <= Date())
        #expect(expense.updatedAt <= Date())
    }
    
    // MARK: - Mutability
    
    @Test
    func isActiveCanBeToggled() {
        let expense = RecurringExpense(name: "Test", amount: 100, category: "Other", frequency: "daily")
        
        #expect(expense.isActive == true)
        expense.isActive = false
        #expect(expense.isActive == false)
    }
}
