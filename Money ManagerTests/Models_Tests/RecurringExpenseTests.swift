import Foundation
import SwiftData
import Testing
@testable import Money_Manager

struct RecurringExpenseModelTests {
    
    @Test
    func testExpenseHasRequiredProperties() {
        let expense = Expense(
            amount: 649,
            category: "Entertainment",
            date: Date(),
            expenseDescription: "Netflix"
        )
        
        #expect(expense.amount == 649)
        #expect(expense.category == "Entertainment")
        #expect(expense.expenseDescription == "Netflix")
    }
    
    @Test
    func testExpenseDefaultValues() {
        let expense = Expense(
            amount: 5000,
            category: "Debt & Payments",
            date: Date()
        )
        
        #expect(expense.id != nil)
        #expect(expense.createdAt != nil)
        #expect(expense.updatedAt != nil)
        #expect(expense.isDeleted == false)
        #expect(expense.time == nil)
        #expect(expense.notes == nil)
        #expect(expense.recurringExpenseId == nil)
        #expect(expense.groupId == nil)
        #expect(expense.groupName == nil)
    }
    
    @Test
    func testExpenseWithGroupData() {
        let groupId = UUID()
        
        let expense = Expense(
            amount: 999,
            category: "Utilities",
            date: Date(),
            expenseDescription: "Subscription",
            groupId: groupId,
            groupName: "Roommates"
        )
        
        #expect(expense.groupId == groupId)
        #expect(expense.groupName == "Roommates")
    }
    
    @Test
    func testExpenseWithRecurringExpenseId() {
        let recurringId = UUID()
        
        let expense = Expense(
            amount: 15000,
            category: "Housing",
            date: Date(),
            expenseDescription: "Rent",
            recurringExpenseId: recurringId
        )
        
        #expect(expense.recurringExpenseId == recurringId)
    }
    
    @Test
    func testExpenseWithNegativeAmount() {
        let expense = Expense(
            amount: -100,
            category: "Other",
            date: Date(),
            notes: "Refund"
        )
        
        #expect(expense.amount == -100)
        #expect(expense.notes == "Refund")
    }
    
    @Test
    func testExpenseWithZeroAmount() {
        let expense = Expense(
            amount: 0,
            category: "Entertainment",
            date: Date(),
            expenseDescription: "Free Trial"
        )
        
        #expect(expense.amount == 0)
    }
    
    @Test
    func testExpenseWithAllOptionalFields() {
        let expenseTime = Date()
        let groupId = UUID()
        let recurringId = UUID()
        
        let expense = Expense(
            amount: 100,
            category: "Other",
            date: Date(),
            time: expenseTime,
            expenseDescription: "Test",
            notes: "Test notes",
            recurringExpenseId: recurringId,
            groupId: groupId,
            groupName: "Test Group"
        )
        
        #expect(expense.time == expenseTime)
        #expect(expense.expenseDescription == "Test")
        #expect(expense.notes == "Test notes")
        #expect(expense.recurringExpenseId == recurringId)
        #expect(expense.groupId == groupId)
        #expect(expense.groupName == "Test Group")
    }
    
    @Test
    func testExpenseCanBeMarkedAsDeleted() {
        let expense = Expense(
            amount: 100,
            category: "Other",
            date: Date()
        )
        
        #expect(expense.isDeleted == false)
        expense.isDeleted = true
        #expect(expense.isDeleted == true)
    }
}
