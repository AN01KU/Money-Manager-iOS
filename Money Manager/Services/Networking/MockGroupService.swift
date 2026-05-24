//
//  MockGroupService.swift
//  Money Manager
//

#if DEBUG
import Foundation

final class MockGroupService: GroupServiceProtocol {
    static let shared = MockGroupService()

    // Configurable stubs for tests
    var stubbedGroups: [SplitGroup] = []
    var stubbedGroupDetails: SplitGroup? = nil
    var stubbedMembers: [GroupMember] = []
    var stubbedBalances: [GroupBalance] = []
    var addMemberError: Error? = nil
    var createGroupResult: SplitGroup? = nil
    var renameGroupError: Error? = nil
    var deleteGroupError: Error? = nil
    var removeMemberError: Error? = nil
    var leaveGroupError: Error? = nil
    var deleteSettlementError: Error? = nil

    // Call tracking
    var addMemberCalls: [(groupId: UUID, email: String)] = []
    var createGroupCalls: [String] = []

    private init() {}

    /// Returns a fresh isolated instance for use in individual tests.
    static func fresh() -> MockGroupService { MockGroupService() }

    func fetchGroups() async throws -> [SplitGroup] {
        stubbedGroups
    }

    func createGroup(name: String) async throws -> SplitGroup {
        createGroupCalls.append(name)
        if let result = createGroupResult { return result }
        return SplitGroup(id: UUID(), name: name, createdBy: UUID(), createdAt: Date(), members: [], balances: [], settlements: [])
    }

    func renameGroup(groupId: UUID, name: String) async throws -> SplitGroup {
        if let error = renameGroupError { throw error }
        return SplitGroup(id: groupId, name: name, createdBy: UUID(), createdAt: Date(), members: [], balances: [], settlements: [])
    }

    func deleteGroup(groupId: UUID) async throws {
        if let error = deleteGroupError { throw error }
    }

    func removeMember(groupId: UUID, userId: UUID) async throws {
        if let error = removeMemberError { throw error }
    }

    func leaveGroup(groupId: UUID) async throws {
        if let error = leaveGroupError { throw error }
    }

    func fetchGroupDetails(groupId: UUID) async throws -> SplitGroup {
        if let details = stubbedGroupDetails { return details }
        return SplitGroup(
            id: groupId, name: "Mock Group", createdBy: UUID(), createdAt: Date(),
            members: stubbedMembers, balances: stubbedBalances, settlements: []
        )
    }

    func fetchMembers(groupId: UUID) async throws -> [GroupMember] {
        stubbedMembers
    }

    func addMember(groupId: UUID, email: String) async throws {
        addMemberCalls.append((groupId: groupId, email: email))
        if let error = addMemberError { throw error }
    }

    func fetchBalances(groupId: UUID) async throws -> [GroupBalance] {
        stubbedBalances
    }

    var stubbedTransactions: [GroupTransaction] = []
    var deleteError: Error? = nil
    var deleteCallCount = 0
    var updateGroupTransactionError: Error? = nil
    var lastUpdateRequest: APIUpdateGroupTransactionRequest? = nil

    func fetchGroupTransactions(groupId: UUID) async throws -> [GroupTransaction] {
        stubbedTransactions
    }

    func deleteGroupTransaction(groupId: UUID, transactionId: UUID) async throws {
        deleteCallCount += 1
        if let error = deleteError { throw error }
    }

    func createGroupTransaction(_ request: APICreateGroupTransactionRequest, groupId: UUID) async throws -> GroupTransaction {
        let dto = APIGroupTransaction(
            id: UUID(),
            groupId: groupId,
            paidByUserId: request.paidByUserId,
            totalAmount: request.totalAmount,
            category: request.category,
            date: request.date,
            description: request.description,
            notes: request.notes,
            isDeleted: false,
            createdAt: Date(),
            updatedAt: Date(),
            splits: []
        )
        return try GroupTransaction(from: dto)
    }

    func updateGroupTransaction(_ request: APIUpdateGroupTransactionRequest, groupId: UUID, transactionId: UUID) async throws -> GroupTransaction {
        lastUpdateRequest = request
        if let error = updateGroupTransactionError { throw error }
        let dto = APIGroupTransaction(
            id: transactionId,
            groupId: groupId,
            paidByUserId: UUID(),
            totalAmount: 0,
            category: request.category ?? "other",
            date: request.date ?? Date(),
            description: request.description,
            notes: request.notes,
            isDeleted: false,
            createdAt: Date(),
            updatedAt: Date(),
            splits: []
        )
        return try GroupTransaction(from: dto)
    }

    func deleteSettlement(settlementId: UUID) async throws {
        if let error = deleteSettlementError { throw error }
    }

    func createSettlement(_ request: APICreateSettlementRequest) async throws -> Settlement {
        let dto = APISettlement(
            id: UUID(),
            groupId: request.groupId,
            fromUser: request.fromUser,
            toUser: request.toUser,
            amount: request.amount,
            notes: request.notes,
            createdAt: Date()
        )
        return Settlement(from: dto)
    }
}
#endif
