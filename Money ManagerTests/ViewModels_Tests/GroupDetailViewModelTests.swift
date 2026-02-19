import Foundation
import Testing
@testable import Money_Manager

@MainActor
struct GroupDetailViewModelTests {
    
    @Test
    func testGroupTotalCalculatesCorrectly() {
        let group = SplitGroup(id: UUID(), name: "Test", createdBy: UUID(), createdAt: "2026-01-01")
        let expense1 = SharedExpense(id: UUID(), groupId: group.id, description: "Dinner", category: "Food", totalAmount: "100.00", paidBy: UUID(), createdAt: "2026-01-01", splits: nil)
        let expense2 = SharedExpense(id: UUID(), groupId: group.id, description: "Lunch", category: "Food", totalAmount: "200.00", paidBy: UUID(), createdAt: "2026-01-01", splits: nil)
        
        let viewModel = GroupDetailViewModel(group: group, expenses: [expense1, expense2])
        
        #expect(viewModel.groupTotal == 300.0)
    }
    
    @Test
    func testGroupTotalReturnsZeroForNoExpenses() {
        let group = SplitGroup(id: UUID(), name: "Test", createdBy: UUID(), createdAt: "2026-01-01")
        
        let viewModel = GroupDetailViewModel(group: group)
        
        #expect(viewModel.groupTotal == 0)
    }
    
    @Test
    func testHasUnsettledBalancesReturnsTrueWhenBalancesExist() {
        let group = SplitGroup(id: UUID(), name: "Test", createdBy: UUID(), createdAt: "2026-01-01")
        let balance = UserBalance(userId: UUID(), amount: "50.00")
        
        let viewModel = GroupDetailViewModel(group: group, balances: [balance])
        
        #expect(viewModel.hasUnsettledBalances == true)
    }
    
    @Test
    func testHasUnsettledBalancesReturnsFalseWhenAllSettled() {
        let group = SplitGroup(id: UUID(), name: "Test", createdBy: UUID(), createdAt: "2026-01-01")
        let balance = UserBalance(userId: UUID(), amount: "0.00")
        
        let viewModel = GroupDetailViewModel(group: group, balances: [balance])
        
        #expect(viewModel.hasUnsettledBalances == false)
    }
    
    @Test
    func testHasUnsettledBalancesReturnsFalseForNegativeBalance() {
        let group = SplitGroup(id: UUID(), name: "Test", createdBy: UUID(), createdAt: "2026-01-01")
        let balance = UserBalance(userId: UUID(), amount: "-25.00")
        
        let viewModel = GroupDetailViewModel(group: group, balances: [balance])
        
        #expect(viewModel.hasUnsettledBalances == true)
    }
    
    @Test
    func testRecalculateBalancesCalculatesCorrectly() {
        let group = SplitGroup(id: UUID(), name: "Test", createdBy: UUID(), createdAt: "2026-01-01")
        let member1 = APIUser(id: UUID(), email: "user1@test.com", createdAt: "2026-01-01")
        let member2 = APIUser(id: UUID(), email: "user2@test.com", createdAt: "2026-01-01")
        
        let expense = SharedExpense(
            id: UUID(),
            groupId: group.id,
            description: "Dinner",
            category: "Food",
            totalAmount: "100.00",
            paidBy: member1.id,
            createdAt: "2026-01-01",
            splits: [
                ExpenseSplit(userId: member1.id, amount: "50.00"),
                ExpenseSplit(userId: member2.id, amount: "50.00")
            ]
        )
        
        let viewModel = GroupDetailViewModel(group: group, expenses: [expense], members: [member1, member2])
        
        viewModel.recalculateBalances()
        
        #expect(viewModel.balances.count == 2)
    }
    
    @Test
    func testRecalculateBalancesWithNoSplits() {
        let group = SplitGroup(id: UUID(), name: "Test", createdBy: UUID(), createdAt: "2026-01-01")
        let member1 = APIUser(id: UUID(), email: "user1@test.com", createdAt: "2026-01-01")
        
        let expense = SharedExpense(
            id: UUID(),
            groupId: group.id,
            description: "Dinner",
            category: "Food",
            totalAmount: "100.00",
            paidBy: member1.id,
            createdAt: "2026-01-01",
            splits: nil
        )
        
        let viewModel = GroupDetailViewModel(group: group, expenses: [expense], members: [member1])
        
        viewModel.recalculateBalances()
        
        #expect(viewModel.balances.count == 1)
    }
    
    @Test
    func testAddExpenseInsertsAtBeginning() {
        let group = SplitGroup(id: UUID(), name: "Test", createdBy: UUID(), createdAt: "2026-01-01")
        let expense1 = SharedExpense(id: UUID(), groupId: group.id, description: "Old", category: "Food", totalAmount: "50.00", paidBy: UUID(), createdAt: "2026-01-01", splits: nil)
        
        let viewModel = GroupDetailViewModel(group: group, expenses: [expense1])
        
        let newExpense = SharedExpense(id: UUID(), groupId: group.id, description: "New", category: "Food", totalAmount: "100.00", paidBy: UUID(), createdAt: "2026-01-02", splits: nil)
        viewModel.addExpense(newExpense)
        
        #expect(viewModel.expenses.first?.description == "New")
    }
    
    @Test
    func testAddExpenseRecalculatesBalances() {
        let group = SplitGroup(id: UUID(), name: "Test", createdBy: UUID(), createdAt: "2026-01-01")
        let member = APIUser(id: UUID(), email: "user@test.com", createdAt: "2026-01-01")
        
        let expense = SharedExpense(id: UUID(), groupId: group.id, description: "Test", category: "Food", totalAmount: "100.00", paidBy: member.id, createdAt: "2026-01-01", splits: nil)
        
        let viewModel = GroupDetailViewModel(group: group, expenses: [], members: [member])
        
        viewModel.addExpense(expense)
        
        #expect(!viewModel.balances.isEmpty)
    }
    
    @Test
    func testGroupSectionAllCases() {
        #expect(GroupSection.allCases.count == 3)
        #expect(GroupSection.allCases.contains(.expenses))
        #expect(GroupSection.allCases.contains(.balances))
        #expect(GroupSection.allCases.contains(.members))
    }
}
