//
//  GroupService.swift
//  Money Manager
//

import Foundation

final class GroupService: GroupServiceProtocol {
    static let shared = GroupService()
    private let apiClient = AppAPIClient.shared

    private init() {}

    func fetchGroups() async throws -> [APIGroupWithDetails] {
        let response: APIGroupsListResponse = try await apiClient.get(.groups)
        return response.data
    }

    func createGroup(name: String) async throws -> APIGroup {
        let request = APICreateGroupRequest(name: name)
        return try await apiClient.post(.groups, body: request)
    }

    func fetchGroupDetails(groupId: UUID) async throws -> APIGroupDetails {
        try await apiClient.get(.group(groupId))
    }

    func fetchMembers(groupId: UUID) async throws -> [APIGroupMember] {
        let response: APIListResponse<APIGroupMember> = try await apiClient.get(.groupMembers(groupId))
        return response.data
    }

    func addMember(groupId: UUID, email: String) async throws {
        let request = APIAddMemberRequest(email: email)
        let _: APIMessageResponse = try await apiClient.post(.groupAddMember(groupId), body: request)
    }

    func fetchBalances(groupId: UUID) async throws -> [APIGroupBalance] {
        try await apiClient.get(.groupBalances(groupId))
    }

    func createGroupTransaction(_ request: APICreateGroupTransactionRequest, groupId: UUID) async throws -> APIGroupTransaction {
        try await apiClient.post(.groupTransactions(groupId), body: request)
    }

    func fetchGroupTransactions(groupId: UUID) async throws -> [APIGroupTransaction] {
        let response: APIListResponse<APIGroupTransaction> = try await apiClient.get(.groupTransactions(groupId))
        return response.data
    }

    func deleteGroupTransaction(groupId: UUID, transactionId: UUID) async throws {
        let _: APIMessageResponse = try await apiClient.deleteMessage(.groupTransaction(groupId: groupId, transactionId: transactionId))
    }

    func createSettlement(_ request: APICreateSettlementRequest) async throws -> APISettlement {
        try await apiClient.post(.settlements, body: request)
    }
}
