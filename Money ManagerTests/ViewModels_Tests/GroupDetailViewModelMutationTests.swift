import Foundation
import Testing
@testable import Money_Manager

/// Tests for GroupDetailViewModel: filteredTransactions, renameGroup, deleteGroup,
/// removeMember, leaveGroup, and deleteSettlement.
@MainActor
struct GroupDetailViewModelMutationTests {

    // MARK: - Helpers

    private func makeGroup(id: UUID = UUID(), createdBy: UUID = UUID()) -> APIGroupWithDetails {
        APIGroupWithDetails(id: id, name: "Test Group", createdBy: createdBy, createdAt: Date(), members: [], balances: [])
    }

    private func makeMember(id: UUID = UUID(), email: String = "user@example.com") -> APIGroupMember {
        APIGroupMember(id: id, email: email, username: email.components(separatedBy: "@").first ?? email, joinedAt: Date())
    }

    private func makeTransaction(id: UUID = UUID(), description: String? = nil, category: String = "Food", totalAmount: Double = 50) -> APIGroupTransaction {
        APIGroupTransaction(
            id: id, groupId: UUID(), paidByUserId: UUID(),
            totalAmount: totalAmount, category: category, date: Date(),
            description: description, notes: nil, isDeleted: false,
            createdAt: Date(), updatedAt: Date(), splits: []
        )
    }

    private func makeSettlement(id: UUID = UUID(), groupId: UUID = UUID()) -> APISettlement {
        APISettlement(id: id, groupId: groupId, fromUser: UUID(), toUser: UUID(), amount: 20, notes: nil, createdAt: Date())
    }

    // MARK: - filteredTransactions

    @Test func testFilteredTransactionsReturnsAllWhenSearchEmpty() {
        let vm = GroupDetailViewModel(group: makeGroup())
        vm.transactions = [makeTransaction(), makeTransaction()]
        #expect(vm.filteredTransactions.count == 2)
    }

    @Test func testFilteredTransactionsMatchesDescription() {
        let vm = GroupDetailViewModel(group: makeGroup())
        vm.transactions = [
            makeTransaction(description: "lunch at cafe"),
            makeTransaction(description: "uber ride")
        ]
        vm.transactionSearchText = "lunch"
        #expect(vm.filteredTransactions.count == 1)
        #expect(vm.filteredTransactions.first?.description == "lunch at cafe")
    }

    @Test func testFilteredTransactionsMatchesCategory() {
        let vm = GroupDetailViewModel(group: makeGroup())
        vm.transactions = [
            makeTransaction(category: "Food"),
            makeTransaction(category: "Transport")
        ]
        vm.transactionSearchText = "Transport"
        #expect(vm.filteredTransactions.count == 1)
        #expect(vm.filteredTransactions.first?.category == "Transport")
    }

    @Test func testFilteredTransactionsIsCaseInsensitive() {
        let vm = GroupDetailViewModel(group: makeGroup())
        vm.transactions = [makeTransaction(description: "Starbucks")]
        vm.transactionSearchText = "starbucks"
        #expect(vm.filteredTransactions.count == 1)
    }

    @Test func testFilteredTransactionsReturnsEmptyWhenNoMatch() {
        let vm = GroupDetailViewModel(group: makeGroup())
        vm.transactions = [makeTransaction(description: "dinner"), makeTransaction(category: "Food")]
        vm.transactionSearchText = "zzznomatch"
        #expect(vm.filteredTransactions.isEmpty)
    }

    @Test func testFilteredTransactionsMatchesNilDescriptionOnlyByCategory() {
        let vm = GroupDetailViewModel(group: makeGroup())
        vm.transactions = [makeTransaction(description: nil, category: "Groceries")]
        vm.transactionSearchText = "Groceries"
        #expect(vm.filteredTransactions.count == 1)
    }

    // MARK: - renameGroup

    @Test func testRenameGroupIgnoresBlankName() {
        let mock = MockGroupService.fresh()
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: mock)
        let originalName = vm.group.name
        vm.renameGroup(to: "   ")
        #expect(vm.group.name == originalName)
    }

    @Test func testRenameGroupIgnoresWhitespaceOnlyName() {
        let mock = MockGroupService.fresh()
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: mock)
        let originalName = vm.group.name
        vm.renameGroup(to: "\t\n")
        #expect(vm.group.name == originalName)
    }

    @Test func testRenameGroupSuccessUpdatesGroupAndSetsIsRenamed() async {
        let mock = MockGroupService.fresh()
        let groupId = UUID()
        let vm = GroupDetailViewModel(group: makeGroup(id: groupId), groupService: mock)
        vm.renameGroup(to: "New Name")
        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(vm.group.name == "New Name")
        #expect(vm.isRenamed == true)
    }

    @Test func testRenameGroupTrimsWhitespace() async {
        let mock = MockGroupService.fresh()
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: mock)
        vm.renameGroup(to: "  Trimmed Name  ")
        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(vm.group.name == "Trimmed Name")
    }

    @Test func testRenameGroupFailureSetsErrorMessage() async {
        let mock = MockGroupService.fresh()
        struct RenameError: Error, LocalizedError {
            var errorDescription: String? { "rename failed" }
        }
        mock.renameGroupError = RenameError()
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: mock)
        vm.renameGroup(to: "New Name")
        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(vm.errorMessage != nil)
        #expect(vm.isRenamed == false)
    }

    // MARK: - deleteGroup

    @Test func testDeleteGroupSuccessSetsDidDeleteOrLeave() async {
        let mock = MockGroupService.fresh()
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: mock)
        vm.deleteGroup()
        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(vm.didDeleteOrLeave == true)
    }

    @Test func testDeleteGroupFailureSetsErrorMessage() async {
        let mock = MockGroupService.fresh()
        struct DeleteGroupError: Error, LocalizedError {
            var errorDescription: String? { "cannot delete" }
        }
        mock.deleteGroupError = DeleteGroupError()
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: mock)
        vm.deleteGroup()
        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(vm.errorMessage != nil)
        #expect(vm.didDeleteOrLeave == false)
    }

    // MARK: - removeMember

    @Test func testRemoveMemberOptimisticallyRemovesMemberFromList() {
        let mock = MockGroupService.fresh()
        let alice = makeMember(email: "alice@example.com")
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: mock)
        vm.members = [alice]
        vm.removeMember(alice)
        #expect(vm.members.isEmpty)
    }

    @Test func testRemoveMemberSuccessRefreshesMembers() async {
        let mock = MockGroupService.fresh()
        let alice = makeMember(email: "alice@example.com")
        let bob = makeMember(email: "bob@example.com")
        mock.stubbedMembers = [bob] // after removal, only bob remains
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: mock)
        vm.members = [alice, bob]
        vm.removeMember(alice)
        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(vm.members.count == 1)
        #expect(vm.members.first?.email == "bob@example.com")
    }

    @Test func testRemoveMemberFailureRestoresMembersAndSetsError() async {
        let mock = MockGroupService.fresh()
        struct RemoveError: Error, LocalizedError {
            var errorDescription: String? { "remove failed" }
        }
        mock.removeMemberError = RemoveError()
        let alice = makeMember(email: "alice@example.com")
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: mock)
        vm.members = [alice]
        vm.removeMember(alice)
        try? await Task.sleep(nanoseconds: 100_000_000)
        // Restored
        #expect(vm.members.contains(where: { $0.id == alice.id }))
        #expect(vm.errorMessage != nil)
    }

    // MARK: - leaveGroup

    @Test func testLeaveGroupSuccessSetsDidDeleteOrLeave() async {
        let mock = MockGroupService.fresh()
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: mock)
        vm.leaveGroup()
        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(vm.didDeleteOrLeave == true)
    }

    @Test func testLeaveGroupFailureSetsErrorMessage() async {
        let mock = MockGroupService.fresh()
        struct LeaveError: Error, LocalizedError {
            var errorDescription: String? { "cannot leave" }
        }
        mock.leaveGroupError = LeaveError()
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: mock)
        vm.leaveGroup()
        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(vm.errorMessage != nil)
        #expect(vm.didDeleteOrLeave == false)
    }

    // MARK: - deleteSettlement

    @Test func testDeleteSettlementOptimisticallyRemovesFromList() {
        let mock = MockGroupService.fresh()
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: mock)
        let settlement = makeSettlement()
        vm.settlements = [settlement]
        vm.deleteSettlement(settlement)
        #expect(vm.settlements.isEmpty)
    }

    @Test func testDeleteSettlementFailureRestoresSettlementAndSetsError() async {
        let mock = MockGroupService.fresh()
        struct SettlementDeleteError: Error, LocalizedError {
            var errorDescription: String? { "delete failed" }
        }
        mock.deleteSettlementError = SettlementDeleteError()
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: mock)
        let settlement = makeSettlement()
        vm.settlements = [settlement]
        vm.deleteSettlement(settlement)
        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(vm.settlements.contains(where: { $0.id == settlement.id }))
        #expect(vm.errorMessage != nil)
    }

    @Test func testDeleteSettlementSuccessReloadsData() async {
        let mock = MockGroupService.fresh()
        let groupId = UUID()
        let alice = makeMember()
        mock.stubbedGroupDetails = {
            let body = APIGroupDetailsBody(
                id: groupId, name: "Test Group", createdBy: UUID(), createdAt: Date(),
                members: [alice], balances: [], settlements: []
            )
            return APIGroupDetails(group: body, isMember: true)
        }()
        mock.stubbedTransactions = []
        let vm = GroupDetailViewModel(group: makeGroup(id: groupId), groupService: mock)
        let settlement = makeSettlement(groupId: groupId)
        vm.settlements = [settlement]
        vm.deleteSettlement(settlement)
        try? await Task.sleep(nanoseconds: 200_000_000)
        // Settlements should be cleared (reloadData returns empty settlements from mock)
        #expect(vm.settlements.isEmpty)
    }

    // MARK: - transactionEdited failure path

    @Test func testTransactionEditedFailureRestoresOldAndSetsError() async {
        let mock = MockGroupService.fresh()
        struct EditError: Error, LocalizedError {
            var errorDescription: String? { "edit failed" }
        }
        mock.deleteError = EditError()
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: mock)
        let txId = UUID()
        let old = makeTransaction(id: txId, totalAmount: 100)
        let updated = makeTransaction(id: UUID(), totalAmount: 200)
        vm.transactions = [old]
        vm.transactionEdited(replacing: old, with: updated)
        try? await Task.sleep(nanoseconds: 100_000_000)
        // After failure, old transaction should be restored
        #expect(vm.transactions.contains(where: { $0.id == old.id }))
        #expect(vm.errorMessage != nil)
    }
}
