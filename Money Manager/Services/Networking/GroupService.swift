//
//  GroupService.swift
//  Money Manager
//

import Foundation

final class GroupService: GroupServiceProtocol {
    static let shared = GroupService()
    private let apiClient = APIClient.shared

    private init() {}

    func fetchGroups() async throws -> [APIGroupWithDetails] {
        let response: APIGroupsListResponse = try await apiClient.get("/groups")
        return response.data
    }

    func createGroup(name: String) async throws -> APIGroup {
        let request = APICreateGroupRequest(name: name)
        return try await apiClient.post("/groups", body: request)
    }

    func fetchGroupDetails(groupId: UUID) async throws -> APIGroupDetails {
        try await apiClient.get("/groups/\(groupId.uuidString)")
    }

    func fetchMembers(groupId: UUID) async throws -> [APIGroupMember] {
        let response: APIGroupMembersResponse = try await apiClient.get("/groups/\(groupId.uuidString)/members")
        return response.members
    }

    func addMember(groupId: UUID, email: String) async throws {
        let request = APIAddMemberRequest(email: email)
        let _: APIMessageResponse = try await apiClient.post("/groups/\(groupId.uuidString)/add-member", body: request)
    }

    func fetchBalances(groupId: UUID) async throws -> [APIGroupBalance] {
        try await apiClient.get("/groups/\(groupId.uuidString)/balances")
    }

    func createSharedExpense(_ request: APICreateSharedExpenseRequest) async throws -> APIGroupExpense {
        try await apiClient.post("/groups/\(request.groupId.uuidString)/expenses", body: request)
    }

    func createSettlement(_ request: APICreateSettlementRequest) async throws -> APISettlement {
        try await apiClient.post("/groups/\(request.groupId.uuidString)/settlements", body: request)
    }
}
