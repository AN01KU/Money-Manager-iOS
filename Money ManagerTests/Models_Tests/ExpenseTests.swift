import Foundation
import SwiftData
import Testing
@testable import Money_Manager

struct ExpenseModelTests {
    
    @Test
    func testExpenseHasRequiredProperties() {
        let expense = Expense(
            amount: 500,
            category: "Food & Dining",
            date: Date()
        )
        
        #expect(expense.amount == 500)
        #expect(expense.category == "Food & Dining")
    }
    
    @Test
    func testExpenseDefaultValuesOnInit() {
        let expense = Expense(
            amount: 100,
            category: "Transport",
            date: Date()
        )
        
        #expect(expense.id != nil)
        #expect(expense.createdAt != nil)
        #expect(expense.updatedAt != nil)
        #expect(expense.isDeleted == false)
        #expect(expense.time == nil)
        #expect(expense.expenseDescription == nil)
        #expect(expense.notes == nil)
        #expect(expense.groupId == nil)
        #expect(expense.groupName == nil)
        #expect(expense.recurringExpenseId == nil)
    }
    
    @Test
    func testExpenseWithGroupData() {
        let groupId = UUID()
        let expense = Expense(
            amount: 1000,
            category: "Travel",
            date: Date(),
            groupId: groupId,
            groupName: "Goa Trip"
        )
        
        #expect(expense.groupId == groupId)
        #expect(expense.groupName == "Goa Trip")
    }
    
    @Test
    func testExpenseWithAllOptionalParameters() {
        let expenseTime = Date()
        let groupId = UUID()
        let recurringId = UUID()
        
        let expense = Expense(
            amount: 250,
            category: "Shopping",
            date: Date(),
            time: expenseTime,
            expenseDescription: "New shirt",
            notes: "Gift for friend",
            recurringExpenseId: recurringId,
            groupId: groupId,
            groupName: "Office Lunch"
        )
        
        #expect(expense.time == expenseTime)
        #expect(expense.expenseDescription == "New shirt")
        #expect(expense.notes == "Gift for friend")
        #expect(expense.recurringExpenseId == recurringId)
        #expect(expense.groupName == "Office Lunch")
    }
    
    @Test
    func testExpenseAmountCanBeZero() {
        let expense = Expense(
            amount: 0,
            category: "Other",
            date: Date()
        )
        
        #expect(expense.amount == 0)
    }
    
    @Test
    func testExpenseAmountCanBeNegative() {
        let expense = Expense(
            amount: -50,
            category: "Other",
            date: Date(),
            notes: "Refund"
        )
        
        #expect(expense.amount == -50)
        #expect(expense.notes == "Refund")
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
    
    @Test
    func testExpenseWithDescription() {
        let expense = Expense(
            amount: 649,
            category: "Entertainment",
            date: Date(),
            expenseDescription: "Netflix"
        )
        
        #expect(expense.expenseDescription == "Netflix")
    }
    
    @Test
    func testExpenseWithRecurringExpenseId() {
        let recurringId = UUID()
        
        let expense = Expense(
            amount: 100,
            category: "Other",
            date: Date(),
            recurringExpenseId: recurringId
        )
        
        #expect(expense.recurringExpenseId == recurringId)
    }
}
