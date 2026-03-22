// MARK: - Commented out: GroupDetailViewModel removed in offline-v1
/*
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
        let member1 = APIUser(id: UUID(), email: "user1@test.com", username: "User1", createdAt: "2026-01-01")
        let member2 = APIUser(id: UUID(), email: "user2@test.com", username: "User2", createdAt: "2026-01-01")
        
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
        let member1 = APIUser(id: UUID(), email: "user1@test.com", username: "User1", createdAt: "2026-01-01")
        
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
        let member = APIUser(id: UUID(), email: "user@test.com", username: "User", createdAt: "2026-01-01")
        
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
    
    // MARK: - Add Member (Invitation) Tests
    
    @Test
    func testAddMemberAppendsMemberToList() {
        let group = SplitGroup(id: UUID(), name: "Test", createdBy: UUID(), createdAt: "2026-01-01")
        let viewModel = GroupDetailViewModel(group: group, members: [])
        
        viewModel.addMember(email: "new@test.com")
        
        #expect(viewModel.members.count == 1)
        #expect(viewModel.members.first?.email == "new@test.com")
    }
    
    @Test
    func testAddMemberMarksAsPending() {
        let group = SplitGroup(id: UUID(), name: "Test", createdBy: UUID(), createdAt: "2026-01-01")
        let viewModel = GroupDetailViewModel(group: group, members: [])
        
        viewModel.addMember(email: "pending@test.com")
        
        let addedMember = viewModel.members.first!
        #expect(viewModel.pendingMemberIds.contains(addedMember.id))
    }
    
    @Test
    func testAddMemberDismissesSheet() {
        let group = SplitGroup(id: UUID(), name: "Test", createdBy: UUID(), createdAt: "2026-01-01")
        let viewModel = GroupDetailViewModel(group: group)
        viewModel.showAddMember = true
        
        viewModel.addMember(email: "user@test.com")
        
        #expect(viewModel.showAddMember == false)
    }
    
    @Test
    func testAddMemberPreservesExistingMembers() {
        let group = SplitGroup(id: UUID(), name: "Test", createdBy: UUID(), createdAt: "2026-01-01")
        let existing = APIUser(id: UUID(), email: "existing@test.com", username: "Existing", createdAt: "2026-01-01")
        let viewModel = GroupDetailViewModel(group: group, members: [existing])
        
        viewModel.addMember(email: "new@test.com")
        
        #expect(viewModel.members.count == 2)
        #expect(viewModel.members.first?.email == "existing@test.com")
        #expect(viewModel.members.last?.email == "new@test.com")
    }
    
    @Test
    func testAddMemberDoesNotMarkExistingAsPending() {
        let group = SplitGroup(id: UUID(), name: "Test", createdBy: UUID(), createdAt: "2026-01-01")
        let existing = APIUser(id: UUID(), email: "existing@test.com", username: "Existing", createdAt: "2026-01-01")
        let viewModel = GroupDetailViewModel(group: group, members: [existing])
        
        viewModel.addMember(email: "new@test.com")
        
        #expect(!viewModel.pendingMemberIds.contains(existing.id))
    }
    
    @Test
    func testAddMultipleMembersBothPending() {
        let group = SplitGroup(id: UUID(), name: "Test", createdBy: UUID(), createdAt: "2026-01-01")
        let viewModel = GroupDetailViewModel(group: group, members: [])
        
        viewModel.addMember(email: "a@test.com")
        viewModel.addMember(email: "b@test.com")
        
        #expect(viewModel.members.count == 2)
        #expect(viewModel.pendingMemberIds.count == 2)
    }
    
    @Test
    func testPendingMemberIdsStartsEmpty() {
        let group = SplitGroup(id: UUID(), name: "Test", createdBy: UUID(), createdAt: "2026-01-01")
        let viewModel = GroupDetailViewModel(group: group)
        
        #expect(viewModel.pendingMemberIds.isEmpty)
    }
    
    // MARK: - Recalculate Balances Correctness
    
    @Test
    func testRecalculateBalancesPayerGetsPositiveBalance() {
        let group = SplitGroup(id: UUID(), name: "Test", createdBy: UUID(), createdAt: "2026-01-01")
        let payer = APIUser(id: UUID(), email: "payer@test.com", username: "Payer", createdAt: "2026-01-01")
        let other = APIUser(id: UUID(), email: "other@test.com", username: "Other", createdAt: "2026-01-01")
        
        let expense = SharedExpense(
            id: UUID(), groupId: group.id, description: "Dinner", category: "Food",
            totalAmount: "200.00", paidBy: payer.id, createdAt: "2026-01-01",
            splits: [
                ExpenseSplit(userId: payer.id, amount: "100.00"),
                ExpenseSplit(userId: other.id, amount: "100.00")
            ]
        )
        
        let viewModel = GroupDetailViewModel(group: group, expenses: [expense], members: [payer, other])
        viewModel.recalculateBalances()
        
        let payerBalance = viewModel.balances.first(where: { $0.userId == payer.id })
        let otherBalance = viewModel.balances.first(where: { $0.userId == other.id })
        
        #expect((Double(payerBalance?.amount ?? "0") ?? 0) == 100.0)
        #expect((Double(otherBalance?.amount ?? "0") ?? 0) == -100.0)
    }
    
    @Test
    func testRecalculateBalancesMultipleExpensesNetCorrectly() {
        let group = SplitGroup(id: UUID(), name: "Test", createdBy: UUID(), createdAt: "2026-01-01")
        let user1 = APIUser(id: UUID(), email: "u1@test.com", username: "U1", createdAt: "2026-01-01")
        let user2 = APIUser(id: UUID(), email: "u2@test.com", username: "U2", createdAt: "2026-01-01")
        
        let expense1 = SharedExpense(
            id: UUID(), groupId: group.id, description: "Lunch", category: "Food",
            totalAmount: "100.00", paidBy: user1.id, createdAt: "2026-01-01",
            splits: [
                ExpenseSplit(userId: user1.id, amount: "50.00"),
                ExpenseSplit(userId: user2.id, amount: "50.00")
            ]
        )
        let expense2 = SharedExpense(
            id: UUID(), groupId: group.id, description: "Coffee", category: "Food",
            totalAmount: "60.00", paidBy: user2.id, createdAt: "2026-01-01",
            splits: [
                ExpenseSplit(userId: user1.id, amount: "30.00"),
                ExpenseSplit(userId: user2.id, amount: "30.00")
            ]
        )
        
        let viewModel = GroupDetailViewModel(group: group, expenses: [expense1, expense2], members: [user1, user2])
        viewModel.recalculateBalances()
        
        let balance1 = Double(viewModel.balances.first(where: { $0.userId == user1.id })?.amount ?? "0") ?? 0
        let balance2 = Double(viewModel.balances.first(where: { $0.userId == user2.id })?.amount ?? "0") ?? 0
        
        // user1 paid 100, owes 80 (50+30) → net +20
        // user2 paid 60, owes 80 (50+30) → net -20
        #expect(balance1 == 20.0)
        #expect(balance2 == -20.0)
    }
    
    @Test
    func testRecalculateBalancesSortedByAbsoluteValue() {
        let group = SplitGroup(id: UUID(), name: "Test", createdBy: UUID(), createdAt: "2026-01-01")
        let user1 = APIUser(id: UUID(), email: "u1@test.com", username: "U1", createdAt: "2026-01-01")
        let user2 = APIUser(id: UUID(), email: "u2@test.com", username: "U2", createdAt: "2026-01-01")
        let user3 = APIUser(id: UUID(), email: "u3@test.com", username: "U3", createdAt: "2026-01-01")
        
        let expense = SharedExpense(
            id: UUID(), groupId: group.id, description: "Trip", category: "Travel",
            totalAmount: "300.00", paidBy: user1.id, createdAt: "2026-01-01",
            splits: [
                ExpenseSplit(userId: user1.id, amount: "100.00"),
                ExpenseSplit(userId: user2.id, amount: "50.00"),
                ExpenseSplit(userId: user3.id, amount: "150.00")
            ]
        )
        
        let viewModel = GroupDetailViewModel(group: group, expenses: [expense], members: [user1, user2, user3])
        viewModel.recalculateBalances()
        
        let amounts = viewModel.balances.map { abs(Double($0.amount) ?? 0) }
        #expect(amounts == amounts.sorted(by: >))
    }
}

*/
