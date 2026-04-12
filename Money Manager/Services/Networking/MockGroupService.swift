//
//  MockGroupService.swift
//  Money Manager
//

#if DEBUG
import Foundation

final class MockGroupService: GroupServiceProtocol {
    static let shared = MockGroupService()

    // Configurable stubs for tests
    var stubbedGroups: [APIGroupWithDetails] = []
    var stubbedGroupDetails: APIGroupDetails? = nil
    var stubbedMembers: [APIGroupMember] = []
    var stubbedBalances: [APIGroupBalance] = []
    var addMemberError: Error? = nil
    var createGroupResult: APIGroup? = nil

    // Call tracking
    var addMemberCalls: [(groupId: UUID, email: String)] = []
    var createGroupCalls: [String] = []

    private init() {}

    /// Returns a fresh isolated instance for use in individual tests.
    static func fresh() -> MockGroupService { MockGroupService() }

    func fetchGroups() async throws -> [APIGroupWithDetails] {
        stubbedGroups
    }

    func createGroup(name: String) async throws -> APIGroup {
        createGroupCalls.append(name)
        if let result = createGroupResult { return result }
        return APIGroup(id: UUID(), name: name, createdBy: UUID(), createdAt: Date())
    }

    func fetchGroupDetails(groupId: UUID) async throws -> APIGroupDetails {
        if let details = stubbedGroupDetails { return details }
        let body = APIGroupDetailsBody(
            id: groupId, name: "Mock Group", createdBy: UUID(), createdAt: Date(),
            members: stubbedMembers, balances: stubbedBalances, settlements: []
        )
        return APIGroupDetails(group: body, isMember: true)
    }

    func fetchMembers(groupId: UUID) async throws -> [APIGroupMember] {
        stubbedMembers
    }

    func addMember(groupId: UUID, email: String) async throws {
        addMemberCalls.append((groupId: groupId, email: email))
        if let error = addMemberError { throw error }
    }

    func fetchBalances(groupId: UUID) async throws -> [APIGroupBalance] {
        stubbedBalances
    }

    var stubbedTransactions: [APIGroupTransaction] = []

    func fetchGroupTransactions(groupId: UUID) async throws -> [APIGroupTransaction] {
        stubbedTransactions
    }

    func deleteGroupTransaction(groupId: UUID, transactionId: UUID) async throws {}

    func createGroupTransaction(_ request: APICreateGroupTransactionRequest, groupId: UUID) async throws -> APIGroupTransaction {
        APIGroupTransaction(
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
    }

    func createSettlement(_ request: APICreateSettlementRequest) async throws -> APISettlement {
        APISettlement(
            id: UUID(),
            groupId: request.groupId,
            fromUser: request.fromUser,
            toUser: request.toUser,
            amount: request.amount,
            notes: request.notes,
            createdAt: Date()
        )
    }
}
#endif
