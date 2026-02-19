import Foundation
import SwiftData
import Testing
@testable import Money_Manager

struct ExpenseModelTests {
    
    @Test
    func testExpenseIsRecurringFlagAutoSetWhenRecurringExpenseIdProvided() {
        let recurringId = UUID()
        let expense = Expense(
            amount: 500,
            category: "Food & Dining",
            date: Date(),
            recurringExpenseId: recurringId
        )
        
        #expect(expense.isRecurring == true)
        #expect(expense.recurringExpenseId == recurringId)
    }
    
    @Test
    func testExpenseIsRecurringFlagFalseWhenNoRecurringExpenseId() {
        let expense = Expense(
            amount: 500,
            category: "Food & Dining",
            date: Date()
        )
        
        #expect(expense.isRecurring == false)
        #expect(expense.recurringExpenseId == nil)
    }
    
    @Test
    func testExpenseDefaultValuesOnInit() {
        let expense = Expense(
            amount: 100,
            category: "Transport",
            date: Date()
        )
        
        #expect(expense.isDeleted == false)
        #expect(expense.time == nil)
        #expect(expense.expenseDescription == nil)
        #expect(expense.notes == nil)
        #expect(expense.groupId == nil)
        #expect(expense.groupName == nil)
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
        let recurringId = UUID()
        let groupId = UUID()
        
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
    }
}
