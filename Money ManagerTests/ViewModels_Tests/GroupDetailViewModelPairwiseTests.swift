import Foundation
import Testing
@testable import Money_Manager

/// Tests for GroupDetailViewModel: pairwiseDebts, showError/showAddMemberError,
/// transactionEdited, and deleteTransaction.
@MainActor
struct GroupDetailViewModelPairwiseTests {

    // MARK: - Helpers

    private func makeGroup(id: UUID = UUID()) -> APIGroupWithDetails {
        APIGroupWithDetails(id: id, name: "Test", createdBy: UUID(), createdAt: Date(), members: [], balances: [])
    }

    private func makeMember(id: UUID = UUID(), email: String = "u@example.com") -> APIGroupMember {
        APIGroupMember(id: id, email: email, username: email.components(separatedBy: "@").first ?? email, joinedAt: Date())
    }

    private func makeBalance(userId: UUID, amount: Double) -> APIGroupBalance {
        APIGroupBalance(userId: userId, amount: amount)
    }

    private func makeTransaction(id: UUID = UUID(), totalAmount: Double, paidBy: UUID = UUID()) -> APIGroupTransaction {
        APIGroupTransaction(
            id: id, groupId: UUID(), paidByUserId: paidBy,
            totalAmount: totalAmount, category: "Food", date: Date(),
            description: "tx", notes: nil, isDeleted: false,
            createdAt: Date(), updatedAt: Date(), splits: []
        )
    }

    // MARK: - pairwiseDebts: no balances

    @Test func testPairwiseDebtsEmptyWhenNoBalances() {
        let vm = GroupDetailViewModel(group: makeGroup())
        #expect(vm.pairwiseDebts.isEmpty)
    }

    @Test func testPairwiseDebtsEmptyWhenAllBalancesAreZero() {
        let vm = GroupDetailViewModel(group: makeGroup())
        vm.balances = [makeBalance(userId: UUID(), amount: 0)]
        #expect(vm.pairwiseDebts.isEmpty)
    }

    // MARK: - pairwiseDebts: simple two-person case

    @Test func testPairwiseDebtsTwoPeopleSimpleDebt() {
        let alice = UUID()
        let bob = UUID()
        let vm = GroupDetailViewModel(group: makeGroup())
        // Bob paid more → bob is owed 50; alice owes 50
        vm.balances = [
            makeBalance(userId: alice, amount: -50),
            makeBalance(userId: bob,   amount:  50)
        ]
        let debts = vm.pairwiseDebts
        #expect(debts.count == 1)
        #expect(debts[0].fromUserId == alice)
        #expect(debts[0].toUserId == bob)
        #expect(abs(debts[0].amount - 50) < 0.01)
    }

    @Test func testPairwiseDebtsTwoPeoplePartialSettle() {
        let alice = UUID()
        let bob = UUID()
        let vm = GroupDetailViewModel(group: makeGroup())
        vm.balances = [
            makeBalance(userId: alice, amount: -30),
            makeBalance(userId: bob,   amount:  30)
        ]
        let debts = vm.pairwiseDebts
        #expect(debts.count == 1)
        #expect(abs(debts[0].amount - 30) < 0.01)
    }

    // MARK: - pairwiseDebts: three-person case

    @Test func testPairwiseDebtsThreePeopleBalancesSplitCorrectly() {
        // Alice: +100 (is owed), Bob: -60 (owes), Charlie: -40 (owes)
        let alice = UUID()
        let bob = UUID()
        let charlie = UUID()
        let vm = GroupDetailViewModel(group: makeGroup())
        vm.balances = [
            makeBalance(userId: alice,   amount:  100),
            makeBalance(userId: bob,     amount:  -60),
            makeBalance(userId: charlie, amount:  -40)
        ]
        let debts = vm.pairwiseDebts
        // Both bob and charlie owe alice
        let bobDebt = debts.first(where: { $0.fromUserId == bob })
        let charlieDebt = debts.first(where: { $0.fromUserId == charlie })
        #expect(bobDebt != nil)
        #expect(charlieDebt != nil)
        #expect(abs((bobDebt?.amount ?? 0) - 60) < 0.01)
        #expect(abs((charlieDebt?.amount ?? 0) - 40) < 0.01)
    }

    // MARK: - pairwiseDebts: negligible amounts are skipped

    @Test func testPairwiseDebtsSkipsNegligibleAmounts() {
        let alice = UUID()
        let bob = UUID()
        let vm = GroupDetailViewModel(group: makeGroup())
        // Below the 0.01 threshold
        vm.balances = [
            makeBalance(userId: alice, amount: -0.005),
            makeBalance(userId: bob,   amount:  0.005)
        ]
        let debts = vm.pairwiseDebts
        #expect(debts.isEmpty)
    }

    // MARK: - showError computed property

    @Test func testShowErrorIsFalseWhenNoErrorMessage() {
        let vm = GroupDetailViewModel(group: makeGroup())
        #expect(vm.showError == false)
    }

    @Test func testShowErrorIsTrueWhenErrorMessageIsSet() {
        let vm = GroupDetailViewModel(group: makeGroup())
        vm.errorMessage = "Something went wrong"
        #expect(vm.showError == true)
    }

    @Test func testSettingShowErrorToFalseClearsErrorMessage() {
        let vm = GroupDetailViewModel(group: makeGroup())
        vm.errorMessage = "Something went wrong"
        vm.showError = false
        #expect(vm.errorMessage == nil)
        #expect(vm.showError == false)
    }

    @Test func testSettingShowErrorToTrueDoesNotChangeMessage() {
        let vm = GroupDetailViewModel(group: makeGroup())
        vm.errorMessage = "Existing error"
        vm.showError = true // no-op on set(true)
        #expect(vm.errorMessage == "Existing error")
    }

    // MARK: - showAddMemberError computed property

    @Test func testShowAddMemberErrorIsFalseByDefault() {
        let vm = GroupDetailViewModel(group: makeGroup())
        #expect(vm.showAddMemberError == false)
    }

    @Test func testShowAddMemberErrorIsTrueWhenErrorSet() {
        let vm = GroupDetailViewModel(group: makeGroup())
        vm.addMemberError = "user not found"
        #expect(vm.showAddMemberError == true)
    }

    @Test func testSettingShowAddMemberErrorToFalseClearsIt() {
        let vm = GroupDetailViewModel(group: makeGroup())
        vm.addMemberError = "user not found"
        vm.showAddMemberError = false
        #expect(vm.addMemberError == nil)
        #expect(vm.showAddMemberError == false)
    }

    // MARK: - transactionEdited

    @Test func testTransactionEditedReplacesExistingTransaction() {
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: MockGroupService.fresh())
        let txId = UUID()
        let old = makeTransaction(id: txId, totalAmount: 100)
        let updated = makeTransaction(id: UUID(), totalAmount: 200, paidBy: UUID())
        vm.transactions = [old]

        vm.transactionEdited(replacing: old, with: updated)

        #expect(vm.transactions.count == 1)
        #expect(vm.transactions[0].totalAmount == 200)
    }

    @Test func testTransactionEditedInsertsAtTopWhenOldNotFound() {
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: MockGroupService.fresh())
        let existing = makeTransaction(totalAmount: 50)
        vm.transactions = [existing]
        let old = makeTransaction(totalAmount: 99) // not in list
        let updated = makeTransaction(totalAmount: 150)

        vm.transactionEdited(replacing: old, with: updated)

        #expect(vm.transactions.first?.totalAmount == 150)
        #expect(vm.transactions.count == 2)
    }

    @Test func testTransactionEditedRecalculatesBalances() {
        let alice = makeMember()
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: MockGroupService.fresh())
        vm.members = [alice]
        let old = makeTransaction(totalAmount: 100, paidBy: alice.id)
        vm.transactions = [old]

        let updated = makeTransaction(totalAmount: 200, paidBy: alice.id)
        vm.transactionEdited(replacing: old, with: updated)

        // balances should reflect the new transaction
        let balance = vm.balances.first(where: { $0.userId == alice.id })
        #expect(balance != nil)
    }

    // MARK: - deleteTransaction

    @Test func testDeleteTransactionRemovesItFromList() {
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: MockGroupService.fresh())
        let tx = makeTransaction(totalAmount: 100)
        vm.transactions = [tx]

        vm.deleteTransaction(tx)

        #expect(vm.transactions.isEmpty)
    }

    @Test func testDeleteTransactionRecalculatesBalances() {
        let alice = makeMember()
        let bob = makeMember()
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: MockGroupService.fresh())
        vm.members = [alice, bob]
        let tx = makeTransaction(totalAmount: 100, paidBy: alice.id)
        vm.transactions = [tx]

        vm.deleteTransaction(tx)

        // After deletion, transactions empty → all balances should be 0
        for balance in vm.balances {
            #expect(abs(balance.amount) < 0.01)
        }
    }

    @Test func testDeleteTransactionRestoresOnServiceFailure() async {
        let mock = MockGroupService.fresh()
        struct DeleteError: Error {}
        mock.deleteError = DeleteError()

        let groupId = UUID()
        let vm = GroupDetailViewModel(group: makeGroup(id: groupId), groupService: mock)
        let tx = makeTransaction(totalAmount: 100)
        vm.transactions = [tx]

        vm.deleteTransaction(tx)

        try? await Task.sleep(nanoseconds: 100_000_000)

        // Should be restored after failure
        #expect(vm.transactions.contains(where: { $0.id == tx.id }))
        #expect(vm.errorMessage != nil)
    }
}
