import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct GroupModelsTests {
    
    @Test
    func testSplitGroupModelInitialization() {
        let groupId = UUID()
        let createdBy = UUID()
        
        let group = SplitGroupModel(
            id: groupId,
            name: "Test Group",
            createdBy: createdBy,
            createdAt: "2026-01-01"
        )
        
        #expect(group.id == groupId)
        #expect(group.name == "Test Group")
        #expect(group.createdBy == createdBy)
        #expect(group.createdAt == "2026-01-01")
        #expect(group.members.isEmpty)
        #expect(group.expenses.isEmpty)
    }
    
    @Test
    func testGroupMemberModelInitialization() {
        let memberId = UUID()
        
        let member = GroupMemberModel(
            id: memberId,
            email: "test@example.com",
            username: "testuser",
            createdAt: "2026-01-01"
        )
        
        #expect(member.id == memberId)
        #expect(member.email == "test@example.com")
        #expect(member.username == "testuser")
        #expect(member.createdAt == "2026-01-01")
        #expect(member.group == nil)
    }
    
    @Test
    func testGroupExpenseModelInitialization() {
        let expenseId = UUID()
        let paidBy = UUID()
        
        let expense = GroupExpenseModel(
            id: expenseId,
            description: "Dinner",
            category: "Food",
            totalAmount: 500.0,
            paidBy: paidBy,
            createdAt: "2026-01-01"
        )
        
        #expect(expense.id == expenseId)
        #expect(expense.expenseDescription == "Dinner")
        #expect(expense.category == "Food")
        #expect(expense.totalAmount == 500.0)
        #expect(expense.paidBy == paidBy)
        #expect(expense.createdAt == "2026-01-01")
        #expect(expense.splitsData == nil)
    }
    
    @Test
    func testGroupBalanceModelInitialization() {
        let userId = UUID()
        
        let balance = GroupBalanceModel(
            userId: userId,
            amount: 100.0
        )
        
        #expect(balance.userId == userId)
        #expect(balance.amount == 100.0)
        #expect(balance.group == nil)
    }
    
    @Test
    func testGroupBalanceModelWithGroup() {
        let groupId = UUID()
        let createdBy = UUID()
        let userId = UUID()
        
        let group = SplitGroupModel(
            id: groupId,
            name: "Test Group",
            createdBy: createdBy,
            createdAt: "2026-01-01"
        )
        
        let balance = GroupBalanceModel(
            userId: userId,
            amount: 50.0,
            group: group
        )
        
        #expect(balance.group?.id == groupId)
    }
    
    @Test
    func testGroupMemberModelCanBeLinkedToGroup() {
        let groupId = UUID()
        let createdBy = UUID()
        let memberId = UUID()
        
        let group = SplitGroupModel(
            id: groupId,
            name: "Test Group",
            createdBy: createdBy,
            createdAt: "2026-01-01"
        )
        
        let member = GroupMemberModel(
            id: memberId,
            email: "member@example.com",
            username: "member",
            createdAt: "2026-01-01"
        )
        
        member.group = group
        
        #expect(member.group?.id == groupId)
    }
    
    @Test
    func testGroupExpenseModelCanBeLinkedToGroup() {
        let groupId = UUID()
        let createdBy = UUID()
        let expenseId = UUID()
        let paidBy = UUID()
        
        let group = SplitGroupModel(
            id: groupId,
            name: "Test Group",
            createdBy: createdBy,
            createdAt: "2026-01-01"
        )
        
        let expense = GroupExpenseModel(
            id: expenseId,
            description: "Lunch",
            category: "Food",
            totalAmount: 200.0,
            paidBy: paidBy,
            createdAt: "2026-01-01"
        )
        
        expense.group = group
        
        #expect(expense.group?.id == groupId)
    }
}
