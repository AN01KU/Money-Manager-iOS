import Foundation
import Testing
@testable import Money_Manager

/// Tests for GroupDetailViewModel: filteredTransactions, renameGroup, deleteGroup,
/// removeMember, leaveGroup, and deleteSettlement.
@MainActor
struct GroupDetailViewModelMutationTests {

    // MARK: - Helpers

    private func makeGroup(id: UUID = UUID(), createdBy: UUID = UUID()) -> SplitGroup {
        SplitGroup(id: id, name: "Test Group", createdBy: createdBy, createdAt: Date(), members: [], balances: [], settlements: [])
    }

    private func makeMember(id: UUID = UUID(), email: String = "user@example.com") -> GroupMember {
        GroupMember(from: APIGroupMember(id: id, email: email, username: email.components(separatedBy: "@").first ?? email, joinedAt: Date()))
    }

    private func makeTransaction(id: UUID = UUID(), description: String? = nil, category: String = "Food", totalAmount: Double = 50) -> GroupTransaction {
        let dto = APIGroupTransaction(
            id: id, groupId: UUID(), paidByUserId: UUID(),
            totalAmount: totalAmount, category: category, date: Date(),
            description: description, notes: nil, isDeleted: false,
            createdAt: Date(), updatedAt: Date(), splits: []
        )
        return try! GroupTransaction(from: dto)
    }

    private func makeSettlement(id: UUID = UUID(), groupId: UUID = UUID()) -> Settlement {
        Settlement(from: APISettlement(id: id, groupId: groupId, fromUser: UUID(), toUser: UUID(), amount: 20, notes: nil, createdAt: Date()))
    }

    /// Builds a GroupService + MockAPIClient for mutation tests.
    private func makeService(
        groupId: UUID = UUID(),
        stubbedMembers: [GroupMember] = [],
        stubbedTransactions: [GroupTransaction] = [],
        renameGroupError: Error? = nil,
        deleteGroupError: Error? = nil,
        removeMemberError: Error? = nil,
        leaveGroupError: Error? = nil,
        deleteError: Error? = nil,
        deleteSettlementError: Error? = nil
    ) -> (GroupService, MockAPIClient, deleteCallCount: () -> Int) {
        let client = MockAPIClient()
        var deleteCount = 0

        let memberDTOs = stubbedMembers.map { m in
            APIGroupMember(id: m.id, email: m.email, username: m.username, joinedAt: Date())
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
                    id: id, name: "Test Group", createdBy: UUID(), createdAt: Date(),
                    members: memberDTOs, balances: [], settlements: nil
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
        client.patchHandler = { endpoint, _ in
            if case .group = endpoint {
                if let err = renameGroupError { throw err }
                return APIGroup(id: groupId, name: "New Name", createdBy: UUID(), createdAt: Date())
            }
            throw MockAPIClient.MockError.notConfigured
        }
        client.deleteHandler = { endpoint in
            if case .group = endpoint {
                if let err = deleteGroupError { throw err }
            }
        }
        client.deleteMessageHandler = { endpoint in
            switch endpoint {
            case .groupMember:
                if let err = removeMemberError { throw err }
                return APIMessageResponse(message: "ok")
            case .groupTransaction:
                deleteCount += 1
                if let err = deleteError { throw err }
                return APIMessageResponse(message: "ok")
            case .settlement:
                if let err = deleteSettlementError { throw err }
                return APIMessageResponse(message: "ok")
            case .groupLeave:
                if let err = leaveGroupError { throw err }
                return APIMessageResponse(message: "ok")
            default:
                throw MockAPIClient.MockError.notConfigured
            }
        }
        client.postHandler = { endpoint, _ in
            if case .groupLeave = endpoint {
                if let err = leaveGroupError { throw err }
                return APIMessageResponse(message: "ok")
            }
            throw MockAPIClient.MockError.notConfigured
        }

        return (GroupService(apiClient: client), client, { deleteCount })
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
        let (service, _, _) = makeService()
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: service)
        let originalName = vm.group.name
        vm.renameGroup(to: "   ")
        #expect(vm.group.name == originalName)
    }

    @Test func testRenameGroupIgnoresWhitespaceOnlyName() {
        let (service, _, _) = makeService()
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: service)
        let originalName = vm.group.name
        vm.renameGroup(to: "\t\n")
        #expect(vm.group.name == originalName)
    }

    @Test func testRenameGroupSuccessUpdatesGroupAndSetsIsRenamed() async {
        let groupId = UUID()
        let (service, _, _) = makeService(groupId: groupId)
        let vm = GroupDetailViewModel(group: makeGroup(id: groupId), groupService: service)
        vm.renameGroup(to: "New Name")
        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(vm.group.name == "New Name")
        #expect(vm.isRenamed == true)
    }

    @Test func testRenameGroupTrimsWhitespace() async {
        let groupId = UUID()
        // Return trimmed name from mock
        let client = MockAPIClient()
        client.patchHandler = { _, _ in
            APIGroup(id: groupId, name: "Trimmed Name", createdBy: UUID(), createdAt: Date())
        }
        client.getHandler = { _ in throw MockAPIClient.MockError.notConfigured }
        let service = GroupService(apiClient: client)
        let vm = GroupDetailViewModel(group: makeGroup(id: groupId), groupService: service)
        vm.renameGroup(to: "  Trimmed Name  ")
        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(vm.group.name == "Trimmed Name")
    }

    @Test func testRenameGroupFailureSetsErrorMessage() async {
        struct RenameError: Error, LocalizedError {
            var errorDescription: String? { "rename failed" }
        }
        let (service, _, _) = makeService(renameGroupError: RenameError())
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: service)
        vm.renameGroup(to: "New Name")
        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(vm.errorMessage != nil)
        #expect(vm.isRenamed == false)
    }

    // MARK: - deleteGroup

    @Test func testDeleteGroupSuccessSetsDidDeleteOrLeave() async {
        let (service, _, _) = makeService()
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: service)
        vm.deleteGroup()
        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(vm.didDeleteOrLeave == true)
    }

    @Test func testDeleteGroupFailureSetsErrorMessage() async {
        struct DeleteGroupError: Error, LocalizedError {
            var errorDescription: String? { "cannot delete" }
        }
        let (service, _, _) = makeService(deleteGroupError: DeleteGroupError())
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: service)
        vm.deleteGroup()
        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(vm.errorMessage != nil)
        #expect(vm.didDeleteOrLeave == false)
    }

    // MARK: - canRemoveMember

    @Test func testCanRemoveMember_anyMemberCanRemoveOtherMember() {
        let creatorId = UUID()
        let alice = makeMember()
        let bob = makeMember()
        let vm = GroupDetailViewModel(group: makeGroup(createdBy: creatorId), currentUserId: alice.id)
        vm.members = [alice, bob]
        #expect(vm.canRemoveMember(bob) == true)
    }

    @Test func testCanRemoveMember_memberCannotRemoveSelf() {
        let alice = makeMember()
        let vm = GroupDetailViewModel(group: makeGroup(), currentUserId: alice.id)
        vm.members = [alice]
        #expect(vm.canRemoveMember(alice) == false)
    }

    @Test func testCanRemoveMember_unauthenticatedCannotRemove() {
        let alice = makeMember()
        let vm = GroupDetailViewModel(group: makeGroup(), currentUserId: nil)
        vm.members = [alice]
        #expect(vm.canRemoveMember(alice) == false)
    }

    @Test func testCanRemoveMember_nonCreatorCanRemoveCreator() {
        let creatorId = UUID()
        let creator = makeMember(id: creatorId)
        let alice = makeMember()
        let vm = GroupDetailViewModel(group: makeGroup(createdBy: creatorId), currentUserId: alice.id)
        vm.members = [creator, alice]
        #expect(vm.canRemoveMember(creator) == true)
    }

    // MARK: - removeMember

    @Test func testRemoveMemberOptimisticallyRemovesMemberFromList() {
        let (service, _, _) = makeService()
        let alice = makeMember(email: "alice@example.com")
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: service)
        vm.members = [alice]
        vm.removeMember(alice)
        #expect(vm.members.isEmpty)
    }

    @Test func testRemoveMemberSuccessRefreshesMembers() async {
        let bob = makeMember(email: "bob@example.com")
        let alice = makeMember(email: "alice@example.com")
        // After removal, only bob remains
        let (service, _, _) = makeService(stubbedMembers: [bob])
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: service)
        vm.members = [alice, bob]
        vm.removeMember(alice)
        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(vm.members.count == 1)
        #expect(vm.members.first?.email == "bob@example.com")
    }

    @Test func testRemoveMemberFailureRestoresMembersAndSetsError() async {
        struct RemoveError: Error, LocalizedError {
            var errorDescription: String? { "remove failed" }
        }
        let alice = makeMember(email: "alice@example.com")
        let (service, _, _) = makeService(removeMemberError: RemoveError())
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: service)
        vm.members = [alice]
        vm.removeMember(alice)
        try? await Task.sleep(nanoseconds: 100_000_000)
        // Restored
        #expect(vm.members.contains(where: { $0.id == alice.id }))
        #expect(vm.errorMessage != nil)
    }

    // MARK: - leaveGroup

    @Test func testLeaveGroupSuccessSetsDidDeleteOrLeave() async {
        let (service, _, _) = makeService()
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: service)
        vm.leaveGroup()
        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(vm.didDeleteOrLeave == true)
    }

    @Test func testLeaveGroupFailureSetsErrorMessage() async {
        struct LeaveError: Error, LocalizedError {
            var errorDescription: String? { "cannot leave" }
        }
        let (service, _, _) = makeService(leaveGroupError: LeaveError())
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: service)
        vm.leaveGroup()
        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(vm.errorMessage != nil)
        #expect(vm.didDeleteOrLeave == false)
    }

    // MARK: - deleteSettlement

    @Test func testDeleteSettlementOptimisticallyRemovesFromList() {
        let (service, _, _) = makeService()
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: service)
        let settlement = makeSettlement()
        vm.settlements = [settlement]
        vm.deleteSettlement(settlement)
        #expect(vm.settlements.isEmpty)
    }

    @Test func testDeleteSettlementFailureRestoresSettlementAndSetsError() async {
        struct SettlementDeleteError: Error, LocalizedError {
            var errorDescription: String? { "delete failed" }
        }
        let (service, _, _) = makeService(deleteSettlementError: SettlementDeleteError())
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: service)
        let settlement = makeSettlement()
        vm.settlements = [settlement]
        vm.deleteSettlement(settlement)
        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(vm.settlements.contains(where: { $0.id == settlement.id }))
        #expect(vm.errorMessage != nil)
    }

    @Test func testDeleteSettlementSuccessReloadsData() async {
        let groupId = UUID()
        let alice = makeMember()
        let (service, _, _) = makeService(groupId: groupId, stubbedMembers: [alice])
        let vm = GroupDetailViewModel(group: makeGroup(id: groupId), groupService: service)
        let settlement = makeSettlement(groupId: groupId)
        vm.settlements = [settlement]
        vm.deleteSettlement(settlement)
        try? await Task.sleep(nanoseconds: 200_000_000)
        // Settlements should be cleared (reloadData returns empty settlements from mock)
        #expect(vm.settlements.isEmpty)
    }

    // MARK: - transactionEdited

    @Test func testTransactionEditedOptimisticallyReplacesOld() async {
        let (service, _, _) = makeService()
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: service)
        let txId = UUID()
        let old = makeTransaction(id: txId, totalAmount: 100)
        let updated = makeTransaction(id: txId, totalAmount: 200)
        vm.transactions = [old]
        vm.transactionEdited(replacing: old, with: updated)
        // Optimistic update is immediate
        #expect(vm.transactions.contains(where: { $0.id == txId && $0.totalAmount == 200 }))
    }

    @Test func testTransactionEditedDoesNotCallDelete() async {
        // Regression: transactionEdited must NOT call deleteGroupTransaction.
        // The PATCH already ran in AddTransactionViewModel; calling DELETE here would destroy the transaction.
        let (service, _, getDeleteCallCount) = makeService()
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: service)
        let txId = UUID()
        let old = makeTransaction(id: txId, totalAmount: 100)
        let updated = makeTransaction(id: txId, totalAmount: 200)
        vm.transactions = [old]
        vm.transactionEdited(replacing: old, with: updated)
        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(getDeleteCallCount() == 0)
    }

    @Test func testTransactionEditedWithDifferentIdUpdatesCorrectSlot() async {
        let (service, _, _) = makeService()
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: service)
        let txId = UUID()
        let other = makeTransaction(totalAmount: 50)
        let old = makeTransaction(id: txId, totalAmount: 100)
        let updated = makeTransaction(id: txId, totalAmount: 200)
        vm.transactions = [old, other]
        vm.transactionEdited(replacing: old, with: updated)
        // The slot for old should now contain updated; other is untouched
        #expect(vm.transactions.contains(where: { $0.id == txId && $0.totalAmount == 200 }))
        #expect(vm.transactions.contains(where: { $0.id == other.id }))
    }
}
