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
        return APIGroup(id: UUID(), name: name, created_by: UUID(), created_at: Date())
    }

    func fetchGroupDetails(groupId: UUID) async throws -> APIGroupDetails {
        if let details = stubbedGroupDetails { return details }
        let body = APIGroupDetailsBody(
            id: groupId, name: "Mock Group", created_by: UUID(), created_at: Date(),
            members: stubbedMembers, balances: stubbedBalances, expenses: []
        )
        return APIGroupDetails(group: body, is_member: true)
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

    func createSharedExpense(_ request: APICreateSharedExpenseRequest) async throws -> APIGroupExpense {
        APIGroupExpense(
            id: UUID(),
            description: request.description,
            total_amount: request.totalAmount,
            paid_by: request.splits.first?.userId ?? UUID(),
            created_at: Date()
        )
    }

    func createSettlement(_ request: APICreateSettlementRequest) async throws -> APISettlement {
        APISettlement(
            id: UUID(),
            groupId: request.groupId,
            fromUser: request.fromUser,
            toUser: request.toUser,
            amount: request.amount,
            createdAt: Date()
        )
    }
}
#endif
