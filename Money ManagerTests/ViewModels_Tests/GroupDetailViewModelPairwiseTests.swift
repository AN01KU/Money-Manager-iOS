import Foundation
import Testing
@testable import Money_Manager

/// Tests for GroupDetailViewModel: pairwiseDebts, showError/showAddMemberError,
/// transactionEdited, and deleteTransaction.
@MainActor
struct GroupDetailViewModelPairwiseTests {

    // MARK: - Helpers

    private func makeGroup(id: UUID = UUID()) -> SplitGroup {
        SplitGroup(id: id, name: "Test", createdBy: UUID(), createdAt: Date(), members: [], balances: [], settlements: [])
    }

    private func makeMember(id: UUID = UUID(), email: String = "u@example.com") -> GroupMember {
        GroupMember(from: APIGroupMember(id: id, email: email, username: email.components(separatedBy: "@").first ?? email, joinedAt: Date()))
    }

    private func makeBalance(userId: UUID, amount: Double) -> GroupBalance {
        GroupBalance(from: APIGroupBalance(userId: userId, amount: amount))
    }

    private func makeTransaction(id: UUID = UUID(), totalAmount: Double, paidBy: UUID = UUID()) -> GroupTransaction {
        let dto = APIGroupTransaction(
            id: id, groupId: UUID(), paidByUserId: paidBy,
            totalAmount: totalAmount, category: "Food", date: Date(),
            description: "tx", notes: nil, isDeleted: false,
            createdAt: Date(), updatedAt: Date(), splits: []
        )
        return try! GroupTransaction(from: dto)
    }

    /// Builds a GroupService backed by a MockAPIClient.
    /// - stubbedGroupDetails: returned for GET .group — used by reload after edits/deletes
    /// - stubbedTransactions: returned for GET .groupTransactions
    /// - deleteGroupTxError: error to throw on deleteMessage(.groupTransaction)
    /// - deleteGroupTxCount: closure returning the number of deleteGroupTransaction calls made
    private func makeService(
        groupId: UUID = UUID(),
        stubbedMembers: [GroupMember] = [],
        stubbedBalances: [GroupBalance] = [],
        stubbedTransactions: [GroupTransaction] = [],
        deleteGroupTxError: Error? = nil
    ) -> (GroupService, MockAPIClient, deleteGroupTxCount: () -> Int) {
        let client = MockAPIClient()
        var deleteCount = 0

        let memberDTOs = stubbedMembers.map { m in
            APIGroupMember(id: m.id, email: m.email, username: m.username, joinedAt: Date())
        }
        let balanceDTOs = stubbedBalances.map { b in
            APIGroupBalance(userId: b.userId, amount: b.amount)
        }
        let txDTOs = stubbedTransactions.map { tx in
            APIGroupTransaction(
                id: tx.id, groupId: groupId, paidByUserId: tx.paidByUserId,
                totalAmount: tx.totalAmount, category: tx.category, date: tx.date,
                description: tx.description, notes: tx.notes, isDeleted: false,
                createdAt: tx.date, updatedAt: tx.date, splits: []
            )
        }

        client.getHandler = { endpoint in
            switch endpoint {
            case .group(let id):
                let body = APIGroupDetailsBody(
                    id: id, name: "Test", createdBy: UUID(), createdAt: Date(),
                    members: memberDTOs, balances: balanceDTOs, settlements: nil
                )
                return APIGroupDetails(group: body, isMember: true)
            case .groupTransactions:
                return APIListResponse(data: txDTOs)
            case .groupMembers:
                return APIListResponse(data: memberDTOs)
            default:
                throw MockAPIClient.MockError.notConfigured
            }
        }
        client.deleteMessageHandler = { endpoint in
            switch endpoint {
            case .groupTransaction:
                deleteCount += 1
                if let err = deleteGroupTxError { throw err }
                return APIMessageResponse(message: "ok")
            default:
                throw MockAPIClient.MockError.notConfigured
            }
        }

        return (GroupService(apiClient: client), client, { deleteCount })
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
        let (service, _, _) = makeService()
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: service)
        let txId = UUID()
        let old = makeTransaction(id: txId, totalAmount: 100)
        let updated = makeTransaction(id: UUID(), totalAmount: 200, paidBy: UUID())
        vm.transactions = [old]

        vm.transactionEdited(replacing: old, with: updated)

        #expect(vm.transactions.count == 1)
        #expect(vm.transactions[0].totalAmount == 200)
    }

    @Test func testTransactionEditedInsertsAtTopWhenOldNotFound() {
        let (service, _, _) = makeService()
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: service)
        let existing = makeTransaction(totalAmount: 50)
        vm.transactions = [existing]
        let old = makeTransaction(totalAmount: 99) // not in list
        let updated = makeTransaction(totalAmount: 150)

        vm.transactionEdited(replacing: old, with: updated)

        #expect(vm.transactions.first?.totalAmount == 150)
        #expect(vm.transactions.count == 2)
    }

    @Test func testTransactionEditedTriggersReload() async {
        let groupId = UUID()
        let alice = makeMember()
        let (service, _, _) = makeService(
            groupId: groupId,
            stubbedMembers: [alice],
            stubbedBalances: [makeBalance(userId: alice.id, amount: 50)]
        )
        let vm = GroupDetailViewModel(group: makeGroup(id: groupId), groupService: service)
        let old = makeTransaction(totalAmount: 100, paidBy: alice.id)
        let updated = makeTransaction(totalAmount: 200, paidBy: alice.id)
        vm.transactions = [old]

        vm.transactionEdited(replacing: old, with: updated)
        try? await Task.sleep(nanoseconds: 200_000_000)

        // After reload, balances should come from server
        let balance = vm.balances.first(where: { $0.userId == alice.id })
        #expect(balance != nil)
        #expect(abs((balance?.amount ?? 0) - 50) < 0.01)
    }

    // MARK: - deleteTransaction

    @Test func testDeleteTransactionRemovesItFromList() {
        let (service, _, _) = makeService()
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: service)
        let tx = makeTransaction(totalAmount: 100)
        vm.transactions = [tx]

        vm.deleteTransaction(tx)

        #expect(vm.transactions.isEmpty)
    }

    @Test func testDeleteTransactionTriggersReload() async {
        let groupId = UUID()
        let alice = makeMember()
        let bob = makeMember()
        let (service, _, _) = makeService(
            groupId: groupId,
            stubbedMembers: [alice, bob]
        )
        let vm = GroupDetailViewModel(group: makeGroup(id: groupId), groupService: service)
        let tx = makeTransaction(totalAmount: 100, paidBy: alice.id)
        vm.transactions = [tx]

        vm.deleteTransaction(tx)
        try? await Task.sleep(nanoseconds: 200_000_000)

        // After reload, transactions should reflect server state (empty in mock)
        #expect(vm.transactions.isEmpty)
    }

    @Test func testDeleteTransactionRestoresOnServiceFailure() async {
        struct DeleteError: Error {}
        let groupId = UUID()
        let (service, _, _) = makeService(groupId: groupId, deleteGroupTxError: DeleteError())
        let vm = GroupDetailViewModel(group: makeGroup(id: groupId), groupService: service)
        let tx = makeTransaction(totalAmount: 100)
        vm.transactions = [tx]

        vm.deleteTransaction(tx)

        try? await Task.sleep(nanoseconds: 100_000_000)

        // Should be restored after failure
        #expect(vm.transactions.contains(where: { $0.id == tx.id }))
        #expect(vm.errorMessage != nil)
    }
}
